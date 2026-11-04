import QtQuick 2.15
import "Accents.js" as Accents

// Phone-style QWERTY (Gboard proportions) on a 10-unit grid:
//   q w e r t y u i o p
//    a s d f g h j k l
//   ⇧  z x c v b n m  ⌫
//   ?123 ☺ ,   space   . ⏎
// Hold a letter for accents (top row: number first), hold "." for punctuation.
Item {
    id: qw

    property var host            // Main window: shiftState, input buffer, hideKeyboard()
    property var currentTheme
    property var vk
    property var controller
    property var gestureEngine

    readonly property int shiftState: host ? host.shiftState : 0   // 0 off, 1 once, 2 caps lock
    readonly property bool upper: shiftState > 0

    readonly property real gap: 6
    readonly property real unit: width / 10
    readonly property real rowH: (height - gap * 3) / 4

    function rowY(r) { return r * (rowH + gap) }
    function keyX(u) { return u * unit + gap / 2 }
    function keyW(w) { return w * unit - gap }

    function resetWord() {
        if (!host) return
        host.currentInputBuffer = ""
        if (gestureEngine) gestureEngine.updateCurrentPrefix("")
    }

    function typed(ch) {
        if (!host) return
        host.currentInputBuffer += ch
        if (gestureEngine) gestureEngine.updateCurrentPrefix(host.currentInputBuffer)
        if (host.shiftState === 1) host.shiftState = 0
    }

    readonly property var letterRows: [
        { y: 0, x0: 0,   keys: "qwertyuiop" },
        { y: 1, x0: 0.5, keys: "asdfghjkl" },
        { y: 2, x0: 1.5, keys: "zxcvbnm" }
    ]

    // ---- Letters ----
    Repeater {
        model: qw.letterRows
        delegate: Item {
            readonly property var rowData: modelData
            Repeater {
                model: rowData.keys.length
                delegate: KeyButton {
                    readonly property string base: rowData.keys[index]
                    x: qw.keyX(rowData.x0 + index)
                    y: qw.rowY(rowData.y)
                    width: qw.keyW(1)
                    height: qw.rowH
                    label: qw.upper ? base.toUpperCase() : base
                    hintAccent: Accents.digitFor(base)
                    currentTheme: qw.currentTheme
                    vk: qw.vk
                    gestureEngine: qw.gestureEngine
                    onKeyTriggered: (key) => qw.typed(key)
                }
            }
        }
    }

    // ---- Shift / Backspace ----
    Timer { id: shiftDoubleTap; interval: 300 }

    KeyButton {
        x: qw.keyX(0)
        y: qw.rowY(2)
        width: qw.keyW(1.5)
        height: qw.rowH
        icon: qw.shiftState === 2 ? "caps" : (qw.shiftState === 1 ? "shift-on" : "shift")
        isSpecial: true
        isCustomAction: true
        currentTheme: qw.currentTheme
        onReleased: {
            if (!qw.host) return
            if (shiftDoubleTap.running) {           // double tap: caps lock
                shiftDoubleTap.stop()
                qw.host.shiftState = 2
            } else {
                shiftDoubleTap.start()
                qw.host.shiftState = qw.host.shiftState > 0 ? 0 : 1
            }
        }
    }

    KeyButton {
        x: qw.keyX(8.5)
        y: qw.rowY(2)
        width: qw.keyW(1.5)
        height: qw.rowH
        icon: "backspace"
        isSpecial: true
        isBackspace: true
        currentTheme: qw.currentTheme
        controller: qw.controller
        vk: qw.vk
    }

    // ---- Bottom row ----
    KeyButton {
        x: qw.keyX(0)
        y: qw.rowY(3)
        width: qw.keyW(1.5)
        height: qw.rowH
        label: "?123"
        isSpecial: true
        isCustomAction: true
        currentTheme: qw.currentTheme
        onReleased: if (qw.controller) qw.controller.layoutMode = "symbols"
    }
    KeyButton {
        x: qw.keyX(1.5)
        y: qw.rowY(3)
        width: qw.keyW(1)
        height: qw.rowH
        icon: "emoji"
        isSpecial: true
        isCustomAction: true
        currentTheme: qw.currentTheme
        onReleased: if (qw.controller) qw.controller.layoutMode = "emoji"
    }
    KeyButton {
        x: qw.keyX(2.5)
        y: qw.rowY(3)
        width: qw.keyW(1)
        height: qw.rowH
        label: ","
        isSpecial: true
        currentTheme: qw.currentTheme
        vk: qw.vk
        accents: Accents.variants(",", false)
        onKeyTriggered: qw.resetWord()
    }
    KeyButton {
        x: qw.keyX(3.5)
        y: qw.rowY(3)
        width: qw.keyW(4)
        height: qw.rowH
        label: " "
        textToSend: " "
        autoAccents: false
        currentTheme: qw.currentTheme
        vk: qw.vk
        onKeyTriggered: qw.resetWord()
    }
    KeyButton {
        x: qw.keyX(7.5)
        y: qw.rowY(3)
        width: qw.keyW(1)
        height: qw.rowH
        label: "."
        isSpecial: true
        currentTheme: qw.currentTheme
        vk: qw.vk
        accents: Accents.variants(".", false)
        onKeyTriggered: qw.resetWord()
    }
    KeyButton {
        x: qw.keyX(8.5)
        y: qw.rowY(3)
        width: qw.keyW(1.5)
        height: qw.rowH
        icon: "enter"
        textToSend: "\n"
        isSpecial: true
        isPrimaryAction: true
        currentTheme: qw.currentTheme
        vk: qw.vk
        onKeyTriggered: qw.resetWord()
    }
}
