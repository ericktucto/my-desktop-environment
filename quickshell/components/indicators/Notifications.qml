import QtQuick
import "../base/" as Base
import "../controls/" as C
import "../widgets/notifylist/" as N
import "../../services/notify/" as S
import "../../services/settings/" as ST
import "../../services/actions/" as AC
import "../../" as App

// Pill de notificaciones: campana + no leídas. Al abrirla muestra el historial.
Base.Island {
    id: root

    visible: ST.SettingsStore.pills.notifications

    expandedWidth: App.Config.panel.notificationsWidth
    expandedHeight: panel.implicitHeight + 2 * paddingContainer

    readonly property int unread: S.NotificationStore.unreadCount

    Row {
        spacing: App.Config.pill.contentSpacing

        C.IconSvg {
            source: Qt.resolvedUrl("../../assets/svg/" + (S.NotificationStore.dnd ? "notification-off" : "notification-on") + ".svg")
            size: App.Config.pill.iconSize
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.unread > 0
            text: root.unread > 99 ? "99+" : root.unread
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Al abrir o cerrar el panel todo queda como leído
    onOpened: S.NotificationStore.markAllRead()
    onClosed: S.NotificationStore.markAllRead()

    // Pill cerrada: clic derecho = No molestar.
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: !root.expanded
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        // Derecho (por defecto No molestar) y central, según Preferencias → Barra e isla
        onClicked: mouse => AC.ActionRunner.run(mouse.button === Qt.RightButton ? ST.SettingsStore.notifPill.right : ST.SettingsStore.notifPill.middle)
    }

    body: N.NotifyPanel {
        id: panel
        width: parent ? parent.width : 0
    }
}
