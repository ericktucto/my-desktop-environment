import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import "../../../" as App

Item {
    id: root

    width: parent.width
    height: parent.height

    // Directorio de wallpapers
    readonly property string wallpapersDir: App.Config.wallpaperPicker.dir

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
            }
        }
    }

    // Permite re-escanear manualmente (p. ej. al abrir el selector)
    function scanWallpapers() {
        scanner.running = false;
        scanner.running = true;
    }

    // Grid de wallpapers
    GridView {
        id: gridView
        anchors.fill: parent
        flow: GridView.FlowTopToBottom
        height: cellHeight * 2

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

        Keys.onReturnPressed: root.applyWallpaper(root.imageFiles[currentIndex])
        Keys.onEnterPressed: root.applyWallpaper(root.imageFiles[currentIndex])

        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: Rectangle {
            width: gridView.imgWidth
            height: gridView.imgHeight
            radius: App.Config.wallpaperPicker.radius
            // Borde azul si está seleccionado, transparente si no
            color: GridView.isCurrentItem ? App.Theme.blue : "transparent"

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
