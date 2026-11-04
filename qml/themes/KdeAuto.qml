import QtQuick 2.15

// Follows the active KDE color scheme via the Qt platform palette
// (provided by plasma-integration; updates live when the scheme changes).
QtObject {
    id: theme

    property string themeName: "Auto (KDE)"

    property SystemPalette pal: SystemPalette { colorGroup: SystemPalette.Active }
    readonly property bool isDark: pal.window.hslLightness < 0.5

    function shade(c, amount) {
        // Darken on light schemes, lighten on dark ones
        return isDark ? Qt.lighter(c, 1 + amount) : Qt.darker(c, 1 + amount)
    }

    property color backgroundColor: pal.window
    property color cardBorderColor: shade(pal.window, 0.25)
    property int cardRadius: 12

    property color keyBackgroundColor: pal.button
    property color keyActiveColor: Qt.tint(pal.button, Qt.rgba(pal.highlight.r, pal.highlight.g, pal.highlight.b, 0.35))
    property color keyBorderColor: shade(pal.button, 0.18)
    property int keyBorderWidth: 1
    property int keyRadius: 6

    property color specialKeyBackgroundColor: shade(pal.button, 0.08)
    property color textColor: pal.buttonText
    property color accentColor: pal.highlight
    property color accentTextColor: isDark ? Qt.lighter(pal.highlight, 1.25) : Qt.darker(pal.highlight, 1.25)  // accent-coloured text on keys
    property color redWarningColor: "#da4453"

    property color headerPillBg: shade(pal.window, 0.10)
    property color sizeModePillBg: shade(pal.window, 0.16)
    property color pillTextColor: pal.windowText

    property color dpadBg: shade(pal.window, 0.10)
    property color dpadHeaderColor: pal.highlight

    property string fontFamily: Qt.application.font.family
}
