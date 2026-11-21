import QtQuick
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../" as App

// Mini calendario para elegir una fecha: ‹ mes ›, la cuadrícula y atajos (Hoy, Mañana, Sin fecha).
Rectangle {
    id: root

    // Fecha elegida ("AAAA-MM-DD" o "")
    property string value: ""
    property string todayKey: ""
    property bool allowClear: true

    signal picked(string key)

    readonly property var months: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var dayLetters: ["lu", "ma", "mi", "ju", "vi", "sá", "do"]

    // Primer día del mes que se muestra ("AAAA-MM-01")
    property string monthStart: ""

    width: 252
    height: column.implicitHeight + 20
    radius: 16
    color: App.Theme.island
    border.color: App.Theme.border
    border.width: 1

    // Al abrirlo muestra el mes de la fecha elegida (o el de hoy)
    function open() {
        const k = Dates.isKey(value) ? value : todayKey;
        monthStart = k.slice(0, 8) + "01";
    }

    function shift(n) {
        const d = Dates.parseKey(monthStart);
        monthStart = Dates.keyOf(new Date(d.getFullYear(), d.getMonth() + n, 1));
    }

    // 42 celdas desde el lunes de la primera semana
    readonly property var cells: {
        if (!Dates.isKey(monthStart))
            return [];
        const first = Dates.weekday(monthStart) - 1;
        const start = Dates.addDays(monthStart, -first);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const k = Dates.addDays(start, i);
            out.push({
                key: k,
                day: Dates.parseKey(k).getDate(),
                inMonth: k.slice(0, 7) === monthStart.slice(0, 7)
            });
        }
        return out;
    }

    Column {
        id: column
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 6

        Item {
            width: parent.width
            height: 26
            TaskIconButton {
                size: 24
                glyph: 0xf104
                onClicked: root.shift(-1)
            }
            Text {
                anchors.centerIn: parent
                text: Dates.isKey(root.monthStart) ? root.months[Dates.parseKey(root.monthStart).getMonth()] + " " + root.monthStart.slice(0, 4) : ""
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.DemiBold
            }
            TaskIconButton {
                anchors.right: parent.right
                size: 24
                glyph: 0xf105
                onClicked: root.shift(1)
            }
        }

        Row {
            Repeater {
                model: root.dayLetters
                Text {
                    required property string modelData
                    width: column.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: App.Theme.grayDark
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }

        Grid {
            columns: 7
            Repeater {
                model: root.cells
                Rectangle {
                    id: cell
                    required property var modelData
                    width: column.width / 7
                    height: 28
                    radius: 14
                    color: modelData.key === root.value ? App.Theme.primary : (cellMouse.containsMouse ? App.Theme.surfaceActive : "transparent")
                    border.width: modelData.key === root.todayKey && modelData.key !== root.value ? 1 : 0
                    border.color: App.Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        color: cell.modelData.key === root.value ? App.Theme.onPrimary : (cell.modelData.inMonth ? App.Theme.white : App.Theme.grayDark)
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picked(cell.modelData.key)
                    }
                }
            }
        }

        Row {
            spacing: 6
            topPadding: 2
            Repeater {
                model: root.allowClear ? [
                    {
                        label: "Hoy",
                        off: 0
                    },
                    {
                        label: "Mañana",
                        off: 1
                    },
                    {
                        label: "Sin fecha",
                        off: -1
                    }
                ] : [
                    {
                        label: "Hoy",
                        off: 0
                    },
                    {
                        label: "Mañana",
                        off: 1
                    }
                ]
                Rectangle {
                    id: quick
                    required property var modelData
                    width: quickText.implicitWidth + 20
                    height: 26
                    radius: 13
                    color: quickMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface
                    Text {
                        id: quickText
                        anchors.centerIn: parent
                        text: quick.modelData.label
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.xs
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: quickMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picked(quick.modelData.off < 0 ? "" : Dates.addDays(root.todayKey, quick.modelData.off))
                    }
                }
            }
        }
    }
}
