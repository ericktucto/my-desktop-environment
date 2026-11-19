import QtQuick
import "../../controls/" as C
import "../../../" as App

// Botón redondo con un ícono SVG. Atenuado y sin respuesta si el reproductor no lo permite.
Rectangle {
    id: root

    property string icon
    property bool active: true          // false = el reproductor no lo permite
    property bool highlighted: false    // relleno de color (play/pausa, aleatorio activo)
    property color accent: App.Theme.primary
    property real iconSize: 20
    // En lugar del SVG: un glifo de Nerd Font (código) o un texto corto («+1»)
    property int glyph: 0
    property string text: ""

    signal clicked

    width: App.Config.media.buttonSize
    height: width
    radius: width / 2
    color: highlighted ? accent : (mouse.containsMouse && active ? App.Theme.surfaceActive : "transparent")
    opacity: active ? 1 : 0.35

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.glyph !== 0 || root.text !== ""
        text: root.glyph !== 0 ? String.fromCodePoint(root.glyph) : root.text
        color: App.Theme.white
        font.family: root.glyph !== 0 ? App.Config.fonts.icons : App.Config.fonts.text
        font.pixelSize: root.glyph !== 0 ? root.iconSize - 2 : App.Config.fontSize.md
        font.weight: Font.DemiBold
    }

    C.IconSvg {
        anchors.centerIn: parent
        visible: root.glyph === 0 && root.text === ""
        source: root.icon !== "" ? Qt.resolvedUrl("../../../assets/svg/" + root.icon + ".svg") : ""
        size: root.iconSize
        color: App.Theme.white
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.active
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
