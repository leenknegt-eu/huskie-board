import QtQuick 2.15
import "Emoji.js" as Emoji

// Emoji picker, Gboard style: scrollable grid of the current category, and a bottom
// bar with ABC, category tabs and backspace.
Item {
    id: em

    property var host
    property var currentTheme
    property var vk
    property var controller

    property int category: 0

    readonly property color ink: currentTheme ? currentTheme.textColor : "#202124"
    readonly property color accent: currentTheme ? currentTheme.accentColor : "#1a73e8"
    readonly property bool animate: typeof prefs === "undefined" || prefs.animations

    readonly property real gap: 6
    readonly property real unit: width / 10
    readonly property real barH: Math.max(40, (height - gap * 3) / 4)

    // ---- Emoji grid ----
    Flickable {
        id: flick
        x: 0
        y: 0
        width: em.width
        height: em.height - em.barH - em.gap
        clip: true
        contentWidth: width
        contentHeight: grid.height
        boundsBehavior: Flickable.StopAtBounds

        readonly property int cols: Math.max(6, Math.floor(width / 64))
        readonly property real cell: width / cols

        Grid {
            id: grid
            columns: flick.cols
            Repeater {
                model: Emoji.categories[em.category].emoji
                delegate: Item {
                    width: flick.cell
                    height: Math.min(flick.cell, 60)

                    Rectangle {     // press highlight
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: width / 2
                        color: em.accent
                        opacity: cellArea.pressed ? 0.22 : 0
                        Behavior on opacity { enabled: em.animate; NumberAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Math.min(30, parent.height * 0.55)
                    }
                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        onClicked: if (em.vk) em.vk.sendEmoji(modelData)
                    }
                }
            }
        }
    }

    // ---- Bottom bar: ABC | category tabs | backspace ----
    KeyButton {
        x: em.unit * 0 + em.gap / 2
        y: em.height - em.barH
        width: em.unit * 1.5 - em.gap
        height: em.barH
        label: "ABC"
        isSpecial: true
        isCustomAction: true
        currentTheme: em.currentTheme
        onReleased: if (em.controller) em.controller.layoutMode = "abc"
    }

    Row {
        id: tabs
        x: em.unit * 1.5
        y: em.height - em.barH
        width: em.unit * 7
        height: em.barH
        Repeater {
            model: Emoji.categories
            delegate: Item {
                width: tabs.width / Emoji.categories.length
                height: tabs.height
                readonly property bool current: index === em.category
                Rectangle {     // tonal selection pill
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 6, 52)
                    height: Math.min(parent.height - 6, 36)
                    radius: height / 2
                    color: Qt.rgba(em.accent.r, em.accent.g, em.accent.b, 0.22)
                    visible: parent.current
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font.pixelSize: 20
                    opacity: parent.current ? 1 : 0.6
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { em.category = index; flick.contentY = 0 }
                }
            }
        }
    }

    KeyButton {
        x: em.unit * 8.5 + em.gap / 2
        y: em.height - em.barH
        width: em.unit * 1.5 - em.gap
        height: em.barH
        icon: "backspace"
        isSpecial: true
        isBackspace: true
        currentTheme: em.currentTheme
        controller: em.controller
        vk: em.vk
    }
}
