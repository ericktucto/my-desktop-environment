import QtQuick
import Quickshell
import "../rows/" as R
import "../../../services/apps/" as AP
import "../../../services/launcher/" as L
import "../../../services/settings/" as ST
import "../../../" as App

// Apps y launcher: la terminal, el navegador y el gestor de archivos que usa la shell, y el launcher
// (favoritos, cuántos resultados y lo que recuerda).
Page {
    id: page

    readonly property var apps: ST.SettingsStore.apps
    readonly property var launcher: ST.SettingsStore.launcher

    // [{ id, label }] para elegir una app de un tipo: «Predeterminada» y las instaladas
    function choices(kind, defLabel) {
        return [
            {
                id: "",
                label: defLabel
            }
        ].concat(AP.AppsStore.installed(kind).map(a => ({
                    id: a.id,
                    label: a.name
                })));
    }

    pageId: "apps"
    pageName: "Apps y launcher"
    subtitle: "Qué abre la shell cuando necesita una terminal, un navegador o un gestor de archivos, y cómo se comporta el launcher."

    R.Section {
        text: "Apps predeterminadas"
    }
    R.CycleRow {
        searchId: "appTerminal"
        label: "Terminal"
        hint: "El launcher, el portapapeles, Super+T y «Acerca de» la usan."
        keywords: "kitty foot alacritty consola"
        options: page.choices("terminal", "kitty")
        value: page.apps.terminal
        defaultValue: ""
        changed: page.apps.terminal !== ""
        onPicked: id => page.apps.terminal = id
    }
    R.TextRow {
        searchId: "appTerminalCmd"
        label: "Terminal: comando propio"
        hint: "Si lo escribes, reemplaza a la app de arriba. Por ejemplo: foot -a stix"
        keywords: "kitty foot alacritty consola"
        value: page.apps.terminalCmd
        placeholder: "ninguno"
        fieldWidth: 220
        onAccepted: t => page.apps.terminalCmd = t.trim()
    }
    R.CycleRow {
        searchId: "appBrowser"
        label: "Navegador"
        hint: "Para abrir enlaces (calendario, GitHub, capturas subidas…)."
        keywords: "firefox chrome internet web enlaces"
        options: page.choices("browser", "Predeterminado del sistema")
        value: page.apps.browser
        defaultValue: ""
        changed: page.apps.browser !== ""
        onPicked: id => page.apps.browser = id
    }
    R.TextRow {
        searchId: "appBrowserCmd"
        label: "Navegador: comando propio"
        keywords: "firefox chrome internet web enlaces"
        value: page.apps.browserCmd
        placeholder: "ninguno"
        fieldWidth: 220
        onAccepted: t => page.apps.browserCmd = t.trim()
    }
    R.CycleRow {
        searchId: "appFiles"
        label: "Archivos"
        hint: "Para abrir carpetas."
        keywords: "gestor explorador thunar nautilus dolphin carpetas"
        options: page.choices("files", "Predeterminado del sistema")
        value: page.apps.files
        defaultValue: ""
        changed: page.apps.files !== ""
        onPicked: id => page.apps.files = id
    }
    R.TextRow {
        searchId: "appFilesCmd"
        label: "Archivos: comando propio"
        keywords: "gestor explorador thunar nautilus dolphin carpetas"
        value: page.apps.filesCmd
        placeholder: "ninguno"
        fieldWidth: 220
        onAccepted: t => page.apps.filesCmd = t.trim()
    }

    R.Section {
        text: "Launcher"
    }
    R.StepperRow {
        searchId: "launcherMaxResults"
        label: "Resultados"
        hint: "Cuántos muestra la búsqueda como máximo."
        keywords: "launcher buscar cantidad"
        text: String(page.launcher.maxResults)
        changed: page.launcher.maxResults !== App.Config.launcher.maxResults
        onResetRequested: page.launcher.maxResults = App.Config.launcher.maxResults
        onDecrement: page.launcher.maxResults = Math.max(10, page.launcher.maxResults - 10)
        onIncrement: page.launcher.maxResults = Math.min(200, page.launcher.maxResults + 10)
    }
    R.StepperRow {
        searchId: "launcherHistory"
        label: "Comandos recordados"
        hint: "Los que se escriben con «t:» en el launcher."
        keywords: "launcher historial terminal"
        text: String(page.launcher.historyMax)
        changed: page.launcher.historyMax !== App.Config.launcher.historyMax
        onResetRequested: page.launcher.historyMax = App.Config.launcher.historyMax
        onDecrement: page.launcher.historyMax = Math.max(5, page.launcher.historyMax - 5)
        onIncrement: page.launcher.historyMax = Math.min(100, page.launcher.historyMax + 5)
    }
    R.ActionRow {
        searchId: "launcherClear"
        label: "Borrar lo que recuerda"
        hint: "El orden por uso y los comandos de «t:». Los favoritos no se tocan."
        keywords: "launcher historial limpiar"
        actionLabel: "Borrar"
        onTriggered: L.LauncherStore.clearData()
    }

    R.Section {
        text: "Favoritos del launcher"
    }
    Text {
        width: page.width - 16
        wrapMode: Text.WordWrap
        text: L.LauncherStore.favorites.length === 0 ? "Aún no hay favoritos. Se agregan con la estrella de cada app en el launcher." : "Salen primero en el launcher, en este orden. Se agregan con la estrella de cada app en el launcher y se quitan aquí con ✕ o con esa misma estrella."
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }
    Repeater {
        model: L.LauncherStore.favorites
        R.OrderRow {
            required property string modelData
            required property int index
            label: DesktopEntries.byId(modelData)?.name ?? modelData
            first: index === 0
            last: index === L.LauncherStore.favorites.length - 1
            removable: true
            onMoved: dir => L.LauncherStore.moveFavorite(modelData, dir)
            onRemoved: L.LauncherStore.toggleFavorite(modelData)
        }
    }

    R.ActionRow {
        searchId: "resetApps"
        label: "Restablecer las apps y el launcher"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: {
            ST.SettingsStore.resetSection("apps");
            ST.SettingsStore.resetSection("launcher");
        }
    }
}
