import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property string label: ""
    property string hintAccent: ""
    property var accents: []
    property string textToSend: ""
    property bool isSpecial: false
    property bool isPrimaryAction: false
    property bool isBackspace: false
    property bool isCustomAction: false
    property var currentTheme
    property var vk
    property var controller
    property var gestureEngine

    property int selectedAccentIndex: -1
    property bool isAccentOverlayOpen: false

    signal keyTriggered(string key)
    signal pressed()
    signal released()
    signal longPressed()

    Layout.fillHeight: true

    // User preferences (the "prefs" Settings object lives in Main.qml)
    readonly property bool gboardStyle: typeof prefs === "undefined" || prefs.keyStyle !== "classic"
    readonly property bool animate: typeof prefs === "undefined" || prefs.animations
    readonly property bool popoutEnabled: typeof prefs === "undefined" || prefs.keyPopout
    readonly property bool isPressed: mouseArea.pressed

    // Keep the pressed key (and its popout) above neighbouring keys
    z: isPressed || isAccentOverlayOpen ? 10 : 0

    radius: currentTheme ? currentTheme.keyRadius : 12

    readonly property color baseColor: isPrimaryAction ? (currentTheme ? currentTheme.accentColor : "#0284c7") :
           (isSpecial ? (currentTheme && currentTheme.specialKeyBackgroundColor ? currentTheme.specialKeyBackgroundColor : (currentTheme ? currentTheme.keyBackgroundColor : "#1e293b")) :
           (currentTheme ? currentTheme.keyBackgroundColor : "#1e293b"))
    readonly property color pressedColor: isPrimaryAction ? Qt.darker(baseColor, 1.18) :
           (currentTheme ? currentTheme.keyActiveColor : "#334155")

    // Pressed feedback: colour change (Gboard) instead of the classic shrink
    color: isPressed ? pressedColor : baseColor
    Behavior on color {
        enabled: root.animate
        ColorAnimation { duration: root.isPressed ? 40 : 160 }
    }

    border.color: isPrimaryAction ? (currentTheme ? currentTheme.accentColor : "#0284c7") :
                  (currentTheme ? currentTheme.keyBorderColor : "#334155")
    border.width: gboardStyle ? 0 : (currentTheme && currentTheme.keyBorderWidth !== undefined ? currentTheme.keyBorderWidth : 1)

    scale: (!gboardStyle && isPressed) ? 0.95 : 1.0
    Behavior on scale {
        enabled: root.animate
        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
    }

    // Flat Gboard keys get a hairline bottom shadow so they still read as keys
    Rectangle {
        visible: root.gboardStyle && !root.isPrimaryAction
        z: -1
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: -1
        radius: root.radius
        color: "#000000"
        opacity: 0.12
    }

    // ---- Key popout (Gboard-style preview above the finger) ----------------
    readonly property bool popoutWanted: popoutEnabled && isPressed && !isAccentOverlayOpen
                                         && !isSpecial && !isPrimaryAction && !isCustomAction
                                         && label.length > 0 && label.length <= 2

    Item {
        id: popout
        z: 100
        width: Math.max(root.width * 1.12, 46)
        height: Math.max(root.height * 1.2, 56)
        x: (root.width - width) / 2
        y: -height - 6
        transformOrigin: Item.Bottom
        visible: opacity > 0.01
        opacity: root.popoutWanted ? 1 : 0
        scale: root.popoutWanted ? 1 : 0.55
        Behavior on opacity { enabled: root.animate; NumberAnimation { duration: root.popoutWanted ? 70 : 120; easing.type: Easing.OutQuad } }
        Behavior on scale { enabled: root.animate; NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

        Rectangle {     // soft shadow
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -3
            radius: popoutBody.radius
            color: "#000000"
            opacity: 0.35
        }
        Rectangle {
            id: popoutBody
            anchors.fill: parent
            radius: (currentTheme ? currentTheme.keyRadius : 12) + 4
            color: currentTheme ? currentTheme.keyBackgroundColor : "#1e293b"
            border.width: 1
            border.color: currentTheme ? currentTheme.keyBorderColor : "#334155"

            Text {
                anchors.centerIn: parent
                text: root.label
                color: currentTheme ? currentTheme.textColor : "#f8fafc"
                font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
                font.pixelSize: 30
            }
        }
    }

    // Main Key Label
    Text {
        id: labelText
        text: root.label
        anchors.centerIn: parent
        color: root.isPrimaryAction ? "#ffffff" :
               (root.isSpecial ? (currentTheme ? currentTheme.accentTextColor : "#38bdf8") :
               (currentTheme ? currentTheme.textColor : "#f8fafc"))
        font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
        font.pixelSize: root.label.length > 8 ? 9 :
                       (root.label.length > 5 ? 11 :
                       (root.label.length > 3 ? 13 : (root.isSpecial ? 15 : (root.gboardStyle ? 21 : 18))))
        font.bold: root.isSpecial || root.isPrimaryAction
        // hide the label while the popout shows it, like Gboard
        opacity: root.popoutWanted ? 0.25 : 1
    }

    // Superscript Accent Hint (Top Right)
    Text {
        text: root.hintAccent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 6
        color: currentTheme ? currentTheme.accentTextColor : "#38bdf8"
        font.pixelSize: 10
        font.bold: true
        visible: root.hintAccent !== "" && !root.isSpecial
    }

    // Custom Lightweight Accent Overlay (Does NOT steal touch grab)
    Rectangle {
        id: accentOverlay
        visible: opacity > 0.01
        opacity: root.isAccentOverlayOpen ? 1 : 0
        scale: root.isAccentOverlayOpen ? 1 : 0.8
        transformOrigin: Item.Bottom
        Behavior on opacity { enabled: root.animate; NumberAnimation { duration: 90 } }
        Behavior on scale { enabled: root.animate; NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
        z: 9999
        y: -height - 8
        x: (parent.width - width) / 2
        width: accentRow.width + 8
        height: 44
        radius: 12
        color: currentTheme ? currentTheme.backgroundColor : "#0f172a"
        border.color: currentTheme ? currentTheme.accentColor : "#0284c7"
        border.width: 1

        Row {
            id: accentRow
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: root.accents
                delegate: Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: index === root.selectedAccentIndex ?
                           (currentTheme ? currentTheme.accentColor : "#0284c7") :
                           (currentTheme ? currentTheme.keyBackgroundColor : "#1e293b")

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: index === root.selectedAccentIndex ? "#ffffff" : (currentTheme ? currentTheme.textColor : "#ffffff")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.vk) {
                                root.vk.sendText(modelData)
                            } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                                virtualKeyEngine.sendText(modelData)
                            }
                            root.isAccentOverlayOpen = false
                            root.selectedAccentIndex = -1
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: longPressTimer
        interval: 300
        repeat: false
        onTriggered: {
            root.longPressed()
            if (root.accents && root.accents.length > 0) {
                root.selectedAccentIndex = 0
                root.isAccentOverlayOpen = true
            } else if (root.isBackspace && controller) {
                controller.startBackspaceTimer()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        onPressed: {
            root.pressed()
            longPressTimer.start()
            if (gestureEngine) {
                gestureEngine.startTouch(Qt.point(mouse.x, mouse.y))
            }
        }

        onPositionChanged: (mouse) => {
            if (gestureEngine && pressed) {
                gestureEngine.updateTouch(Qt.point(mouse.x, mouse.y))
            }

            // Slide-to-select accent logic
            if (root.isAccentOverlayOpen && root.accents && root.accents.length > 0) {
                var popupPoint = mouseArea.mapToItem(accentRow, mouse.x, mouse.y)
                var idx = Math.floor(popupPoint.x / 40)
                if (idx >= 0 && idx < root.accents.length) {
                    root.selectedAccentIndex = idx
                }
            }
        }

        onReleased: {
            longPressTimer.stop()

            if (gestureEngine) {
                gestureEngine.endTouch()
            }

            root.released()

            if (root.isAccentOverlayOpen) {
                var selIdx = (root.selectedAccentIndex >= 0 && root.selectedAccentIndex < root.accents.length) ? root.selectedAccentIndex : 0
                var selChar = root.accents[selIdx]
                if (root.vk) {
                    root.vk.sendText(selChar)
                } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                    virtualKeyEngine.sendText(selChar)
                }
                root.isAccentOverlayOpen = false
                root.selectedAccentIndex = -1
            } else if (root.isBackspace) {
                if (controller) controller.stopBackspaceTimer()
                if (root.vk) {
                    root.vk.sendBackspace()
                } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                    virtualKeyEngine.sendBackspace()
                }
            } else if (!root.isCustomAction) {
                var send = root.textToSend !== "" ? root.textToSend : root.label
                if (send !== "") {
                    if (root.vk) {
                        root.vk.sendText(send)
                    } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                        virtualKeyEngine.sendText(send)
                    }
                }
                root.keyTriggered(send)
            }
        }

        onCanceled: {
            longPressTimer.stop()
            if (root.isAccentOverlayOpen) {
                var selIdx = (root.selectedAccentIndex >= 0 && root.selectedAccentIndex < root.accents.length) ? root.selectedAccentIndex : 0
                var selChar = root.accents[selIdx]
                if (root.vk) {
                    root.vk.sendText(selChar)
                } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                    virtualKeyEngine.sendText(selChar)
                }
                root.isAccentOverlayOpen = false
                root.selectedAccentIndex = -1
            }
        }
    }
}
