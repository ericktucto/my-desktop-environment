import QtQuick
import "../../../" as App

// Una fila de una lista que se ordena: botones ↑ y ↓ (`moved(-1)` o `moved(1)`); se apagan en los extremos.
SettingRow {
    id: root

    property bool first: false
    property bool last: false

    // Con botón ✕ para quitar la fila
    property bool removable: false

    signal moved(int dir)
    signal removed

    component Arrow: Rectangle {
        id: btn
        property string glyph
        signal clicked
        width: 26
        height: 26
        radius: 13
        anchors.verticalCenter: parent.verticalCenter
        opacity: enabled ? 1 : 0.35
        color: arrowMouse.containsMouse && enabled ? App.Theme.surfaceActive : App.Theme.surface
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Arrow {
        visible: root.removable
        glyph: "✕"
        onClicked: root.removed()
    }
    Arrow {
        glyph: "↓"
        enabled: !root.last
        onClicked: root.moved(1)
    }
    Arrow {
        glyph: "↑"
        enabled: !root.first
        onClicked: root.moved(-1)
    }
}
