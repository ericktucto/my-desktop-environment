import QtQuick
import Quickshell
import Quickshell.Io
import "../rows/" as R
import "../../../services/accounts/" as AC
import "../../../services/calendar/" as CAL
import "../../../services/settings/" as ST
import "../../../" as App

// Cuentas: Google (el calendario) y GitHub (el estado de los PR e issues de las tareas).
Page {
    id: page

    readonly property var gh: AC.AccountsStore
    readonly property var cal: CAL.CalendarStore
    readonly property string googleDir: Quickshell.env("HOME") + "/.config/stixshell/google"

    pageId: "accounts"
    pageName: "Cuentas"
    subtitle: "Los servicios conectados."

    readonly property bool shown: ST.SettingsUi.open && ST.SettingsUi.page === pageId
    onShownChanged: {
        if (shown) {
            gh.refresh();
            cal.checkStatus();
        }
    }

    function ghErrorText(e) {
        return {
            "offline": "Sin conexión con GitHub",
            "invalid": "El token no vale",
            "denied": "Cancelaste el permiso",
            "expired": "El código venció",
            "no-client": "Falta el client_id de la OAuth App"
        }[e] ?? e;
    }

    // Importar el client.json de Google Cloud
    Process {
        id: importer
        onExited: page.cal.checkStatus()
    }
    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "") {
                    importer.command = ["sh", "-c", 'mkdir -p "$2" && cp "$1" "$2/client.json" && chmod 600 "$2/client.json"', "_", p, page.googleDir];
                    importer.running = true;
                }
            }
        }
    }

    // ── Google ──
    R.Section {
        text: "Google"
    }
    R.InfoRow {
        searchId: "googleStatus"
        label: page.cal.connected ? "Conectada" : (page.cal.hasClient ? "Sin conectar" : "Falta el client.json")
        hint: page.cal.connected ? (page.cal.email !== "" ? page.cal.email : "Google Calendar") : (page.cal.error === "" ? "Sirve para ver tus eventos en el calendario (solo lectura)." : page.cal.error)
        keywords: "google calendario correo cuenta gmail"
        value: page.cal.connected ? "✓" : ""
        valueColor: App.Theme.green
    }
    R.ActionRow {
        searchId: "googleConnect"
        label: page.cal.connected ? "Desconectar Google" : (page.cal.loggingIn ? "Esperando el navegador…" : "Conectar con Google")
        hint: page.cal.connected ? "Borra la sesión y revoca el permiso." : "Se abre el navegador para dar el permiso."
        keywords: "google iniciar sesion login cerrar"
        actionLabel: page.cal.connected ? "Desconectar" : "Conectar"
        primary: !page.cal.connected
        enabled: page.cal.connected || (page.cal.hasClient && !page.cal.loggingIn)
        onTriggered: page.cal.connected ? page.cal.logout() : page.cal.login()
    }
    R.ActionRow {
        searchId: "googleClient"
        label: "Importar el client.json"
        hint: "El cliente OAuth de tipo «App de escritorio» que se descarga de Google Cloud (ver README)."
        keywords: "google credenciales oauth"
        actionLabel: "Elegir…"
        onTriggered: {
            if (picker.running)
                return;
            picker.command = ["python3", Quickshell.shellPath("scripts/pick.py"), "file", "", "Elegir el client.json", "*.json"];
            picker.running = true;
        }
    }

    // ── GitHub ──
    R.Section {
        text: "GitHub"
    }
    R.InfoRow {
        searchId: "githubStatus"
        label: page.gh.ghConnected ? "Conectada" : "Sin conectar"
        hint: page.gh.ghConnected ? (page.gh.ghName !== "" ? page.gh.ghName + " · @" + page.gh.ghLogin : "@" + page.gh.ghLogin) : (page.gh.ghError !== "" ? page.ghErrorText(page.gh.ghError) : "Sirve para el estado de los PR e issues en las tareas, también los privados.")
        keywords: "github cuenta token pr issues"
        value: page.gh.ghConnected ? "✓" : ""
        valueColor: App.Theme.green
    }
    R.InfoRow {
        visible: page.gh.deviceCode !== ""
        label: "Escribe este código en " + page.gh.deviceUri
        hint: "Ya se copió y se abrió el navegador. Esperando que lo aceptes…"
        value: page.gh.deviceCode
        valueColor: App.Theme.white
    }
    R.ActionRow {
        visible: page.gh.ghConnected
        searchId: "githubLogout"
        label: "Desconectar GitHub"
        hint: "Borra el token guardado."
        keywords: "github cerrar sesion token"
        actionLabel: "Desconectar"
        onTriggered: page.gh.logout()
    }
    R.ActionRow {
        visible: !page.gh.ghConnected
        searchId: "githubDevice"
        label: page.gh.deviceCode !== "" ? "Cancelar" : "Conectar con GitHub"
        hint: "Login por código: necesita el client_id de una OAuth App (abajo)."
        keywords: "github iniciar sesion login codigo dispositivo"
        actionLabel: page.gh.deviceCode !== "" ? "Cancelar" : "Conectar"
        primary: page.gh.deviceCode === ""
        enabled: !page.gh.ghBusy || page.gh.deviceCode !== ""
        onTriggered: page.gh.deviceCode !== "" ? page.gh.cancelDevice() : page.gh.deviceLogin()
    }
    R.TextRow {
        visible: !page.gh.ghConnected
        searchId: "githubClientId"
        label: "client_id de la OAuth App"
        hint: "En github.com/settings/developers: una OAuth App con «Enable Device Flow»."
        keywords: "github oauth"
        value: ST.SettingsStore.accounts.githubClientId
        placeholder: "Ov23…"
        fieldWidth: 220
        onAccepted: t => ST.SettingsStore.accounts.githubClientId = t.trim()
    }
    R.TextRow {
        visible: !page.gh.ghConnected
        searchId: "githubToken"
        label: "O pega un token personal"
        hint: "Con el permiso «repo» para ver los privados. Se comprueba y se guarda; Enter para aplicar."
        keywords: "github token personal pat"
        value: ""
        placeholder: "ghp_…"
        fieldWidth: 220
        onAccepted: t => page.gh.saveToken(t)
    }
}
