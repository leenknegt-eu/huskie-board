import QtQuick 2.15
import "Accents.js" as Accents

// Full PC-style layout for "Extended" size: function row, number row, QWERTY with
// punctuation, Ctrl/Super/Alt and an inverted-T arrow cluster. Keys sit on a
// 15-unit grid so columns (e.g. ↑ above ↓) line up exactly.
//
// Modifiers latch: tap Ctrl, then C sends Ctrl+C. Tap a modifier again to release it.
Item {
    id: ext

    property var currentTheme
    property var vk
    property var controller

    // Latched modifier state
    property bool shift: false
    property bool caps: false
    property bool ctrl: false
    property bool alt: false
    property bool sup: false
    readonly property bool anyCombo: ctrl || alt || sup
    // Bit mask understood by WaylandVirtualKeyboard::sendCombo: 1 Shift, 4 Ctrl, 8 Alt, 64 Super
    readonly property int modMask: (shift ? 1 : 0) | (ctrl ? 4 : 0) | (alt ? 8 : 0) | (sup ? 64 : 0)

    readonly property real gap: 5
    readonly property real unit: width / 15
    readonly property var rowWeights: [0.72, 1, 1, 1, 1, 1]
    readonly property real rowUnit: (height - gap * (rowWeights.length - 1)) / rowWeights.reduce(function (a, b) { return a + b }, 0)

    // [label, shifted label, evdev keycode, width units, type]
    // types: char (default) | key | repeat | arrow | bksp | enter | space | shift | caps | ctrl | alt | super
    function row(keys) {
        var x = 0, out = []
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i]
            var w = k[3] || 1
            out.push({ l: k[0], s: k[1], k: k[2], w: w, t: k[4] || "char", x: x })
            x += w
        }
        return out
    }
    function letters(str, codes) {
        var out = []
        for (var i = 0; i < str.length; i++) out.push([str[i], str[i].toUpperCase(), codes[i]])
        return out
    }

    readonly property var rows: [
        row([["Esc", "", 1, 1, "key"],
             ["F1", "", 59, 1, "key"], ["F2", "", 60, 1, "key"], ["F3", "", 61, 1, "key"], ["F4", "", 62, 1, "key"],
             ["F5", "", 63, 1, "key"], ["F6", "", 64, 1, "key"], ["F7", "", 65, 1, "key"], ["F8", "", 66, 1, "key"],
             ["F9", "", 67, 1, "key"], ["F10", "", 68, 1, "key"], ["F11", "", 87, 1, "key"], ["F12", "", 88, 1, "key"],
             ["Home", "", 102, 1, "repeat"], ["End", "", 107, 1, "repeat"]]),
        row([["`", "~", 41], ["1", "!", 2], ["2", "@", 3], ["3", "#", 4], ["4", "$", 5], ["5", "%", 6],
             ["6", "^", 7], ["7", "&", 8], ["8", "*", 9], ["9", "(", 10], ["0", ")", 11],
             ["-", "_", 12], ["=", "+", 13], ["⌫", "", 14, 2, "bksp"]]),
        row([["Tab", "", 15, 1.5, "key"]]
            .concat(letters("qwertyuiop", [16, 17, 18, 19, 20, 21, 22, 23, 24, 25]))
            .concat([["[", "{", 26], ["]", "}", 27], ["\\", "|", 43, 1.5]])),
        row([["Caps", "", 58, 1.75, "caps"]]
            .concat(letters("asdfghjkl", [30, 31, 32, 33, 34, 35, 36, 37, 38]))
            .concat([[";", ":", 39], ["'", "\"", 40], ["Enter", "", 28, 2.25, "enter"]])),
        row([["Shift", "", 42, 2, "shift"]]
            .concat(letters("zxcvbnm", [44, 45, 46, 47, 48, 49, 50]))
            .concat([[",", "<", 51], [".", ">", 52], ["/", "?", 53],
                     ["Shift", "", 54, 1, "shift"], ["↑", "", 103, 1, "arrow"], ["Del", "", 111, 1, "repeat"]])),
        row([["Ctrl", "", 29, 1.25, "ctrl"], ["Super", "", 125, 1.25, "super"], ["Alt", "", 56, 1.25, "alt"],
             ["", "", 57, 6.25, "space"],
             ["Alt", "", 100, 1, "alt"], ["Ctrl", "", 97, 1, "ctrl"],
             ["←", "", 105, 1, "arrow"], ["↓", "", 108, 1, "arrow"], ["→", "", 106, 1, "arrow"]])
    ]

    function isLetter(s) { return s.length === 1 && s.toLowerCase() !== s.toUpperCase() }

    function displayLabel(d) {
        if (d.t === "space") return ""
        if (d.t !== "char") return d.l
        if (isLetter(d.l)) return (shift !== caps) ? d.s : d.l
        return shift ? d.s : d.l
    }

    function releaseLatches() {
        shift = false; ctrl = false; alt = false; sup = false
    }

    function isActiveModifier(d) {
        return (d.t === "shift" && shift) || (d.t === "caps" && caps) || (d.t === "ctrl" && ctrl)
            || (d.t === "alt" && alt) || (d.t === "super" && sup)
    }

    // Dispatch for a tap (repeat/arrow keys are handled on press instead)
    function tap(d) {
        if (!vk) return
        switch (d.t) {
        case "shift": shift = !shift; return
        case "caps":  caps = !caps; return
        case "ctrl":  ctrl = !ctrl; return
        case "alt":   alt = !alt; return
        case "super": sup = !sup; return
        case "char":
            if (anyCombo) vk.sendCombo(modMask, d.k)
            else vk.sendText(displayLabel(d))
            break
        case "space":
            if (anyCombo || shift) vk.sendCombo(modMask, d.k); else vk.sendText(" ")
            break
        case "enter":
            if (modMask) vk.sendCombo(modMask, d.k); else vk.sendText("\n")
            break
        case "bksp":
            if (modMask) vk.sendCombo(modMask, d.k); else vk.sendBackspace()
            break
        default: // "key"
            if (modMask) vk.sendCombo(modMask, d.k); else vk.sendKey(d.k)
        }
        releaseLatches()
    }

    Repeater {
        model: ext.rows.length
        delegate: Item {
            id: rowItem
            readonly property int rowIndex: index
            readonly property real rowH: ext.rowUnit * ext.rowWeights[index]
            x: 0
            y: {
                var yy = 0
                for (var r = 0; r < index; r++) yy += ext.rowUnit * ext.rowWeights[r] + ext.gap
                return yy
            }
            width: ext.width
            height: rowH

            Repeater {
                model: ext.rows[rowItem.rowIndex]
                delegate: KeyButton {
                    readonly property var d: modelData
                    x: d.x * ext.unit + ext.gap / 2
                    y: 0
                    width: d.w * ext.unit - ext.gap
                    height: rowItem.height
                    label: ext.displayLabel(d)
                    icon: d.t === "shift" ? (ext.shift ? "shift-on" : "shift")
                        : (d.t === "bksp" ? "backspace" : (d.t === "enter" ? "enter" : ""))
                    // hold a letter for accents (no digits here: there is a number row)
                    accents: (d.t === "char" && ext.isLetter(d.l) && !ext.anyCombo) ? Accents.variants(ext.displayLabel(d), false) : []
                    onAccentCommitted: ext.releaseLatches()
                    hintAccent: (d.t === "char" && !ext.isLetter(d.l)) ? (ext.shift ? d.l : d.s) : ""
                    isSpecial: d.t !== "char" && d.t !== "space"
                    showPopout: d.t === "char"
                    isPrimaryAction: ext.isActiveModifier(d) || d.t === "enter"
                    isCustomAction: true
                    currentTheme: ext.currentTheme
                    vk: ext.vk
                    controller: ext.controller

                    onPressed: {
                        // Arrows / navigation: act immediately and auto-repeat while held
                        if (d.t === "arrow" || d.t === "repeat") {
                            if (ext.modMask) {
                                ext.vk.sendCombo(ext.modMask, d.k)
                                ext.releaseLatches()
                            } else {
                                ext.vk.sendKey(d.k)
                                if (ext.controller) ext.controller.startKeyRepeat(d.k)
                            }
                        } else if (d.t === "bksp" && !ext.modMask && ext.controller) {
                            ext.controller.startBackspaceTimer()   // deletes once now, repeats while held
                        }
                    }
                    onReleased: {
                        if (d.t === "arrow" || d.t === "repeat") {
                            if (ext.controller) ext.controller.stopKeyRepeat()
                        } else if (d.t === "bksp" && !ext.modMask && ext.controller) {
                            ext.controller.stopBackspaceTimer()
                        } else {
                            ext.tap(d)
                        }
                    }
                }
            }
        }
    }
}
