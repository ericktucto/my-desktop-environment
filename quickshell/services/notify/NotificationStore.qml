pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: store

    property list<Notification> history: []
    property int unreadCount: 0

    readonly property var server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        actionIconsSupported: true

        onNotification: notification => {
            notification.tracked = true;
            store.history.unshift(notification);

            notification.closed.connect(() => {
                history = history.filter(n => n != notification);
            });

            store.unreadCount++;
        }
    }
    function dismiss(notif: Notification) {
        notif.tracked = false;
    }
}
