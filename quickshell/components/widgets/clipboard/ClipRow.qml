import QtQuick
import "../../../services/clipboard/" as S
import "../../../" as App

// Una fila del historial: la primera parte del texto, o la miniatura de una imagen con sus datos.
Rectangle {
    id: root

    property var entry: null
    readonly property bool isImage: entry ? entry.isImage : false

    signal clicked
    signal doubleClicked

    height: App.Config.clipboard.rowHeight
    radius: App.Config.radius.md
    // La fila seleccionada la resalta el `highlight` del ListView; aquí solo el hover.
    color: mouse.containsMouse ? Qt.alpha(App.Theme.surfaceHigh, 0.5) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    // Las imágenes se decodifican a la caché solo cuando su fila llega a crearse
    Component.onCompleted: {
        if (entry && entry.isImage)
            S.ClipboardStore.requestImage(entry);
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Rectangle {
            id: thumb
            visible: root.isImage
            anchors.verticalCenter: parent.verticalCenter
            width: App.Config.clipboard.thumbSize
            height: width
            radius: App.Config.radius.sm
            color: App.Theme.surface
            clip: true

            Image {
                anchors.fill: parent
                source: root.entry ? (S.ClipboardStore.imageUrls[root.entry.id] || "") : ""
                sourceSize: Qt.size(App.Config.clipboard.thumbSize * 2, App.Config.clipboard.thumbSize * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (thumb.visible ? thumb.width + parent.spacing : 0)

            Text {
                width: parent.width
                text: root.entry ? root.entry.preview : ""
                color: App.Theme.text
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: root.isImage ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                wrapMode: root.isImage ? Text.NoWrap : Text.WrapAnywhere
                maximumLineCount: root.isImage ? 1 : 2
            }

            Text {
                visible: root.isImage
                width: parent.width
                text: !root.entry ? "" : (root.entry.width > 0 ? root.entry.width + "×" + root.entry.height + " · " + root.entry.size : (root.entry.name || ""))
                color: App.Theme.subtext
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
