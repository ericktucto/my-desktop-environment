import QtQuick
import "../../controls/" as C
import "../../../services/theme/" as T
import "../../../" as App

// Fila de arriba del selector de wallpapers: colores dinámicos (matugen). Switch, estilo y color fuente.
Item {
    id: root

    readonly property var store: T.ThemeStore
    readonly property bool usable: store.available && store.dynamic

    implicitHeight: App.Config.wallpaperPicker.themeRow + App.Config.wallpaperPicker.tintRow

    // Pill de una opción (estilo o nivel de color)
    component ChoicePill: Rectangle {
        id: pill
        property string label
        property bool active: false
        signal picked

        height: 28
        width: txt.implicitWidth + 24
        radius: 14
        color: active ? App.Theme.primary : (pm.containsMouse && root.store.dynamic ? App.Theme.surfaceActive : App.Theme.surface)

        Text {
            id: txt
            anchors.centerIn: parent
            text: pill.label
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: pill.active ? Font.DemiBold : Font.Medium
        }
        MouseArea {
            id: pm
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.store.dynamic
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.picked()
        }
    }

    // Alto de la primera fila (switch, estilos y colores fuente)
    Item {
        id: topRow
        anchors.top: parent.top
        width: 1
        height: App.Config.wallpaperPicker.themeRow
    }

    Row {
        id: left
        anchors.verticalCenter: topRow.verticalCenter
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Colores del wallpaper"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        C.Switch {
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.store.available
            opacity: root.store.available ? 1 : 0.4
            checked: root.store.dynamic
            onToggled: function (on) {
                root.store.setDynamic(on);
            }
        }
    }

    // Estilo (o el aviso, si no hay matugen o falló)
    Row {
        id: schemes
        anchors.left: left.right
        anchors.leftMargin: 20
        anchors.verticalCenter: topRow.verticalCenter
        spacing: 6
        visible: root.store.available && root.store.message === ""
        opacity: root.store.dynamic ? 1 : 0.35

        Repeater {
            model: App.Config.theme.schemes
            delegate: ChoicePill {
                required property var modelData
                label: modelData.label
                active: root.store.scheme === modelData.id
                onPicked: root.store.setScheme(modelData.id)
            }
        }
    }
    Text {
        anchors.left: left.right
        anchors.leftMargin: 20
        anchors.verticalCenter: topRow.verticalCenter
        visible: !schemes.visible
        text: root.store.message !== "" ? root.store.message : "Instala matugen para usar los colores del wallpaper"
        color: App.Theme.amber
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    // Colores que matugen encuentra en el wallpaper: el elegido manda
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: topRow.verticalCenter
        spacing: 8
        opacity: root.usable ? (root.store.busy ? 0.5 : 1) : 0.35

        Repeater {
            model: root.store.sources
            delegate: Rectangle {
                id: chip
                required property int index
                required property string modelData
                width: 24
                height: 24
                radius: 12
                color: modelData
                border.width: root.store.index === index ? 2 : 1
                border.color: root.store.index === index ? App.Theme.white : App.Theme.islandEdge

                MouseArea {
                    anchors.fill: parent
                    enabled: root.usable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.setSource(chip.index)
                }
            }
        }
    }

    // Cuánto se colorea la shell con la paleta del wallpaper
    Row {
        anchors.top: topRow.bottom
        anchors.left: parent.left
        height: App.Config.wallpaperPicker.tintRow
        spacing: 10
        opacity: root.store.dynamic ? 1 : 0.35

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Colorear"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Repeater {
            model: App.Config.theme.tints
            delegate: ChoicePill {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                label: modelData.label
                active: root.store.tint === modelData.id
                onPicked: root.store.setTint(modelData.id)
            }
        }
    }
}
