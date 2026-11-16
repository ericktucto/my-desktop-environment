import QtQuick
import Quickshell
import "../../controls/" as C
import "../../../services/launcher/" as L
import "../../../services/launcher/Search.js" as Search
import "../../../services/screenshot/" as S
import "../../../" as App

// Panel de stickers sobre la barra de herramientas: los emojis del launcher (con buscador y los más usados
// primero) y los PNG o SVG propios de ~/.config/stixshell/stickers (o uno elegido de cualquier carpeta).
Rectangle {
    id: panel

    // Un emoji (`emoji`) o un archivo (`src`, con "file://")
    signal picked(string emoji, string src)

    width: 440
    height: 330
    radius: 22
    color: App.Theme.island
    border.width: 1
    border.color: App.Theme.islandEdge

    property int tab: 0
    readonly property var rows: tab === 0 ? Search.emojiRows(search.text, {
        emojis: L.LauncherStore.emojis,
        usage: L.LauncherStore.usage
    }) : []

    onVisibleChanged: {
        if (!visible)
            return;
        L.LauncherStore.loadEmojis();
        S.ScreenshotStore.refreshStickers();
        if (tab === 0)
            search.giveFocus();
    }

    component Tab: Rectangle {
        id: t
        property string label: ""
        property bool active: false
        signal clicked
        height: 30
        width: lbl.implicitWidth + 28
        radius: 15
        color: active ? App.Theme.surfaceActive : (m.containsMouse ? App.Theme.surface : "transparent")
        Text {
            id: lbl
            anchors.centerIn: parent
            text: t.label
            color: t.active ? App.Theme.white : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: t.clicked()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Row {
            spacing: 6
            Tab {
                label: "Emojis"
                active: panel.tab === 0
                onClicked: {
                    panel.tab = 0;
                    search.giveFocus();
                }
            }
            Tab {
                label: "Mis stickers"
                active: panel.tab === 1
                onClicked: panel.tab = 1
            }
        }

        // ── Emojis ──
        C.TextField {
            id: search
            visible: panel.tab === 0
            placeholder: "Buscar emoji…"
            height: 36
        }
        GridView {
            id: emojiGrid
            visible: panel.tab === 0
            width: parent.width
            height: parent.height - 30 - 36 - 20
            cellWidth: 44
            cellHeight: 44
            clip: true
            model: panel.rows
            boundsBehavior: Flickable.StopAtBounds

            // Los delegados no alcanzan el id de la raíz: la elección pasa por aquí
            function choose(emoji, key) {
                L.LauncherStore.use(key);
                panel.picked(emoji, "");
            }

            delegate: Rectangle {
                id: cell
                required property var modelData
                width: emojiGrid.cellWidth
                height: emojiGrid.cellHeight
                radius: 10
                color: cm.containsMouse ? App.Theme.surfaceActive : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: cell.modelData.emoji
                    font.pixelSize: 26
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: emojiGrid.choose(cell.modelData.emoji, cell.modelData.key)
                }
            }
        }

        // ── Mis stickers ──
        Rectangle {
            visible: panel.tab === 1
            width: pickLabel.implicitWidth + 32
            height: 32
            radius: 16
            color: pickMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface
            Text {
                id: pickLabel
                anchors.centerIn: parent
                text: "Desde archivo…"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: pickMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: S.ScreenshotStore.pickSticker()
            }
        }
        Text {
            visible: panel.tab === 1 && S.ScreenshotStore.stickerFiles.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Pon tus PNG o SVG en\n" + S.ScreenshotStore.stickersDir.replace(Quickshell.env("HOME"), "~") + "\ny aparecen aquí."
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        GridView {
            id: fileGrid
            visible: panel.tab === 1
            width: parent.width
            height: parent.height - 30 - 32 - 20
            cellWidth: 72
            cellHeight: 72
            clip: true
            model: S.ScreenshotStore.stickerFiles
            boundsBehavior: Flickable.StopAtBounds

            function choose(path) {
                panel.picked("", "file://" + path);
            }

            delegate: Rectangle {
                id: fcell
                required property string modelData
                width: fileGrid.cellWidth
                height: fileGrid.cellHeight
                radius: 10
                color: fm.containsMouse ? App.Theme.surfaceActive : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    source: "file://" + fcell.modelData
                    sourceSize: Qt.size(112, 112)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                MouseArea {
                    id: fm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fileGrid.choose(fcell.modelData)
                }
            }
        }
    }
}
