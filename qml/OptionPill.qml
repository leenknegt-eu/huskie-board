import QtQuick 2.15

// Material 3 filter chip: outlined, tonal fill + leading check mark when selected
Rectangle {
    id: chip
    property string text
    property bool selected: false
    property color accent: "#00a2ed"
    property color labelColor: "#d0d5dd"
    signal tapped()

    height: 32
    width: label.implicitWidth + (selected ? 44 : 32)
    radius: 8
    color: selected ? Qt.rgba(accent.r, accent.g, accent.b, 0.22) : "transparent"
    border.width: selected ? 0 : 1
    border.color: Qt.rgba(labelColor.r, labelColor.g, labelColor.b, 0.45)
    Behavior on width { NumberAnimation { duration: 120 } }

    Row {
        anchors.centerIn: parent
        spacing: 6
        Canvas {
            visible: chip.selected
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            onVisibleChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.strokeStyle = chip.labelColor; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); c.moveTo(3, 8.5); c.lineTo(6.5, 12); c.lineTo(13, 4.5); c.stroke()
            }
        }
        Text {
            id: label
            text: chip.text
            color: chip.labelColor
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: chip.tapped()
    }
}
