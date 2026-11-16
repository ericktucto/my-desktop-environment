import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Formulario de una red de empresa (802.1X, PEAP o TTLS con usuario y contraseña, como eduroam).
Rectangle {
    id: root

    readonly property var store: NS.NetworkStore
    property string eap: "peap"
    property string phase2: "mschapv2"
    property string caMode: "system"      // "system" | "file" | "none"
    property string caFile: ""

    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: App.Theme.surfaceActive
    border.width: 1
    border.color: App.Theme.primary

    onVisibleChanged: {
        if (!visible)
            return;
        const dr = store.enterpriseDraft;
        eap = dr ? dr.eap : "peap";
        phase2 = dr ? dr.phase2 : "mschapv2";
        userInput.text = dr ? dr.identity : "";
        anonInput.text = dr ? dr.anonymous : "";
        domainInput.text = dr ? dr.domain : "";
        passInput.text = "";
        passInput.showText = false;
        caMode = dr ? (dr.ca === "none" ? "none" : (dr.ca === "system" ? "system" : "file")) : "system";
        caFile = dr && dr.ca !== "system" && dr.ca !== "none" ? dr.ca : "";
        (userInput.text === "" ? userInput : passInput).focusInput();
    }

    function connectNow() {
        if (store.enterpriseBusy || userInput.text.trim() === "" || passInput.text === "")
            return;
        if (caMode === "file" && caFile === "") {
            store.say("Elige el archivo del certificado");
            return;
        }
        store.connectEnterprise({
            eap: eap,
            phase2: eap === "peap" ? "mschapv2" : phase2,
            identity: userInput.text.trim(),
            anonymous: anonInput.text.trim(),
            password: passInput.text,
            ca: caMode === "file" ? caFile : caMode,
            domain: domainInput.text.trim()
        });
    }

    component Label: Text {
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.store.enterpriseFor
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }

        Label {
            text: "MÉTODO"
        }
        Flow {
            width: parent.width
            spacing: 6
            NetChip {
                label: "PEAP"
                selected: root.eap === "peap"
                onClicked: root.eap = "peap"
            }
            NetChip {
                label: "TTLS"
                selected: root.eap === "ttls"
                onClicked: root.eap = "ttls"
            }
            NetChip {
                visible: root.eap === "ttls"
                label: "PAP"
                selected: root.phase2 === "pap"
                onClicked: root.phase2 = "pap"
            }
            NetChip {
                visible: root.eap === "ttls"
                label: "MSCHAPv2"
                selected: root.phase2 === "mschapv2"
                onClicked: root.phase2 = "mschapv2"
            }
        }
        NetField {
            id: userInput
            width: parent.width
            placeholder: "Usuario"
            onAccepted: passInput.focusInput()
        }
        NetField {
            id: passInput
            width: parent.width
            secret: true
            placeholder: "Contraseña"
            onAccepted: root.connectNow()
        }
        NetField {
            id: anonInput
            width: parent.width
            placeholder: "Identidad anónima (opcional)"
            onAccepted: domainInput.focusInput()
        }

        Label {
            text: "CERTIFICADO"
        }
        Flow {
            width: parent.width
            spacing: 6
            NetChip {
                label: "Del sistema"
                selected: root.caMode === "system"
                onClicked: root.caMode = "system"
            }
            NetChip {
                label: root.caFile !== "" ? root.caFile.substring(root.caFile.lastIndexOf("/") + 1) : "Archivo…"
                selected: root.caMode === "file"
                onClicked: {
                    root.caMode = "file";
                    root.store.pickCaCert(function (path) {
                        root.caFile = path;
                    });
                }
            }
            NetChip {
                label: "No verificar"
                selected: root.caMode === "none"
                onClicked: root.caMode = "none"
            }
        }
        Text {
            visible: root.caMode === "none"
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Cualquiera con el mismo nombre de red podría ver tu contraseña."
            color: App.Theme.orange
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        NetField {
            id: domainInput
            visible: root.caMode !== "none"
            width: parent.width
            placeholder: "Dominio del servidor (opcional), por ejemplo uni.edu"
            onAccepted: root.connectNow()
        }

        Row {
            anchors.right: parent.right
            spacing: 8
            SmallButton {
                label: "Cancelar"
                onClicked: root.store.cancelEnterprise()
            }
            SmallButton {
                primary: true
                label: root.store.enterpriseBusy ? "Conectando…" : "Conectar"
                onClicked: root.connectNow()
            }
        }
    }
}
