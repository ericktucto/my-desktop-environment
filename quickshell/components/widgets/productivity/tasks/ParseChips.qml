import QtQuick
import "../../../../" as App

// Chips de lo que entendió el analizador al escribir una tarea ("mañana 09:00 ×", "+Trabajo ×", "p1 ×").
// Cada × quita ese pedazo del texto (lo hace quien usa el componente con la señal `removed`).
Flow {
    id: root

    // [{ id, kind, label, spans }] (TaskStore.chipsFor)
    property var chips: []

    signal removed(var chip)

    spacing: 6

    readonly property var glyphs: ({
            "date": 0xf073,
            "start": 0xf073,
            "repeat": 0xf01e,
            "estimate": 0xf017,
            "priority": 0xf024,
            "project": 0xf07b,
            "tag": 0,
            "link": 0xf0c1,
            "template": 0xf0c5
        })

    function colorOf(chip) {
        if (chip.kind === "priority")
            return App.Config.tasks.priorityColors[chip.label.slice(1)] || App.Theme.gray;
        if (chip.kind === "project" && chip.label.endsWith("(nuevo)"))
            return App.Theme.amber;
        return App.Theme.white;
    }

    Repeater {
        model: root.chips
        Rectangle {
            id: chip
            required property var modelData
            height: 24
            width: row.implicitWidth + 20
            radius: 12
            color: App.Theme.surface

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 5

                Text {
                    visible: (root.glyphs[chip.modelData.kind] ?? 0) !== 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(root.glyphs[chip.modelData.kind] || 0x20)
                    color: root.colorOf(chip.modelData)
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.xs
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.label
                    color: root.colorOf(chip.modelData)
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                    font.weight: Font.Medium
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xf00d)
                    color: closeMouse.containsMouse ? App.Theme.red : App.Theme.gray
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.xs
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removed(chip.modelData)
                    }
                }
            }
        }
    }
}
