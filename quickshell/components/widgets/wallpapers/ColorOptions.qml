import QtQuick
import "../controlcenter/" as CC
import "../../../services/theme/" as T
import "../../../" as App

// Encabezado del selector de wallpapers: cómo se colorea la shell. Tres modos:
//   Del wallpaper:        toda la shell toma la paleta de la imagen (intensidad, estilo y color base).
//   Acento del wallpaper: la barra queda como el sistema; solo el acento sale de la imagen (color base).
//   Acento propio:        la barra queda como el sistema; el acento lo eliges tú (muestras).
// Dos filas de alto fijo (los modos y sus opciones), así la isla no cambia de alto al cambiar de modo.
Item {
    id: root

    readonly property var store: T.ThemeStore
    readonly property var cfg: App.Config.theme
    readonly property string mode: store.mode
    // Los dos primeros modos necesitan matugen
    readonly property bool wallpaperMode: mode !== "custom"
    readonly property bool usable: store.available || !wallpaperMode
    // El selector completo está abierto (lo muestra Wallpapers en lugar de la cuadrícula)
    property bool picking: false
    signal togglePicker

    implicitHeight: App.Config.wallpaperPicker.themeRow + App.Config.wallpaperPicker.tintRow

    component Label: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        rightPadding: 2
    }

    // Un punto de color (color base de la imagen o muestra del acento propio)
    component Dot: Rectangle {
        id: dot
        property bool selected: false
        signal clicked

        width: 22
        height: 22
        radius: 11
        border.width: selected ? 2 : 1
        border.color: selected ? App.Theme.white : App.Theme.islandEdge

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: dot.clicked()
        }
    }

    // ── Fila 1: los modos, lo que hace el elegido y el acento que quedó ──
    Item {
        id: top
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: App.Config.wallpaperPicker.themeRow

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

        // El acento que quedó
        Rectangle {
            id: current
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            color: App.Theme.primary
            border.width: 1
            border.color: App.Theme.islandEdge
        }

        // Qué hace el modo (o el aviso de matugen / el error)
        Text {
            anchors.left: modes.right
            anchors.leftMargin: 14
            anchors.right: current.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.store.message !== "" ? root.store.message : (!root.store.available && root.wallpaperMode ? "Instala matugen para usar los colores de la imagen" : root.cfg.modes.find(m => m.id === root.mode).hint)
            color: root.store.message !== "" || (!root.store.available && root.wallpaperMode) ? App.Theme.amber : App.Theme.subtext
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
            elide: Text.ElideRight
        }
    }

    // ── Fila 2: las opciones del modo ──
    Item {
        anchors.top: top.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: App.Config.wallpaperPicker.tintRow
        opacity: root.store.busy ? 0.6 : 1

        // Del wallpaper: intensidad, estilo de la paleta y color base
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.mode === "scheme"
            enabled: root.usable

            Label {
                text: "Intensidad"
            }
            Repeater {
                model: root.cfg.tints
                CC.Chip {
                    required property var modelData
                    height: 28
                    radius: 14
                    label: modelData.label
                    selected: root.store.tint === modelData.id
                    onClicked: root.store.setTint(modelData.id)
                }
            }
            Item {
                width: 10
                height: 1
            }
            Label {
                text: "Estilo"
            }
            Repeater {
                model: root.cfg.schemes
                CC.Chip {
                    required property var modelData
                    height: 28
                    radius: 14
                    label: modelData.label
                    selected: root.store.scheme === modelData.id
                    onClicked: root.store.setScheme(modelData.id)
                }
            }
            Item {
                width: 10
                height: 1
            }
            Label {
                text: "Color base"
            }
            Repeater {
                model: root.store.sources
                Dot {
                    required property int index
                    required property string modelData
                    color: modelData
                    selected: root.store.index === index
                    onClicked: root.store.setSource(index)
                }
            }
        }

        // Acento del wallpaper: cuál de los colores de la imagen
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.mode === "accent"
            enabled: root.usable

            Label {
                text: "Color base de la imagen"
            }
            Repeater {
                model: root.store.sources
                Dot {
                    required property int index
                    required property string modelData
                    color: modelData
                    selected: root.store.index === index
                    onClicked: root.store.setSource(index)
                }
            }
        }

        // Acento propio: muestras y el color elegido
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.mode === "custom"

            Label {
                text: "Acento"
            }
            Repeater {
                model: root.cfg.swatches
                Dot {
                    required property string modelData
                    color: modelData
                    selected: root.store.color === modelData
                    onClicked: root.store.setColor(modelData)
                }
            }
            CC.Chip {
                height: 28
                radius: 14
                label: "+"
                selected: root.picking
                onClicked: root.togglePicker()
            }
            CC.Chip {
                height: 28
                radius: 14
                label: root.store.eyedropping ? "Elige en la pantalla…" : "Gotero"
                onClicked: root.store.pickColor()
            }
            Label {
                leftPadding: 4
                text: root.store.color
                font.family: App.Config.fonts.mono
                color: App.Theme.subtext
            }
        }
    }
}
