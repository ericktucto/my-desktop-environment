import QtQuick
import "../../../" as App

// Una opción entre muchas: botones ‹ y › recorren `options` ([{ id, label }]) y se ve la elegida.
SettingRow {
    id: root

    property var options: []
    property string value: ""
    property string defaultValue: ""

    signal picked(string id)

    readonly property int index: Math.max(0, options.findIndex(o => o.id === value))

    changed: defaultValue !== "" && value !== defaultValue
    onResetRequested: picked(defaultValue)

    function move(step) {
        if (options.length > 0)
            picked(options[(index + step + options.length) % options.length].id);
    }

    component Arrow: Rectangle {
        id: btn
        property string glyph
        signal clicked
        width: 26
        height: 26
        radius: 13
        anchors.verticalCenter: parent.verticalCenter
        color: arrowMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg
        }
        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // (RTL: el primero de la lista queda a la derecha)
    Arrow {
        glyph: "›"
        onClicked: root.move(1)
    }
    Text {
        width: 210
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.options[root.index]?.label ?? root.value
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }
    Arrow {
        glyph: "‹"
        onClicked: root.move(-1)
    }
}
