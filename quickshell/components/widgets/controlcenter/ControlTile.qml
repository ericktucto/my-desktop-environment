import QtQuick
import "../../controls/" as C
import "../../../" as App

// Casilla del centro de control: pastilla con un ícono en un círculo, título, subtítulo y, si `detail`,
// una flecha ›. Con `ready: false` (función todavía sin hacer) el clic no hace nada.
Rectangle {
    id: root

    property url icon
    // Carácter de la fuente de íconos (Nerd Font), si no hay `icon`
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property color activeColor: App.Theme.primary
    property bool detail: false
    property bool ready: true
    // La flecha puede funcionar aunque la casilla no (p. ej. Bluetooth sin adaptador abre la vista con el aviso)
    property bool detailReady: ready

    signal clicked
    signal detailClicked

    // Texto e ícono: oscuros sobre un color claro (ámbar, verde) y blancos sobre uno oscuro (azul)
    readonly property real luminance: 0.299 * activeColor.r + 0.587 * activeColor.g + 0.114 * activeColor.b
    readonly property color contentColor: checked && luminance > 0.55 ? App.Theme.black : App.Theme.white

    implicitHeight: App.Config.control.tileHeight
    radius: height / 2
    color: checked ? activeColor : App.Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    // Aclara el fondo con el hover
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.containsMouse ? App.Theme.surfaceHover : "transparent"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.ready)
                root.clicked();
        }
    }

    // Círculo del ícono
    Rectangle {
        id: iconCircle
        width: App.Config.control.tileIcon
        height: width
        radius: width / 2
        x: (root.height - height) / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Qt.rgba(0, 0, 0, 0.18) : App.Theme.surfaceHover

        Text {
            visible: root.glyph !== ""
            anchors.centerIn: parent
            text: root.glyph
            color: root.contentColor
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.control.tileGlyph
        }
        C.IconSvg {
            visible: root.glyph === ""
            anchors.centerIn: parent
            source: root.icon
            size: App.Config.control.tileGlyph
            color: root.contentColor
        }
    }

    Column {
        anchors.left: iconCircle.right
        anchors.leftMargin: 10
        anchors.right: arrow.visible ? arrow.left : parent.right
        anchors.rightMargin: arrow.visible ? 4 : 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.contentColor
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: root.contentColor
            opacity: 0.7
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    // ›  (más adelante abrirá el panel de redes o de dispositivos)
    Item {
        id: arrow
        visible: root.detail
        width: 28
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: 8

        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xf0142)
            color: root.contentColor
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.iconLg
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: root.detailReady ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.detailReady)
                    root.detailClicked();
            }
        }
    }
}
