import QtQuick 2.15

// Material 3 segmented button (single select). options: [{ value, label }]
Item {
    id: seg
    property var options: []
    property var current
    property color accent: "#00a2ed"
    property color ink: "#1d1b20"
    property color surface: "#ffffff"   // background it sits on (fill is blended opaque)
    signal selected(var value)

    height: 40
    implicitWidth: row.implicitWidth

    readonly property color outline: Qt.rgba(ink.r, ink.g, ink.b, 0.45)
    readonly property color selectedFill: Qt.tint(surface, Qt.rgba(accent.r, accent.g, accent.b, 0.22))

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: seg.outline
    }

    Row {
        id: row
        anchors.fill: parent
        Repeater {
            model: seg.options
            delegate: Item {
                readonly property bool isSel: modelData.value === seg.current
                width: Math.max(96, lbl.implicitWidth + (isSel ? 52 : 32))
                height: seg.height

                // selected fill, rounded only on the outer ends
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: parent.isSel
                    color: seg.selectedFill
                    radius: (index === 0 || index === seg.options.length - 1) ? height / 2 : 0
                    Rectangle {     // square off the inner side of an end segment
                        visible: seg.options.length > 1 && (index === 0 || index === seg.options.length - 1)
                        width: parent.width / 2; height: parent.height
                        x: index === 0 ? parent.width / 2 : 0
                        color: seg.selectedFill
                    }
                }
                Rectangle {     // divider
                    visible: index > 0
                    width: 1; height: parent.height
                    color: seg.outline
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Canvas {
                        visible: parent.parent.isSel
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        onVisibleChanged: requestPaint()
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            c.strokeStyle = seg.ink; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round"
                            c.beginPath(); c.moveTo(3, 8.5); c.lineTo(6.5, 12); c.lineTo(13, 4.5); c.stroke()
                        }
                    }
                    Text {
                        id: lbl
                        text: modelData.label
                        color: seg.ink
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: seg.selected(modelData.value) }
            }
        }
    }
}
