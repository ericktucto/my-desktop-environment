import QtQuick
import Quickshell

Rectangle {
    id: root

    // Propiedades de entrada
    property string name: ""
    property string description: ""
    property string iconSource: ""
    property bool isCurrent: false

    // Estilo
    property color bgColor: "transparent"
    property color hoverColor: "#3a3f4a"
    property color textColor: "#cdd6f4"
    property color subtextColor: "#8a93a5"
    property int fontSize: 13

    // Tamaño
    implicitHeight: 52
    implicitWidth: parent ? parent.width : 300

    color: isCurrent ? "#3a3f4a" : "transparent"
    radius: 8

    // ── Resolver el tipo de icono ──
    function resolveIcon(iconStr) {
        if (!iconStr || iconStr === "") return "";

        // Caso 1: Ruta absoluta (empieza con /)
        if (iconStr.startsWith("/")) {
            return "file://" + iconStr;
        }

        // Caso 2: URL explícita (data:, https://, etc.)
        if (iconStr.includes(":")) {
            return iconStr;
        }

        // Caso 3: Icono del sistema (nombre de tema)
        return "image://icon/" + iconStr;
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // ── Icono ──
        Image {
            id: iconImage
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            source: root.resolveIcon(root.iconSource)
            sourceSize.width: 32
            sourceSize.height: 32
            fillMode: Image.PreserveAspectFit
            smooth: true

            // Fallback: un placeholder si no carga
            Rectangle {
                anchors.fill: parent
                color: root.hoverColor
                radius: 6
                visible: parent.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: "󰩉" // icono genérico NF
                    color: root.subtextColor
                    font.pixelSize: 18
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

    // ── Hover ──
    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {}
        onExited: root.color = "transparent"
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // ── Señal de clic ──
    signal clicked()
}

