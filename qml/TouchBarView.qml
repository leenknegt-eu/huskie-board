import QtQuick 2.15
import QtQuick.Layouts 1.15

// Gboard-style icon toolbar above the keys
Item {
    id: touchBar
    height: 44

    property var currentTheme
    property var controller
    property var vk
    property var klipper
    property var cardBox
    property var mainWindow

    readonly property color ink: currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd"
    readonly property color accent: currentTheme ? currentTheme.accentColor : "#00a2ed"
    // flat toolbar: no circle behind idle icons
    readonly property color idle: "transparent"

    readonly property var sizeModes: ["normal", "full", "onehand"]

    RowLayout {
        anchors.fill: parent
        spacing: 6

        // Drag grip (floating mode only)
        Item {
            visible: !!(cardBox && cardBox.draggable)
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            Text {
                anchors.centerIn: parent
                text: ":::"
                color: touchBar.ink
                font.pixelSize: 14
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                property point startPos: "0,0"
                onPressed: (mouse) => { startPos = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    // moveBy() keeps the card on-screen and ignores drags when docked
                    if (pressed && cardBox) cardBox.moveBy(mouse.x - startPos.x, mouse.y - startPos.y)
                }
            }
        }

        IconButton {
            icon: "clipboard"
            active: !!(controller && controller.layoutMode === "klipper")
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: if (controller) controller.layoutMode = (controller.layoutMode === "klipper" ? "abc" : "klipper")
        }

        IconButton {
            icon: "terminal"
            active: !!(controller && controller.isTerminalMode)
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: if (controller) controller.isTerminalMode = !controller.isTerminalMode
        }

        Item { Layout.fillWidth: true }

        // Layout size: tap to cycle normal -> extended -> one-handed
        IconButton {
            icon: controller ? ("size-" + controller.sizeMode) : "size-normal"
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: {
                if (!controller) return
                var i = touchBar.sizeModes.indexOf(controller.sizeMode)
                controller.sizeMode = touchBar.sizeModes[(i + 1) % touchBar.sizeModes.length]
            }
        }

        // Dock / float: icon shows the current state
        IconButton {
            icon: (cardBox && cardBox.docked) ? "docked" : "floating"
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: if (mainWindow) mainWindow.toggleDocked()
        }

        IconButton {
            icon: "gear"
            active: !!(mainWindow && mainWindow.showSettings)
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: if (mainWindow) mainWindow.showSettings = !mainWindow.showSettings
        }

        IconButton {
            icon: "hide"
            iconColor: touchBar.ink; activeColor: touchBar.accent; idleColor: touchBar.idle
            onClicked: if (mainWindow) mainWindow.hideKeyboard()
        }
    }
}
