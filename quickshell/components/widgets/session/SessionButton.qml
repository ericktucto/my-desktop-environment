import QtQuick
import "../../controls/" as C
import "../../../" as App

// Botón del menú de sesión: cuadrado con ícono y texto debajo.
Item {
    id: root

    property string icon
    property string text
    property bool selected: false
    property bool armed: false
    property string armedText: ""

    signal clicked
    signal hovered

    readonly property var cfg: App.Config.session

    width: cfg.buttonSize
    height: cfg.buttonSize + cfg.labelGap + cfg.labelHeight

    Rectangle {
        id: box
        width: root.cfg.buttonSize
        height: width
        radius: App.Config.pill.radiusExpanded * 0.6
        color: root.armed ? App.Theme.red : (root.selected ? App.Theme.primary : App.Theme.surface)

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.control
            }
        }

        C.IconSvg {
            anchors.centerIn: parent
            source: Qt.resolvedUrl("../../../assets/svg/" + root.icon + ".svg")
            size: root.cfg.iconSize
            color: App.Theme.white
        }
    }

    Text {
        anchors.top: box.bottom
        anchors.topMargin: root.cfg.labelGap
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.cfg.labelHeight
        text: root.armed ? root.armedText : root.text
        color: root.armed ? App.Theme.red : (root.selected ? App.Theme.white : App.Theme.gray)
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.clicked()
    }
}
