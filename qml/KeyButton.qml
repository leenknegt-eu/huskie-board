import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "Accents.js" as Accents

Rectangle {
    id: root

    property string label: ""
    property string icon: ""             // KeyIcon name; replaces the text label when set
    property string hintAccent: ""       // small hint in the top-right corner
    property var accents: []             // explicit long-press alternatives
    property bool autoAccents: true      // otherwise derive them from the label (Accents.js)
    property bool digitAccent: true      // offer the top-row number first (q=1 ... p=0)
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
    signal accentCommitted(string ch)

    Layout.fillHeight: true

    // User preferences (the "prefs" Settings object lives in Main.qml)
    readonly property bool gboardStyle: typeof prefs === "undefined" || prefs.keyStyle !== "classic"
    readonly property bool animate: typeof prefs === "undefined" || prefs.animations
    readonly property bool popoutEnabled: typeof prefs === "undefined" || prefs.keyPopout
    readonly property bool isPressed: mouseArea.pressed

    readonly property var effectiveAccents: (accents && accents.length) ? accents
        : ((autoAccents && !isSpecial && !isCustomAction) ? Accents.variants(label, digitAccent) : [])

    // Keep the pressed key (and its popups) above neighbouring keys
    z: isPressed || isAccentOverlayOpen ? 10 : 0

    radius: isPrimaryAction && gboardStyle ? Math.min(height, width) / 2
                                           : (currentTheme ? currentTheme.keyRadius : 12)

    readonly property color textCol: currentTheme ? currentTheme.textColor : "#f8fafc"
    readonly property color accentCol: currentTheme ? currentTheme.accentColor : "#0284c7"
    readonly property color baseColor: isPrimaryAction ? accentCol :
           (isSpecial ? (currentTheme && currentTheme.specialKeyBackgroundColor ? currentTheme.specialKeyBackgroundColor : (currentTheme ? currentTheme.keyBackgroundColor : "#1e293b")) :
           (currentTheme ? currentTheme.keyBackgroundColor : "#1e293b"))
    readonly property color pressedColor: isPrimaryAction ? Qt.darker(baseColor, 1.18) :
           (currentTheme ? currentTheme.keyActiveColor : "#334155")
    readonly property color labelColor: isPrimaryAction ? "#ffffff" :
           ((isSpecial && !gboardStyle) ? (currentTheme ? currentTheme.accentTextColor : "#38bdf8") : textCol)

    // Pressed feedback: colour change (Gboard) instead of the classic shrink
    color: isPressed ? pressedColor : baseColor
    Behavior on color {
        enabled: root.animate
        ColorAnimation { duration: root.isPressed ? 40 : 160 }
    }

    border.color: isPrimaryAction ? accentCol : (currentTheme ? currentTheme.keyBorderColor : "#334155")
    border.width: gboardStyle ? 0 : (currentTheme && currentTheme.keyBorderWidth !== undefined ? currentTheme.keyBorderWidth : 1)

    scale: (!gboardStyle && isPressed) ? 0.95 : 1.0
    Behavior on scale {
        enabled: root.animate
        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
    }

    // ---- Label / icon ---------------------------------------------------------
    Text {
        id: labelText
        visible: root.icon === ""
        text: root.label
        anchors.centerIn: parent
        color: root.labelColor
        font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
        font.pixelSize: root.label.length > 8 ? 9 :
                       (root.label.length > 5 ? 11 :
                       (root.label.length > 3 ? 13 : (root.isSpecial ? 15 : (root.gboardStyle ? 21 : 18))))
        font.weight: root.gboardStyle ? (root.isSpecial ? Font.Medium : Font.Normal) : Font.Normal
        font.bold: !root.gboardStyle && (root.isSpecial || root.isPrimaryAction)
        // dim the label while the popout shows it, like Gboard
        opacity: root.popoutWanted ? 0.25 : 1
    }

    KeyIcon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        color: root.labelColor
        width: Math.min(24, root.height * 0.5)
        height: width
    }

    // Small hint (top row digit / shifted symbol)
    Text {
        text: root.hintAccent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 3
        anchors.rightMargin: 6
        color: root.gboardStyle ? root.textCol : (currentTheme ? currentTheme.accentTextColor : "#38bdf8")
        opacity: root.gboardStyle ? 0.5 : 1
        font.pixelSize: 10
        font.bold: !root.gboardStyle
        visible: root.hintAccent !== "" && !root.isSpecial
    }

    // ---- Key popout (preview above the finger) ---------------------------------
    readonly property bool popoutWanted: popoutEnabled && isPressed && !isAccentOverlayOpen
                                         && !isSpecial && !isPrimaryAction && !isCustomAction
                                         && icon === "" && label.trim().length > 0 && label.length <= 2

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
                color: root.textCol
                font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
                font.pixelSize: 30
            }
        }
    }

    // ---- Long-press alternatives (mobile style) --------------------------------
    // Hold a key: a popup of variants appears with the first one over the key.
    // Slide to pick (rows and columns), release to type it.
    Item {
        id: accentPopup
        z: 9999
        visible: opacity > 0.01
        opacity: root.isAccentOverlayOpen ? 1 : 0
        scale: root.isAccentOverlayOpen ? 1 : 0.85
        transformOrigin: Item.Bottom
        Behavior on opacity { enabled: root.animate; NumberAnimation { duration: 90 } }
        Behavior on scale { enabled: root.animate; NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

        readonly property int count: root.effectiveAccents.length
        readonly property real cellW: Math.max(40, Math.min(root.width, 56))
        readonly property real cellH: Math.max(44, Math.min(root.height, 58))
        readonly property real winW: root.Window.width > 0 ? root.Window.width : 1000
        readonly property int maxCols: Math.max(1, Math.min(10, Math.floor((winW - 16) / cellW)))
        // balance rows: 9 -> 1x9, 14 -> 2x7
        readonly property int rows: Math.max(1, Math.ceil(count / maxCols))
        readonly property int cols: Math.max(1, Math.ceil(count / rows))
        width: cols * cellW + 8
        height: rows * cellH + 8

        // Place the first cell over the key, then keep the popup inside the keyboard
        // card horizontally (or the window if no card is found) and below the window top
        function place() {
            var p = root.mapToItem(null, 0, 0)
            var left = 4, right = winW - 4
            for (var a = root.parent; a; a = a.parent) {
                if (a.objectName === "cardBox") {
                    var c = a.mapToItem(null, 0, 0)
                    left = Math.max(left, c.x + 6)
                    right = Math.min(right, c.x + a.width - 6)
                    break
                }
            }
            var dx = (root.width - cellW) / 2 - 4
            if (p.x + dx + width > right) dx -= (p.x + dx + width) - right
            if (p.x + dx < left) dx = left - p.x
            var dy = -height - 6
            if (p.y + dy < 4) dy = 4 - p.y
            x = dx
            y = dy
        }

        Rectangle {     // shadow
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -3
            radius: accentBody.radius
            color: "#000000"
            opacity: 0.35
        }
        Rectangle {
            id: accentBody
            anchors.fill: parent
            radius: (currentTheme ? currentTheme.keyRadius : 12) + 4
            color: currentTheme ? currentTheme.keyBackgroundColor : "#1e293b"
            border.width: 1
            border.color: currentTheme ? currentTheme.keyBorderColor : "#334155"
        }

        Item {
            id: accentGrid
            x: 4
            y: 4
            width: accentPopup.cols * accentPopup.cellW
            height: accentPopup.rows * accentPopup.cellH

            Repeater {
                model: root.effectiveAccents
                delegate: Rectangle {
                    x: (index % accentPopup.cols) * accentPopup.cellW + 2
                    y: Math.floor(index / accentPopup.cols) * accentPopup.cellH + 2
                    width: accentPopup.cellW - 4
                    height: accentPopup.cellH - 4
                    radius: (currentTheme ? currentTheme.keyRadius : 12)
                    color: index === root.selectedAccentIndex ? root.accentCol : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: index === root.selectedAccentIndex ? "#ffffff" : root.textCol
                        font.family: currentTheme ? currentTheme.fontFamily : "sans-serif"
                        font.pixelSize: 22
                    }
                }
            }
        }

        function indexAt(px, py) {
            var col = Math.max(0, Math.min(cols - 1, Math.floor(px / cellW)))
            var row = Math.max(0, Math.min(rows - 1, Math.floor(py / cellH)))
            return Math.min(count - 1, row * cols + col)
        }
    }

    function sendChar(ch) {
        if (root.vk) root.vk.sendText(ch)
        else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) virtualKeyEngine.sendText(ch)
    }

    function commitAccent() {
        var list = root.effectiveAccents
        var idx = (root.selectedAccentIndex >= 0 && root.selectedAccentIndex < list.length) ? root.selectedAccentIndex : 0
        var ch = list[idx]
        root.isAccentOverlayOpen = false
        root.selectedAccentIndex = -1
        sendChar(ch)
        root.accentCommitted(ch)
        root.keyTriggered(ch)
    }

    Timer {
        id: longPressTimer
        interval: 350
        repeat: false
        onTriggered: {
            root.longPressed()
            if (root.effectiveAccents.length > 0) {
                accentPopup.place()
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

        onPressed: (mouse) => {
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
            if (root.isAccentOverlayOpen) {
                var p = mouseArea.mapToItem(accentGrid, mouse.x, mouse.y)
                root.selectedAccentIndex = accentPopup.indexAt(p.x, p.y)
            }
        }

        onReleased: {
            longPressTimer.stop()
            if (gestureEngine) {
                gestureEngine.endTouch()
            }

            // An alternative was picked: type it and skip the normal key action
            if (root.isAccentOverlayOpen) {
                root.commitAccent()
                return
            }

            root.released()

            if (root.isBackspace) {
                if (controller) controller.stopBackspaceTimer()
                if (root.vk) {
                    root.vk.sendBackspace()
                } else if (typeof virtualKeyEngine !== "undefined" && virtualKeyEngine) {
                    virtualKeyEngine.sendBackspace()
                }
            } else if (!root.isCustomAction) {
                var send = root.textToSend !== "" ? root.textToSend : root.label
                if (send !== "") sendChar(send)
                root.keyTriggered(send)
            }
        }

        onCanceled: {
            longPressTimer.stop()
            if (root.isAccentOverlayOpen) root.commitAccent()
        }
    }
}
