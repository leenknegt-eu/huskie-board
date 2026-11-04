import QtQuick 2.15

// Selectable pill used in the settings panel
Rectangle {
    id: pill
    property string text
    property bool selected: false
    property color accent: "#00a2ed"
    property color labelColor: "#d0d5dd"
    signal tapped()

    width: Math.max(96, pillLabel.implicitWidth + 24)
    height: 32
    radius: 16
    color: selected ? accent : "transparent"
    border.color: selected ? accent : labelColor
    border.width: 1

    Text {
        id: pillLabel
        anchors.centerIn: parent
        text: pill.text
        color: pill.selected ? "#ffffff" : pill.labelColor
        font.pixelSize: 12
        font.bold: pill.selected
    }

    MouseArea {
        anchors.fill: parent
        onClicked: pill.tapped()
    }
}
