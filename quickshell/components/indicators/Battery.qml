import QtQuick
import "../base" as Base
import "../../" as App
import "../../components/widgets/notifylist" as N

Base.Island {
    id: root
    expandedWidth: App.Config.panel.notificationsWidth
    expandedHeight: list.implicitHeight + 16

    color: expanded ? "transparent" : App.Theme.island
    paddingContainer: expanded ? 0 : App.Config.pill.padding

    BatteryText {}

    body: N.NotifyList {
        id: list
    }
}
