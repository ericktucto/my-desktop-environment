import QtQuick
import "../rows/" as R
import "../../../services/sound/" as SND
import "../../../services/settings/" as ST
import "../../../" as App

// Sonidos del sistema: interruptor general, volumen y, por evento (notificaciones, dispositivos, energía y
// acciones de la shell), su interruptor, el sonido del tema y «Probar».
Page {
    id: page

    readonly property var store: SND.SoundStore
    readonly property var cfg: ST.SettingsStore.sounds
    readonly property var groups: ["Notificaciones", "Dispositivos", "Energía", "Acciones"]

    pageId: "sounds"
    pageName: "Sonidos"
    subtitle: "Los sonidos de la shell: del tema de sonidos del sistema (freedesktop) o un archivo tuyo (oga, ogg, wav, flac o mp3)."

    R.SwitchRow {
        searchId: "soundsEnabled"
        label: "Sonidos del sistema"
        hint: "El interruptor general: apagado, no suena ninguno."
        keywords: "audio silencio mute efectos"
        checked: page.cfg.enabled
        defaultValue: true
        onToggled: c => page.cfg.enabled = c
    }
    R.SliderRow {
        searchId: "soundsVolume"
        label: "Volumen de los sonidos"
        keywords: "audio efectos"
        defaultValue: 0.8
        value: page.cfg.volume
        onMoved: v => page.cfg.volume = v
        onReleased: page.store.playFile("message-new-instant")
    }

    Repeater {
        model: page.groups
        Column {
            id: grp
            required property string modelData
            width: page.width - 16
            spacing: 8

            R.Section {
                text: grp.modelData
            }
            Repeater {
                model: page.store.events.filter(e => e.group === grp.modelData)
                R.SoundRow {
                    required property var modelData
                    event: modelData
                }
            }
        }
    }

    R.ActionRow {
        searchId: "resetSounds"
        label: "Restablecer los sonidos"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: ST.SettingsStore.resetSection("sounds")
    }
}
