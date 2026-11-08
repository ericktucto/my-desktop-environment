import QtQuick
import "../../../services/workspaces/" as S
import "../../../" as App

// Tarjeta de un workspace: número, íconos de sus ventanas y destino de arrastre.
Rectangle {
    id: card

    required property int wsId
    property Item dragParent

    signal done

    readonly property var cfg: App.Config.workspaces
    readonly property bool active: S.WorkspaceStore.currentId === wsId
    readonly property var wins: S.WorkspaceStore.windows(wsId)
    // Con más de maxRows ventanas, la última fila pasa a ser "+N más"
    readonly property bool overflowing: wins.length > cfg.maxRows
    readonly property var shown: overflowing ? wins.slice(0, cfg.maxRows - 1) : wins
    readonly property int overflow: overflowing ? wins.length - (cfg.maxRows - 1) : 0

    width: cfg.cardWidth
    height: S.WorkspaceStore.cardHeight
    radius: cfg.cardRadius
    color: drop.containsDrag ? App.Theme.surfaceActive : (hover.hovered ? App.Theme.surfaceHover : App.Theme.surface)
    border.width: active || drop.containsDrag ? 2 : 0
    border.color: App.Theme.primary

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    HoverHandler {
        id: hover
    }

    // Clic en la tarjeta (los íconos, declarados después, reciben el suyo)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            S.WorkspaceStore.focus(card.wsId);
            card.done();
        }
    }

    Text {
        x: card.cfg.cardPadding + 4
        y: card.cfg.cardPadding
        text: card.wsId
        color: card.active ? App.Theme.white : App.Theme.gray
        font.family: App.Config.fonts.mono
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.Medium
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: card.cfg.cardPadding + card.cfg.headerHeight + 6
        visible: card.wins.length === 0
        text: "Vacío"
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    Column {
        id: list
        x: card.cfg.cardPadding
        y: card.cfg.cardPadding + card.cfg.headerHeight
        width: card.width - 2 * card.cfg.cardPadding
        spacing: card.cfg.rowSpacing

        Repeater {
            model: card.shown

            WindowRow {
                required property var modelData
                width: list.width
                toplevel: modelData
                dragParent: card.dragParent
                onActivated: card.done()
            }
        }

        Text {
            visible: card.overflow > 0
            height: card.cfg.rowHeight
            leftPadding: 8
            verticalAlignment: Text.AlignVCenter
            text: "+" + card.overflow + " más"
            color: App.Theme.grayDark
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["stixshell-window"]
        onDropped: drop => {
            const t = drop.source.toplevel;
            if (t && t.workspace?.id !== card.wsId)
                S.WorkspaceStore.moveWindow(t, card.wsId);
        }
    }
}
