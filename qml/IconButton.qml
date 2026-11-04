import QtQuick 2.15

// Round toolbar button with a vector icon (drawn, so it is pixel-centred
// regardless of font glyph metrics). icon: "gear" | "docked" | "floating" | "hide"
Rectangle {
    id: btn
    property string icon: "gear"
    property bool active: false
    property color iconColor: "#d0d5dd"
    property color activeColor: "#00a2ed"
    property color idleColor: "#21252d"
    signal clicked()

    width: 34
    height: 34
    radius: width / 2
    color: active ? activeColor : idleColor
    Behavior on color { ColorAnimation { duration: 120 } }

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: 20
        height: 20
        antialiasing: true
        readonly property color ink: btn.active ? "#ffffff" : btn.iconColor
        onInkChanged: requestPaint()
        Connections { target: btn; function onIconChanged() { canvas.requestPaint() } }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = ink
            ctx.strokeStyle = ink
            ctx.lineWidth = 1.8
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            var cx = width / 2, cy = height / 2

            if (btn.icon === "gear") {
                var teeth = 8, rOut = 9, rIn = 6.6, rHole = 2.9
                ctx.beginPath()
                for (var i = 0; i < teeth * 2; i++) {
                    // each tooth: two points on the outer radius, two on the inner
                    var a0 = (i / (teeth * 2)) * Math.PI * 2 - Math.PI / 2
                    var a1 = ((i + 1) / (teeth * 2)) * Math.PI * 2 - Math.PI / 2
                    var r = (i % 2 === 0) ? rOut : rIn
                    var inset = (i % 2 === 0) ? 0.12 : 0
                    if (i === 0) ctx.moveTo(cx + r * Math.cos(a0 + inset), cy + r * Math.sin(a0 + inset))
                    else ctx.lineTo(cx + r * Math.cos(a0 + inset), cy + r * Math.sin(a0 + inset))
                    ctx.lineTo(cx + r * Math.cos(a1 - inset), cy + r * Math.sin(a1 - inset))
                }
                ctx.closePath()
                ctx.moveTo(cx + rHole, cy)
                ctx.arc(cx, cy, rHole, 0, Math.PI * 2, true)   // opposite winding -> hole
                ctx.fillRule = Qt.OddEvenFill
                ctx.fill()
            } else if (btn.icon === "docked" || btn.icon === "floating") {
                // a screen; docked = bar along its bottom edge, floating = block hovering inside
                ctx.beginPath()
                ctx.rect(2.5, 3.5, 15, 13)
                ctx.stroke()
                ctx.beginPath()
                if (btn.icon === "docked") ctx.rect(2.5, 12, 15, 4.5)
                else ctx.rect(6, 8.5, 8, 4)
                ctx.fill()
            } else if (btn.icon === "clipboard") {
                ctx.beginPath()
                ctx.rect(4.5, 4, 11, 14)
                ctx.stroke()
                ctx.beginPath()
                ctx.rect(7.5, 2.5, 5, 3)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(7.5, 9.5); ctx.lineTo(12.5, 9.5)
                ctx.moveTo(7.5, 13); ctx.lineTo(12.5, 13)
                ctx.stroke()
            } else if (btn.icon === "terminal") {
                ctx.beginPath()
                ctx.rect(2.5, 3.5, 15, 13)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(5.5, 7.5); ctx.lineTo(8.5, 10); ctx.lineTo(5.5, 12.5)
                ctx.moveTo(10, 13); ctx.lineTo(14.5, 13)
                ctx.stroke()
            } else if (btn.icon === "size-normal" || btn.icon === "size-full" || btn.icon === "size-onehand") {
                // keyboard outline sized like the mode; one-handed is pushed to the right
                var w = btn.icon === "size-full" ? 17 : (btn.icon === "size-onehand" ? 8 : 12)
                var x0 = btn.icon === "size-onehand" ? 18 - w : cx - w / 2
                ctx.beginPath()
                ctx.rect(x0, 6, w, 9)
                ctx.stroke()
                ctx.beginPath()
                var n = Math.max(2, Math.floor(w / 3.2))
                for (var j = 0; j < n; j++) ctx.rect(x0 + 2 + j * ((w - 4) / n), 8.6, 1.4, 1.4)
                ctx.rect(x0 + w / 2 - 2.5, 11.8, 5, 1.2)
                ctx.fill()
            } else if (btn.icon === "hide") {
                ctx.beginPath()
                ctx.moveTo(cx - 6, cy - 3)
                ctx.lineTo(cx, cy + 3)
                ctx.lineTo(cx + 6, cy - 3)
                ctx.lineWidth = 2.2
                ctx.stroke()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btn.clicked()
    }
}
