import QtQuick
import "../rows/" as R
import "../../../services/actions/" as AC
import "../../../services/settings/" as ST
import "../../../" as App

// Barra e isla: qué hace cada clic y la rueda sobre el reloj (la isla central). Se aplican al instante.
Page {
    id: page

    readonly property var isl: ST.SettingsStore.island
    readonly property var clicks: AC.ActionRunner.clickActions
    readonly property var wheels: AC.ActionRunner.wheelActions

    pageId: "bar"
    pageName: "Barra e isla"
    subtitle: "Qué hace cada clic y la rueda sobre el reloj, en el centro de la barra."

    R.Section {
        text: "Isla central (el reloj)"
    }
    R.CycleRow {
        searchId: "islandLeft"
        label: "Clic izquierdo"
        keywords: "reloj isla central click boton"
        options: page.clicks
        value: page.isl.left
        defaultValue: "productivity"
        onPicked: id => page.isl.left = id
    }
    R.CycleRow {
        searchId: "islandRight"
        label: "Clic derecho"
        keywords: "reloj isla central click boton"
        options: page.clicks
        value: page.isl.right
        defaultValue: "control"
        onPicked: id => page.isl.right = id
    }
    R.CycleRow {
        searchId: "islandMiddle"
        label: "Clic central"
        keywords: "reloj isla central click rueda boton"
        options: page.clicks
        value: page.isl.middle
        defaultValue: "none"
        onPicked: id => page.isl.middle = id
    }
    R.CycleRow {
        searchId: "islandWheel"
        label: "Rueda"
        hint: "Girar la rueda con el mouse encima del reloj."
        keywords: "scroll volumen brillo"
        options: page.wheels
        value: page.isl.wheel
        defaultValue: "volume"
        onPicked: id => page.isl.wheel = id
    }
    R.CycleRow {
        searchId: "islandShiftWheel"
        label: "Shift + rueda"
        keywords: "scroll volumen brillo"
        options: page.wheels
        value: page.isl.shiftWheel
        defaultValue: "brightness"
        onPicked: id => page.isl.shiftWheel = id
    }
    R.Section {
        text: "Workspaces (los puntos)"
    }
    R.CycleRow {
        searchId: "wsRight"
        label: "Clic derecho"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.wsPill.right
        defaultValue: "workspaces"
        onPicked: id => ST.SettingsStore.wsPill.right = id
    }
    R.CycleRow {
        searchId: "wsMiddle"
        label: "Clic central"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.wsPill.middle
        defaultValue: "none"
        onPicked: id => ST.SettingsStore.wsPill.middle = id
    }
    R.CycleRow {
        searchId: "wsWheel"
        label: "Rueda"
        hint: "El clic izquierdo va al workspace del punto."
        keywords: "barra pill click boton rueda"
        options: page.wheels
        value: ST.SettingsStore.wsPill.wheel
        defaultValue: "workspace"
        onPicked: id => ST.SettingsStore.wsPill.wheel = id
    }

    R.Section {
        text: "Ventana activa"
    }
    R.CycleRow {
        searchId: "winLeft"
        label: "Clic izquierdo"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.windowPill.left
        defaultValue: "windowApp"
        onPicked: id => ST.SettingsStore.windowPill.left = id
    }
    R.CycleRow {
        searchId: "winRight"
        label: "Clic derecho"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.windowPill.right
        defaultValue: "windowMenu"
        onPicked: id => ST.SettingsStore.windowPill.right = id
    }
    R.CycleRow {
        searchId: "winMiddle"
        label: "Clic central"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.windowPill.middle
        defaultValue: "closeWindow"
        onPicked: id => ST.SettingsStore.windowPill.middle = id
    }

    R.Section {
        text: "Notificaciones"
    }
    R.CycleRow {
        searchId: "notifRight"
        label: "Clic derecho"
        hint: "El clic izquierdo abre el historial."
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.notifPill.right
        defaultValue: "dnd"
        onPicked: id => ST.SettingsStore.notifPill.right = id
    }
    R.CycleRow {
        searchId: "notifMiddle"
        label: "Clic central"
        keywords: "barra pill click boton rueda"
        options: page.clicks
        value: ST.SettingsStore.notifPill.middle
        defaultValue: "none"
        onPicked: id => ST.SettingsStore.notifPill.middle = id
    }

    R.Section {
        text: "Reloj"
    }
    R.SwitchRow {
        searchId: "clock12"
        label: "Formato de 12 horas"
        hint: "Con AM/PM. Apagado, 24 horas."
        keywords: "hora reloj am pm 24"
        checked: ST.SettingsStore.clock.hour12
        defaultValue: true
        onToggled: c => ST.SettingsStore.clock.hour12 = c
    }
    R.SwitchRow {
        searchId: "clockSeconds"
        label: "Mostrar segundos"
        keywords: "hora reloj"
        checked: ST.SettingsStore.clock.seconds
        defaultValue: false
        onToggled: c => ST.SettingsStore.clock.seconds = c
    }

    R.Section {
        text: "Pills de la barra"
    }
    Repeater {
        model: [
            {
                key: "activeWindow",
                label: "Ventana activa",
                hint: "Ícono, nombre y título de la ventana (sus menús salen del clic)."
            },
            {
                key: "zoom",
                label: "Zoom",
                hint: "El botón de Zoom."
            },
            {
                key: "tray",
                label: "Bandeja del sistema",
                hint: "Los íconos de las apps en segundo plano."
            },
            {
                key: "network",
                label: "Red",
                hint: "Wi-Fi o cable."
            },
            {
                key: "bluetooth",
                label: "Bluetooth",
                hint: "Sale cuando hay un dispositivo conectado."
            },
            {
                key: "battery",
                label: "Batería",
                hint: "El porcentaje y el panel de energía."
            },
            {
                key: "notifications",
                label: "Notificaciones",
                hint: "La campana y el historial."
            }
        ]
        R.SwitchRow {
            required property var modelData
            searchId: "pill-" + modelData.key
            label: modelData.label
            hint: modelData.hint
            keywords: "barra pill mostrar ocultar"
            checked: ST.SettingsStore.pills[modelData.key]
            defaultValue: true
            onToggled: c => ST.SettingsStore.pills[modelData.key] = c
        }
    }

    R.ActionRow {
        searchId: "resetIsland"
        label: "Restablecer la barra"
        hint: "Clics, reloj y pills a los valores de fábrica."
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: {
            ST.SettingsStore.resetSection("island");
            ST.SettingsStore.resetSection("pillClicks");
            ST.SettingsStore.resetSection("clock");
            ST.SettingsStore.resetSection("pills");
        }
    }
}
