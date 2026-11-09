import QtQuick
import "../widgets/session/" as SE
import "../../services/session/" as S
import "../../" as App

// Suspender · Reiniciar · Apagar desde la pantalla de bloqueo. Reiniciar y apagar piden un
// segundo clic (el botón se pone rojo unos segundos), como en el menú de sesión.
Row {
    id: root

    spacing: App.Config.lock.powerSpacing

    // índice del botón que espera confirmación (-1 = ninguno)
    property int armedIndex: -1

    readonly property var items: [
        {
            id: "suspend",
            confirm: false
        },
        {
            id: "reboot",
            confirm: true
        },
        {
            id: "poweroff",
            confirm: true
        }
    ]

    function actionFor(id) {
        return S.SessionStore.actions.find(a => a.id === id);
    }

    Timer {
        id: confirmTimer
        interval: App.Config.lock.confirmTimeout
        onTriggered: root.armedIndex = -1
    }

    Repeater {
        model: root.items

        SE.SessionButton {
            required property var modelData
            required property int index
            readonly property var action: root.actionFor(modelData.id)

            icon: action.icon
            text: action.text
            armedText: action.confirmText
            armed: root.armedIndex === index
            onHovered: if (root.armedIndex !== index)
                root.armedIndex = -1
            onClicked: {
                if (modelData.confirm && root.armedIndex !== index) {
                    root.armedIndex = index;
                    confirmTimer.restart();
                    return;
                }
                confirmTimer.stop();
                root.armedIndex = -1;
                S.SessionStore.run(modelData.id);
            }
        }
    }
}
