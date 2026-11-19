pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Colores del wallpaper (services/theme, scripts/theme.py): ~/.cache/stixshell/theme.json.
    // Sin ese archivo, o con los colores dinámicos apagados, quedan los fijos de abajo.
    property var dyn: ({})
    // Los colores solo se animan después de cargar el archivo (al arrancar no hay fundido desde los fijos)
    property bool ready: false

    function load() {
        try {
            root.dyn = JSON.parse(themeFile.text()).shell ?? {};
        } catch (err) {
            root.dyn = {};
        }
    }

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.cache/stixshell/theme.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.load()
        onFileChanged: reload()
        onLoadFailed: root.dyn = {}
    }

    Component.onCompleted: {
        load();
        Qt.callLater(() => root.ready = true);
    }

    component Fade: Behavior {
        enabled: root.ready
        ColorAnimation {
            duration: Config.theme.fade
        }
    }

    // ===== Superficie =====
    property color island:     dyn.island ?? "#0a0a0f"
    // Separadores dentro de los paneles: siempre neutros
    readonly property color islandEdge: Qt.rgba(1, 1, 1, 0.10)
    // El borde fino (1 px) de las islas y los paneles flotantes: lleva el color elegido
    property color border: dyn.border ?? Qt.rgba(1, 1, 1, 0.10)

    // ===== Superficies y texto (launcher, inputs) =====
    property color surfaceHigh: dyn.surfaceHigh ?? "#3a3f4a"     // selección y hover del launcher, borde de inputs
    property color text:        dyn.text ?? "#cdd6f4"     // texto de listas e IconSvg por defecto
    property color subtext:     dyn.subtext ?? "#8a93a5"     // descripciones
    property color placeholder: dyn.placeholder ?? "#888888"     // placeholder de inputs

    // ===== Blancos translúcidos =====
    property color surface:       dyn.surface ?? Qt.rgba(1, 1, 1, 0.06)   // fondo de tarjetas y botones
    property color surfaceHover:  dyn.surfaceHover ?? Qt.rgba(1, 1, 1, 0.08)   // hover suave / botón pequeño
    property color surfaceActive: dyn.surfaceActive ?? Qt.rgba(1, 1, 1, 0.16)   // hover del botón pequeño
    property color track:         dyn.track ?? Qt.rgba(1, 1, 1, 0.14)   // parte inactiva del Slider

    // ===== Neutros =====
    property color white:  dyn.white ?? "#ffffff"      // con colores Teñido o Intenso lleva un toque del tono
    property color gray:   dyn.gray ?? "#b4bcd0"
    property color grayDark: dyn.grayDark ?? "#6b7394"
    readonly property color black:  "#0a0a0f"

    // ===== Nombrados =====
    property color primary:    dyn.primary ?? "#2979ff"

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

    // ===== Fundido al cambiar de wallpaper =====
    Fade on island {}
    Fade on border {}
    Fade on surfaceHigh {}
    Fade on text {}
    Fade on subtext {}
    Fade on placeholder {}
    Fade on surface {}
    Fade on surfaceHover {}
    Fade on surfaceActive {}
    Fade on track {}
    Fade on gray {}
    Fade on grayDark {}
    Fade on white {}
    Fade on primary {}
}
