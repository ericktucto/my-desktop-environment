import QtQuick
import "../../controls/" as C
import "../../../services/notify/" as S
import "../../../" as App

// Panel de la pill de notificaciones: botones arriba, historial debajo.
Column {
    id: root

    readonly property var cfg: App.Config.notifications
    readonly property int total: S.NotificationStore.history.length
    property bool confirming: false

    spacing: 12

    // Botón redondo del encabezado
    component HeaderButton: Rectangle {
        id: btn

        property url icon
        property color fill: Qt.rgba(1, 1, 1, 0.06)
        property bool active: true
        signal clicked

        width: root.cfg.headerHeight
        height: width
        radius: width / 2
        color: fill
        opacity: active ? 1 : 0.4

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.control
            }
        }

        // Aclara el fondo con el hover
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(1, 1, 1, btnMouse.containsMouse && btn.active ? 0.08 : 0)
        }

        C.IconSvg {
            anchors.centerIn: parent
            source: btn.icon
            size: root.cfg.headerIconSize
            color: App.Theme.white
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.active
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // Si el historial se vacía, se cancela la confirmación
    onTotalChanged: if (total === 0)
        confirming = false

    Timer {
        id: confirmTimer
        interval: root.cfg.clearConfirm
        onTriggered: root.confirming = false
    }

    // ── Encabezado: No molestar · contador · Limpiar ──
    Row {
        id: header
        width: parent.width
        height: root.cfg.headerHeight
        spacing: 8

        HeaderButton {
            icon: Qt.resolvedUrl("../../../assets/svg/" + (S.NotificationStore.dnd ? "notification-off" : "notification-on") + ".svg")
            fill: S.NotificationStore.dnd ? App.Theme.primary : Qt.rgba(1, 1, 1, 0.06)
            onClicked: S.NotificationStore.setDnd(!S.NotificationStore.dnd)
        }

        Rectangle {
            width: header.width - 2 * root.cfg.headerHeight - 2 * header.spacing
            height: root.cfg.headerHeight
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.06)

            Text {
                anchors.centerIn: parent
                text: {
                    if (root.confirming)
                        return "¿Borrar todo?";
                    if (root.total === 0)
                        return "Sin notificaciones";
                    return root.total === 1 ? "1 notificación" : root.total + " notificaciones";
                }
                color: root.confirming ? App.Theme.red : App.Theme.white
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.Medium
            }
        }

        HeaderButton {
            icon: Qt.resolvedUrl("../../../assets/svg/clear.svg")
            fill: root.confirming ? App.Theme.red : Qt.rgba(1, 1, 1, 0.06)
            active: root.total > 0
            onClicked: {
                if (root.confirming) {
                    confirmTimer.stop();
                    root.confirming = false;
                    S.NotificationStore.clearAll();
                } else {
                    root.confirming = true;
                    confirmTimer.restart();
                }
            }
        }
    }

    NotifyList {
        width: parent.width
        visible: root.total > 0
    }
}
