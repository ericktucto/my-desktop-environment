import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../base" as Base
import "../../" as App

// Pill del system tray. Nunca se expande (no tiene body).
// Chevron a la izquierda: pliega los íconos y deja solo la cantidad.
Base.Island {
    id: root

    // El ancho de la pill sigue al contenido, que ya se anima por dentro
    animateWidth: false

    // Sin íconos en la bandeja la pill desaparece (el Row de la barra ignora lo invisible)
    visible: count > 0

    // Siempre arranca con los íconos visibles (no se persiste)
    property bool shown: true

    readonly property int count: SystemTray.items.values.length
    readonly property int gap: App.Config.pill.contentSpacing

    // Un solo hijo: así el spacing del Row de Island no interviene y los huecos
    // (gap) van dentro de los tramos animados, sin dejar espacio cuando miden 0.
    Row {
        spacing: 0

        // ── Chevron ──
        Text {
            id: chevron
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(root.shown ? 0xf053 : 0xf054)   //  /
            font.family: "Symbols Nerd Font"
            font.pixelSize: App.Config.fontSize.sm
            color: App.Theme.white
            opacity: chevronMouse.containsMouse ? 1 : 0.8

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shown = !root.shown
            }
        }

        // ── Íconos: su ancho va de 0 a su ancho real ──
        Item {
            height: iconsRow.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            width: root.shown ? iconsRow.implicitWidth + root.gap : 0
            opacity: root.shown ? 1 : 0

            Behavior on width {
                NumberAnimation {
                    duration: App.Config.anim.pill
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: App.Config.anim.pill
                }
            }

            Row {
                id: iconsRow
                x: root.gap
                spacing: root.gap

                Repeater {
                    model: SystemTray.items
                    delegate: TrayItem {}
                }
            }
        }

        // ── Contador: su ancho va de 0 a su ancho real ──
        Item {
            height: countText.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            width: root.shown ? 0 : countText.implicitWidth + root.gap
            opacity: root.shown ? 0 : 1

            Behavior on width {
                NumberAnimation {
                    duration: App.Config.anim.pill
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: App.Config.anim.pill
                }
            }

            Text {
                id: countText
                x: root.gap
                text: root.count
                color: App.Theme.white
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
        }
    }

    // Plegada: un clic en cualquier parte de la pill la despliega.
    // Con los íconos visibles se desactiva y solo el chevron pliega
    // (así los clics llegan a los íconos).
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: !root.shown
        cursorShape: Qt.PointingHandCursor
        onClicked: root.shown = true
    }
}
