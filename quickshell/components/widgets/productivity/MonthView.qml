import QtQuick
import "../../../services/calendar/" as CS
import "../../../" as App

// Vista Mes: seis semanas (lunes a domingo). Hoy lleva un círculo, el elegido un anillo,
// los feriados el número en rojo y los eventos, puntos de color. La rueda cambia de mes.
Item {
    id: root

    readonly property var store: CS.CalendarStore
    readonly property real headH: 24
    readonly property real cellW: width / 7
    readonly property real cellH: (height - headH) / 6

    Row {
        Repeater {
            model: root.store.daysMin
            Text {
                required property string modelData
                width: root.cellW
                height: root.headH
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.Medium
            }
        }
    }

    Grid {
        y: root.headH
        columns: 7

        Repeater {
            model: root.store.monthGrid
            Item {
                id: cell
                required property var modelData
                readonly property string key: root.store.keyOf(modelData)
                readonly property bool inMonth: modelData.getMonth() === root.store.selected.getMonth()
                readonly property bool isToday: key === root.store.todayKey
                readonly property bool isSelected: key === root.store.selectedKey
                readonly property bool holiday: root.store.isHoliday(key)
                readonly property var dots: root.store.dotsOn(key)
                width: root.cellW
                height: root.cellH

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 12
                    color: cellMouse.containsMouse && !cell.isSelected ? App.Theme.surface : "transparent"
                    border.width: cell.isSelected ? 2 : 0
                    border.color: App.Theme.primary
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    opacity: cell.inMonth ? 1 : 0.38

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26
                        height: 26
                        radius: 13
                        color: cell.isToday ? App.Theme.primary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData.getDate()
                            color: cell.isToday ? App.Theme.white : (cell.holiday ? App.Theme.red : App.Theme.white)
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.lg
                            font.weight: cell.isToday || cell.holiday ? Font.DemiBold : Font.Normal
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3
                        height: 6
                        Repeater {
                            model: Math.min(cell.dots.length, App.Config.calendar.dots)
                            Rectangle {
                                required property int index
                                width: 6
                                height: 6
                                radius: cell.dots[index].task ? 1 : 3
                                color: cell.dots[index].color
                            }
                        }
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.select(cell.modelData)
                    onDoubleClicked: {
                        root.store.select(cell.modelData);
                        root.store.setView("day");
                    }
                }
            }
        }
    }

    // La rueda del touchpad manda pasos chicos: se acumulan hasta un paso entero
    WheelHandler {
        property real acc: 0
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            acc += event.angleDelta.y;
            if (Math.abs(acc) >= 120) {
                root.store.shift(acc < 0 ? 1 : -1);
                acc = 0;
            }
        }
    }
}
