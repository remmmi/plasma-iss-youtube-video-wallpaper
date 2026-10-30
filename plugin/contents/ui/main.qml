/*
 *  ISS live: Plasma 5 video wallpaper playing the local HLS relay
 *  (systemd --user service iss-hls-relay).
 *  Playback is done by the C++ module local.isslive.shared: a single player
 *  for all screens (one decode, identical frames so the screens stay in
 *  sync), muted, with reconnection and a watchdog.
 */

import QtQuick 2.12
import QtQuick.Window 2.12
import QtMultimedia 5.12
import local.isslive.shared 1.0

import "."

Rectangle {
    id: root
    color: "black"

    readonly property string sourceUrl: wallpaper.configuration.Source
    readonly property bool spanned: wallpaper.configuration.Layout === 1
    readonly property int fillModeIndex: wallpaper.configuration.FillMode
    readonly property bool autoPosition: wallpaper.configuration.AutoPosition

    // Screen of this wallpaper, in virtual desktop coordinates
    readonly property rect screenRect: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
    readonly property string screenName: Screen.name
    // Key of this instance in SyncBus: a destroyed wallpaper (plasmashell
    // sometimes recreates them at startup) must not erase the next one's entry
    readonly property string busKey: "isslive-" + Math.random().toString(36).slice(2)

    // Density of this screen in pixels per mm (physical sizes from xrandr)
    readonly property real pxPerMm: Screen.pixelDensity > 0 ? Screen.pixelDensity : 3.78

    // Spanned mode: physical position (mm) of the top left corner of the screen.
    // In automatic mode it is derived from the screen layout using the largest
    // pixel size of the desktop, so that screens do not overlap.
    function referenceMmPerPx() {
        var screens = Qt.application.screens
        var best = 1 / pxPerMm
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].pixelDensity > 0) {
                best = Math.max(best, 1 / screens[i].pixelDensity)
            }
        }
        return best
    }

    function updatePhysicalRect() {
        if (!spanned) {
            return
        }
        if (autoPosition) {
            var k = referenceMmPerPx()
            var autoX = Math.round(screenRect.x * k)
            var autoY = Math.round(screenRect.y * k)
            // Shows the computed position in the settings
            if (wallpaper.configuration.PositionX !== autoX) {
                wallpaper.configuration.PositionX = autoX
            }
            if (wallpaper.configuration.PositionY !== autoY) {
                wallpaper.configuration.PositionY = autoY
            }
        }
        SyncBus.setPhysicalRect(busKey, physicalRect)
    }

    readonly property rect physicalRect: Qt.rect(wallpaper.configuration.PositionX,
                                                  wallpaper.configuration.PositionY,
                                                  screenRect.width / pxPerMm,
                                                  screenRect.height / pxPerMm)

    // Deferred update: it writes to the config, which must not happen while
    // a binding is being evaluated
    function scheduleUpdate() { Qt.callLater(root.updatePhysicalRect) }
    onSpannedChanged: spanned ? scheduleUpdate() : SyncBus.removePhysicalRect(busKey)
    onAutoPositionChanged: scheduleUpdate()
    onPhysicalRectChanged: scheduleUpdate()
    onScreenNameChanged: scheduleUpdate()
    Connections {
        target: Qt.application
        function onScreensChanged() { root.scheduleUpdate() }
    }

    SharedVideoSource {
        id: sharedSource
        url: root.sourceUrl
    }

    VideoOutput {
        id: videoOutput
        source: sharedSource
        fillMode: root.fillModeIndex === 1 ? VideoOutput.PreserveAspectCrop
                : root.fillModeIndex === 2 ? VideoOutput.Stretch
                : VideoOutput.PreserveAspectFit
        // In spanned mode the video covers the whole physical canvas, scaled
        // for this screen: a mm stays a mm from one screen to the next
        x: root.spanned ? (SyncBus.canvas.x - root.physicalRect.x) * root.pxPerMm : 0
        y: root.spanned ? (SyncBus.canvas.y - root.physicalRect.y) * root.pxPerMm : 0
        width: root.spanned ? SyncBus.canvas.width * root.pxPerMm : root.width
        height: root.spanned ? SyncBus.canvas.height * root.pxPerMm : root.height
    }

    Deblock {
        anchors.fill: parent
        visible: wallpaper.configuration.Deblock
        source: videoOutput
        strength: wallpaper.configuration.DeblockStrength / 100
        // Display scale of the video: screen pixels per source pixel
        blockSize: videoOutput.sourceRect.width > 0
                   ? 8 * videoOutput.contentRect.width / videoOutput.sourceRect.width : 8
    }

    Component.onCompleted: scheduleUpdate()
    Component.onDestruction: SyncBus.removePhysicalRect(busKey)
}
