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
    readonly property string wallpapersDir: "/home/erick/Pictures/Wallpapers"

    // Lista de archivos de imagen (rutas absolutas)
    property var imageFiles: []

    // Aplica un wallpaper con swaybg (reutilizable desde click o teclado)
    function applyWallpaper(imagePath) {
        if (!imagePath)
            return;
        console.log("Aplicando wallpaper:", imagePath);
        App.Wallpaper.set(imagePath);
        killProc.running = true;
        setter.imagePath = imagePath;
        setter.running = true;
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

        readonly property int spacing: App.Config.spacingCell
        readonly property int imgWidth: App.Config.imgWidth
        readonly property int imgHeight: App.Config.imgHeight

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
        Keys.onEscapePressed: root.closed()

        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: Rectangle {
            width: gridView.imgWidth
            height: gridView.imgHeight
            radius: 8
            // Borde azul si está seleccionado, transparente si no
            color: GridView.isCurrentItem ? App.Theme.blue : "transparent"

            Image {
                id: thumb
                anchors.fill: parent
                anchors.margins: App.Config.borderImg
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
                            radius: 8
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
                            duration: 200
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

    // Procesos declarados una sola vez, no creados en cada click
    Process {
        id: killProc
        command: ["pkill", "swaybg"]
    }

    Process {
        id: setter
        property string imagePath: ""
        command: ["swaybg", "-i", setter.imagePath, "-m", "fill"]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                console.log("swaybg stderr:", text)
        }
    }
}
