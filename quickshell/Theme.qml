pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // ===== Superficie =====
    readonly property color island:     "#0a0a0f"
    readonly property color islandEdge: Qt.rgba(1, 1, 1, 0.10)

    // ===== Superficies y texto (launcher, inputs) =====
    readonly property color surfaceHigh: "#3a3f4a"     // selección y hover del launcher, borde de inputs
    readonly property color text:        "#cdd6f4"     // texto de listas e IconSvg por defecto
    readonly property color subtext:     "#8a93a5"     // descripciones
    readonly property color placeholder: "#888888"     // placeholder de inputs

    // ===== Blancos translúcidos =====
    readonly property color surface:       Qt.rgba(1, 1, 1, 0.06)   // fondo de tarjetas y botones
    readonly property color surfaceHover:  Qt.rgba(1, 1, 1, 0.08)   // hover suave / botón pequeño
    readonly property color surfaceActive: Qt.rgba(1, 1, 1, 0.16)   // hover del botón pequeño
    readonly property color track:         Qt.rgba(1, 1, 1, 0.14)   // parte inactiva del Slider

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
