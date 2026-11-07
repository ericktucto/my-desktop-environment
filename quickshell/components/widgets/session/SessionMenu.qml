import QtQuick
import "../../../services/session/" as S
import "../../../" as App

// Menú de sesión: fila de botones, flechas + Enter.
FocusScope {
    id: root

    readonly property var cfg: App.Config.session
    property int currentIndex: cfg.defaultIndex
    property int armedIndex: -1

    signal chosen(string id)

    function move(delta) {
        const n = Math.max(0, Math.min(S.SessionStore.actions.length - 1, currentIndex + delta));
        select(n);
    }

    function select(i) {
        if (i !== currentIndex) {
            currentIndex = i;
            disarm();
        }
    }

    function disarm() {
        armedIndex = -1;
        confirmTimer.stop();
    }

    function activate(i) {
        const a = S.SessionStore.actions[i];
        if (a.confirm && armedIndex !== i) {
            armedIndex = i;
            confirmTimer.restart();
            return;
        }
        disarm();
        chosen(a.id);
    }

    onVisibleChanged: {
        if (visible) {
            currentIndex = cfg.defaultIndex;
            disarm();
            forceActiveFocus();
        }
    }

    Timer {
        id: confirmTimer
        interval: root.cfg.confirmTimeout
        onTriggered: root.armedIndex = -1
    }

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Up:
            move(-1);
            break;
        case Qt.Key_Right:
        case Qt.Key_Down:
            move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            activate(currentIndex);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    Row {
        anchors.centerIn: parent
        spacing: root.cfg.spacing

        Repeater {
            model: S.SessionStore.actions

            SessionButton {
                required property var modelData
                required property int index
                icon: modelData.icon
                text: modelData.text
                armedText: modelData.confirmText
                selected: root.currentIndex === index
                armed: root.armedIndex === index
                onHovered: root.select(index)
                onClicked: {
                    root.select(index);
                    root.activate(index);
                }
            }
        }
    }
}
