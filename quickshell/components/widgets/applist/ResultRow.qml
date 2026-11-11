import QtQuick
import Quickshell
import "../../../" as App

// Una fila del launcher: app, acción, acción de sesión, emoji, resultado de la calculadora o comando.
Rectangle {
    id: root

    // Fila de services/launcher/Search.js
    property var row: ({})
    property bool selected: false
    // Texto de confirmación cuando la fila está armada (acciones de sesión)
    property string armedText: ""

    signal clicked
    signal starClicked

    readonly property bool isApp: row.kind === "app"
    readonly property bool hasIcon: row.kind !== "hint"

    implicitHeight: App.Config.launcher.rowHeight
    radius: App.Config.radius.md
    // La fila seleccionada la resalta el `highlight` del ListView; aquí solo el hover.
    color: mouse.containsMouse && row.kind !== "hint" ? Qt.alpha(App.Theme.surfaceHigh, 0.5) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    // Ruta absoluta o nombre del tema
    function resolveIcon(iconStr) {
        if (!iconStr)
            return "";
        if (iconStr.startsWith("/"))
            return "file://" + iconStr;
        if (iconStr.includes(":"))
            return iconStr;
        return Quickshell.iconPath(iconStr, true);
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        // ── Ícono: del tema, emoji o glifo ──
        Item {
            id: iconSlot
            visible: root.hasIcon
            anchors.verticalCenter: parent.verticalCenter
            width: App.Config.launcher.iconSize
            height: App.Config.launcher.iconSize

            Image {
                id: themeIcon
                anchors.fill: parent
                visible: root.row.kind === "app" || root.row.kind === "action"
                source: visible ? root.resolveIcon(root.row.icon) : ""
                sourceSize: Qt.size(App.Config.launcher.iconSize, App.Config.launcher.iconSize)
                fillMode: Image.PreserveAspectFit
                smooth: true

                // Sin ícono: un marcador
                Rectangle {
                    anchors.fill: parent
                    visible: parent.visible && parent.status !== Image.Ready
                    color: App.Theme.surfaceHigh
                    radius: App.Config.radius.sm
                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(0xf0a49)
                        font.family: App.Config.fonts.icons
                        color: App.Theme.subtext
                        font.pixelSize: App.Config.fontSize.iconLg
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.row.kind === "emoji"
                text: root.row.emoji || ""
                font.pixelSize: App.Config.launcher.emojiSize
            }
            Text {
                anchors.centerIn: parent
                visible: root.row.glyph !== undefined
                text: root.row.glyph !== undefined ? String.fromCodePoint(root.row.glyph) : ""
                color: App.Theme.white
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.iconLg
            }
        }

        // ── Textos ──
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (iconSlot.visible ? iconSlot.width + parent.spacing : 0) - (star.visible ? star.width + parent.spacing : 0)

            Text {
                width: parent.width
                text: root.armedText !== "" ? root.armedText : (root.row.title || "")
                color: root.armedText !== "" ? App.Theme.red : (root.row.kind === "hint" ? App.Theme.subtext : App.Theme.text)
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.row.subtitle || ""
                color: App.Theme.subtext
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                elide: Text.ElideRight
            }
        }

        // ── Estrella: los favoritos la muestran siempre; el resto, al pasar el mouse o al seleccionar ──
        Item {
            id: star
            visible: root.isApp && (root.row.favorite || root.selected || mouse.containsMouse)
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(root.row.favorite ? 0xf04ce : 0xf04d2)
                color: root.row.favorite ? App.Theme.amber : (starMouse.containsMouse ? App.Theme.white : App.Theme.subtext)
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.iconLg
            }
            MouseArea {
                id: starMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.starClicked()
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: root.row.kind === "hint" ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (root.row.kind !== "hint")
            root.clicked()
    }
}
