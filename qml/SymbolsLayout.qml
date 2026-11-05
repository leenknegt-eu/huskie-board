import QtQuick 2.15

// Symbols ("?123"), Gboard style, on the same 10-unit grid as QwertyLayout.
// Two pages: =\< switches to the second page, ?123 back to the first.
Item {
    id: sy

    property var host
    property var currentTheme
    property var vk
    property var controller

    property int page: 0

    readonly property real gap: 6
    readonly property real unit: width / 10
    readonly property real rowH: (height - gap * 3) / 4

    function rowY(r) { return r * (rowH + gap) }
    function keyX(u) { return u * unit + gap / 2 }
    function keyW(w) { return w * unit - gap }

    readonly property var pages: [
        [ "1234567890".split(""),
          ["@", "#", "$", "_", "&", "-", "+", "(", ")", "/"],
          ["*", "\"", "'", ":", ";", "!", "?"] ],
        [ ["~", "`", "|", "•", "√", "π", "÷", "×", "<", ">"],
          ["£", "¢", "€", "¥", "^", "°", "=", "{", "}", "\\"],
          ["%", "©", "®", "™", "✓", "[", "]"] ]
    ]

    // Rows 1-2: ten keys each; row 3: seven keys between the page key and backspace
    Repeater {
        model: 3
        delegate: Item {
            readonly property int r: index
            readonly property var keys: sy.pages[sy.page][r]
            Repeater {
                model: keys
                delegate: KeyButton {
                    x: sy.keyX((r === 2 ? 1.5 : 0) + index)
                    y: sy.rowY(r)
                    width: sy.keyW(1)
                    height: sy.rowH
                    label: modelData
                    currentTheme: sy.currentTheme
                    vk: sy.vk
                }
            }
        }
    }

    KeyButton {
        x: sy.keyX(0)
        y: sy.rowY(2)
        width: sy.keyW(1.5)
        height: sy.rowH
        label: sy.page === 0 ? "=\\<" : "?123"
        isSpecial: true
        isCustomAction: true
        currentTheme: sy.currentTheme
        onReleased: sy.page = sy.page === 0 ? 1 : 0
    }

    KeyButton {
        x: sy.keyX(8.5)
        y: sy.rowY(2)
        width: sy.keyW(1.5)
        height: sy.rowH
        icon: "backspace"
        isSpecial: true
        isBackspace: true
        currentTheme: sy.currentTheme
        controller: sy.controller
        vk: sy.vk
    }

    // ---- Bottom row: identical to the letters layout ----
    KeyButton {
        x: sy.keyX(0)
        y: sy.rowY(3)
        width: sy.keyW(1.5)
        height: sy.rowH
        label: "ABC"
        isSpecial: true
        isCustomAction: true
        currentTheme: sy.currentTheme
        onReleased: { sy.page = 0; if (sy.controller) sy.controller.layoutMode = "abc" }
    }
    KeyButton {
        x: sy.keyX(1.5)
        y: sy.rowY(3)
        width: sy.keyW(1)
        height: sy.rowH
        icon: "emoji"
        isSpecial: true
        isCustomAction: true
        currentTheme: sy.currentTheme
        onReleased: if (sy.controller) sy.controller.layoutMode = "emoji"
    }
    KeyButton {
        x: sy.keyX(2.5)
        y: sy.rowY(3)
        width: sy.keyW(1)
        height: sy.rowH
        label: ","
        isSpecial: true
        currentTheme: sy.currentTheme
        vk: sy.vk
    }
    KeyButton {
        x: sy.keyX(3.5)
        y: sy.rowY(3)
        width: sy.keyW(4)
        height: sy.rowH
        label: " "
        textToSend: " "
        autoAccents: false
        currentTheme: sy.currentTheme
        vk: sy.vk
    }
    KeyButton {
        x: sy.keyX(7.5)
        y: sy.rowY(3)
        width: sy.keyW(1)
        height: sy.rowH
        label: "."
        isSpecial: true
        currentTheme: sy.currentTheme
        vk: sy.vk
    }
    KeyButton {
        x: sy.keyX(8.5)
        y: sy.rowY(3)
        width: sy.keyW(1.5)
        height: sy.rowH
        icon: "enter"
        textToSend: "\n"
        isSpecial: true
        isPrimaryAction: true
        currentTheme: sy.currentTheme
        vk: sy.vk
    }
}
