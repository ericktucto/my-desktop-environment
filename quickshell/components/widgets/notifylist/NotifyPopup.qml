import QtQuick
import "../../../services/notify/" as S
import "../../../" as App

// Un popup: la tarjeta con animación de entrada/salida y cierre automático.
// Cerrarlo solo lo oculta; la entrada sigue en el historial.
Item {
    id: root

    required property string modelData

    readonly property var cfg: App.Config.notifications
    readonly property var entry: S.NotificationStore.entry(modelData)
    readonly property bool critical: entry ? entry.urgency === 2 : false

    // 0 = fuera (a la derecha, transparente), 1 = en su lugar
    property real shown: 0
    property bool closing: false

    width: cfg.popupWidth
    height: card.height
    opacity: shown

    // Sale con animación y luego se oculta del store
    function close() {
        if (closing)
            return;
        closing = true;
        exitAnim.start();
    }

    Component.onCompleted: enterAnim.start()

    NumberAnimation {
        id: enterAnim
        target: root
        property: "shown"
        to: 1
        duration: App.Config.anim.pill
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: exitAnim
        target: root
        property: "shown"
        to: 0
        duration: App.Config.anim.pill
        easing.type: Easing.InCubic
        onFinished: S.NotificationStore.hidePopup(root.modelData)
    }

    NotifyItem {
        id: card
        modelData: root.modelData
        popup: true
        width: root.width
        x: (1 - root.shown) * 40

        onCloseRequested: root.close()
        onRightClicked: root.close()
        onActivated: S.NotificationStore.activate(root.modelData)
    }

    HoverHandler {
        id: hover
    }

    // Las críticas no se cierran solas. Con el mouse encima el tiempo se detiene
    // y al salir vuelve a contar desde cero.
    Timer {
        // expireTimeout viene en ms (-1 = la app no indicó uno)
        interval: root.entry && root.entry.expireTimeout > 0 ? root.entry.expireTimeout : root.cfg.popupTimeout
        running: !root.critical && !hover.hovered && !root.closing && !card.expanded && root.shown >= 1
        onTriggered: root.close()
    }
}
