import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services/region/" as RG
import "../../../" as App

// Selector de región (grabador y VPN): una ventana a pantalla completa por monitor, con el escritorio oscurecido.
// Se arrastra para marcar el área (y se puede mover o cambiar de tamaño desde los bordes y las esquinas);
// el botón Aceptar (o Enter) la confirma y Esc cancela. El marco es RegionFrame.
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: win

        required property var modelData
        screen: modelData
        visible: RG.RegionStore.picking

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Confirma el área marcada en esta pantalla (el id del botón se llama accept: de ahí el nombre)
        function acceptSel() {
            const s = frame.sel;
            if (frame.has)
                RG.RegionStore.accept(win.modelData.name, win.modelData.x + s.x, win.modelData.y + s.y, s.width, s.height);
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "stixshell-region"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: root
            anchors.fill: parent
            focus: true

            // Área elegida, en coordenadas de esta pantalla
            readonly property rect sel: frame.sel
            readonly property bool has: frame.has

            Keys.onEscapePressed: RG.RegionStore.cancel()
            Keys.onReturnPressed: win.acceptSel()
            Keys.onEnterPressed: win.acceptSel()

            // Al abrir, vuelve a marcarse la región anterior (si era de esta pantalla)
            Connections {
                target: RG.RegionStore
                function onPickingChanged() {
                    if (!RG.RegionStore.picking)
                        return;
                    const r = RG.RegionStore.initial;
                    frame.sel = r && r.screen === win.modelData.name ? Qt.rect(r.x - win.modelData.x, r.y - win.modelData.y, r.w, r.h) : Qt.rect(0, 0, 0, 0);
                    root.forceActiveFocus();
                }
            }

            RegionFrame {
                id: frame
                anchors.fill: parent
            }

            // ── Barra de abajo: solo Aceptar ──
            Rectangle {
                id: bar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 56
                width: accept.width + 16
                height: 52
                radius: height / 2
                color: App.Theme.island
                border.width: 1
                border.color: App.Theme.border

                Rectangle {
                    id: accept
                    anchors.centerIn: parent
                    width: acceptRow.implicitWidth + 40
                    height: parent.height - 12
                    radius: height / 2
                    color: !root.has ? App.Theme.surface : (acceptMouse.containsMouse ? Qt.lighter(App.Theme.primary, 1.12) : App.Theme.primary)
                    opacity: root.has ? 1 : 0.5

                    Behavior on color {
                        ColorAnimation {
                            duration: App.Config.anim.control
                        }
                    }

                    Row {
                        id: acceptRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xf012c)
                            color: App.Theme.white
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.iconLg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Aceptar"
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.lg
                            font.weight: Font.DemiBold
                        }
                    }
                    MouseArea {
                        id: acceptMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.has
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.acceptSel()
                    }
                }
            }
        }
    }
}
