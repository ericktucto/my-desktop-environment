import QtQuick
import "../../controls/" as C
import "../../../" as App

// Encabezado de una vista del centro de control: ‹ para volver, título, subtítulo y el switch.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool checked: false
    // El switch se atenúa si no se puede usar
    property bool switchEnabled: true

    signal backRequested
    signal toggled

    height: 46

    Rectangle {
        id: back
        width: 34
        height: 34
        radius: 17
        anchors.verticalCenter: parent.verticalCenter
        color: backMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xf0141)
            color: App.Theme.white
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.iconLg
        }
        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.backRequested()
        }
    }

    Column {
        anchors.left: back.right
        anchors.leftMargin: 12
        anchors.right: toggle.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: root.title
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg + 2
            font.weight: Font.DemiBold
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    C.Switch {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        opacity: root.switchEnabled ? 1 : 0.4
        onToggled: root.toggled()
    }
}
