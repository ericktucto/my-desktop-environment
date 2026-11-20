import QtQuick
import "../rows/" as R
import "../../../services/idle/" as I
import "../../../services/power/" as P
import "../../../services/settings/" as ST
import "../../../" as App

// Energía: inactividad con la batería y con el cargador, brillo al atenuar, avisos de batería baja, perfil de
// energía y cafeína. Es lo mismo que el panel de la pill de batería.
Page {
    id: page

    readonly property var ss: ST.SettingsStore
    readonly property var idle: ST.SettingsStore.idle
    readonly property var low: ST.SettingsStore.low

    pageId: "energy"
    pageName: "Energía"
    subtitle: P.BatteryStore.percent + " % · " + P.BatteryStore.stateText

    R.Section {
        text: "Ahora"
    }
    R.SwitchRow {
        searchId: "caffeine"
        label: "No bloquear ni apagar"
        hint: "Cafeína: la pantalla no se atenúa, bloquea ni apaga hasta que la quites."
        keywords: "cafeina inactividad idle"
        checked: I.IdleStore.caffeine
        changed: false
        onToggled: c => I.IdleStore.toggleCaffeine()
    }
    R.SwitchRow {
        visible: P.BatteryStore.conservationAvailable
        searchId: "conservation"
        label: "Cargar hasta 60 %"
        hint: "Modo conservación: cuida la batería cargando solo hasta ~60 %."
        keywords: "conservacion bateria ideapad"
        enabled: P.BatteryStore.conservationWritable
        checked: P.BatteryStore.conservation
        changed: false
        onToggled: c => P.BatteryStore.setConservation(c)
    }

    R.Section {
        text: "Perfil de energía"
    }
    R.ChoiceRow {
        visible: P.ProfileStore.available
        searchId: "profileBattery"
        label: "Con batería"
        hint: "El perfil que se aplica cuando la laptop usa solo la batería."
        keywords: "perfil ahorro equilibrado rendimiento"
        options: P.ProfileStore.choices.map(p => ({
                    id: p.key,
                    label: p.label ?? p.key
                }))
        value: page.ss.profiles.battery
        defaultValue: App.Config.profiles.battery
        onPicked: id => page.ss.profiles.battery = id
    }
    R.ChoiceRow {
        visible: P.ProfileStore.available
        searchId: "profileAc"
        label: "Con cargador"
        keywords: "perfil ahorro equilibrado rendimiento"
        options: P.ProfileStore.choices.map(p => ({
                    id: p.key,
                    label: p.label ?? p.key
                }))
        value: page.ss.profiles.ac
        defaultValue: App.Config.profiles.ac
        onPicked: id => page.ss.profiles.ac = id
    }
    R.Section {
        visible: !P.ProfileStore.available
        text: "Perfiles no disponibles: power-profiles-daemon no responde"
    }

    R.Section {
        text: "Inactividad con batería"
    }
    R.StepperRow {
        searchId: "idleBatteryDim"
        label: "Atenuar"
        hint: "Con batería"
        keywords: "atenuar bajar brillo inactividad tiempo bateria"
        text: page.ss.format(page.idle.battery.dim)
        changed: page.idle.battery.dim !== App.Config.idle.battery.dim
        onResetRequested: page.idle.battery.dim = App.Config.idle.battery.dim
        onDecrement: page.idle.battery.dim = page.ss.stepDown(page.idle.battery.dim)
        onIncrement: page.idle.battery.dim = page.ss.stepUp(page.idle.battery.dim)
    }
    R.StepperRow {
        searchId: "idleBatteryLock"
        label: "Bloquear"
        hint: "Con batería"
        keywords: "bloqueo pantalla inactividad tiempo bateria"
        text: page.ss.format(page.idle.battery.lock)
        changed: page.idle.battery.lock !== App.Config.idle.battery.lock
        onResetRequested: page.idle.battery.lock = App.Config.idle.battery.lock
        onDecrement: page.idle.battery.lock = page.ss.stepDown(page.idle.battery.lock)
        onIncrement: page.idle.battery.lock = page.ss.stepUp(page.idle.battery.lock)
    }
    R.StepperRow {
        searchId: "idleBatteryScreenOff"
        label: "Apagar pantalla"
        hint: "Con batería"
        keywords: "dpms inactividad tiempo bateria"
        text: page.ss.format(page.idle.battery.screenOff)
        changed: page.idle.battery.screenOff !== App.Config.idle.battery.screenOff
        onResetRequested: page.idle.battery.screenOff = App.Config.idle.battery.screenOff
        onDecrement: page.idle.battery.screenOff = page.ss.stepDown(page.idle.battery.screenOff)
        onIncrement: page.idle.battery.screenOff = page.ss.stepUp(page.idle.battery.screenOff)
    }
    R.StepperRow {
        searchId: "idleBatterySuspend"
        label: "Suspender"
        hint: "Con batería"
        keywords: "dormir inactividad tiempo bateria"
        text: page.ss.format(page.idle.battery.suspend)
        changed: page.idle.battery.suspend !== App.Config.idle.battery.suspend
        onResetRequested: page.idle.battery.suspend = App.Config.idle.battery.suspend
        onDecrement: page.idle.battery.suspend = page.ss.stepDown(page.idle.battery.suspend)
        onIncrement: page.idle.battery.suspend = page.ss.stepUp(page.idle.battery.suspend)
    }

    R.Section {
        text: "Inactividad con cargador"
    }
    R.StepperRow {
        searchId: "idleAcDim"
        label: "Atenuar"
        hint: "Con cargador"
        keywords: "atenuar bajar brillo inactividad tiempo cargador enchufado"
        text: page.ss.format(page.idle.ac.dim)
        changed: page.idle.ac.dim !== App.Config.idle.ac.dim
        onResetRequested: page.idle.ac.dim = App.Config.idle.ac.dim
        onDecrement: page.idle.ac.dim = page.ss.stepDown(page.idle.ac.dim)
        onIncrement: page.idle.ac.dim = page.ss.stepUp(page.idle.ac.dim)
    }
    R.StepperRow {
        searchId: "idleAcLock"
        label: "Bloquear"
        hint: "Con cargador"
        keywords: "bloqueo pantalla inactividad tiempo cargador enchufado"
        text: page.ss.format(page.idle.ac.lock)
        changed: page.idle.ac.lock !== App.Config.idle.ac.lock
        onResetRequested: page.idle.ac.lock = App.Config.idle.ac.lock
        onDecrement: page.idle.ac.lock = page.ss.stepDown(page.idle.ac.lock)
        onIncrement: page.idle.ac.lock = page.ss.stepUp(page.idle.ac.lock)
    }
    R.StepperRow {
        searchId: "idleAcScreenOff"
        label: "Apagar pantalla"
        hint: "Con cargador"
        keywords: "dpms inactividad tiempo cargador enchufado"
        text: page.ss.format(page.idle.ac.screenOff)
        changed: page.idle.ac.screenOff !== App.Config.idle.ac.screenOff
        onResetRequested: page.idle.ac.screenOff = App.Config.idle.ac.screenOff
        onDecrement: page.idle.ac.screenOff = page.ss.stepDown(page.idle.ac.screenOff)
        onIncrement: page.idle.ac.screenOff = page.ss.stepUp(page.idle.ac.screenOff)
    }
    R.StepperRow {
        searchId: "idleAcSuspend"
        label: "Suspender"
        hint: "Con cargador"
        keywords: "dormir inactividad tiempo cargador enchufado"
        text: page.ss.format(page.idle.ac.suspend)
        changed: page.idle.ac.suspend !== App.Config.idle.ac.suspend
        onResetRequested: page.idle.ac.suspend = App.Config.idle.ac.suspend
        onDecrement: page.idle.ac.suspend = page.ss.stepDown(page.idle.ac.suspend)
        onIncrement: page.idle.ac.suspend = page.ss.stepUp(page.idle.ac.suspend)
    }

    R.Section {
        text: "Brillo y avisos"
    }
    R.SliderRow {
        searchId: "dimLevel"
        label: "Brillo al atenuar"
        keywords: "atenuar pantalla brillo"
        to: 0.5
        from: 0
        step: 0.01
        defaultValue: App.Config.idle.dimLevel
        value: page.idle.dimLevel
        onMoved: v => page.idle.dimLevel = Math.max(App.Config.brightness.min, v)
    }
    R.StepperRow {
        searchId: "lowWarn"
        label: "Aviso de batería baja"
        hint: "Porcentaje de carga (Apagado = sin aviso)."
        keywords: "bateria baja porcentaje aviso"
        text: page.ss.pctText(page.low.warn)
        changed: page.low.warn !== App.Config.idle.lowBattery.warn
        onResetRequested: page.low.warn = App.Config.idle.lowBattery.warn
        onDecrement: page.low.warn = page.ss.pctDown(page.low.warn)
        onIncrement: page.low.warn = page.ss.pctUp(page.low.warn)
    }
    R.StepperRow {
        searchId: "lowCritical"
        label: "Batería crítica"
        hint: "Porcentaje de carga (Apagado = sin aviso)."
        keywords: "bateria baja porcentaje aviso"
        text: page.ss.pctText(page.low.critical)
        changed: page.low.critical !== App.Config.idle.lowBattery.critical
        onResetRequested: page.low.critical = App.Config.idle.lowBattery.critical
        onDecrement: page.low.critical = page.ss.pctDown(page.low.critical)
        onIncrement: page.low.critical = page.ss.pctUp(page.low.critical)
    }
    R.StepperRow {
        searchId: "lowSuspend"
        label: "Suspender por batería"
        hint: "Porcentaje de carga (Apagado = sin aviso)."
        keywords: "bateria baja porcentaje aviso"
        text: page.ss.pctText(page.low.suspend)
        changed: page.low.suspend !== App.Config.idle.lowBattery.suspend
        onResetRequested: page.low.suspend = App.Config.idle.lowBattery.suspend
        onDecrement: page.low.suspend = page.ss.pctDown(page.low.suspend)
        onIncrement: page.low.suspend = page.ss.pctUp(page.low.suspend)
    }

    R.ActionRow {
        searchId: "resetEnergy"
        label: "Restablecer la energía"
        hint: "Vuelve la inactividad, los avisos y los perfiles a los valores de fábrica."
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: page.ss.resetSection("energy")
    }
}
