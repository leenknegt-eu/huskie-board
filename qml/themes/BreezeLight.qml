import QtQuick 2.15

// KDE Breeze Light palette
QtObject {
    id: theme

    property string themeName: "Breeze Light"

    property color backgroundColor: "#eff0f1"
    property color cardBorderColor: "#bdc3c7"
    property int cardRadius: 24

    property color keyBackgroundColor: "#fcfcfc"
    property color keyActiveColor: "#d6ecf8"
    property color keyBorderColor: "#c4c9cd"
    property int keyBorderWidth: 1
    property int keyRadius: 10

    property color specialKeyBackgroundColor: "#e3e5e7"
    property color textColor: "#232629"
    property color accentColor: "#3daee9"
    property color accentTextColor: "#2980b9"  // accent-coloured text on keys
    property color redWarningColor: "#da4453"

    property color headerPillBg: "#dee0e2"
    property color sizeModePillBg: "#d1d4d7"
    property color pillTextColor: "#232629"

    property color dpadBg: "#dee0e2"
    property color dpadHeaderColor: "#3daee9"

    property string fontFamily: "Noto Sans, sans-serif"
}
