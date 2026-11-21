import QtQuick
import "../../controls/" as C
import "../../../services/screenshot/" as S
import "../../../" as App

// Barra de abajo del capturador: Área · Ventana · Pantalla │ ⏱ retardo │ Editor; y, con el Editor y un área
// elegida, Copiar · Guardar · Listo. Al volver a editar una imagen guardada solo salen las acciones.
Rectangle {
    id: root

    readonly property var store: S.ScreenshotStore
    // Hay un área elegida a la que aplicar las acciones
    property bool chosen: false

    implicitWidth: row.implicitWidth + 16
    implicitHeight: App.Config.screenshot.barHeight
    radius: height / 2
    color: App.Theme.island
    border.width: 1
    border.color: App.Theme.border

    function glyph(code) {
        return String.fromCodePoint(code);
    }

    component ModeButton: Rectangle {
        id: mb
        property string glyph: ""
        property string label: ""
        property bool active: false
        signal clicked

        height: root.implicitHeight - 12
        width: mbRow.implicitWidth + 28
        radius: height / 2
        color: active ? Qt.rgba(App.Theme.primary.r, App.Theme.primary.g, App.Theme.primary.b, 0.25) : (mbMouse.containsMouse ? App.Theme.surfaceActive : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }

        Row {
            id: mbRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: mb.glyph !== ""
                text: mb.glyph
                color: mb.active ? App.Theme.primary : App.Theme.white
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.iconLg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: mb.label
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                font.weight: mb.active ? Font.DemiBold : Font.Medium
            }
        }
        MouseArea {
            id: mbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.clicked()
        }
    }

    component Sep: Rectangle {
        width: 1
        height: 24
        color: App.Theme.islandEdge
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // ── Qué capturar ──
        ModeButton {
            visible: root.store.editSource === ""
            glyph: root.glyph(0xf019e)
            label: "Área"
            active: root.store.mode === "area"
            onClicked: root.store.setMode("area")
        }
        ModeButton {
            visible: root.store.editSource === ""
            glyph: root.glyph(0xf05af)
            label: "Ventana"
            active: root.store.mode === "window"
            onClicked: root.store.setMode("window")
        }
        ModeButton {
            visible: root.store.editSource === ""
            glyph: root.glyph(0xf0379)
            label: "Pantalla"
            active: root.store.mode === "screen"
            onClicked: root.store.setMode("screen")
        }
        ModeButton {
            visible: root.store.editSource === ""
            glyph: root.glyph(0xf113d)
            label: "Texto"
            active: root.store.mode === "text"
            onClicked: root.store.setMode("text")
        }

        Sep {
            visible: root.store.editSource === ""
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Retardo ──
        ModeButton {
            visible: root.store.editSource === ""
            glyph: root.glyph(0xf051b)
            label: root.store.delay > 0 ? root.store.delay + " s" : "Retardo"
            active: root.store.delay > 0
            onClicked: root.store.cycleDelay()
        }

        Sep {
            visible: root.store.editSource === ""
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Editor ──
        Row {
            visible: root.store.editSource === ""
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
                text: "Editor"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                font.weight: Font.Medium
            }
            C.Switch {
                anchors.verticalCenter: parent.verticalCenter
                checked: root.store.cfg.editor
                onToggled: function (on) {
                    root.store.setEditor(on);
                }
            }
            Item {
                width: 4
                height: 1
            }
        }

        // ── Con un área elegida ──
        Sep {
            visible: root.store.editorOn && root.chosen
            anchors.verticalCenter: parent.verticalCenter
        }
        ModeButton {
            visible: root.store.editorOn && root.chosen
            glyph: root.glyph(0xf113d)
            label: "Texto"
            onClicked: root.store.actionRequested("text")
        }
        ModeButton {
            visible: root.store.editorOn && root.chosen
            glyph: root.glyph(0xf018f)
            label: "Copiar"
            onClicked: root.store.actionRequested("copy")
        }
        ModeButton {
            visible: root.store.editorOn && root.chosen
            glyph: root.glyph(0xf0193)
            label: "Guardar"
            onClicked: root.store.actionRequested("save")
        }
        Rectangle {
            visible: root.store.editorOn && root.chosen
            height: root.implicitHeight - 12
            width: doneRow.implicitWidth + 32
            radius: height / 2
            color: doneMouse.containsMouse ? Qt.lighter(App.Theme.primary, 1.12) : App.Theme.primary
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: doneRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph(0xf012c)
                    color: App.Theme.onPrimary
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.iconLg
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Listo"
                    color: App.Theme.onPrimary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg
                    font.weight: Font.DemiBold
                }
            }
            MouseArea {
                id: doneMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.store.actionRequested("both")
            }
        }
        // Volver a editar una imagen: cancelar
        ModeButton {
            visible: root.store.editSource !== ""
            glyph: root.glyph(0xf0156)
            label: "Cancelar"
            onClicked: root.store.cancel()
        }
    }
}
