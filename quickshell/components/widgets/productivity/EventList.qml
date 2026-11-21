import QtQuick
import "../controlcenter/" as CC
import "../../../services/calendar/" as CS
import "../../../" as App

// Lista de eventos del día elegido: arriba el día y "+ Evento"; debajo los eventos (y feriados)
// y, si hace falta, el aviso para conectar con Google.
Item {
    id: root

    readonly property var store: CS.CalendarStore
    readonly property bool sample: App.Config.calendar.testSample !== ""
    readonly property var items: store.eventsOn(store.selectedKey)

    signal closeRequested

    // Lo que se dice bajo los eventos: "" = nada
    readonly property string notice: {
        if (sample)
            return "";
        if (!store.hasClient)
            return "Falta el cliente de Google. Mira «Google Calendar» en el README.";
        if (!store.connected)
            return "Conecta tu cuenta de Google para ver tus eventos";
        if (store.error === "expired")
            return "Vuelve a conectar con Google";
        return "";
    }
    readonly property bool canLogin: !sample && store.hasClient && (!store.connected || store.error === "expired")
    readonly property string status: {
        if (store.error === "offline")
            return "Sin conexión" + (store.updated > 0 ? " · actualizado " + store.timeText(store.updated) : "");
        if (store.error !== "" && store.error !== "expired" && store.error !== "no-token" && store.error !== "no-client")
            return store.error;
        return "";
    }

    // Al desplegar un evento, la lista lo sube hasta arriba para que se vean sus botones
    function showExpanded() {
        const id = store.expandedId;
        if (id === "")
            return;
        const i = items.findIndex(e => e.id === id);
        const it = i >= 0 ? rep.itemAt(i) : null;
        if (it)
            flick.contentY = Math.max(0, Math.min(it.y, flick.contentHeight - flick.height));
    }

    Connections {
        target: root.store
        function onExpandedIdChanged() {
            Qt.callLater(root.showExpanded);
        }
    }

    function collapse() {
        if (store.expandedId === "")
            return false;
        store.expandedId = "";
        return true;
    }

    Item {
        id: head
        width: parent.width
        height: 26

        Text {
            id: dayLabel
            anchors.verticalCenter: parent.verticalCenter
            text: (root.store.selectedKey === root.store.todayKey ? "HOY · " : "") + root.store.longDate(root.store.selected).toUpperCase()
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }
        Text {
            anchors.left: dayLabel.right
            anchors.leftMargin: 12
            anchors.right: newButton.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.status
            elide: Text.ElideRight
            color: root.store.error === "offline" ? App.Theme.gray : App.Theme.amber
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
        Rectangle {
            id: newButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: newText.implicitWidth + 24
            height: 24
            radius: 12
            color: newMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface
            Text {
                id: newText
                anchors.centerIn: parent
                text: "+ Evento"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: newMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.store.newEventOnSelected();
                    root.closeRequested();
                }
            }
        }
    }

    Flickable {
        id: flick
        y: head.height + 6
        width: parent.width
        height: parent.height - y
        contentWidth: width
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: flick.width
            spacing: 2

            Repeater {
                id: rep
                model: root.items
                EventItem {
                    required property var modelData
                    ev: modelData
                    width: list.width
                    onCloseRequested: root.closeRequested()
                }
            }

            Text {
                visible: root.items.length === 0 && root.notice === ""
                width: parent.width
                topPadding: 18
                horizontalAlignment: Text.AlignHCenter
                text: "Sin eventos"
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }

            Column {
                visible: root.notice !== ""
                width: parent.width
                topPadding: root.items.length === 0 ? 14 : 8
                spacing: 8
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.notice
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
                CC.SmallButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.canLogin
                    primary: !root.store.loggingIn
                    label: root.store.loggingIn ? "Esperando al navegador…" : "Conectar con Google"
                    onClicked: root.store.login()
                }
            }
        }
    }
}
