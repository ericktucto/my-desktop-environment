import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Vista de red del centro de control: Wi-Fi (switch, redes, buscar, red oculta), conexión por cable y VPN de
// WireGuard y OpenVPN (conectar, borrar y agregar desde un archivo, una imagen con QR, el portapapeles o la pantalla).
// ⚙ en una red abre sus detalles (IP, DNS, QR); una red de empresa abre el formulario 802.1X.
// Teclado: ↑ ↓, Enter (conectar o desconectar) y Supr (olvidar o borrar, dos veces). Esc: ControlCenter.back().
FocusScope {
    id: root

    signal backRequested

    readonly property var store: NS.NetworkStore
    // Fila elegida con el teclado: primero las redes y luego las VPN (-1 = ninguna)
    property int current: -1
    property bool menuOpen: false
    property bool hiddenOpen: false
    // Las 6 mejores (la conectada y las guardadas primero); "Mostrar todas" despliega el resto
    property bool showAll: false
    readonly property int netCount: store.enabled ? (showAll ? store.order.count : Math.min(6, store.order.count)) : 0
    readonly property int total: netCount + store.vpns.length
    // Mientras se escribe algo (contraseña, red oculta, nombre de la VPN) las flechas no mueven la selección
    readonly property bool typing: store.passwordFor !== "" || hiddenOpen || store.pending !== null || store.enterpriseFor !== "" || store.details !== null

    // La pantalla de contraseña es corta: la isla se ajusta a su alto en vez de dejar el de la vista principal
    readonly property bool compact: store.passwordFor !== "" && store.details === null
    readonly property real compactHeight: header.height + 10 + top.height + 10 + passwordScreen.implicitHeight

    // Bajo el título de la pantalla de contraseña: "Segura · WPA2 · señal 72 %"
    readonly property string passwordSubtitle: {
        const n = store.byName[store.passwordFor];
        return n ? store.securityText(n) + " · señal " + Math.round(n.signalStrength * 100) + " %" : "";
    }

    onTotalChanged: current = Math.min(current, total - 1)
    onVisibleChanged: {
        if (visible) {
            current = -1;
            menuOpen = false;
            showAll = false;
            forceActiveFocus();
        }
    }

    function rowItem(i) {
        return i < netCount ? netRep.itemAt(i) : vpnRep.itemAt(i - netCount);
    }

    // Cierra lo que esté abierto (contraseña, menú, formulario, tarjeta de VPN); true si había algo
    function cancelInner() {
        if (store.pending) {
            store.cancelImport();
        } else if (store.enterpriseFor !== "") {
            store.cancelEnterprise();
        } else if (store.share) {
            store.closeShare();
        } else if (store.details) {
            store.closeDetails();
        } else if (hiddenOpen) {
            hiddenOpen = false;
        } else if (menuOpen) {
            menuOpen = false;
        } else if (store.passwordFor !== "") {
            store.closePassword();
        } else {
            return false;
        }
        root.forceActiveFocus();
        return true;
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
        if (typing || total === 0)
            return;
        switch (event.key) {
        case Qt.Key_Down:
            current = Math.min(total - 1, current + 1);
            ensureVisible(rowItem(current));
            break;
        case Qt.Key_Up:
            current = Math.max(0, current - 1);
            ensureVisible(rowItem(current));
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (current >= 0 && current < netCount)
                store.activate(store.byName[store.order.get(current).name]);
            else if (current >= netCount)
                store.toggleVpn(store.vpns[current - netCount]);
            break;
        case Qt.Key_Delete:
            if (current >= 0)
                rowItem(current)?.askForget();
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

    // Botón de texto con glifo (Buscar de nuevo, Red oculta, Agregar VPN…)
    component Action: Rectangle {
        id: act
        property string glyph: ""
        property string label: ""
        signal clicked
        width: row.implicitWidth + 24
        height: 34
        radius: 17
        color: m.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: act.glyph
                color: App.Theme.white
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: act.label
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: act.clicked()
        }
    }

    // ── Encabezado ──
    PageHeader {
        id: header
        anchors.top: parent.top
        width: parent.width
        title: root.store.details ? root.store.details.title : (root.store.passwordFor !== "" ? root.store.passwordFor : "Red")
        subtitle: root.store.details ? "" : (root.store.passwordFor !== "" ? root.passwordSubtitle : (root.store.enabled && root.store.current ? root.store.current.name : ""))
        showSwitch: root.store.details === null && root.store.passwordFor === ""
        checked: root.store.enabled
        switchEnabled: root.store.wifiAvailable && !root.store.blocked
        onBackRequested: root.store.details || root.store.passwordFor !== "" ? root.cancelInner() : root.backRequested()
        onToggled: root.store.toggle()
    }

    // ── Mensaje corto, tarjeta de la VPN y formulario de red oculta ──
    Column {
        id: top
        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width
        spacing: 10

        Text {
            visible: root.store.message !== "" || root.store.reading
            width: parent.width
            text: root.store.message !== "" ? root.store.message : "Leyendo la configuración…"
            color: root.store.message !== "" ? App.Theme.orange : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        // La red pide iniciar sesión (portal cautivo) o no tiene internet
        Rectangle {
            visible: (root.store.portal || root.store.limited) && root.store.passwordFor === "" && root.store.details === null
            width: parent.width
            implicitHeight: portalRow.implicitHeight + 24
            radius: 16
            color: App.Theme.surfaceActive
            border.width: 1
            border.color: App.Theme.amber

            Row {
                id: portalRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(App.Config.network.glyphAlert)
                    color: App.Theme.amber
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.iconLg + 2
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 28 - portalButton.width - 20
                    text: root.store.portal ? "«" + root.store.netName + "» pide iniciar sesión" : "«" + root.store.netName + "» no tiene salida a internet"
                    wrapMode: Text.Wrap
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                }
                SmallButton {
                    id: portalButton
                    anchors.verticalCenter: parent.verticalCenter
                    primary: true
                    label: root.store.portal ? "Iniciar sesión" : "Reintentar"
                    onClicked: root.store.portal ? root.store.openPortal() : root.store.checkNow()
                }
            }
        }
        VpnImport {
            visible: root.store.pending !== null
            width: parent.width
        }
        EnterpriseForm {
            visible: root.store.enterpriseFor !== ""
            width: parent.width
        }
        Rectangle {
            id: hiddenForm
            visible: root.hiddenOpen
            width: parent.width
            implicitHeight: hiddenCol.implicitHeight + 28
            radius: 18
            color: App.Theme.surfaceActive
            border.width: 1
            border.color: App.Theme.primary

            onVisibleChanged: {
                if (visible) {
                    ssidInput.text = "";
                    keyInput.text = "";
                    ssidInput.forceActiveFocus();
                }
            }
            function connectNow() {
                if (ssidInput.text.trim() === "")
                    return;
                root.store.connectHidden(ssidInput.text.trim(), keyInput.text);
                root.hiddenOpen = false;
                root.forceActiveFocus();
            }

            Column {
                id: hiddenCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 8

                Text {
                    text: "Conectar a una red oculta"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: "transparent"
                    border.width: 1
                    border.color: ssidInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh
                    TextInput {
                        id: ssidInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: App.Theme.white
                        font.pixelSize: App.Config.fontSize.lg
                        clip: true
                        Keys.onTabPressed: keyInput.forceActiveFocus()
                        Keys.onReturnPressed: event => {
                            event.accepted = true;
                            keyInput.forceActiveFocus();
                        }
                    }
                    Text {
                        visible: ssidInput.text === ""
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Nombre de la red"
                        color: App.Theme.placeholder
                        font.pixelSize: App.Config.fontSize.lg
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: "transparent"
                    border.width: 1
                    border.color: keyInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh
                    TextInput {
                        id: keyInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: App.Theme.white
                        font.pixelSize: App.Config.fontSize.lg
                        echoMode: TextInput.Password
                        clip: true
                        Keys.onReturnPressed: event => {
                            event.accepted = true;
                            hiddenForm.connectNow();
                        }
                        Keys.onEnterPressed: event => {
                            event.accepted = true;
                            hiddenForm.connectNow();
                        }
                    }
                    Text {
                        visible: keyInput.text === ""
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Contraseña (vacía si es abierta)"
                        color: App.Theme.placeholder
                        font.pixelSize: App.Config.fontSize.lg
                    }
                }
                Row {
                    anchors.right: parent.right
                    spacing: 8
                    SmallButton {
                        label: "Cancelar"
                        onClicked: {
                            root.hiddenOpen = false;
                            root.forceActiveFocus();
                        }
                    }
                    SmallButton {
                        primary: true
                        label: "Conectar"
                        onClicked: hiddenForm.connectNow()
                    }
                }
            }
        }
    }

    // ── Contraseña de una red ──
    WifiPassword {
        id: passwordScreen
        visible: root.store.passwordFor !== "" && root.store.details === null
        anchors.top: top.bottom
        anchors.topMargin: 10
        width: parent.width
    }

    // ── Detalles de una red ──
    NetworkDetails {
        visible: root.store.details !== null
        anchors.top: top.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
    }

    // ── Listas (se desplazan dentro del alto fijo de la vista) ──
    Flickable {
        id: flick
        visible: root.store.details === null && root.store.passwordFor === ""
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

            // Cableada
            Item {
                id: wiredRow
                visible: root.store.wiredConnected
                width: parent.width
                height: visible ? 52 : 0
                Text {
                    id: wiredGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: String.fromCodePoint(App.Config.network.glyphWired)
                    color: App.Theme.primary
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.iconLg + 2
                }
                Column {
                    anchors.left: wiredGlyph.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "Cableada"
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.md
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Conectada"
                        color: App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 13
                    color: wiredGear.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(App.Config.network.glyphGear)
                        color: App.Theme.gray
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.icon
                    }
                    MouseArea {
                        id: wiredGear
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.store.openWiredDetails(root.store.wired.find(d => d.connected) ?? root.store.wired[0])
                    }
                }
            }

            // Wi-Fi
            Item {
                visible: root.store.wifiAvailable
                width: parent.width
                height: visible ? 26 : 0
                Section {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "REDES WI-FI"
                }
            }
            Text {
                visible: root.store.wifiAvailable && !root.store.enabled
                width: parent.width
                leftPadding: 4
                bottomPadding: 6
                text: root.store.blocked ? "Wi-Fi bloqueado por el sistema" : "Wi-Fi apagado"
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                id: netRep
                model: root.store.enabled ? root.store.order : null
                delegate: NetworkRow {
                    required property int index
                    // Solo las primeras 6 hasta "Mostrar todas"; las demás no ocupan lugar
                    visible: root.showAll || index < 6
                    width: lists.width
                    selected: root.current === index
                }
            }
            Flow {
                visible: root.store.enabled
                width: parent.width
                spacing: 8
                Action {
                    visible: root.store.order.count > 6
                    glyph: String.fromCodePoint(root.showAll ? 0xf0143 : 0xf0140)
                    label: root.showAll ? "Menos redes" : "Mostrar todas (" + root.store.order.count + ")"
                    onClicked: root.showAll = !root.showAll
                }
                Action {
                    glyph: String.fromCodePoint(0xf0450)
                    label: "Buscar de nuevo"
                    onClicked: root.store.scan()
                }
                Action {
                    glyph: String.fromCodePoint(0xf0415)
                    label: "Red oculta"
                    onClicked: {
                        root.hiddenOpen = !root.hiddenOpen;
                    }
                }
            }

            // VPN
            Item {
                width: parent.width
                height: 34
                Section {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "VPN"
                }
            }
            Text {
                visible: root.store.vpns.length === 0
                width: parent.width
                leftPadding: 4
                bottomPadding: 4
                text: "Ninguna todavía"
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                id: vpnRep
                model: root.store.vpns
                delegate: VpnRow {
                    required property var modelData
                    required property int index
                    vpn: modelData
                    width: lists.width
                    selected: root.current === root.netCount + index
                }
            }
            Action {
                glyph: String.fromCodePoint(0xf0415)
                label: "Agregar VPN"
                onClicked: root.menuOpen = !root.menuOpen
            }
            // Origen de la configuración
            Column {
                visible: root.menuOpen
                width: parent.width
                spacing: 2

                Repeater {
                    model: [
                        {
                            g: 0xf0214,
                            t: "Archivo (.conf o .ovpn)",
                            o: "file"
                        },
                        {
                            g: 0xf0432,
                            t: "Imagen con el QR",
                            o: "qr-file"
                        },
                        {
                            g: 0xf014c,
                            t: "Portapapeles (QR o texto)",
                            o: "clipboard"
                        },
                        {
                            g: 0xf019e,
                            t: "Región de la pantalla",
                            o: "region"
                        }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: lists.width
                        height: 40
                        radius: 12
                        color: om.containsMouse ? App.Theme.surfaceHover : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Text {
                                width: 24
                                horizontalAlignment: Text.AlignHCenter
                                text: String.fromCodePoint(modelData.g)
                                color: App.Theme.gray
                                font.family: App.Config.fonts.icons
                                font.pixelSize: App.Config.fontSize.iconLg
                            }
                            Text {
                                text: modelData.t
                                color: App.Theme.white
                                font.family: App.Config.fonts.text
                                font.pixelSize: App.Config.fontSize.md
                            }
                        }
                        MouseArea {
                            id: om
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false;
                                root.store.importFrom(modelData.o);
                            }
                        }
                    }
                }
            }
        }
    }
}
