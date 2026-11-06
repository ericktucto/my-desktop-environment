import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../base" as Base
import "../../" as App

Base.Island {
    expandedHeight: App.Config.panel.workspacesHeight
    expandedWidth: App.Config.panel.workspacesWidth

    Row {
        anchors.verticalCenter: parent.verticalCenter

        spacing: App.Config.workspaces.spacing
        Repeater {
            model: App.Config.workspaces.count
            delegate: Rectangle {
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === (index + 1))
                readonly property bool active: ws?.active || false
                readonly property bool hasWindows: ws?.toplevels.values.length > 0 || false

                width: active ? App.Config.workspaces.activeWidth : App.Config.workspaces.dotSize
                height: App.Config.workspaces.dotSize
                color: active ? App.Theme.primary : hasWindows ? App.Theme.white : 'transparent'
                border.color: App.Theme.white
                border.width: active ? 0 : 1
                radius: App.Config.workspaces.dotSize

                Behavior on width  { NumberAnimation { duration: App.Config.anim.pill; easing.type: Easing.OutCubic } }
            }
        }
    }
}
