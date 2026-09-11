import QtQuick
import QtQuick.Effects
import "../../" as App

Item {
    id: root
    anchors.fill: parent

    property int duration: 600
    // Cuál capa muestra el wallpaper actual: false = A visible, true = B visible
    property bool showingB: false
    readonly property int radiusImage: 16
    readonly property color backgroundColor: App.Theme.black

    // ── Capa A ──
    Image {
        id: layerA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
        opacity: root.showingB ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.InOutQuad
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: layerA.width
                    height: layerA.height
                    radius: root.radiusImage
                    color: App.Theme.black
                }
            }
        }
    }

    // ── Capa B ──
    Image {
        id: layerB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
        opacity: root.showingB ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.InOutQuad
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: layerB.width
                    height: layerB.height
                    radius: root.radiusImage
                    color: App.Theme.black
                }
            }
        }
    }

    // Cambia el wallpaper: carga en la capa oculta, espera a que cargue, alterna
    function change(path) {
        const url = `file://${path}`;

        // Primera carga: directo en A, visible, sin transición
        if (layerA.source == "" && layerB.source == "") {
            layerA.source = url;
            return;
        }

        // La capa oculta recibe la imagen nueva
        if (root.showingB)
            layerA.source = url;
        else
            // B visible -> cargar en A (oculta)
            layerB.source = url;   // A visible -> cargar en B (oculta)
    }

    // Cuando la capa OCULTA termina de cargar, se hace el swap (fade)
    Connections {
        target: layerA
        function onStatusChanged() {
            // A estaba oculta (B visible) y ya cargó -> mostrar A
            if (layerA.status === Image.Ready && root.showingB)
                root.showingB = false;
        }
    }
    Connections {
        target: layerB
        function onStatusChanged() {
            // B estaba oculta (A visible) y ya cargó -> mostrar B
            if (layerB.status === Image.Ready && !root.showingB)
                root.showingB = true;
        }
    }

    Connections {
        target: App.Wallpaper
        function onCurrentChanged() {
            if (App.Wallpaper.current)
                root.change(App.Wallpaper.current);
        }
    }

    Component.onCompleted: {
        if (App.Wallpaper.current)
            root.change(App.Wallpaper.current);
    }
}
