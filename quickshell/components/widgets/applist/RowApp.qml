import QtQuick
import Quickshell
import "../../../" as App

Rectangle {
    id: root

    // Propiedades de entrada
    property string name: ""
    property string description: ""
    property string iconSource: ""

    // Estilo
    property color hoverColor: App.Theme.surfaceHigh
    property color textColor: App.Theme.text
    property color subtextColor: App.Theme.subtext
    property int fontSize: App.Config.fontSize.md

    // Tamaño
    implicitHeight: App.Config.launcher.rowHeight
    implicitWidth: parent ? parent.width : 300

    // La fila seleccionada la resalta el `highlight` del ListView; aquí solo el hover.
    // Es un binding (nunca se asigna), así que no se rompe al salir el mouse.
    color: mouse.containsMouse ? Qt.alpha(hoverColor, 0.5) : "transparent"
    radius: App.Config.radius.md

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    // ── Resolver el ícono: ruta absoluta o nombre del tema ──
    function resolveIcon(iconStr) {
        if (!iconStr)
            return "";
        if (iconStr.startsWith("/"))
            return "file://" + iconStr;
        // URL explícita (data:, https://, etc.)
        if (iconStr.includes(":"))
            return iconStr;
        return Quickshell.iconPath(iconStr, true);
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // ── Icono ──
        Image {
            id: iconImage
            anchors.verticalCenter: parent.verticalCenter
            width: App.Config.launcher.iconSize
            height: App.Config.launcher.iconSize
            source: root.resolveIcon(root.iconSource)
            sourceSize.width: App.Config.launcher.iconSize
            sourceSize.height: App.Config.launcher.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: true

            // Fallback: un placeholder si no carga
            Rectangle {
                anchors.fill: parent
                color: root.hoverColor
                radius: App.Config.radius.sm
                visible: parent.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: "󰩉" // icono genérico NF
                    font.family: App.Config.fonts.icons
                    color: root.subtextColor
                    font.pixelSize: App.Config.fontSize.iconLg
                }
            }
        }

        // ── Textos: nombre + descripción ──
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - iconImage.width - parent.spacing

            Text {
                text: root.name
                color: root.textColor
                font.pixelSize: root.fontSize
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.description
                color: root.subtextColor
                font.pixelSize: root.fontSize - 2
                elide: Text.ElideRight
                width: parent.width
                visible: root.description !== ""
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // ── Señal de clic ──
    signal clicked
}
