import QtQuick
import Quickshell
import "../../../services/notify/" as S
import "../../../" as App

// Historial: una tarjeta por notificación, la más nueva arriba.
// El modelo son las keys (strings), así que solo se crean/borran los delegates que cambian.
ListView {
    id: list

    implicitHeight: Math.min(contentHeight, App.Config.notifications.listMaxHeight)

    clip: true
    spacing: App.Config.notifications.spacing
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
        values: S.NotificationStore.history.map(e => e.key)
    }

    delegate: NotifyItem {
        id: card
        width: ListView.view.width
        onCloseRequested: S.NotificationStore.remove(modelData)
        onActivated: S.NotificationStore.activate(modelData)
    }
}
