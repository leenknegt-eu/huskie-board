import QtQuick 2.15
import "Emoji.js" as Emoji

// Emoji picker, Gboard style: the full Unicode emoji set (see tools/gen-emoji.py),
// a lazily created grid per category, skin tones on long press, and a bottom bar
// with ABC, category tabs and backspace. Emoji newer than the installed emoji font
// are hidden so they never show up as empty boxes.
Item {
    id: em

    property var host
    property var currentTheme
    property var vk
    property var controller

    property int category: 0

    readonly property color ink: currentTheme ? currentTheme.textColor : "#202124"
    readonly property color accent: currentTheme ? currentTheme.accentColor : "#1a73e8"
    readonly property color surface: currentTheme ? currentTheme.keyBackgroundColor : "#ffffff"
    readonly property bool animate: typeof prefs === "undefined" || prefs.animations

    readonly property real gap: 6
    readonly property real unit: width / 10
    readonly property real barH: Math.max(40, (height - gap * 3) / 4)

    // ---- Font coverage ------------------------------------------------------------
    // fullVersion: newest emoji version whose samples all render -> shown without checks.
    // Newer emoji (a font may cover the latest version only partly) are checked one by
    // one, so nothing ever shows up as an empty box.
    property real fullVersion: -1
    property var newerOk: ({})
    function detectFontCoverage() {
        if (!controller) { fullVersion = 99; return }
        var byVersion = {}
        for (var c = 0; c < Emoji.categories.length; c++) {
            var list = Emoji.categories[c].emoji
            for (var i = 0; i < list.length; i++) {
                var v = list[i].v
                if (!byVersion[v]) byVersion[v] = []
                if (byVersion[v].length < 4) byVersion[v].push(list[i].e)
            }
        }
        var versions = Object.keys(byVersion).map(Number).sort(function (a, b) { return b - a })
        var full = 0
        for (var k = 0; k < versions.length; k++) {
            var samples = byVersion[versions[k]]
            if (samples.every(function (e) { return controller.emojiRenderable(e) })) { full = versions[k]; break }
        }
        var ok = {}, checked = 0, passed = 0
        for (var c2 = 0; c2 < Emoji.categories.length; c2++) {
            var l2 = Emoji.categories[c2].emoji
            for (var j = 0; j < l2.length; j++) {
                if (l2[j].v <= full) continue
                ++checked
                if (controller.emojiRenderable(l2[j].e)) { ok[l2[j].e] = true; ++passed }
            }
        }
        newerOk = ok
        fullVersion = full
        console.info("Emoji: Unicode " + Emoji.unicodeVersion + " data; font fully covers Emoji " + full
                     + ", " + passed + "/" + checked + " newer emoji drawable")
    }
    onVisibleChanged: if (visible && fullVersion < 0) detectFontCoverage()

    readonly property var shown: fullVersion < 0 ? []
        : Emoji.categories[category].emoji.filter(function (x) { return x.v <= em.fullVersion || em.newerOk[x.e] === true })

    // ---- Emoji grid (only visible cells are created) ----
    GridView {
        id: grid
        x: 0
        y: 0
        width: em.width
        height: em.height - em.barH - em.gap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        readonly property int cols: Math.max(6, Math.floor(width / 64))
        cellWidth: width / cols
        cellHeight: Math.min(cellWidth, 60)
        model: em.shown
        cacheBuffer: 240

        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            readonly property var entry: modelData
            readonly property bool hasTones: !!(entry.t && entry.t.length)

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
                text: entry.e
                font.family: "emoji"   // must match KeyboardController::emojiRenderable
                font.pixelSize: Math.min(30, parent.height * 0.55)
            }
            Rectangle {     // small corner mark: has skin tones
                visible: parent.hasTones
                width: 5; height: 5; radius: 2.5
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.margins: 7
                color: em.ink
                opacity: 0.35
            }
            MouseArea {
                id: cellArea
                anchors.fill: parent
                pressAndHoldInterval: 350
                onClicked: if (em.vk) em.vk.sendEmoji(entry.e)
                onPressAndHold: {
                    if (!parent.hasTones) return
                    var p = parent.mapToItem(em, 0, 0)
                    tonePopup.open([entry.e].concat(entry.t), p.x + parent.width / 2, p.y)
                }
            }
        }
    }

    // ---- Skin-tone popup ----
    MouseArea {     // tap outside closes it
        anchors.fill: parent
        visible: tonePopup.visible
        z: 50
        onClicked: tonePopup.visible = false
    }
    Rectangle {
        id: tonePopup
        z: 51
        visible: false
        property var options: []
        readonly property real cell: 52
        width: Math.min(em.width, options.length * cell + 12)
        height: cell + 12
        radius: 16
        color: em.surface
        border.width: 1
        border.color: Qt.rgba(em.ink.r, em.ink.g, em.ink.b, 0.15)

        function open(list, cx, top) {
            options = list
            x = Math.max(0, Math.min(em.width - width, cx - width / 2))
            y = Math.max(0, top - height - 4)
            visible = true
        }

        Elevation { anchors.fill: parent; radius: parent.radius; level: 3; z: -1 }
        Flickable {
            anchors.fill: parent
            anchors.margins: 6
            contentWidth: toneRow.width
            clip: true
            Row {
                id: toneRow
                Repeater {
                    model: tonePopup.options
                    delegate: Item {
                        width: tonePopup.cell
                        height: tonePopup.cell
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 12
                            color: em.accent
                            opacity: toneArea.pressed ? 0.22 : 0
                        }
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "emoji"   // must match KeyboardController::emojiRenderable
                            font.pixelSize: 28
                        }
                        MouseArea {
                            id: toneArea
                            anchors.fill: parent
                            onClicked: {
                                if (em.vk) em.vk.sendEmoji(modelData)
                                tonePopup.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Bottom bar: ABC | category tabs | backspace ----
    KeyButton {
        x: em.gap / 2
        y: em.height - em.barH
        width: em.unit * 1.5 - em.gap
        height: em.barH
        label: "ABC"
        isSpecial: true
        isCustomAction: true
        currentTheme: em.currentTheme
        onReleased: { tonePopup.visible = false; if (em.controller) em.controller.layoutMode = "abc" }
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
                    width: Math.min(parent.width - 4, 48)
                    height: Math.min(parent.height - 6, 34)
                    radius: height / 2
                    color: Qt.rgba(em.accent.r, em.accent.g, em.accent.b, 0.22)
                    visible: parent.current
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font.family: "emoji"   // must match KeyboardController::emojiRenderable
                    font.pixelSize: 19
                    opacity: parent.current ? 1 : 0.6
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { tonePopup.visible = false; em.category = index; grid.positionViewAtBeginning() }
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
