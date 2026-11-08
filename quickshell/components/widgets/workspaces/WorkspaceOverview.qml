import QtQuick
import Quickshell.Hyprland
import "../../../" as App

// Vista general: una tarjeta por workspace.
Item {
    id: root

    signal done

    onVisibleChanged: {
        if (visible)
            Hyprland.refreshToplevels();
    }

    Row {
        anchors.centerIn: parent
        spacing: App.Config.workspaces.cardSpacing

        Repeater {
            model: App.Config.workspaces.count

            WorkspaceCard {
                required property int index
                wsId: index + 1
                dragParent: root
                onDone: root.done()
            }
        }
    }
}
