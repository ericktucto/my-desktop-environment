import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../base" as Base
import "../../" as App

Base.Island {
    expandedHeight: 80
    expandedWidth: 360
    radiusExpanded: 32

    Row {
        anchors.verticalCenter: parent.verticalCenter

        spacing: 10
        Repeater {
            model: 4
            delegate: Rectangle {
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id == (index + 1))
                readonly property bool active: ws?.active || false
                readonly property bool hasWindows: ws?.toplevels.values.length > 0 || false

                width: active ? 20 : 10
                height: 10
                color: active ? App.Theme.primary : hasWindows ? App.Theme.white : 'transparent'
                border.color: App.Theme.white
                border.width: active ? 0 : 1
                radius: 10

                Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }
        }
    }

    /*
     * @todo agregar para arrastrar ventanas entre workspaces
    body: Text {
        text: "Hola Erick"
        color: App.Theme.white
    }
    */
}
