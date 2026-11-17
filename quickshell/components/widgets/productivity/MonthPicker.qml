import QtQuick
import "../../../services/calendar/" as CS
import "../../../" as App

// Selector de mes y año: "‹ 2026 ›" y los doce meses. Elegir uno salta a ese mes.
Rectangle {
    id: root

    readonly property var store: CS.CalendarStore
    property int year: store.selected.getFullYear()

    color: App.Theme.island

    onVisibleChanged: if (visible)
        year = store.selected.getFullYear()

    // Absorbe los clics para que no lleguen a la vista de abajo
    MouseArea {
        anchors.fill: parent
    }

    Row {
        id: yearRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        CalButton {
            glyph: 0xf0141
            onClicked: root.year--
        }
        Text {
            width: 80
            height: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.year
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg + 2
            font.weight: Font.DemiBold
        }
        CalButton {
            glyph: 0xf0142
            onClicked: root.year++
        }
    }

    Grid {
        anchors.top: yearRow.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 4
        spacing: 10

        readonly property real cellW: (root.width - 3 * spacing) / 4
        readonly property real cellH: (root.height - yearRow.height - 16 - 2 * spacing) / 3

        Repeater {
            model: 12
            Rectangle {
                id: cell
                required property int index
                readonly property bool isCurrent: root.year === root.store.now.getFullYear() && index === root.store.now.getMonth()
                readonly property bool isSelected: root.year === root.store.selected.getFullYear() && index === root.store.selected.getMonth()
                width: (root.width - 30) / 4
                height: (root.height - yearRow.height - 16 - 20) / 3
                radius: 16
                color: isCurrent ? App.Theme.primary : (cellMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                border.width: isSelected && !isCurrent ? 2 : 0
                border.color: App.Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: root.store.months[cell.index]
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg
                    font.weight: cell.isCurrent || cell.isSelected ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.jumpTo(root.year, cell.index)
                }
            }
        }
    }
}
