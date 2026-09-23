import QtQuick
import "../base" as Base
import "../../" as App
import "../../components/widgets/notifylist" as N

Base.Island {
    id: root
    collapsedWidth: 115
    expandedWidth: 340
    expandedHeight: list.implicitHeight + 16

    color: expanded ? "transparent" : App.Theme.island
    paddingContainer: expanded ? 0 : 16

    BatteryText {}

    body: N.NotifyList {
        id: list
    }
}
