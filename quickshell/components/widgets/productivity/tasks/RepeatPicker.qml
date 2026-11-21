import QtQuick
import "../../../../services/tasks/Parse.js" as Parse
import "../../../../" as App

// Editor de la repetición de una tarea: cada cuánto (día, laborable, semana, mes, año), cada N,
// los días de la semana y desde cuándo se cuenta. Cada cambio se aplica al instante.
Rectangle {
    id: root

    // { freq, interval, days, from } o null (no se repite)
    property var repeat: null

    // Un cambio: la repetición nueva, o null para quitarla
    signal changed(var repeat)

    readonly property var freqs: [
        {
            id: "daily",
            label: "Día"
        },
        {
            id: "weekdays",
            label: "Laborable"
        },
        {
            id: "weekly",
            label: "Semana"
        },
        {
            id: "monthly",
            label: "Mes"
        },
        {
            id: "yearly",
            label: "Año"
        }
    ]
    readonly property var dayLetters: ["L", "M", "X", "J", "V", "S", "D"]
    readonly property var unitNames: ({
            "daily": "días",
            "weekly": "semanas",
            "monthly": "meses",
            "yearly": "años"
        })

    width: 330
    height: column.implicitHeight + 24
    radius: 16
    color: App.Theme.island
    border.color: App.Theme.border
    border.width: 1

    function make(freq) {
        return {
            freq: freq,
            interval: 1,
            days: [],
            from: repeat ? repeat.from : "due"
        };
    }

    function patch(changes) {
        if (repeat)
            root.changed(Object.assign({}, repeat, changes));
    }

    component Option: Rectangle {
        id: option
        property string label: ""
        property bool selected: false
        signal clicked

        implicitWidth: optionText.implicitWidth + 22
        height: 28
        radius: 14
        color: selected ? App.Theme.primary : (optionMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
        Text {
            id: optionText
            anchors.centerIn: parent
            text: option.label
            color: option.selected ? App.Theme.onPrimary : App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: optionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: option.clicked()
        }
    }

    Column {
        id: column
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 10

        Text {
            text: root.repeat ? Parse.repeatLabel(root.repeat) : "No se repite"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }

        Flow {
            width: parent.width
            spacing: 4
            Repeater {
                model: root.freqs
                Option {
                    required property var modelData
                    label: modelData.label
                    selected: root.repeat !== null && root.repeat.freq === modelData.id
                    onClicked: {
                        if (root.repeat && root.repeat.freq === modelData.id)
                            return;
                        const r = root.make(modelData.id);
                        if (root.repeat && modelData.id !== "weekly")
                            r.interval = root.repeat.interval;
                        root.changed(r);
                    }
                }
            }
        }

        // Cada N días, semanas, meses o años
        Row {
            visible: root.repeat !== null && root.repeat.freq !== "weekdays"
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Cada"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            TaskIconButton {
                size: 24
                glyph: 0xf068
                onClicked: root.patch({
                    interval: Math.max(1, root.repeat.interval - 1)
                })
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                horizontalAlignment: Text.AlignHCenter
                text: root.repeat ? root.repeat.interval : ""
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.DemiBold
            }
            TaskIconButton {
                size: 24
                glyph: 0xf067
                onClicked: root.patch({
                    interval: Math.min(99, root.repeat.interval + 1)
                })
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.repeat ? (root.unitNames[root.repeat.freq] ?? "") : ""
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        // Días de la semana (solo con "Semana")
        Row {
            visible: root.repeat !== null && root.repeat.freq === "weekly"
            spacing: 4
            Repeater {
                model: root.dayLetters
                Rectangle {
                    id: dayButton
                    required property string modelData
                    required property int index
                    readonly property bool on: root.repeat !== null && root.repeat.days.includes(index + 1)
                    width: 34
                    height: 28
                    radius: 14
                    color: on ? App.Theme.primary : (dayMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                    Text {
                        anchors.centerIn: parent
                        text: dayButton.modelData
                        color: dayButton.on ? App.Theme.onPrimary : App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const d = dayButton.index + 1;
                            const days = root.repeat.days.includes(d) ? root.repeat.days.filter(x => x !== d) : root.repeat.days.concat([d]);
                            root.patch({
                                days: days.sort()
                            });
                        }
                    }
                }
            }
        }

        // Desde cuándo se cuenta
        Flow {
            visible: root.repeat !== null
            width: parent.width
            spacing: 4
            Option {
                label: "Desde la fecha límite"
                selected: root.repeat !== null && root.repeat.from === "due"
                onClicked: root.patch({
                    from: "due"
                })
            }
            Option {
                label: "Desde que la completo"
                selected: root.repeat !== null && root.repeat.from === "done"
                onClicked: root.patch({
                    from: "done"
                })
            }
        }

        Option {
            visible: root.repeat !== null
            label: "No repetir"
            onClicked: root.changed(null)
        }
    }
}
