import QtQuick
import "../../controls/" as C
import "../../../services/network/" as NS
import "../../../" as App

// Detalles de una red guardada o cableada: IP, puerta de enlace, DNS en uso, y para cambiar la dirección IP
// (automática o manual), el DNS (automático, uno de Config.network.dnsPresets o personalizado) y la conexión
// automática; [Compartir con QR] y [Olvidar] en las de Wi-Fi.
Item {
    id: root

    readonly property var store: NS.NetworkStore
    readonly property var d: store.details
    readonly property var presets: App.Config.network.dnsPresets

    property string ipMethod: "auto"
    property string dnsMode: "auto"     // "auto" | "custom" | índice de un preset como texto
    property bool autoconnect: true
    property bool confirming: false

    // Lista "a,b" → "a,b" sin espacios ni barras (nmcli separa los DNS con coma o con |)
    function normalize(s) {
        return s.split(/[,|\s]+/).filter(x => x !== "").join(",");
    }

    onDChanged: {
        confirming = false;
        if (!d)
            return;
        ipMethod = d.method === "manual" ? "manual" : "auto";
        const first = d.addresses.split(",")[0].trim();
        addressInput.text = first;
        gatewayInput.text = d.gateway;
        autoconnect = d.autoconnect;
        const dns = normalize(d.dns);
        if (!d.ignoreAutoDns || dns === "") {
            dnsMode = "auto";
            customInput.text = "";
        } else {
            const i = presets.findIndex(p => p.dns === dns);
            dnsMode = i >= 0 ? String(i) : "custom";
            customInput.text = dns;
        }
    }

    function dnsValue() {
        if (dnsMode === "auto")
            return "auto";
        if (dnsMode === "custom")
            return normalize(customInput.text);
        return presets[parseInt(dnsMode)].dns;
    }

    function save() {
        store.saveDetails({
            method: ipMethod,
            address: addressInput.text.trim(),
            gateway: gatewayInput.text.trim(),
            dns: dnsValue(),
            autoconnect: autoconnect
        });
    }

    function securityText(k) {
        switch (k) {
        case "wpa-psk":
            return "WPA2";
        case "sae":
            return "WPA3";
        case "wpa-eap":
            return "Empresa (802.1X)";
        case "":
        case "none":
            return "Abierta";
        }
        return k;
    }

    component Label: Text {
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }
    component Info: Text {
        width: parent.width
        elide: Text.ElideRight
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: flick.width
            spacing: 8

            // Estado en vivo
            Column {
                width: parent.width
                spacing: 2
                Info {
                    text: root.d ? root.d.subtitle + (root.d.kind === "wifi" ? " · " + root.securityText(root.d.security) : "") : ""
                    color: App.Theme.gray
                }
                Info {
                    visible: root.d && root.d.live
                    text: root.d && root.d.live ? "IP " + root.d.live.ip + " · Puerta " + root.d.live.gateway : ""
                }
                Info {
                    visible: root.d && root.d.live
                    text: root.d && root.d.live ? "DNS " + root.d.live.dns.replace(/\s+,\s+|\s*\|\s*/g, ", ").trim() : ""
                }
                Info {
                    visible: root.d && root.d.live && root.d.live.mac !== ""
                    text: root.d && root.d.live ? "MAC " + root.d.live.mac : ""
                    color: App.Theme.gray
                }
                Info {
                    visible: root.d && root.d.live && !root.store.resolvOk
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    text: "/etc/resolv.conf no sigue a NetworkManager: el DNS de la VPN no se aplica. Corre «sudo sh system/networkmanager.sh»."
                    color: App.Theme.orange
                }
            }

            Label {
                topPadding: 6
                text: "DIRECCIÓN IP"
            }
            Flow {
                width: parent.width
                spacing: 6
                Chip {
                    label: "Automática"
                    selected: root.ipMethod === "auto"
                    onClicked: root.ipMethod = "auto"
                }
                Chip {
                    label: "Manual"
                    selected: root.ipMethod === "manual"
                    onClicked: root.ipMethod = "manual"
                }
            }
            NetField {
                id: addressInput
                visible: root.ipMethod === "manual"
                width: parent.width
                placeholder: "IP con prefijo, por ejemplo 192.168.1.50/24"
                onAccepted: gatewayInput.focusInput()
            }
            NetField {
                id: gatewayInput
                visible: root.ipMethod === "manual"
                width: parent.width
                placeholder: "Puerta de enlace, por ejemplo 192.168.1.1"
                onAccepted: root.save()
            }

            Label {
                topPadding: 6
                text: "DNS"
            }
            Flow {
                width: parent.width
                spacing: 6
                Chip {
                    label: "Automático"
                    selected: root.dnsMode === "auto"
                    onClicked: root.dnsMode = "auto"
                }
                Repeater {
                    model: root.presets
                    delegate: Chip {
                        required property var modelData
                        required property int index
                        label: modelData.label
                        selected: root.dnsMode === String(index)
                        onClicked: root.dnsMode = String(index)
                    }
                }
                Chip {
                    label: "Personalizado"
                    selected: root.dnsMode === "custom"
                    onClicked: {
                        root.dnsMode = "custom";
                        customInput.focusInput();
                    }
                }
            }
            NetField {
                id: customInput
                visible: root.dnsMode === "custom"
                width: parent.width
                placeholder: "Servidores separados por coma: 1.1.1.1, 9.9.9.9"
                onAccepted: root.save()
            }

            Item {
                width: parent.width
                height: 34
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Conexión automática"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
                C.Switch {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.autoconnect
                    onToggled: root.autoconnect = !root.autoconnect
                }
            }

            Flow {
                width: parent.width
                spacing: 8
                SmallButton {
                    visible: root.d && root.d.kind === "wifi"
                    label: String.fromCodePoint(App.Config.network.glyphQr) + "  Compartir con QR"
                    onClicked: root.store.share ? root.store.closeShare() : root.store.startShare()
                }
                SmallButton {
                    visible: root.d && root.d.kind === "wifi"
                    label: root.confirming ? "¿Olvidar? Pulsa otra vez" : "Olvidar"
                    onClicked: {
                        if (root.confirming)
                            root.store.forgetDetails();
                        else {
                            root.confirming = true;
                            confirmTimer.restart();
                        }
                    }
                }
                SmallButton {
                    primary: true
                    label: "Guardar"
                    onClicked: root.save()
                }
            }

            WifiShare {
                visible: root.store.share !== null
                width: parent.width
            }
        }
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: root.confirming = false
    }
}
