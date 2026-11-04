import QtQuick 2.15

// Soft Material-style drop shadow built from stacked translucent layers, so it
// renders on every scene-graph backend (no shader effects needed).
// Place it as a sibling *below* the surface, with the same geometry.
Item {
    id: elev
    property real radius: 12
    property int level: 2           // 1 = subtle, 2 = popup, 3 = high
    property color shadowColor: "#000000"

    Repeater {
        model: 4
        delegate: Rectangle {
            readonly property real spread: (index + 1) * elev.level * 0.9
            x: -spread
            y: -spread + elev.level * 1.5
            width: elev.width + spread * 2
            height: elev.height + spread * 2
            radius: elev.radius + spread
            color: elev.shadowColor
            opacity: 0.075 - index * 0.015
        }
    }
}
