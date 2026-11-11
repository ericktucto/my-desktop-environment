import QtQuick
import QtQuick.Effects
import "../../../services/media/" as M
import "../../../" as App

// Carátula del reproductor con esquinas redondeadas (o círculo). Sin carátula: el ícono de la app sobre
// un degradado del tema. Al cambiar de canción, la imagen nueva reemplaza a la anterior solo cuando ya cargó
// (sin parpadeo) y con un fundido corto.
Item {
    id: root

    property real radius: 12
    property bool round: false
    // Para la pill chica: más oscura cuando está en pausa
    property bool dimmed: false

    readonly property string source: M.MediaStore.shownArt

    // Imagen que se está mostrando: cambia cuando la nueva terminó de cargar
    property string shown: ""
    readonly property bool hasArt: shown !== ""

    Image {
        id: loader
        visible: false
        source: root.source
        asynchronous: true
        sourceSize: Qt.size(Math.max(64, root.width * 2), Math.max(64, root.height * 2))
        onStatusChanged: {
            if (status === Image.Ready)
                root.shown = source.toString();
            else if (status === Image.Error)
                root.shown = "";
        }
    }
    onSourceChanged: {
        if (source === "")
            shown = "";
    }

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.round ? width / 2 : root.radius
            color: "black"
        }
    }

    // El contenido se recorta con la máscara redondeada (layer.effect sobre el propio contenido)
    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            brightness: root.dimmed ? -0.35 : 0
        }

        // Sin carátula: degradado del tema con el ícono de la app
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: App.Theme.surfaceHigh
                }
                GradientStop {
                    position: 1
                    color: App.Theme.island
                }
            }
        }
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            visible: !root.hasArt && M.MediaStore.appIcon !== ""
            source: M.MediaStore.appIcon
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.centerIn: parent
            visible: !root.hasArt && M.MediaStore.appIcon === ""
            text: String.fromCodePoint(0xf0386)
            color: App.Theme.subtext
            font.family: App.Config.fonts.icons
            font.pixelSize: parent.width * 0.4
        }

        Image {
            id: display
            anchors.fill: parent
            source: root.shown
            sourceSize: Qt.size(Math.max(64, root.width * 2), Math.max(64, root.height * 2))
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: root.hasArt
        }

        // Fundido al cambiar de imagen
        Rectangle {
            id: veil
            anchors.fill: parent
            color: App.Theme.island
            opacity: 0
        }
    }

    onShownChanged: fade.restart()
    NumberAnimation {
        id: fade
        target: veil
        property: "opacity"
        from: 0.8
        to: 0
        duration: App.Config.media.trackFade
    }
}
