import QtQuick 2.15

// Minimal touch-friendly slider (self-drawn so it matches every theme)
Item {
    id: slider
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property color accent: "#00a2ed"
    property color trackColor: "#888888"
    signal moved(real v)

    height: 36
    readonly property real frac: (value - from) / (to - from)

    Rectangle {     // track
        anchors.verticalCenter: parent.verticalCenter
        x: 10; width: parent.width - 20; height: 4; radius: 2
        color: slider.trackColor
        opacity: 0.35
    }
    Rectangle {     // filled part
        anchors.verticalCenter: parent.verticalCenter
        x: 10; width: (parent.width - 20) * slider.frac; height: 4; radius: 2
        color: slider.accent
    }
    Rectangle {     // handle
        anchors.verticalCenter: parent.verticalCenter
        x: 10 + (parent.width - 20) * slider.frac - width / 2
        width: 22; height: 22; radius: 11
        color: slider.accent
        border.color: "#ffffff"
        border.width: 2
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function update(mx) {
            var f = Math.max(0, Math.min(1, (mx - 10) / (slider.width - 20)))
            var v = slider.from + f * (slider.to - slider.from)
            if (slider.stepSize > 0) v = Math.round(v / slider.stepSize) * slider.stepSize
            v = Math.max(slider.from, Math.min(slider.to, v))
            if (Math.abs(v - slider.value) > 1e-6) slider.moved(v)
        }
        onPressed: (mouse) => update(mouse.x)
        onPositionChanged: (mouse) => update(mouse.x)
    }
}
