import QtQuick 2.15

// Vector key glyphs (Gboard-like outline icons).
// name: "shift" | "shift-on" | "caps" | "backspace" | "enter" | "emoji"
Canvas {
    id: icon
    property string name: ""
    property color color: "#000000"
    width: 24
    height: 24
    antialiasing: true
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineWidth = 1.9
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        var s = width / 24
        ctx.scale(s, s)

        function shiftArrow() {
            ctx.beginPath()
            ctx.moveTo(12, 3.5)
            ctx.lineTo(20.5, 12.5)
            ctx.lineTo(15.5, 12.5)
            ctx.lineTo(15.5, 18)
            ctx.lineTo(8.5, 18)
            ctx.lineTo(8.5, 12.5)
            ctx.lineTo(3.5, 12.5)
            ctx.closePath()
        }

        if (name === "shift") {
            shiftArrow(); ctx.stroke()
        } else if (name === "shift-on") {
            shiftArrow(); ctx.fill(); ctx.stroke()
        } else if (name === "caps") {
            ctx.save(); ctx.translate(0, -1.5); shiftArrow(); ctx.fill(); ctx.stroke(); ctx.restore()
            ctx.beginPath(); ctx.moveTo(8.5, 20.5); ctx.lineTo(15.5, 20.5); ctx.stroke()
        } else if (name === "backspace") {
            ctx.beginPath()
            ctx.moveTo(8, 5.5); ctx.lineTo(20.5, 5.5); ctx.lineTo(20.5, 18.5); ctx.lineTo(8, 18.5)
            ctx.lineTo(2.5, 12); ctx.closePath(); ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(11, 9); ctx.lineTo(17, 15); ctx.moveTo(17, 9); ctx.lineTo(11, 15); ctx.stroke()
        } else if (name === "enter") {
            ctx.beginPath()
            ctx.moveTo(19, 5.5); ctx.lineTo(19, 13.5); ctx.lineTo(5.5, 13.5); ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(9.5, 9.5); ctx.lineTo(5.5, 13.5); ctx.lineTo(9.5, 17.5); ctx.stroke()
        } else if (name === "emoji") {
            ctx.beginPath(); ctx.arc(12, 12, 8.5, 0, Math.PI * 2); ctx.stroke()
            ctx.beginPath(); ctx.arc(9, 10, 1.1, 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(15, 10, 1.1, 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(12, 12.5, 4.2, 0.2 * Math.PI, 0.8 * Math.PI); ctx.stroke()
        }
    }
}
