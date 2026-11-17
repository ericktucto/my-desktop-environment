import QtQuick
import "../../../services/calendar/" as CS
import "../../../" as App

// Vistas por horas (Semana, 3 días y Día): cabeceras de día, fila de todo el día arriba y 24 horas
// con desplazamiento. Los eventos que se cruzan van lado a lado; una línea roja marca la hora actual.
// Un clic en una hora vacía abre el formulario de evento nuevo de Google.
Item {
    id: root

    readonly property var store: CS.CalendarStore
    readonly property var cfg: App.Config.calendar
    readonly property var days: store.gridDays
    readonly property real colW: (width - cfg.gutterWidth) / days.length
    readonly property real headH: 38
    readonly property real chipH: 18

    signal closeRequested

    // Eventos de cada día: de todo el día (con feriados) y con hora
    readonly property var allDays: days.map(d => store.eventsOn(store.keyOf(d)).filter(e => e.allDay))
    readonly property var timedDays: days.map(d => layout(store.eventsOn(store.keyOf(d)).filter(e => !e.allDay)))
    readonly property int allRows: Math.min(2, Math.max(0, ...allDays.map(l => l.length)))
    readonly property real allH: allRows > 0 ? allRows * chipH + 6 : 0

    // Colocación de los eventos que se cruzan: columnas dentro de cada grupo que se solapa
    function layout(list) {
        const items = list.slice().sort((a, b) => a.segStart - b.segStart || b.segEnd - a.segEnd);
        const out = [];
        let group = [], groupEnd = 0;
        const flush = () => {
            const ends = [];
            for (const it of group) {
                let c = ends.findIndex(e => e <= it.ev.segStart);
                if (c < 0) {
                    c = ends.length;
                    ends.push(0);
                }
                ends[c] = it.ev.segEnd;
                it.col = c;
            }
            for (const it of group)
                it.cols = ends.length;
            out.push(...group);
            group = [];
        };
        for (const ev of items) {
            if (group.length > 0 && ev.segStart >= groupEnd) {
                flush();
                groupEnd = 0;
            }
            group.push({
                ev: ev,
                col: 0,
                cols: 1
            });
            groupEnd = Math.max(groupEnd, ev.segEnd);
        }
        if (group.length > 0)
            flush();
        return out;
    }

    // Hora a la que queda el desplazamiento: hoy, una antes de la actual; otro día, una antes del primer
    // evento; sin eventos, las 8
    function scrollToStart() {
        let hour = cfg.defaultStartHour;
        const keys = days.map(d => store.keyOf(d));
        if (keys.includes(store.todayKey)) {
            hour = store.now.getHours() - 1;
        } else {
            let first = -1;
            for (const k of keys) {
                for (const e of store.eventsOn(k)) {
                    if (e.allDay)
                        continue;
                    const h = new Date(e.segStart).getHours() + new Date(e.segStart).getMinutes() / 60;
                    if (first < 0 || h < first)
                        first = h;
                }
                if (first >= 0)
                    break;
            }
            if (first >= 0)
                hour = Math.floor(first) - 1;
        }
        flick.contentY = Math.max(0, Math.min(hour * cfg.hourHeight, flick.contentHeight - flick.height));
    }

    onVisibleChanged: if (visible)
        Qt.callLater(scrollToStart)

    Connections {
        target: root.store
        function onSelectedKeyChanged() {
            if (root.visible)
                Qt.callLater(root.scrollToStart);
        }
        function onViewChanged() {
            if (root.visible)
                Qt.callLater(root.scrollToStart);
        }
    }

    // ── Cabeceras de día ──
    Item {
        id: head
        x: cfg.gutterWidth
        width: parent.width - cfg.gutterWidth
        height: root.headH

        Repeater {
            model: root.days
            Item {
                id: hd
                required property var modelData
                required property int index
                readonly property string key: root.store.keyOf(modelData)
                readonly property bool isToday: key === root.store.todayKey
                readonly property bool isSelected: key === root.store.selectedKey
                readonly property bool holiday: root.store.isHoliday(key)
                x: index * root.colW
                width: root.colW
                height: root.headH

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 12
                    color: hdMouse.containsMouse && !hd.isSelected ? App.Theme.surface : "transparent"
                    border.width: hd.isSelected && root.days.length > 1 ? 2 : 0
                    border.color: App.Theme.primary
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.store.daysMin[root.store.weekday(hd.modelData)]
                        color: hd.holiday ? App.Theme.red : App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 13
                        color: hd.isToday ? App.Theme.primary : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: hd.modelData.getDate()
                            color: hd.isToday ? App.Theme.white : (hd.holiday ? App.Theme.red : App.Theme.white)
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.lg
                            font.weight: Font.DemiBold
                        }
                    }
                }
                MouseArea {
                    id: hdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.select(hd.modelData)
                }
            }
        }
    }

    // ── Eventos de todo el día (y feriados) ──
    Item {
        id: allDay
        y: root.headH
        width: parent.width
        height: root.allH
        visible: root.allRows > 0

        Text {
            width: root.cfg.gutterWidth - 6
            height: root.chipH
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: "todo"
            color: App.Theme.grayDark
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }

        Repeater {
            model: root.allDays
            Item {
                id: col
                required property var modelData
                required property int index
                readonly property int total: modelData.length
                // Con más de dos: el primero y "+N"
                readonly property var shown: total > 2 ? [modelData[0], null] : modelData
                x: root.cfg.gutterWidth + index * root.colW
                width: root.colW

                Repeater {
                    model: col.shown
                    Rectangle {
                        required property var modelData
                        required property int index
                        y: index * root.chipH
                        x: 2
                        width: root.colW - 4
                        height: root.chipH - 2
                        radius: 5
                        color: modelData ? Qt.alpha(modelData.color, 0.28) : App.Theme.surface

                        Rectangle {
                            visible: parent.modelData !== null
                            width: 3
                            height: parent.height
                            radius: 1.5
                            color: parent.modelData ? parent.modelData.color : "transparent"
                        }
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 3
                            verticalAlignment: Text.AlignVCenter
                            text: parent.modelData ? parent.modelData.title : "+" + (col.total - 1) + " más"
                            elide: Text.ElideRight
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.xs
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !parent.modelData || !parent.modelData.holiday
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const k = root.store.keyOf(root.days[col.index]);
                                if (parent.modelData)
                                    root.store.openEvent(parent.modelData, k);
                                else
                                    root.store.select(root.days[col.index]);
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Las 24 horas ──
    Flickable {
        id: flick
        y: root.headH + root.allH
        width: parent.width
        height: parent.height - y
        contentHeight: 24 * root.cfg.hourHeight
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Horas y líneas
        Repeater {
            model: 24
            Item {
                required property int index
                y: index * root.cfg.hourHeight
                width: flick.width
                height: root.cfg.hourHeight

                Text {
                    visible: parent.index > 0
                    y: -7
                    width: root.cfg.gutterWidth - 6
                    horizontalAlignment: Text.AlignRight
                    text: (parent.index % 12 === 0 ? 12 : parent.index % 12) + " " + (parent.index < 12 ? "AM" : "PM")
                    color: App.Theme.grayDark
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
                Rectangle {
                    x: root.cfg.gutterWidth
                    width: flick.width - root.cfg.gutterWidth
                    height: 1
                    color: App.Theme.islandEdge
                }
            }
        }

        // Una columna por día
        Repeater {
            model: root.days
            Item {
                id: dayCol
                required property var modelData
                required property int index
                readonly property string key: root.store.keyOf(modelData)
                readonly property real dayStart: new Date(modelData.getFullYear(), modelData.getMonth(), modelData.getDate()).getTime()
                readonly property real hourH: root.cfg.hourHeight
                x: root.cfg.gutterWidth + index * root.colW
                width: root.colW
                height: flick.contentHeight

                Rectangle {
                    visible: dayCol.index > 0
                    width: 1
                    height: parent.height
                    color: App.Theme.islandEdge
                }

                // Hora vacía: se marca la media hora y un clic crea el evento
                MouseArea {
                    id: slotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    readonly property int slot: Math.max(0, Math.min(47, Math.floor(mouseY / (dayCol.hourH / 2))))
                    onClicked: {
                        const start = dayCol.dayStart + slot * 1800000;
                        root.store.openUrl(root.store.newEventUrl(start, start + 3600000));
                        root.closeRequested();
                    }
                }
                Rectangle {
                    visible: slotMouse.containsMouse
                    x: 2
                    y: slotMouse.slot * dayCol.hourH / 2
                    width: parent.width - 4
                    height: dayCol.hourH / 2
                    radius: 5
                    color: App.Theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                }

                // Bloques
                Repeater {
                    model: root.timedDays[dayCol.index]
                    Rectangle {
                        id: block
                        required property var modelData
                        readonly property var ev: modelData.ev
                        readonly property real h: Math.max((ev.segEnd - ev.segStart) / 3600000 * dayCol.hourH - 1, 18)
                        x: 2 + modelData.col * ((dayCol.width - 4) / modelData.cols)
                        y: (ev.segStart - dayCol.dayStart) / 3600000 * dayCol.hourH
                        width: (dayCol.width - 4) / modelData.cols - 1
                        height: h
                        radius: 6
                        color: Qt.alpha(ev.color, blockMouse.containsMouse ? 0.5 : 0.34)
                        opacity: root.store.isPast(ev) ? 0.55 : 1
                        clip: true

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: block.ev.color
                        }
                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 3
                            anchors.topMargin: 2
                            Text {
                                width: parent.width
                                text: block.ev.title
                                elide: Text.ElideRight
                                color: App.Theme.white
                                font.family: App.Config.fonts.text
                                font.pixelSize: App.Config.fontSize.xs
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: block.h >= 36
                                width: parent.width
                                text: root.store.timeLabel(block.ev)
                                elide: Text.ElideRight
                                color: App.Theme.gray
                                font.family: App.Config.fonts.text
                                font.pixelSize: App.Config.fontSize.xs - 1
                            }
                        }
                        MouseArea {
                            id: blockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.store.openEvent(block.ev, dayCol.key)
                        }
                    }
                }

                // Línea de la hora actual
                Item {
                    visible: dayCol.key === root.store.todayKey
                    y: (root.store.now.getTime() - dayCol.dayStart) / 3600000 * dayCol.hourH
                    width: parent.width
                    Rectangle {
                        x: -4
                        y: -4
                        width: 8
                        height: 8
                        radius: 4
                        color: App.Theme.red
                    }
                    Rectangle {
                        y: -1
                        width: parent.width
                        height: 2
                        color: App.Theme.red
                    }
                }
            }
        }
    }
}
