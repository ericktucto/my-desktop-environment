import QtQuick
import "../controlcenter/" as CC
import "../../../services/theme/" as T
import "../../../" as App

// La vista de colores del selector de wallpapers (reemplaza la cuadrícula, como las vistas Wi-Fi y Bluetooth del centro
// de control): con «Del wallpaper», los colores de la imagen y sus combinaciones; con «Acento propio», el selector de color.
// ‹ o Esc vuelven a la cuadrícula. ← → recorren las combinaciones (y las aplican) y 1 a 6 eligen una.
FocusScope {
    id: root

    readonly property var store: T.ThemeStore
    readonly property bool wallpaperMode: store.mode !== "custom"

    signal back

    function giveFocus() {
        forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (event.modifiers !== Qt.NoModifier || !root.wallpaperMode)
            return;
        if (event.key === Qt.Key_Left)
            root.store.stepCombo(-1);
        else if (event.key === Qt.Key_Right)
            root.store.stepCombo(1);
        else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6 && root.store.combos[event.key - Qt.Key_1])
            root.store.setCombo(root.store.combos[event.key - Qt.Key_1].id);
        else
            return;
        event.accepted = true;
    }

    CC.PageHeader {
        id: head
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        title: root.wallpaperMode ? "Colores del wallpaper" : "Acento propio"
        subtitle: root.wallpaperMode ? (root.store.image.split("/").pop()) : "Solo cambia el acento; los fondos son los del sistema."
        showSwitch: false
        onBackRequested: root.back()
    }

    // ── Del wallpaper ──
    Column {
        visible: root.wallpaperMode
        anchors.top: head.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // Los colores de la imagen, de ancho según cuánto ocupan
        Row {
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                text: "Paleta"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Row {
                id: strip
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                readonly property real avail: root.width - 64 - 10 - 2 * Math.max(0, root.store.palette.length - 1)
                readonly property real total: root.store.palette.reduce((a, p) => a + Math.max(p.share, 0.03), 0)
                Repeater {
                    model: root.store.palette
                    Rectangle {
                        required property var modelData
                        width: Math.max(8, strip.avail * Math.max(modelData.share, 0.03) / strip.total)
                        height: 22
                        radius: 5
                        color: modelData.hex
                        border.width: 1
                        border.color: App.Theme.islandEdge
                    }
                }
            }
        }

        // Las combinaciones
        Row {
            id: cards
            spacing: 10
            readonly property int n: Math.max(1, root.store.combos.length)
            readonly property real cardW: Math.min(150, (root.width - spacing * (n - 1)) / n)
            Repeater {
                model: root.store.combos
                ComboCard {
                    required property var modelData
                    width: cards.cardW
                    combo: modelData
                    tint: root.store.tint
                    selected: root.store.combo === modelData.id
                    onClicked: root.store.setCombo(modelData.id)
                }
            }
        }

        // Qué tan teñido sale el fondo
        Row {
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                text: "Intensidad"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                model: App.Config.theme.tints
                CC.Chip {
                    required property var modelData
                    height: 28
                    radius: 14
                    label: modelData.label
                    selected: root.store.tint === modelData.id
                    onClicked: root.store.setTint(modelData.id)
                }
            }
        }
    }

    // ── Acento propio ──
    ColorPicker {
        visible: !root.wallpaperMode
        anchors.top: head.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        value: root.store.color
        swatches: App.Config.theme.swatches
        eyedropping: root.store.eyedropping
        onPicked: hex => root.store.setColor(hex)
        onEyedropper: root.store.pickColor()
    }
}
