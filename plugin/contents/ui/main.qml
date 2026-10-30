/*
 *  ISS en direct : fond d'ecran video Plasma 5 lisant le relais HLS local
 *  (service systemd --user iss-hls-relay).
 *  La lecture est faite par le module C++ local.isslive.shared : un seul
 *  lecteur pour tous les ecrans (un decodage, images identiques donc
 *  synchronisees), muet, avec reconnexion et chien de garde.
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

    // Ecran de ce fond, en coordonnees du bureau virtuel
    readonly property rect screenRect: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
    readonly property string screenName: Screen.name
    // Cle propre a cette instance dans SyncBus : un fond detruit (plasmashell
    // en recree parfois au demarrage) ne doit pas effacer celle du suivant
    readonly property string busKey: "isslive-" + Math.random().toString(36).slice(2)

    // Densite de cet ecran en pixels par mm (tailles physiques de xrandr)
    readonly property real pxPerMm: Screen.pixelDensity > 0 ? Screen.pixelDensity : 3.78

    // Mode etale : position physique (mm) du coin haut gauche de l'ecran.
    // En automatique, on la deduit de la disposition des ecrans avec la plus
    // grande taille de pixel du bureau, pour que les ecrans ne se chevauchent pas.
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
            // Affiche la position calculee dans les reglages
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

    // Mise a jour differee : elle ecrit dans la config, ce qui ne doit pas
    // se faire pendant l'evaluation d'une liaison
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
        // En mode etale, la video couvre toute la toile physique, mise a
        // l'echelle de cet ecran : un mm reste un mm d'un ecran a l'autre
        x: root.spanned ? (SyncBus.canvas.x - root.physicalRect.x) * root.pxPerMm : 0
        y: root.spanned ? (SyncBus.canvas.y - root.physicalRect.y) * root.pxPerMm : 0
        width: root.spanned ? SyncBus.canvas.width * root.pxPerMm : root.width
        height: root.spanned ? SyncBus.canvas.height * root.pxPerMm : root.height
    }

    Component.onCompleted: scheduleUpdate()
    Component.onDestruction: SyncBus.removePhysicalRect(busKey)
}
