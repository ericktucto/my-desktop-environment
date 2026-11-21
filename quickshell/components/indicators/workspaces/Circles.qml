import QtQuick
import "../../../" as App

// Círculos unidos (end-4): cada workspace es un número en un círculo; los ocupados seguidos comparten un fondo
// como una cápsula y el círculo de acento del activo se desliza al cambiar de workspace.
WsStyle {
    id: root

    readonly property int cell: 24
    readonly property int gap: 2

    // Tramos de workspaces ocupados (o activos) seguidos: [{ from, to }] como posiciones en `items`
    readonly property var runs: {
        const out = [];
        let start = -1;
        for (let i = 0; i <= items.length; i++) {
            const on = i < items.length && (items[i].occupied || items[i].active);
            if (on && start < 0)
                start = i;
            if (!on && start >= 0) {
                out.push({
                    from: start,
                    to: i - 1
                });
                start = -1;
            }
        }
        return out;
    }
    readonly property int activeIndex: items.findIndex(i => i.active)

    implicitWidth: items.length * cell + Math.max(0, items.length - 1) * gap
    implicitHeight: cell
    rowItem: row
    rep: itemsRep

    // Fondos de los tramos
    Repeater {
        model: root.runs
        Rectangle {
            required property var modelData
            x: modelData.from * (root.cell + root.gap)
            width: (modelData.to - modelData.from + 1) * root.cell + (modelData.to - modelData.from) * root.gap
            height: root.cell
            radius: root.cell / 2
            color: App.Theme.surfaceActive
        }
    }

    // El activo
    Rectangle {
        visible: root.activeIndex >= 0
        x: Math.max(0, root.activeIndex) * (root.cell + root.gap)
        width: root.cell
        height: root.cell
        radius: root.cell / 2
        color: App.Theme.primary
        Behavior on x {
            NumberAnimation {
                duration: App.Config.anim.pill
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: row
        spacing: root.gap

        Repeater {
            id: itemsRep
            model: root.items
            delegate: Item {
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id
                width: root.cell
                height: root.cell
                opacity: modelData.extra ? 0.5 : 1

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: App.Theme.surfaceActive
                    opacity: parent.hovered && !parent.modelData.active && !parent.modelData.occupied ? 1 : 0
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.id
                    color: parent.modelData.active ? App.Theme.onPrimary : (parent.modelData.occupied || parent.hovered ? App.Theme.white : App.Theme.gray)
                    font.family: App.Config.fonts.mono
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: parent.modelData.active ? Font.Bold : Font.Medium
                }
            }
        }
    }
}
