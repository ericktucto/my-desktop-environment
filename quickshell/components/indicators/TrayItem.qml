import QtQuick
import Quickshell
import "../../" as App

// Un ícono del system tray. `modelData` es un SystemTrayItem.
Item {
    id: root

    required property var modelData

    implicitWidth: App.Config.tray.iconSize
    implicitHeight: App.Config.tray.iconSize

    // Abre/cierra el menú de la app (estilo propio, ver TrayMenu.qml)
    function openMenu() {
        menu.visible = !menu.visible;
    }

    TrayMenu {
        id: menu
        visible: false
        anchorItem: root
        menuSource: root.modelData.menu
    }

    Image {
        id: icon
        anchors.fill: parent
        source: root.modelData.icon
        sourceSize: Qt.size(App.Config.tray.iconSize, App.Config.tray.iconSize)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: status !== Image.Error
        opacity: mouse.containsMouse ? 1 : 0.9
    }

    // Si el ícono no carga, se muestra la inicial de la app
    Text {
        anchors.centerIn: parent
        visible: icon.status === Image.Error
        text: ((root.modelData.title || root.modelData.id || "?")[0] ?? "?").toUpperCase()
        color: App.Theme.white
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.modelData.onlyMenu)
                    root.openMenu();
                else
                    root.modelData.activate();
            } else if (mouse.button === Qt.RightButton) {
                if (root.modelData.hasMenu)
                    root.openMenu();
            } else if (mouse.button === Qt.MiddleButton) {
                root.modelData.secondaryActivate();
            }
        }

        onWheel: wheel => {
            const horizontal = wheel.angleDelta.y === 0;
            root.modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
            wheel.accepted = true;
        }
    }
}
