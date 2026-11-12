import QtQuick
import QtQuick.Controls
import "../base" as Base
import "../../services/windows/" as WS
import "../../" as App

// Pill de la ventana activa: ícono, nombre de la app y su título. El clic central cierra la ventana.
Base.Island {
    id: root

    // La vista general de workspaces ya muestra las ventanas (y empujaría la pill hasta el reloj)
    property bool workspacesOpen: false

    readonly property var store: WS.ActiveWindowStore

    visible: store.visible && !workspacesOpen
    openOnClick: false

    // Lo que cabe para el texto: el máximo menos el ícono, el relleno y los espacios
    readonly property real textMax: App.Config.activeWindow.maxWidth - 2 * App.Config.pill.paddingX - App.Config.activeWindow.iconSize - App.Config.pill.contentSpacing

    Image {
        anchors.verticalCenter: parent.verticalCenter
        source: root.store.icon
        sourceSize: Qt.size(App.Config.activeWindow.iconSize, App.Config.activeWindow.iconSize)
        width: App.Config.activeWindow.iconSize
        height: App.Config.activeWindow.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            id: nameText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.textMax)
            text: root.store.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        Text {
            id: titleText
            visible: text !== "" && root.textMax - nameText.width - parent.spacing > 24
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.textMax - nameText.width - parent.spacing)
            text: root.store.title
            elide: Text.ElideRight
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton
        onClicked: root.store.closeActive()

        ToolTip.visible: containsMouse
        ToolTip.delay: App.Config.activeWindow.tooltipDelay
        ToolTip.text: (root.store.title !== "" ? root.store.name + " · " + root.store.title : root.store.name) + "\nClic central: cerrar"
    }
}
