import QtQuick
import "../controlcenter/" as CC
import "../../../services/theme/" as T
import "../../../" as App

// Encabezado del selector de wallpapers: cómo se colorea la shell. Dos modos:
//   Del wallpaper: fondo y acento de la imagen, a elegir entre sus combinaciones («Lila + verde»).
//   Acento propio: el acento lo eliges tú; los fondos son los del sistema.
// A la derecha, lo elegido: un clic abre la vista de colores (ColorsView) en lugar de la cuadrícula.
Item {
    id: root

    readonly property var store: T.ThemeStore
    readonly property var cfg: App.Config.theme
    readonly property string mode: store.mode
    // «Del wallpaper» necesita Pillow
    readonly property bool wallpaperMode: mode !== "custom"
    // La vista de colores está abierta (la muestra Wallpapers en lugar de la cuadrícula)
    property bool open: false
    signal toggleColors

    implicitHeight: App.Config.wallpaperPicker.themeRow

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        rightPadding: 2
    }

    Row {
        id: modes
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Label {
            text: "Colores"
            font.weight: Font.DemiBold
            font.pixelSize: App.Config.fontSize.md
            color: App.Theme.white
            rightPadding: 8
        }
        Repeater {
            model: root.cfg.modes
            CC.Chip {
                required property var modelData
                label: modelData.label
                selected: root.mode === modelData.id
                enabled: modelData.id === "custom" || root.store.available
                opacity: enabled ? 1 : 0.4
                onClicked: root.store.setMode(modelData.id)
            }
        }
    }

    // Lo elegido: las dos muestras (fondo y acento) y su nombre; con el acento propio, el color
    Rectangle {
        id: chosen
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        width: chosenRow.implicitWidth + 24
        radius: 15
        color: root.open ? App.Theme.surfaceActive : (chosenMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
        opacity: root.wallpaperMode && root.store.combos.length === 0 ? 0.4 : 1

        Row {
            id: chosenRow
            anchors.centerIn: parent
            spacing: 8

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: root.wallpaperMode ? 30 : 16
                height: 16
                Rectangle {
                    visible: root.wallpaperMode
                    width: 16
                    height: 16
                    radius: 8
                    color: root.store.current ? root.store.current.preview[root.store.tint].island : "transparent"
                    border.width: 1
                    border.color: App.Theme.islandEdge
                }
                Rectangle {
                    x: root.wallpaperMode ? 14 : 0
                    width: 16
                    height: 16
                    radius: 8
                    color: App.Theme.primary
                    border.width: 1
                    border.color: App.Theme.islandEdge
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wallpaperMode ? (root.store.current ? root.store.current.name : "Sin colores") : root.store.color
                color: App.Theme.white
                font.family: root.wallpaperMode ? App.Config.fonts.text : App.Config.fonts.mono
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.open ? "‹" : "›"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
            }
        }
        MouseArea {
            id: chosenMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleColors()
        }
    }

    // Qué hace el modo (o el aviso de Pillow / el error)
    Text {
        anchors.left: modes.right
        anchors.leftMargin: 14
        anchors.right: chosen.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.store.message !== "" ? root.store.message : (!root.store.available && root.wallpaperMode ? "Instala python3-Pillow para usar los colores de la imagen" : root.cfg.modes.find(m => m.id === root.mode).hint)
        color: root.store.message !== "" || (!root.store.available && root.wallpaperMode) ? App.Theme.amber : App.Theme.subtext
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        elide: Text.ElideRight
    }
}
