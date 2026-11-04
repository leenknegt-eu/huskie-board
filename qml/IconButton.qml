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
                // a small keyboard: resting on the baseline (docked) or lifted above it (floating)
                var lift = btn.icon === "floating" ? 4 : 0
                var kw = 14, kh = 8
                var kx = cx - kw / 2, ky = 15 - kh - lift
                ctx.beginPath()
                ctx.rect(kx, ky, kw, kh)
                ctx.stroke()
                ctx.beginPath()                       // key dots
                for (var k = 0; k < 3; k++) ctx.rect(kx + 3 + k * 3.5, ky + 2.6, 1.4, 1.4)
                ctx.fill()
                ctx.beginPath()                       // baseline (screen edge)
                ctx.moveTo(2, 17.5)
                ctx.lineTo(18, 17.5)
                ctx.stroke()
                if (lift > 0) {                       // up arrow hint
                    ctx.beginPath()
                    ctx.moveTo(cx - 2.5, ky - 1.5); ctx.lineTo(cx, ky - 4); ctx.lineTo(cx + 2.5, ky - 1.5)
                    ctx.stroke()
                }
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
