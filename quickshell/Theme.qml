pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // ===== Superficie =====
    readonly property color island:     "#0a0a0f"
    readonly property color islandEdge: Qt.rgba(1, 1, 1, 0.10)

    // ===== Neutros =====
    readonly property color white:  "#ffffff"
    readonly property color gray:   "#b4bcd0"
    readonly property color grayDark: "#6b7394"
    readonly property color black:  "#0a0a0f"

    // ===== Nombrados =====
    readonly property color primary:    "#2979ff"

    // ===== Colores (vívidos) =====
    readonly property color red:     "#ff1744"
    readonly property color orange:  "#ff6d00"
    readonly property color amber:   "#ffb300"
    readonly property color yellow:  "#ffea00"
    readonly property color green:   "#00e676"
    readonly property color teal:    "#1de9b6"
    readonly property color cyan:    "#00e5ff"
    readonly property color blue:    "#2979ff"
    readonly property color indigo:  "#3d5afe"
    readonly property color purple:  "#d500f9"
    readonly property color pink:    "#ff4081"
}
