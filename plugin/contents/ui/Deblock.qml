import QtQuick 2.12

// Applies deblock.frag to the visible part of a VideoOutput. The video is
// captured at the size of the screen (not at the size of the spanned canvas,
// which is much larger), then filtered in a single pass.
Item {
    id: filter

    property Item source
    // Size of an 8 pixel video block once displayed, in screen pixels
    property real blockSize: 8
    // Strength, from 0 to 1
    property real strength: 0.5

    ShaderEffectSource {
        id: capture
        sourceItem: filter.source
        sourceRect: filter.source ? Qt.rect(-filter.source.x, -filter.source.y, filter.width, filter.height)
                                  : Qt.rect(0, 0, 0, 0)
        textureSize: Qt.size(filter.width, filter.height)
        hideSource: filter.visible
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property variant source: capture
        property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
        property real radius: Math.max(1, filter.blockSize * 0.75)
        property real threshold: 0.01 + 0.04 * filter.strength
        property real amount: filter.strength
        fragmentShader: Qt.resolvedUrl("deblock.frag")
    }
}
