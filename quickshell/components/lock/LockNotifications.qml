import QtQuick
import "../../services/notify/" as N
import "../../" as App

// Las notificaciones no leídas de las últimas 24 h, una tarjeta por app (las más nuevas, críticas primero),
// y "+N más · Marcar todas como leídas".
Column {
    id: root

    readonly property var cfg: App.Config.lock
    readonly property var groups: N.NotificationStore.unreadGroups
    // Alto disponible (hasta los botones de energía): cuántas tarjetas caben, y una línea para "+N más"
    property real availHeight: 400
    readonly property int shown: Math.max(1, Math.min(cfg.notifyMax, Math.floor((availHeight - 28) / 64)))

    spacing: 8
    visible: groups.length > 0
    width: cfg.notifyWidth

    Repeater {
        model: root.groups.slice(0, root.shown)
        delegate: LockNotification {
            required property var modelData
            group: modelData
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        Text {
            visible: root.groups.length > root.shown
            text: "+" + (root.groups.length - root.shown) + " más ·"
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            text: "Marcar todas como leídas"
            color: allMouse.containsMouse ? App.Theme.white : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            MouseArea {
                id: allMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: N.NotificationStore.markRead(root.groups.flatMap(g => g.keys))
            }
        }
    }
}
