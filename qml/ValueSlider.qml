import QtQuick 2.15

// Material 3 (2024) slider: thick rounded track split by a vertical handle bar
Item {
    id: slider
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property color accent: "#00a2ed"
    property color trackColor: "#888888"
    signal moved(real v)

    height: 44
    readonly property real frac: (value - from) / (to - from)
    readonly property real handleX: 8 + (width - 16) * frac
    readonly property real gapHalf: 6

    Rectangle {     // active part
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        width: Math.max(0, slider.handleX - slider.gapHalf - 8)
        height: 16
        radius: 8
        color: slider.accent
    }
    Rectangle {     // inactive part
        anchors.verticalCenter: parent.verticalCenter
        x: slider.handleX + slider.gapHalf
        width: Math.max(0, slider.width - 8 - x)
        height: 16
        radius: 8
        color: Qt.rgba(slider.accent.r, slider.accent.g, slider.accent.b, 0.22)
    }
    Rectangle {     // handle bar
        anchors.verticalCenter: parent.verticalCenter
        x: slider.handleX - width / 2
        width: 4
        height: 40
        radius: 2
        color: slider.accent
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function update(mx) {
            var f = Math.max(0, Math.min(1, (mx - 8) / (slider.width - 16)))
            var v = slider.from + f * (slider.to - slider.from)
            if (slider.stepSize > 0) v = Math.round(v / slider.stepSize) * slider.stepSize
            v = Math.max(slider.from, Math.min(slider.to, v))
            if (Math.abs(v - slider.value) > 1e-6) slider.moved(v)
        }
        onPressed: (mouse) => update(mouse.x)
        onPositionChanged: (mouse) => update(mouse.x)
    }
}
