import QtQuick
import "../../controls/" as C
import "../../../services/bluetooth/" as BT
import "../../../" as App

// Vista de Bluetooth del centro de control: encabezado con el switch, la pregunta del agente, los dispositivos
// emparejados y los disponibles. Teclado: ↑ ↓, Enter (conectar, desconectar o emparejar), Supr (olvidar, dos veces)
// y F2 (renombrar). Esc lo maneja el centro de control (back()).
FocusScope {
    id: root

    signal backRequested

    readonly property var store: BT.BluetoothStore
    readonly property var rows: store.paired.concat(store.discovered)
    // Fila elegida con el teclado (-1 = ninguna)
    property int current: -1

    onRowsChanged: current = Math.min(current, rows.length - 1)
    onVisibleChanged: {
        if (visible) {
            current = -1;
            forceActiveFocus();
        }
    }

    function rowItem(i) {
        const n = store.paired.length;
        return i < n ? pairedRep.itemAt(i) : foundRep.itemAt(i - n);
    }

    // Cancela un renombrado en curso; true si había uno
    function cancelRename() {
        for (const rep of [pairedRep, foundRep])
            for (let i = 0; i < rep.count; i++) {
                const r = rep.itemAt(i);
                if (r && r.renaming) {
                    r.cancelRename();
                    root.forceActiveFocus();
                    return true;
                }
            }
        return false;
    }

    readonly property bool renamingAny: {
        for (const rep of [pairedRep, foundRep])
            for (let i = 0; i < rep.count; i++)
                if (rep.itemAt(i)?.renaming)
                    return true;
        return false;
    }

    function ensureVisible(item) {
        if (!item)
            return;
        const y = item.mapToItem(flick.contentItem, 0, 0).y;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + item.height > flick.contentY + flick.height)
            flick.contentY = y + item.height - flick.height;
    }

    Keys.onPressed: function (event) {
        if (renamingAny || rows.length === 0)
            return;
        switch (event.key) {
        case Qt.Key_Down:
            current = Math.min(rows.length - 1, current + 1);
            ensureVisible(rowItem(current));
            break;
        case Qt.Key_Up:
            current = Math.max(0, current - 1);
            ensureVisible(rowItem(current));
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (current >= 0)
                store.activate(rows[current]);
            break;
        case Qt.Key_Delete:
            if (current >= 0)
                rowItem(current)?.askForget();
            break;
        case Qt.Key_F2:
            if (current >= 0)
                rowItem(current)?.startRename();
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    component Section: Text {
        color: App.Theme.gray
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    // ── Encabezado: ‹ · Bluetooth · switch ──
    Item {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 46

        Rectangle {
            id: back
            width: 34
            height: 34
            radius: 17
            anchors.verticalCenter: parent.verticalCenter
            color: backMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xf0141)
                color: App.Theme.white
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.iconLg
            }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }

        Column {
            anchors.left: back.right
            anchors.leftMargin: 12
            anchors.right: toggle.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "Bluetooth"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg + 2
                font.weight: Font.DemiBold
            }
            Text {
                visible: root.store.enabled && root.store.hostName !== ""
                width: parent.width
                text: "Visible como «" + root.store.hostName + "»"
                elide: Text.ElideRight
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        C.Switch {
            id: toggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.store.enabled
            opacity: root.store.available && !root.store.busy ? 1 : 0.4
            onToggled: root.store.toggle()
        }
    }

    // ── Mensaje corto y pregunta del agente ──
    Column {
        id: top
        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width
        spacing: 10

        Text {
            visible: root.store.message !== ""
            width: parent.width
            text: root.store.message
            color: App.Theme.orange
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        BluetoothRequest {
            visible: root.store.request !== null
            width: parent.width
        }
    }

    // ── Estado sin lista ──
    Text {
        visible: !root.store.available || !root.store.enabled
        anchors.centerIn: parent
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: !root.store.available ? "Sin adaptador de Bluetooth" : (root.store.blocked ? "Bloqueado por rfkill. Enciende el switch para desbloquearlo." : "Bluetooth apagado")
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }

    // ── Listas (se desplazan dentro del alto fijo de la vista) ──
    Flickable {
        id: flick
        visible: root.store.available && root.store.enabled
        anchors.top: top.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        contentWidth: width
        contentHeight: lists.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: lists
            width: flick.width
            spacing: 4

            Item {
                width: parent.width
                height: 26
                Section {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DISPOSITIVOS EMPAREJADOS"
                }
            }
            Text {
                visible: root.store.paired.length === 0
                width: parent.width
                leftPadding: 4
                bottomPadding: 6
                text: "Ninguno todavía"
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                id: pairedRep
                model: root.store.paired
                delegate: BluetoothRow {
                    required property var modelData
                    required property int index
                    device: modelData
                    width: lists.width
                    selected: root.current === index
                    // El foco primero: renombrar reordena la lista y destruye esta fila
                    onRename: name => {
                        const page = root;
                        page.forceActiveFocus();
                        page.store.rename(device, name);
                    }
                }
            }

            Item {
                width: parent.width
                height: 34
                Section {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.store.scanning ? "DISPONIBLES (BUSCANDO…)" : "DISPONIBLES"
                }
                // Buscar de nuevo (y volver a ser visible)
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: scanMouse.containsMouse ? App.Theme.surfaceActive : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(0xf0450)
                        color: root.store.scanning ? App.Theme.primary : App.Theme.gray
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.icon
                    }
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.store.scan()
                    }
                }
            }
            Text {
                visible: root.store.discovered.length === 0 && !root.store.scanning
                width: parent.width
                leftPadding: 4
                text: "No se encontró nada cerca"
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                id: foundRep
                model: root.store.discovered
                delegate: BluetoothRow {
                    required property var modelData
                    required property int index
                    device: modelData
                    width: lists.width
                    selected: root.current === root.store.paired.length + index
                }
            }
        }
    }
}
