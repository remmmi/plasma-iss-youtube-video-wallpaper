pragma Singleton
import QtQuick 2.12

// Objet partage par tous les fonds d'ecran du plugin (un par ecran) dans
// plasmashell. En mode etale, chaque ecran y inscrit son rectangle physique
// (en mm) ; la toile commune est le rectangle qui les englobe tous.
QtObject {
    id: bus

    // Rectangles physiques des ecrans en mode etale, par instance de fond
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
        console.warn("isslive: toile " + canvas.width + "x" + canvas.height + " mm")
    }
}
