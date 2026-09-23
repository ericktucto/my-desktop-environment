import QtQuick
import "../../../services/notify/" as N

Rectangle {
    id: container
    color: "transparent"

    readonly property int maxHeight: Screen.height - 160
    readonly property bool hasNotifications: list.count > 0

    implicitWidth: 340
    implicitHeight: hasNotifications ? Math.min(list.contentHeight, container.maxHeight) : 80

    clip: true

    NotifyItemEmpty {
        visible: !hasNotifications
    }

    ListView {
        id: list
        anchors.fill: parent
        spacing: 8
        model: N.NotificationStore.history

        interactive: contentHeight > height

        boundsBehavior: Flickable.StopAtBounds

        delegate: NotifyItem {
            totalCount: list.count
        }
    }

    MouseArea {
        id: disable
        anchors.fill: parent
        onClicked: console.log("click en card notificacione")
    }
}
