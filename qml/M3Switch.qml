import QtQuick 2.15

// Material 3 switch: 52x32 track, thumb grows when on
Item {
    id: sw
    property bool checked: false
    property color accent: "#00a2ed"
    property color ink: "#1d1b20"
    property bool animate: true
    signal toggled(bool checked)

    width: 52
    height: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? sw.accent : "transparent"
        border.width: sw.checked ? 0 : 2
        border.color: Qt.rgba(sw.ink.r, sw.ink.g, sw.ink.b, 0.55)
        Behavior on color { enabled: sw.animate; ColorAnimation { duration: 120 } }
    }
    Rectangle {
        id: thumb
        readonly property real d: sw.checked ? 24 : 16
        width: d
        height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? sw.width - d - 4 : 8
        color: sw.checked ? "#ffffff" : Qt.rgba(sw.ink.r, sw.ink.g, sw.ink.b, 0.55)
        Behavior on x { enabled: sw.animate; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: sw.animate; NumberAnimation { duration: 150 } }
        Behavior on height { enabled: sw.animate; NumberAnimation { duration: 150 } }

        Canvas {     // check mark in the "on" thumb
            anchors.centerIn: parent
            width: 14; height: 14
            visible: sw.checked
            onVisibleChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.strokeStyle = sw.accent; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); c.moveTo(3, 7.5); c.lineTo(6, 10.5); c.lineTo(11.5, 4); c.stroke()
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        onClicked: sw.toggled(!sw.checked)
    }
}
