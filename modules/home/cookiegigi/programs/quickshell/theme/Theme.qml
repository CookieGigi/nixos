pragma Singleton
import Quickshell
import QtQuick

// Catppuccin Macchiato Teal color palette singleton.
// All bar components should import Theme and reference these colors.
Singleton {
    id: root

    // ── Base colors ──────────────────────────────────────────
    readonly property string base: "#24273a"
    readonly property string mantle: "#1e2030"
    readonly property string crust: "#181926"
    readonly property string surface0: "#363a4f"
    readonly property string surface1: "#494d64"
    readonly property string surface2: "#5b6078"
    readonly property string overlay0: "#6e738d"
    readonly property string overlay1: "#8087a2"
    readonly property string overlay2: "#939ab7"
    readonly property string subtext0: "#a5adcb"
    readonly property string subtext1: "#b8c0e0"
    readonly property string text: "#cad3f5"
    readonly property string lavender: "#b7bdf8"
    readonly property string blue: "#8aadf4"
    readonly property string sapphire: "#7dc4e4"
    readonly property string sky: "#91d7e3"
    readonly property string teal: "#8bd5ca"
    readonly property string green: "#a6da95"
    readonly property string yellow: "#eed49f"
    readonly property string peach: "#f5a97f"
    readonly property string maroon: "#ee99a0"
    readonly property string red: "#ed8796"
    readonly property string mauve: "#c6a0f6"
    readonly property string pink: "#f5bde6"
    readonly property string flamingo: "#f0c6c6"
    readonly property string rosewater: "#f4dbd6"

    // ── Convenience aliases ──────────────────────────────────
    readonly property color containerBg: root.base
    readonly property color containerAlpha: "#cc1a2235"
    readonly property int containerRadius: 8
    readonly property int paddingV: 6
    readonly property int paddingH: 12
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int pixelSize: 14
    readonly property color popupBorder: root.teal
    readonly property color popupBg: root.base
    readonly property color popupItemHover: "#00C8B433"
    readonly property color popupItemHl: root.teal
    readonly property color accentColor: root.teal
}
