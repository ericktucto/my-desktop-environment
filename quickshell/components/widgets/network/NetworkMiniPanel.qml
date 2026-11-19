import QtQuick
import "../media/" as MW
import "../controlcenter/" as CC
import "../../controls/" as C
import "../../../services/network/" as NS
import "../../../" as App

// Panel de la pill de Wi-Fi (isla expandida): se arma con las piezas de los satélites (fondo, anillo, fichas).
// Muestra la red (nombre, seguridad, estado) con un anillo de señal, y la IP, la puerta de enlace, el DNS y la
// MAC (un clic copia). Todo es reactivo o se lee al abrir: no hay polling. Botones: interruptor de Wi-Fi,
// Reconectar, Buscar, QR, VPN y Abrir redes (la vista completa del centro de control).
// Teclado: w Wi-Fi · r reconectar · s buscar · q QR · Enter abrir redes.
Item {
    id: root

    readonly property var store: NS.NetworkStore
    readonly property var cfg: App.Config.network
    readonly property bool wifiView: store.shownKind === "wifi"
    readonly property var net: store.current
    readonly property bool connected: wifiView ? net !== null : store.wiredConnected
    readonly property var live: store.live

    // Radio de la isla: el fondo se recorta con esas esquinas
    property real islandRadius: App.Config.pill.radiusExpanded
    readonly property real padding: App.Config.media.padding

    implicitHeight: store.share ? shareCol.implicitHeight : col.implicitHeight

    signal closeRequested

    readonly property color accent: !connected ? App.Theme.grayDark : (store.alert ? App.Theme.amber : App.Theme.primary)

    readonly property string title: {
        if (wifiView)
            return net ? net.name : (store.blocked ? "Wi-Fi bloqueado" : (store.enabled ? "Desconectado" : "Wi-Fi apagado"));
        return store.shownWired ? (store.wiredConnected ? "Cableada" : "Sin cable conectado") : "Sin red cableada";
    }
    readonly property string subtitle: {
        if (!connected)
            return wifiView && store.enabled ? "Sin red" : "";
        const parts = [];
        if (wifiView) {
            const sec = store.securityText(net);
            if (sec !== "")
                parts.push(sec);
        } else if (store.shownWired) {
            parts.push(store.shownWired.name);
        }
        parts.push(store.portal ? "Iniciar sesión" : (store.limited ? "Sin internet" : "Conectada"));
        if (store.vpnActive)
            parts.push("VPN");
        return parts.join(" · ");
    }
    readonly property real signal: wifiView && net ? net.signalStrength : (connected ? 1 : 0)
    readonly property string ringGlyph: wifiView ? (net ? store.glyphFor(net, store.alert) : String.fromCodePoint(cfg.glyphOff)) : String.fromCodePoint(connected ? cfg.glyphWired : cfg.glyphOff)

    function openNetworks() {
        store.openPanel();
        closeRequested();
    }

    function scan() {
        store.scan();
        scanTimer.restart();
    }

    // Buscar solo mientras se mira el resultado
    Timer {
        id: scanTimer
        interval: 4000
        onTriggered: root.store.leave()
    }

    // El teclado funciona con el panel abierto
    focus: true
    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
        else
            store.leave();
    }

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_W:
            store.toggle();
            break;
        case Qt.Key_R:
            store.reconnect();
            break;
        case Qt.Key_S:
            if (wifiView)
                scan();
            break;
        case Qt.Key_Q:
            if (store.share)
                store.closeShare();
            else if (wifiView && net)
                store.shareCurrent();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            openNetworks();
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // ── Fondo: el degradado del color, a todo el ancho de la isla ──
    MW.MediaBackdrop {
        anchors.fill: parent
        anchors.margins: -root.padding
        accent: root.accent
        tint: 0.18
        islandRadius: root.islandRadius
    }

    // ── Principal ──
    Column {
        id: col
        width: parent.width
        spacing: 12
        visible: !root.store.share

        // Con cable y Wi-Fi a la vez: elegir cuál ver
        MW.ItemChips {
            visible: root.store.wired.length > 0 && root.store.wifiAvailable
            model: [
                {
                    key: "wired",
                    label: "Cableada"
                },
                {
                    key: "wifi",
                    label: "Wi-Fi"
                }
            ]
            currentKey: root.store.shownKind
            onPicked: key => root.store.viewKind = key
        }

        // Datos a la izquierda y el anillo de señal a la derecha
        Item {
            width: parent.width
            height: Math.max(info.implicitHeight, root.cfg.ring)

            Column {
                id: info
                anchors.left: parent.left
                anchors.right: ring.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: root.title
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Text {
                    width: parent.width
                    bottomPadding: 6
                    visible: text !== ""
                    text: root.subtitle
                    color: root.store.alert ? App.Theme.amber : App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Lo que se lee una sola vez (sin polling)
                InfoRow {
                    width: parent.width
                    visible: root.live !== null && root.live.ip !== ""
                    label: "IP"
                    value: root.live ? root.live.ip : ""
                    copyValue: root.live ? root.live.ip.split("/")[0] : ""
                }
                InfoRow {
                    width: parent.width
                    visible: root.live !== null && root.live.gateway !== ""
                    label: "Puerta"
                    value: root.live ? root.live.gateway : ""
                }
                InfoRow {
                    width: parent.width
                    visible: root.live !== null && root.live.dns !== ""
                    label: "DNS"
                    value: root.live ? root.live.dns : ""
                }
                InfoRow {
                    width: parent.width
                    visible: root.live !== null && root.live.mac !== ""
                    label: "MAC"
                    value: root.live ? root.live.mac : ""
                }

                // Avisos del store ("Copiado", "Reconectando…")
                Text {
                    width: parent.width
                    topPadding: 4
                    visible: root.store.message !== ""
                    text: root.store.message
                    color: App.Theme.amber
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    elide: Text.ElideRight
                }
            }

            // Señal: anillo con el porcentaje (cable: lleno)
            Item {
                id: ring
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.cfg.ring
                height: width

                MW.ProgressRing {
                    anchors.fill: parent
                    ringWidth: 7
                    value: root.signal
                    color: root.accent
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.ringGlyph
                        color: root.connected ? App.Theme.white : App.Theme.grayDark
                        font.family: App.Config.fonts.icons
                        font.pixelSize: 26
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.wifiView && root.net !== null
                        text: root.net ? Math.round(root.net.signalStrength * 100) + " %" : ""
                        color: App.Theme.white
                        font.family: App.Config.fonts.mono
                        font.pixelSize: App.Config.fontSize.md
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // Una sección por VPN activa: sus datos salen de NetworkManager, una sola lectura (sin polling)
        Repeater {
            model: root.store.vpnLive

            Column {
                id: vpnBox
                required property var modelData
                readonly property var v: modelData
                readonly property var entry: root.store.vpns.find(x => x.uuid === v.uuid) ?? null
                width: col.width
                spacing: 2

                Text {
                    width: parent.width
                    bottomPadding: 2
                    text: "VPN · " + (vpnBox.entry ? vpnBox.entry.name : "") + " · " + (vpnBox.v.kind === "wireguard" ? "WireGuard" : (vpnBox.v.kind === "openvpn" ? "OpenVPN" : "VPN"))
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                InfoRow {
                    width: parent.width
                    visible: vpnBox.v.ip !== ""
                    label: "IP"
                    value: vpnBox.v.ip
                    copyValue: vpnBox.v.ip.split("/")[0]
                }
                InfoRow {
                    width: parent.width
                    visible: vpnBox.v.dns !== ""
                    label: "DNS"
                    value: vpnBox.v.dns
                }
                InfoRow {
                    width: parent.width
                    visible: vpnBox.v.endpoint !== ""
                    label: "Servidor"
                    value: vpnBox.v.endpoint
                }
                InfoRow {
                    width: parent.width
                    label: "Tráfico"
                    value: vpnBox.v.full ? "Todo el tráfico" : (vpnBox.v.nets.length > 0 ? "Solo " + vpnBox.v.nets.join(", ") : "")
                    visible: value !== ""
                }
                InfoRow {
                    width: parent.width
                    visible: vpnBox.v.mtu !== ""
                    label: "MTU"
                    value: vpnBox.v.mtu
                }
                InfoRow {
                    width: parent.width
                    visible: vpnBox.v.keepalive !== ""
                    label: "Keepalive"
                    value: vpnBox.v.keepalive + " s"
                }
            }
        }

        // Interruptor de Wi-Fi y los botones
        Flow {
            width: parent.width
            spacing: 6

            Row {
                spacing: 8
                height: 30
                rightPadding: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.DemiBold
                }
                C.Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: root.store.wifiAvailable && !root.store.blocked
                    opacity: enabled ? 1 : 0.4
                    checked: root.store.enabled
                    onToggled: root.store.toggle()
                }
            }
            CC.Chip {
                label: "Reconectar"
                visible: root.connected || (root.wifiView && root.store.enabled)
                onClicked: root.store.reconnect()
            }
            CC.Chip {
                label: "Buscar"
                visible: root.wifiView && root.store.enabled
                onClicked: root.scan()
            }
            CC.Chip {
                label: "QR"
                visible: root.wifiView && root.net !== null
                onClicked: root.store.shareCurrent()
            }
            CC.Chip {
                label: "Abrir redes"
                onClicked: root.openNetworks()
            }
        }

        // VPN: una ficha por conexión; rellena = activa
        Flow {
            width: parent.width
            spacing: 6
            visible: root.store.vpns.length > 0

            Text {
                height: 30
                verticalAlignment: Text.AlignVCenter
                rightPadding: 4
                text: "VPN"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Repeater {
                model: root.store.vpns
                CC.Chip {
                    required property var modelData
                    label: modelData.name
                    selected: modelData.state !== ""
                    onClicked: root.store.toggleVpn(modelData)
                }
            }
        }
    }

    // ── El QR de la red ──
    Column {
        id: shareCol
        width: parent.width
        spacing: 10
        visible: root.store.share !== null

        // La tarjeta ya trae «Copiar contraseña» y «Cerrar» (vuelve al panel)
        CC.WifiShare {
            width: parent.width
        }
    }
}
