pragma Singleton
import QtQuick 2.12

// Object shared by all the wallpapers of the plugin (one per screen) in
// plasmashell. In spanned mode each screen registers its physical rectangle
// (in mm); the common canvas is the rectangle enclosing all of them.
QtObject {
    id: bus

    // Physical rectangles of the screens in spanned mode, per wallpaper instance
    property var physicalRects: ({})
    property rect canvas: Qt.rect(0, 0, 0, 0)

    function setPhysicalRect(key, r) {
        physicalRects[key] = r
        updateCanvas()
    }

    function removePhysicalRect(key) {
        delete physicalRects[key]
        updateCanvas()
    }

    function updateCanvas() {
        var first = true
        var x1 = 0, y1 = 0, x2 = 0, y2 = 0
        for (var key in physicalRects) {
            var r = physicalRects[key]
            if (first) {
                x1 = r.x; y1 = r.y; x2 = r.x + r.width; y2 = r.y + r.height
                first = false
            } else {
                x1 = Math.min(x1, r.x)
                y1 = Math.min(y1, r.y)
                x2 = Math.max(x2, r.x + r.width)
                y2 = Math.max(y2, r.y + r.height)
            }
        }
        canvas = Qt.rect(x1, y1, x2 - x1, y2 - y1)
        console.warn("isslive: canvas " + canvas.width + "x" + canvas.height + " mm")
    }
}
