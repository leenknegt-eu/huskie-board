import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCore
import HuskieBoard 1.0

Window {
    id: mainWindow
    visible: false
    title: "Huskie-board"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint | Qt.WindowDoesNotAcceptFocus

    // Layer-shell overlay: full-screen transparent surface with an input mask.
    // Input panel: KWin places the surface itself, so it is exactly the keyboard's size.
    readonly property bool panelMode: controller.surfaceRole === "panel"
    width: panelMode ? cardBox.width : Screen.width
    height: panelMode ? cardBox.height : Screen.height

    property string currentInputBuffer: ""
    property bool showSettings: false
    property bool isMinimized: false

    // Persistent user preferences (~/.config/KDE/huskie-board.conf)
    Settings {
        id: prefs
        category: "General"
        property string theme: "Auto"   // "Auto" follows the KDE color scheme
        property bool docked: true      // true = pinned to bottom centre, not draggable
        property string showMode: "auto" // "auto" = follow text-field focus, "manual" = ✖ + floating bubble
        property bool keyPopout: true      // enlarged preview above the pressed key
        property bool animations: true     // slide in/out, popout and press animations
        property string keyStyle: "gboard" // "gboard" (flat keys) or "classic" (outlined keys)
        property real heightScale: 1.0    // key area height multiplier (0.7 - 1.5)
    }

    readonly property var themeChoices: [
        { id: "Auto",          label: "Auto (KDE)" },
        { id: "BreezeLight",   label: "Breeze Light" },
        { id: "BreezeDark",    label: "Breeze Dark" },
        { id: "TeenageOP1",    label: "OP-1" },
        { id: "NothingDark",   label: "Nothing Dark" },
        { id: "NothingLight",  label: "Nothing Light" },
        { id: "HackerMatrix",  label: "Matrix" },
        { id: "Cyberpunk2077", label: "Cyberpunk" },
        { id: "DraculaDark",   label: "Dracula" },
        { id: "NordFrost",     label: "Nord" }
    ]

    function themeFile(name) {
        var known = themeChoices.some(function (t) { return t.id === name })
        return "themes/" + ((!known || name === "Auto") ? "KdeAuto" : name) + ".qml"
    }

    function selectTheme(name) {
        prefs.theme = name
        controller.activeTheme = name
    }

    Component.onCompleted: controller.activeTheme = prefs.theme

    // ---- Visibility -------------------------------------------------------
    // "auto":   shown while a text field is focused (KWin input-method activate /
    //           deactivate), hidden otherwise; ✖ hides until the next text field.
    // "manual": legacy behaviour; ✖ collapses to a floating bubble.
    // Auto needs KWin to have launched us as its input method; otherwise fall back.
    // While the screen is locked the keyboard always follows the password field.
    readonly property string effectiveShowMode: !virtualKeyEngine.hasInputMethod ? "manual"
                                               : (controller.screenLocked ? "auto" : prefs.showMode)
    readonly property bool shouldShow: effectiveShowMode === "manual" || !autoHidden
    // Read at call time (not via the binding above) so handlers never see stale values
    function computeMode() {
        return !virtualKeyEngine.hasInputMethod ? "manual" : (controller.screenLocked ? "auto" : prefs.showMode)
    }
    function computeShouldShow() {
        return computeMode() === "manual" || !autoHidden
    }
    // Input panel only while locked: it is the only keyboard surface KWin shows over the
    // lock screen, but KWin also shrinks the focused app window to make room for it.
    // Everywhere else the layer-shell overlay floats over apps without resizing them.
    function computeDesiredRole() {
        return controller.screenLocked ? "panel" : "layer"
    }
    // Coalesce role + visibility updates; runs after all bindings have settled
    function scheduleUpdate() { Qt.callLater(mainWindow.updateState) }
    function updateState() {
        if (!started) return
        var role = computeDesiredRole()
        if (role !== controller.surfaceRole) {
            controller.applySurfaceRole(mainWindow, role)
            cardBox.placeDefault()
        }
        applyVisibility()
    }

    readonly property string desiredRole: controller.screenLocked ? "panel" : "layer"
    onDesiredRoleChanged: scheduleUpdate()

    // 0 = slid out of view, 1 = fully shown
    property real reveal: 0
    NumberAnimation {
        id: revealAnim
        target: mainWindow
        property: "reveal"
        onFinished: if (mainWindow.reveal <= 0.001 && !mainWindow.computeShouldShow()) mainWindow.visible = false
    }

    function animateReveal(to) {
        revealAnim.stop()
        if (!prefs.animations || !mainWindow.visible) {
            reveal = to
            if (to === 0 && !computeShouldShow()) mainWindow.visible = false
            return
        }
        var showing = to > reveal
        revealAnim.from = reveal
        revealAnim.to = to
        revealAnim.duration = showing ? 220 : 160
        revealAnim.easing.type = showing ? Easing.OutCubic : Easing.InCubic
        revealAnim.start()
    }
    property bool autoHidden: true
    property bool started: false

    // Called from C++ once the layer-shell surface is configured
    function start() {
        controller.applySurfaceRole(mainWindow, computeDesiredRole())
        started = true
        autoHidden = !virtualKeyEngine.imActive
        cardBox.placeDefault()
        applyVisibility()
    }

    function applyVisibility() {
        if (!started) return
        var show = computeShouldShow()
        console.info("Keyboard " + (show ? "show" : "hide") + " (mode " + effectiveShowMode + ", role " + controller.surfaceRole + ")")
        if (show) {
            if (!mainWindow.visible) {
                reveal = prefs.animations ? 0 : 1
                mainWindow.visible = true
            }
            if (isMinimized) minimizedPill.syncMinimizedMask(); else cardBox.syncMask()
            animateReveal(1)
        } else {
            showSettings = false
            animateReveal(0)
        }
    }

    function toggleDocked() {
        prefs.docked = !prefs.docked
    }

    function hideKeyboard() {
        if (computeMode() === "auto") {
            autoHidden = true
            // Let KWin know too, so tapping the same (still focused) field brings us back.
            // Essential on the login/lock screen, where the password field can't be left.
            controller.dismissInKWin()
        } else {
            isMinimized = true
            minimizedPill.syncMinimizedMask()
        }
    }

    onAutoHiddenChanged: scheduleUpdate()

    // A key held while the keyboard disappears never gets its release: make sure
    // auto-repeat (backspace / arrows) can't keep firing in the background.
    onVisibleChanged: if (!visible) { controller.stopBackspaceTimer(); controller.stopKeyRepeat() }
    onEffectiveShowModeChanged: {
        if (effectiveShowMode === "auto") isMinimized = false
        else autoHidden = false
        scheduleUpdate()
    }

    // Focus hops between fields produce deactivate+activate in quick succession;
    // wait a moment before hiding so the keyboard doesn't flicker.
    Timer {
        id: autoHideTimer
        interval: 250
        onTriggered: mainWindow.autoHidden = true
    }

    Connections {
        target: virtualKeyEngine
        function onImActiveChanged() {
            if (mainWindow.computeMode() !== "auto") return
            if (virtualKeyEngine.imActive) {
                autoHideTimer.stop()
                mainWindow.autoHidden = false
            } else {
                autoHideTimer.restart()
            }
        }
        function onSensitiveInputChanged() {
            controller.isPasswordMode = virtualKeyEngine.sensitiveInput
        }
    }
    property int shiftState: 0 // 0 = lowercase, 1 = shift single, 2 = caps lock
    property bool ctrlActive: false
    property bool altActive: false

    KeyboardController {
        id: controller
    }

    WaylandVirtualKeyboard {
        id: virtualKeyEngine
    }

    GestureEngine {
        id: gestureEngine
    }

    KlipperIntegration {
        id: klipper
    }

    // Dynamic Theme Loader
    property var activeTheme
    Loader {
        id: themeLoader
        source: mainWindow.themeFile(controller.activeTheme)
        onLoaded: mainWindow.activeTheme = themeLoader.item
    }

    // Keep everything on-screen when the screen size changes (e.g. tablet rotation)
    onWidthChanged: { cardBox.reposition(); minimizedPill.clamp() }
    onHeightChanged: { cardBox.reposition(); minimizedPill.clamp() }

    Connections {
        target: controller
        // KWin asked for the keyboard (e.g. tap on the focused field after a manual hide)
        function onKwinShowRequested() {
            if (mainWindow.computeMode() === "auto" && virtualKeyEngine.imActive && mainWindow.autoHidden) {
                autoHideTimer.stop()
                mainWindow.autoHidden = false
            }
        }
        function onKeyboardVisibleChanged() {
            if (controller.keyboardVisible) {
                mainWindow.isMinimized = false
                cardBox.syncMask()
            }
        }
        function onTriggerBackspace() {
            virtualKeyEngine.sendBackspace()
            if (mainWindow.currentInputBuffer.length > 0) {
                mainWindow.currentInputBuffer = mainWindow.currentInputBuffer.substring(0, mainWindow.currentInputBuffer.length - 1)
                gestureEngine.updateCurrentPrefix(mainWindow.currentInputBuffer)
            }
        }
        function onTriggerWordBackspace() {
            virtualKeyEngine.sendCtrlBackspace()
            mainWindow.currentInputBuffer = ""
            gestureEngine.updateCurrentPrefix("")
        }
        function onTriggerKeyRepeat(keycode) {
            if (virtualKeyEngine) {
                virtualKeyEngine.pressAndReleaseKey(keycode)
            }
        }
    }

    // Floating Bubble / Mini-Bar Handle (Appears at margin when user taps Close ✖)
    Rectangle {
        id: minimizedPill
        width: 140
        height: 38
        radius: 19
        x: parent.width - width - 20
        y: parent.height - height - 40
        visible: mainWindow.isMinimized
        color: mainWindow.activeTheme ? mainWindow.activeTheme.accentColor : "#00a2ed"
        border.color: "#ffffff"
        border.width: 1

        function syncMinimizedMask() {
            if (mainWindow.isMinimized) {
                controller.updateInputMask(mainWindow, minimizedPill.x, minimizedPill.y, minimizedPill.width, minimizedPill.height)
            }
        }

        function clamp() {
            if (mainWindow.panelMode) return
            x = Math.max(0, Math.min(x, mainWindow.width - width))
            y = Math.max(0, Math.min(y, mainWindow.height - height))
        }

        onXChanged: minimizedPill.syncMinimizedMask()
        onYChanged: minimizedPill.syncMinimizedMask()
        onVisibleChanged: if (mainWindow.isMinimized) minimizedPill.syncMinimizedMask()

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: "⌨️  Touch Key"
                color: "#ffffff"
                font.bold: true
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: bubbleDragArea
            anchors.fill: parent
            property point startPos

            onPressed: (mouse) => {
                startPos = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    var deltaX = mouse.x - startPos.x
                    var deltaY = mouse.y - startPos.y
                    minimizedPill.x += deltaX
                    minimizedPill.y += deltaY
                    minimizedPill.clamp()
                }
            }

            onClicked: {
                mainWindow.isMinimized = false
                cardBox.syncMask()
            }
        }
    }

    // Floating Card Container (Matches Screenshots Floating Design)
    Rectangle {
        id: cardBox
        objectName: "cardBox"
        visible: !mainWindow.isMinimized
        width: controller.sizeMode === "full" ? Screen.width :
               (controller.sizeMode === "onehand" ? 480 : 896)
        // Extended = 6-row PC layout. The terminal / Ctrl-Alt strip only takes space when shown.
        readonly property bool showStrip: controller.isTerminalMode || mainWindow.ctrlActive || mainWindow.altActive
        readonly property real keyAreaBase: controller.sizeMode === "full" ? 338 : 240
        readonly property real keyboardHeight: 72 + (showStrip ? 44 : 0) + Math.round(keyAreaBase * prefs.heightScale)
        // while settings are open the card grows (upwards) so nothing needs scrolling
        height: Math.min(mainWindow.showSettings ? Math.max(keyboardHeight, 600) : keyboardHeight,
                         Screen.height * 0.8)

        // Position is managed imperatively (dragging breaks bindings anyway):
        //  - docked:   bottom centre, flush with the screen edge, not draggable
        //  - floating: draggable, but always kept fully on-screen
        readonly property bool docked: prefs.docked || mainWindow.panelMode
        readonly property bool draggable: !docked
        readonly property int floatMargin: 40

        // Slide in from the bottom edge (reveal 0 -> 1)
        transform: Translate { y: (1 - mainWindow.reveal) * (cardBox.height + cardBox.floatMargin) }
        opacity: 0.35 + 0.65 * mainWindow.reveal

        function placeDefault() {
            if (mainWindow.panelMode) { x = 0; y = 0; return }
            if (docked || controller.sizeMode !== "onehand")
                x = Math.round((mainWindow.width - width) / 2)
            else
                x = mainWindow.width - width - 16
            y = docked ? mainWindow.height - height : mainWindow.height - height - floatMargin
            clamp()
        }

        function clamp() {
            x = Math.max(0, Math.min(x, mainWindow.width - width))
            y = Math.max(0, Math.min(y, mainWindow.height - height))
        }

        function moveBy(dx, dy) {
            if (docked) return
            x += dx
            y += dy
            clamp()
        }

        function reposition() {
            if (docked) placeDefault(); else clamp()
        }

        onDockedChanged: placeDefault()

        function syncMask() {
            if (!mainWindow.isMinimized) {
                controller.updateInputMask(mainWindow, cardBox.x, cardBox.y, cardBox.width, cardBox.height)
            }
        }

        onXChanged: cardBox.syncMask()
        onYChanged: cardBox.syncMask()
        onWidthChanged: { cardBox.placeDefault(); cardBox.syncMask() }   // size mode switched
        // Height changes (height slider, size mode, shortcut strip) grow/shrink the card
        // upwards: keep the bottom edge where it is instead of pushing it off-screen.
        property real lastHeight: height
        onHeightChanged: {
            if (docked || mainWindow.panelMode) {
                cardBox.placeDefault()
            } else {
                cardBox.y -= (height - lastHeight)
                cardBox.clamp()
            }
            lastHeight = height
            cardBox.syncMask()
        }
        onVisibleChanged: if (!mainWindow.isMinimized) cardBox.syncMask()
        Component.onCompleted: { cardBox.placeDefault(); cardBox.syncMask() }

        color: mainWindow.activeTheme ? mainWindow.activeTheme.backgroundColor : "#e3dfd8"
        radius: controller.sizeMode === "full" ? 0 : (mainWindow.activeTheme && mainWindow.activeTheme.cardRadius !== undefined ? mainWindow.activeTheme.cardRadius : 24)
        border.color: mainWindow.activeTheme ? mainWindow.activeTheme.cardBorderColor : "#c8c3b9"
        // Docked: sit flush on the screen edge (no bottom rounding, no outline)
        bottomLeftRadius: docked ? 0 : radius
        bottomRightRadius: docked ? 0 : radius
        border.width: (controller.sizeMode === "full" || docked) ? 0 : 1

        SwipeCanvas {
            gestureEngine: gestureEngine
            currentTheme: mainWindow.activeTheme
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: controller.sizeMode === "full" ? 17 : 12
            anchors.rightMargin: controller.sizeMode === "full" ? 17 : 12
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 8

            // Pill Header Bar (Draggable handle)
            TouchBarView {
                Layout.fillWidth: true
                currentTheme: mainWindow.activeTheme
                controller: controller
                vk: virtualKeyEngine
                klipper: klipper
                cardBox: cardBox
                mainWindow: mainWindow
            }

            // Shortcut strip: terminal quick pills or Ctrl/Alt shortcuts (hidden otherwise)
            Rectangle {
                visible: cardBox.showStrip
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: mainWindow.activeTheme && mainWindow.activeTheme.headerPillBg ? mainWindow.activeTheme.headerPillBg : "#434a56"

                // Dynamic Suggestions, Terminal Bar, or Ctrl/Alt Shortcuts
                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    contentWidth: suggRow.width
                    clip: true

                    RowLayout {
                        id: suggRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        // Dynamic Ctrl Shortcuts Bar (Visible when ctrlActive is true)
                        Repeater {
                            model: mainWindow.ctrlActive ? [
                                { label: "Ctrl+C", mod: 4, k: 46 },
                                { label: "Ctrl+V", mod: 4, k: 47 },
                                { label: "Ctrl+X", mod: 4, k: 45 },
                                { label: "Ctrl+Z", mod: 4, k: 44 },
                                { label: "Ctrl+A", mod: 4, k: 30 },
                                { label: "Ctrl+F", mod: 4, k: 33 },
                                { label: "Ctrl+S", mod: 4, k: 31 },
                                { label: "Ctrl+W", mod: 4, k: 17 },
                                { label: "Ctrl+T", mod: 4, k: 20 },
                                { label: "Ctrl+L", mod: 4, k: 38 }
                            ] : []
                            delegate: Rectangle {
                                width: Math.max(56, ctrlText.width + 16)
                                height: 26
                                radius: 13
                                color: "#0284c7"
                                border.color: "#38bdf8"
                                border.width: 1

                                Text {
                                    id: ctrlText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "#ffffff"
                                    font.family: "monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        virtualKeyEngine.sendCombo(modelData.mod, modelData.k)
                                        mainWindow.ctrlActive = false
                                        mainWindow.altActive = false
                                    }
                                }
                            }
                        }

                        // Dynamic Alt Shortcuts Bar (Visible when altActive is true)
                        Repeater {
                            model: mainWindow.altActive ? [
                                { label: "Alt+Tab", mod: 8, k: 15 },
                                { label: "Alt+F4", mod: 8, k: 62 },
                                { label: "Alt+Space", mod: 8, k: 57 },
                                { label: "Alt+F2", mod: 8, k: 60 },
                                { label: "Alt+◄", mod: 8, k: 105 },
                                { label: "Alt+►", mod: 8, k: 106 }
                            ] : []
                            delegate: Rectangle {
                                width: Math.max(56, altText.width + 16)
                                height: 26
                                radius: 13
                                color: "#d97706"
                                border.color: "#fbbf24"
                                border.width: 1

                                Text {
                                    id: altText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "#ffffff"
                                    font.family: "monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        virtualKeyEngine.sendCombo(modelData.mod, modelData.k)
                                        mainWindow.ctrlActive = false
                                        mainWindow.altActive = false
                                    }
                                }
                            }
                        }

                        // Terminal Quick Pills ($ | ~ / -) - Visible ONLY when isTerminalMode is true AND not in Ctrl/Alt mode
                        Repeater {
                            model: (!mainWindow.ctrlActive && !mainWindow.altActive && controller.isTerminalMode) ? ["$", "|", "~", "/", "-", "_", "sudo ", "grep ", "ls -la ", "cd ", "clear\n"] : []
                            delegate: Rectangle {
                                width: Math.max(28, termText.width + 16)
                                height: 26
                                radius: 13
                                color: "#2d333e"
                                border.color: mainWindow.activeTheme ? mainWindow.activeTheme.accentColor : "#00a2ed"
                                border.width: 1

                                Text {
                                    id: termText
                                    anchors.centerIn: parent
                                    text: modelData.trim()
                                    color: "#38bdf8"
                                    font.family: "monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: virtualKeyEngine.sendText(modelData)
                                }
                            }
                        }

                    }
                }
            }

            // Main Keyboard Views Container
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                StackLayout {
                    id: layoutStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: (controller.sizeMode === "full" && controller.layoutMode === "abc") ? 6 :
                                  controller.layoutMode === "abc" ? 0 :
                                  (controller.layoutMode === "accenti" ? 1 :
                                  (controller.layoutMode === "symbols" ? 2 :
                                  (controller.layoutMode === "numpad" ? 3 :
                                  (controller.layoutMode === "emoji" ? 4 :
                                  (controller.layoutMode === "klipper" ? 5 : 0)))))

                    // View 0: phone-style QWERTY
                    QwertyLayout {
                        host: mainWindow
                        currentTheme: mainWindow.activeTheme
                        vk: virtualKeyEngine
                        controller: controller
                        gestureEngine: gestureEngine
                    }

                    // View 1: IT Accenti Diretti
                    ColumnLayout {
                        spacing: 6
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["à", "è", "é", "ì", "ò", "ù", "€", "§"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }
                    }

                    // View 2: ?123 Symbols (Gboard 4-Row Complete Layout)
                    ColumnLayout {
                        spacing: 6

                        // Row 1: 1 2 3 4 5 6 7 8 9 0
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        // Row 2: @ # $ _ & - + ( ) /
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["@", "#", "$", "_", "&", "-", "+", "(", ")", "/"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        // Row 3: = \ % * " ' : ; ! ? ⌫
                        RowLayout {
                            spacing: 6
                            Repeater {
                                model: ["=", "\\", "%", "*", "\"", "'", ":", ";", "!", "?"]
                                delegate: KeyButton {
                                    label: modelData
                                    currentTheme: mainWindow.activeTheme
                                    vk: virtualKeyEngine
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                            KeyButton {
                                label: "⌫"
                                isSpecial: true
                                isBackspace: true
                                implicitWidth: 60
                                currentTheme: mainWindow.activeTheme
                                controller: controller
                                vk: virtualKeyEngine
                                Layout.fillHeight: true
                            }
                        }

                        // Row 4: ABC 😊 , spazio . ↵ ✖
                        RowLayout {
                            spacing: 6
                            KeyButton {
                                label: "ABC"
                                isSpecial: true
                                isCustomAction: true
                                implicitWidth: 55
                                currentTheme: mainWindow.activeTheme
                                onReleased: controller.layoutMode = "abc"
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: "😊"
                                isSpecial: true
                                isCustomAction: true
                                implicitWidth: 44
                                currentTheme: mainWindow.activeTheme
                                onReleased: controller.layoutMode = "emoji"
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: ","
                                implicitWidth: 44
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: "space"
                                textToSend: " "
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: "."
                                implicitWidth: 44
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: "↵"
                                textToSend: "\n"
                                isSpecial: true
                                isPrimaryAction: true
                                implicitWidth: 65
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                                Layout.fillHeight: true
                            }
                            KeyButton {
                                label: "✖"
                                isSpecial: true
                                isCustomAction: true
                                implicitWidth: 48
                                currentTheme: mainWindow.activeTheme
                                Layout.fillHeight: true
                                onReleased: mainWindow.hideKeyboard()
                            }
                        }
                    }

                    // View 3: Numpad Calcolatrice 3x4
                    GridLayout {
                        columns: 4
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: ["7", "8", "9", "/",
                                    "4", "5", "6", "*",
                                    "1", "2", "3", "-",
                                    "0", ".", "=", "+"]
                            delegate: KeyButton {
                                label: modelData
                                isSpecial: (modelData === "/" || modelData === "*" || modelData === "-" || modelData === "+" || modelData === "=")
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // View 4: Emoji grid + ABC / space / backspace row
                    ColumnLayout {
                        spacing: 6

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: emojiGrid.height
                            clip: true

                            GridLayout {
                                id: emojiGrid
                                columns: 8
                                rowSpacing: 6
                                columnSpacing: 6
                                width: parent.width

                                Repeater {
                                    model: ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣",
                                            "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰",
                                            "😘", "😗", "😙", "😚", "😋", "😛", "😜", "🤪",
                                            "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒",
                                            "👍", "👎", "👏", "🙌", "👐", "🤲", "🤝", "🙏",
                                            "🔥", "✨", "🎉", "❤️", "💯", "🚀", "💡", "⚠️"]
                                    delegate: KeyButton {
                                        label: modelData
                                        isCustomAction: true      // sent below (once)
                                        currentTheme: mainWindow.activeTheme
                                        vk: virtualKeyEngine
                                        Layout.fillWidth: true
                                        implicitHeight: 48
                                        onReleased: virtualKeyEngine.sendEmoji(modelData)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            spacing: 6
                            KeyButton {
                                label: "ABC"
                                isSpecial: true
                                isCustomAction: true
                                implicitWidth: 72
                                currentTheme: mainWindow.activeTheme
                                onReleased: controller.layoutMode = "abc"
                            }
                            KeyButton {
                                label: " "
                                textToSend: " "
                                autoAccents: false
                                Layout.fillWidth: true
                                currentTheme: mainWindow.activeTheme
                                vk: virtualKeyEngine
                            }
                            KeyButton {
                                icon: "backspace"
                                isSpecial: true
                                isBackspace: true
                                implicitWidth: 72
                                currentTheme: mainWindow.activeTheme
                                controller: controller
                                vk: virtualKeyEngine
                            }
                        }
                    }

                    // View 5: Klipper Clipboard View (Clean Modern Layout)
                    ColumnLayout {
                        spacing: 6

                        // Klipper Header Bar
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "📋  Cronologia Appunti (Klipper)"
                                color: mainWindow.activeTheme ? mainWindow.activeTheme.textColor : "#ffffff"
                                font.family: mainWindow.activeTheme ? mainWindow.activeTheme.fontFamily : "sans-serif"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 84
                                height: 26
                                radius: 13
                                color: mainWindow.activeTheme ? mainWindow.activeTheme.accentColor : "#00a2ed"
                                Text {
                                    anchors.centerIn: parent
                                    text: "🔄 Aggiorna"
                                    color: "#ffffff"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: klipper.refreshHistory()
                                }
                            }
                        }

                        // Klipper History Item Cards
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: klipper.history
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42
                                color: klipperMouse.pressed ? (mainWindow.activeTheme ? mainWindow.activeTheme.keyActiveColor : "#24344d") : (mainWindow.activeTheme ? mainWindow.activeTheme.keyBackgroundColor : "#162032")
                                border.color: mainWindow.activeTheme ? mainWindow.activeTheme.keyBorderColor : "#22334d"
                                radius: 10

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Index Badge
                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: mainWindow.activeTheme ? mainWindow.activeTheme.accentColor : "#00a2ed"
                                        Text {
                                            anchors.centerIn: parent
                                            text: (index + 1).toString()
                                            color: "#ffffff"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    // Content Text Preview
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData
                                        elide: Text.ElideRight
                                        color: mainWindow.activeTheme ? mainWindow.activeTheme.textColor : "#fff"
                                        font.family: mainWindow.activeTheme ? mainWindow.activeTheme.fontFamily : "sans-serif"
                                        font.pixelSize: 13
                                    }

                                    // Paste Action Badge
                                    Rectangle {
                                        width: 60
                                        height: 22
                                        radius: 6
                                        color: "#2a3447"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Incolla 📋"
                                            color: "#38bdf8"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: klipperMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        klipper.setClipboardContents(modelData)
                                        virtualKeyEngine.sendCombo(4, 47) // Ctrl+V
                                    }
                                }
                            }
                        }
                    }

                    // View 6: Extended PC layout (sizeMode "full")
                    ExtendedLayout {
                        currentTheme: mainWindow.activeTheme
                        vk: virtualKeyEngine
                        controller: controller
                    }
                }
            }
        }

        // Settings panel: overlays the suggestion bar and keys, below the top bar
        Rectangle {
            id: settingsPanel
            visible: opacity > 0
            opacity: mainWindow.showSettings ? 1 : 0
            scale: mainWindow.showSettings ? 1 : 0.97
            Behavior on opacity { enabled: prefs.animations; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: prefs.animations; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            z: 100
            anchors.fill: parent
            anchors.topMargin: 10 + 44 + 4
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 10
            radius: 24
            color: mainWindow.activeTheme && mainWindow.activeTheme.headerPillBg ? mainWindow.activeTheme.headerPillBg : "#434a56"

            readonly property color labelColor: mainWindow.activeTheme && mainWindow.activeTheme.pillTextColor ? mainWindow.activeTheme.pillTextColor : "#d0d5dd"
            readonly property color accent: mainWindow.activeTheme ? mainWindow.activeTheme.accentColor : "#00a2ed"

            // Swallow touches so keys underneath don't fire
            MouseArea { anchors.fill: parent }

            Flickable {
                anchors.fill: parent
                anchors.margins: 18
                contentHeight: settingsColumn.implicitHeight
                clip: true

                Column {
                    id: settingsColumn
                    width: parent.width
                    spacing: 4

                    // ---- Typing ----
                    Text {
                        text: "Typing"
                        color: settingsPanel.accent
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        bottomPadding: 4
                    }

                    Item {
                        width: parent.width; height: 48
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Key popup"
                            color: settingsPanel.labelColor
                            font.pixelSize: 15
                        }
                        M3Switch {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: prefs.keyPopout
                            accent: settingsPanel.accent
                            ink: settingsPanel.labelColor
                            animate: prefs.animations
                            onToggled: (on) => prefs.keyPopout = on
                        }
                    }

                    Item {
                        width: parent.width; height: 48
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Animations"
                            color: settingsPanel.labelColor
                            font.pixelSize: 15
                        }
                        M3Switch {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: prefs.animations
                            accent: settingsPanel.accent
                            ink: settingsPanel.labelColor
                            animate: prefs.animations
                            onToggled: (on) => prefs.animations = on
                        }
                    }

                    Item {
                        width: parent.width; height: 52
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Key style"
                            color: settingsPanel.labelColor
                            font.pixelSize: 15
                        }
                        M3Segmented {
                            surface: settingsPanel.color
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            accent: settingsPanel.accent
                            ink: settingsPanel.labelColor
                            current: prefs.keyStyle
                            options: [{ value: "gboard", label: "Gboard" }, { value: "classic", label: "Classic" }]
                            onSelected: (v) => prefs.keyStyle = v
                        }
                    }

                    Item {
                        width: parent.width; height: 40
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Keyboard height"
                            color: settingsPanel.labelColor
                            font.pixelSize: 15
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(prefs.heightScale * 100) + "%"
                            color: settingsPanel.labelColor
                            opacity: 0.7
                            font.pixelSize: 14
                        }
                    }

                    ValueSlider {
                        width: parent.width
                        from: 0.7
                        to: 1.5
                        stepSize: 0.05
                        value: prefs.heightScale
                        accent: settingsPanel.accent
                        trackColor: settingsPanel.labelColor
                        onMoved: (v) => prefs.heightScale = v
                    }

                    // ---- Show keyboard ----
                    Text {
                        topPadding: 14
                        bottomPadding: 8
                        text: "Show keyboard"
                        color: settingsPanel.accent
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    M3Segmented {
                        surface: settingsPanel.color
                        accent: settingsPanel.accent
                        ink: settingsPanel.labelColor
                        current: prefs.showMode
                        options: [{ value: "auto", label: "Automatically" }, { value: "manual", label: "Manually" }]
                        onSelected: (v) => prefs.showMode = v
                    }

                    Text {
                        width: parent.width
                        topPadding: 6
                        wrapMode: Text.WordWrap
                        text: virtualKeyEngine.hasInputMethod
                              ? "Automatically: appears when a text field is focused. Manually: a floating button brings it back."
                              : "Automatic mode needs Huskie-board to be selected as the virtual keyboard in System Settings; using manual mode for now."
                        color: settingsPanel.labelColor
                        opacity: 0.7
                        font.pixelSize: 12
                    }

                    // ---- Theme ----
                    Text {
                        topPadding: 14
                        bottomPadding: 8
                        text: "Theme"
                        color: settingsPanel.accent
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Flow {
                        width: parent.width
                        spacing: 8
                        bottomPadding: 8
                        Repeater {
                            model: mainWindow.themeChoices
                            delegate: OptionPill {
                                accent: settingsPanel.accent
                                labelColor: settingsPanel.labelColor
                                text: modelData.label
                                selected: controller.activeTheme === modelData.id
                                onTapped: mainWindow.selectTheme(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
