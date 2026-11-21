import QtQuick
import Quickshell.Hyprland
import "../../../services/workspaces/" as S
import "../../../" as App

// Vista general: una tarjeta por workspace.
Item {
    id: root

    signal done

    onVisibleChanged: {
        if (visible)
            Hyprland.refreshToplevels();
    }

    Grid {
        anchors.centerIn: parent
        columns: S.WorkspaceStore.overviewColumns
        spacing: App.Config.workspaces.cardSpacing

        Repeater {
            model: S.WorkspaceStore.count

            WorkspaceCard {
                required property int index
                wsId: index + 1
                dragParent: root
                onDone: root.done()
            }
        }
    }
}
