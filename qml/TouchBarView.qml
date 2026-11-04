import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: touchBar
    height: 44
    color: "transparent"

    property var currentTheme
    property var controller
    property var vk
    property var klipper
    property var cardBox
    property var mainWindow

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left section: drag grip (floating mode only)
        Rectangle {
            visible: !(cardBox && cardBox.docked)
            width: titleText.width + 16
            height: 34
            color: "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: titleText
                text: ":::"
                color: currentTheme ? currentTheme.textColor : "#1e1e1e"
                font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
                font.pixelSize: 14
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                id: dragMouseArea
                anchors.fill: parent
                cursorShape: cardBox && cardBox.docked ? Qt.ArrowCursor : Qt.SizeAllCursor
                property point startPos: "0,0"

                onPressed: (mouse) => {
                    startPos = Qt.point(mouse.x, mouse.y)
                }

                onPositionChanged: (mouse) => {
                    if (pressed && cardBox) {
                        // moveBy() keeps the card on-screen and ignores drags when docked
                        cardBox.moveBy(mouse.x - startPos.x, mouse.y - startPos.y)
                    }
                }
            }
        }

        // Center section: Mode Pills in Dark Container
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 17
            color: currentTheme && currentTheme.headerPillBg ? currentTheme.headerPillBg : "#434a56"
            Layout.alignment: Qt.AlignVCenter

            Flickable {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                contentWidth: pillRow.width
                clip: true

                Row {
                    id: pillRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    // ABC Pill
                    Rectangle {
                        width: 48
                        height: 26
                        radius: 13
                        color: controller && controller.layoutMode === "abc" ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "ABC"
                            color: controller && controller.layoutMode === "abc" ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (controller) controller.layoutMode = "abc"
                        }
                    }

                    // Split Pill
                    Rectangle {
                        visible: controller ? controller.sizeMode !== "onehand" : true
                        width: 62
                        height: 26
                        radius: 13
                        color: controller && controller.isSplit ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "▯▯ Split"
                            color: controller && controller.isSplit ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (controller) controller.isSplit = !controller.isSplit
                        }
                    }

                    // Klipper Pill
                    Rectangle {
                        width: 64
                        height: 26
                        radius: 13
                        color: controller && controller.layoutMode === "klipper" ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "📋 Klipper"
                            color: controller && controller.layoutMode === "klipper" ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (controller) controller.layoutMode = "klipper"
                        }
                    }

                    // Terminal Mode Pill (>_ Term)
                    Rectangle {
                        width: 64
                        height: 26
                        radius: 13
                        color: controller && controller.isTerminalMode ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ">_ Term"
                            color: controller && controller.isTerminalMode ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (controller) controller.isTerminalMode = !controller.isTerminalMode
                        }
                    }

                }
            }
        }

        // Right section: Size Mode Segmented Switcher in Dark Container
        Rectangle {
            width: 230
            height: 34
            radius: 17
            color: currentTheme && currentTheme.sizeModePillBg ? currentTheme.sizeModePillBg : "#21252d"
            Layout.alignment: Qt.AlignVCenter

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 2

                // Normal
                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height
                    radius: 14
                    color: controller && controller.sizeMode === "normal" ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Normal"
                        color: controller && controller.sizeMode === "normal" ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                        font.pixelSize: 11
                        font.bold: controller && controller.sizeMode === "normal"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (controller) controller.sizeMode = "normal"
                    }
                }

                // Extended (Full)
                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height
                    radius: 14
                    color: controller && controller.sizeMode === "full" ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Extended"
                        color: controller && controller.sizeMode === "full" ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                        font.pixelSize: 11
                        font.bold: controller && controller.sizeMode === "full"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (controller) controller.sizeMode = "full"
                    }
                }

                // 1-Handed
                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height
                    radius: 14
                    color: controller && controller.sizeMode === "onehand" ? (currentTheme ? currentTheme.accentColor : "#00a2ed") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "📱 1-Handed"
                        color: controller && controller.sizeMode === "onehand" ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                        font.pixelSize: 10
                        font.bold: controller && controller.sizeMode === "onehand"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (controller) controller.sizeMode = "onehand"
                    }
                }
            }
        }

        // Settings button (theme, position)
        Rectangle {
            width: 34
            height: 34
            radius: 17
            Layout.alignment: Qt.AlignVCenter
            color: mainWindow && mainWindow.showSettings ? (currentTheme ? currentTheme.accentColor : "#00a2ed")
                                                         : (currentTheme && currentTheme.sizeModePillBg ? currentTheme.sizeModePillBg : "#21252d")

            Text {
                anchors.centerIn: parent
                text: "⚙"
                color: mainWindow && mainWindow.showSettings ? "#ffffff" : (currentTheme && currentTheme.pillTextColor ? currentTheme.pillTextColor : "#d0d5dd")
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (mainWindow) mainWindow.showSettings = !mainWindow.showSettings
            }
        }
    }
}
