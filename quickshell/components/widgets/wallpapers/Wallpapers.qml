import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import "../../controls/" as C
import "../../../services/theme/" as T
import "../../../services/settings/" as ST
import "../../../" as App

Item {
    id: root

    width: parent.width
    height: parent.height

    // Directorio de wallpapers
    readonly property string wallpapersDir: ST.SettingsStore.appearance.wallpaperDir !== "" ? ST.SettingsStore.appearance.wallpaperDir : App.Config.wallpaperPicker.dir

    // La vista de colores (combinaciones o acento propio) en lugar de la cuadrícula
    property bool colors: false
    function openColors(on) {
        colors = on;
        if (on)
            colorsView.giveFocus();
        else
            gridView.forceActiveFocus();
    }
    // Esc: de la vista de colores vuelve a la cuadrícula
    function back() {
        if (!colors)
            return false;
        openColors(false);
        return true;
    }

    // Lista de archivos de imagen (rutas absolutas)
    property var imageFiles: []

    // Aplica un wallpaper (el fondo lo pinta WallpaperTransition al cambiar App.Wallpaper.current)
    function applyWallpaper(imagePath) {
        if (!imagePath)
            return;
        App.Wallpaper.set(imagePath);
        root.closed();
    }

    signal closed

    function giveFocus() {
        gridView.forceActiveFocus();
    }

    // Escanea la carpeta corriendo `find` y parsea la salida
    Process {
        id: scanner
        command: ["find", root.wallpapersDir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", ")"]
        // Ejecuta el escaneo al crear el componente
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                root.imageFiles = lines;
                // La selección del teclado empieza en el wallpaper que está puesto
                gridView.currentIndex = Math.max(0, lines.indexOf(App.Wallpaper.current));
            }
        }
    }

    // Permite re-escanear manualmente (p. ej. al abrir el selector)
    function scanWallpapers() {
        colors = false;
        scanner.running = false;
        scanner.running = true;
    }

    // Colores: los dos modos y lo elegido
    ColorOptions {
        id: themeRow
        open: root.colors
        onToggleColors: root.openColors(!root.colors)
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: App.Config.wallpaperPicker.themeRow
    }

    // La vista de colores (en lugar de la cuadrícula)
    ColorsView {
        id: colorsView
        visible: root.colors
        anchors.top: themeRow.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onBack: root.openColors(false)
    }

    // Grid de wallpapers
    GridView {
        id: gridView
        anchors.top: themeRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        flow: GridView.FlowTopToBottom
        visible: !root.colors

        readonly property int spacing: App.Config.wallpaperPicker.spacingCell
        readonly property int imgWidth: App.Config.wallpaperPicker.imgWidth
        readonly property int imgHeight: App.Config.wallpaperPicker.imgHeight

        cellWidth: imgWidth + spacing
        cellHeight: imgHeight + spacing
        clip: true

        model: root.imageFiles

        // --- Navegación por teclado ---
        focus: true
        keyNavigationEnabled: true
        keyNavigationWraps: false
        highlightFollowsCurrentItem: true

        // 1 y 2 cambian el modo de color; c (o p) abre la vista de colores
        Keys.onPressed: event => {
            if (event.modifiers !== Qt.NoModifier)
                return;
            const modes = ["scheme", "custom"];
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_2) {
                if (event.key === Qt.Key_2 || T.ThemeStore.available)
                    T.ThemeStore.setMode(modes[event.key - Qt.Key_1]);
            } else if (event.key === Qt.Key_C || event.key === Qt.Key_P) {
                root.openColors(true);
            } else {
                return;
            }
            event.accepted = true;
        }
        Keys.onReturnPressed: root.applyWallpaper(root.imageFiles[currentIndex])
        Keys.onEnterPressed: root.applyWallpaper(root.imageFiles[currentIndex])

        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: Rectangle {
            width: gridView.imgWidth
            height: gridView.imgHeight
            radius: App.Config.wallpaperPicker.radius
            // Borde del acento si está seleccionado, transparente si no
            color: GridView.isCurrentItem ? App.Theme.primary : "transparent"

            Image {
                id: thumb
                anchors.fill: parent
                anchors.margins: App.Config.wallpaperPicker.borderImg
                source: `file://${modelData}`
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                sourceSize.width: gridView.imgWidth
                sourceSize.height: gridView.imgHeight

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskThresholdMin: 0.5
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: thumb.width
                            height: thumb.height
                            radius: App.Config.wallpaperPicker.radius
                        }
                    }
                }

                // Placeholder mientras carga
                Rectangle {
                    anchors.fill: parent
                    color: App.Theme.gray
                    opacity: thumb.status === Image.Loading ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: App.Config.anim.fadeIn
                        }
                    }
                }
            }

            // El wallpaper que está puesto
            Rectangle {
                visible: modelData === App.Wallpaper.current
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: App.Config.wallpaperPicker.borderImg + 6
                width: 22
                height: 22
                radius: 11
                color: App.Theme.primary
                border.width: 2
                border.color: App.Theme.white

                C.IconSvg {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("../../../assets/svg/check.svg")
                    size: 12
                    color: App.Theme.onPrimary
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    gridView.currentIndex = index;
                    root.applyWallpaper(modelData);
                }
            }
        }
    }
}
