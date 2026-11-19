import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import "../../../services/theme/" as T
import "../../../" as App

Item {
    id: root

    width: parent.width
    height: parent.height

    // Directorio de wallpapers
    readonly property string wallpapersDir: App.Config.wallpaperPicker.dir

    // El selector completo de color (acento propio) en lugar de la cuadrícula
    property bool picking: false
    // Solo tiene sentido con el acento propio
    Connections {
        target: T.ThemeStore
        function onModeChanged() {
            if (T.ThemeStore.mode !== "custom")
                root.picking = false;
        }
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
        picking = false;
        scanner.running = false;
        scanner.running = true;
    }

    // Colores: los tres modos y las opciones de cada uno
    ColorOptions {
        id: themeRow
        picking: root.picking
        onTogglePicker: root.picking = !root.picking
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: App.Config.wallpaperPicker.themeRow + App.Config.wallpaperPicker.tintRow
    }

    // Selector completo del acento propio (en lugar de la cuadrícula)
    ColorPicker {
        visible: root.picking
        anchors.top: themeRow.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        value: T.ThemeStore.color
        onPicked: hex => T.ThemeStore.setColor(hex)
        onDone: root.picking = false
    }

    // Grid de wallpapers
    GridView {
        id: gridView
        anchors.top: themeRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        flow: GridView.FlowTopToBottom
        visible: !root.picking

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

        // 1, 2 y 3 cambian el modo de color; p abre el selector completo (acento propio)
        Keys.onPressed: event => {
            if (event.modifiers !== Qt.NoModifier)
                return;
            const modes = ["scheme", "accent", "custom"];
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
                if (event.key === Qt.Key_1 + 2 || T.ThemeStore.available)
                    T.ThemeStore.setMode(modes[event.key - Qt.Key_1]);
            } else if (event.key === Qt.Key_P && T.ThemeStore.mode === "custom") {
                root.picking = !root.picking;
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

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: App.Theme.white
                    font.pixelSize: 13
                    font.weight: Font.Bold
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
