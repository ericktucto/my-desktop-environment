import QtQuick
import "../rows/" as R
import "../../../services/nightlight/" as NL
import "../../../services/settings/" as ST
import "../../../" as App

// Luz nocturna (hyprsunset): interruptor, horario, horas, temperatura, ubicación y pausa. Es lo mismo que la
// vista del centro de control.
Page {
    id: page

    readonly property var store: NL.NightLightStore
    readonly property var st: ST.SettingsStore.nightLight
    readonly property var cfg: App.Config.nightLight
    // La temperatura se aplica al soltar el deslizador (cada cambio reinicia el filtro)
    property real pending: st.temperature

    pageId: "nightlight"
    pageName: "Luz nocturna"
    subtitle: store.statusText

    R.SwitchRow {
        searchId: "nlEnabled"
        label: "Luz nocturna"
        hint: page.store.available ? "Entibia los colores de la pantalla de noche." : "Instala hyprsunset para usar la luz nocturna."
        keywords: "filtro azul hyprsunset color calido"
        enabled: page.store.available
        checked: page.store.enabled
        changed: false
        onToggled: c => page.store.setEnabled(c)
    }
    R.ChoiceRow {
        searchId: "nlMode"
        label: "Horario"
        hint: page.store.scheduleText
        keywords: "atardecer amanecer horas fijas siempre"
        options: [
            {
                id: "sun",
                label: "Atardecer a amanecer"
            },
            {
                id: "custom",
                label: "Horas fijas"
            },
            {
                id: "always",
                label: "Siempre"
            }
        ]
        value: page.st.mode
        defaultValue: "sun"
        onPicked: id => page.store.setMode(id)
    }
    R.StepperRow {
        visible: page.st.mode === "custom"
        searchId: "nlStart"
        label: "Desde"
        keywords: "hora inicio"
        text: page.st.start
        onDecrement: page.store.stepTime("start", -1)
        onIncrement: page.store.stepTime("start", 1)
    }
    R.StepperRow {
        visible: page.st.mode === "custom"
        searchId: "nlEnd"
        label: "Hasta"
        keywords: "hora fin"
        text: page.st.end
        onDecrement: page.store.stepTime("end", -1)
        onIncrement: page.store.stepTime("end", 1)
    }
    R.SliderRow {
        searchId: "nlTemp"
        label: "Temperatura"
        hint: page.store.tempWord(page.pending)
        keywords: "kelvin calido frio color"
        from: page.cfg.tempMin
        to: page.cfg.tempMax
        step: page.cfg.tempStep
        defaultValue: page.cfg.temperature
        value: page.pending
        format: v => Math.round(v) + " K"
        onMoved: v => page.pending = v
        onReleased: page.store.setTemperature(page.pending)
        onResetRequested: {
            page.pending = page.cfg.temperature;
            page.store.setTemperature(page.pending);
        }
    }
    R.ActionRow {
        visible: page.store.enabled && page.store.paused
        label: "Pausada hasta mañana"
        actionLabel: "Reanudar"
        onTriggered: page.store.resume()
    }

    R.Section {
        text: "Ubicación"
    }
    R.TextRow {
        searchId: "nlLat"
        label: "Latitud"
        hint: "Para calcular el atardecer. Vacío = de la zona horaria."
        keywords: "ubicacion coordenadas sol"
        value: page.st.latitude
        placeholder: String(page.store.zoneLat)
        fieldWidth: 120
        onAccepted: t => page.st.latitude = t.trim()
    }
    R.TextRow {
        searchId: "nlLon"
        label: "Longitud"
        keywords: "ubicacion coordenadas sol"
        value: page.st.longitude
        placeholder: String(page.store.zoneLon)
        fieldWidth: 120
        onAccepted: t => page.st.longitude = t.trim()
    }
    R.ActionRow {
        searchId: "resetNl"
        label: "Restablecer la luz nocturna"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: ST.SettingsStore.resetSection("nightLight")
    }
}
