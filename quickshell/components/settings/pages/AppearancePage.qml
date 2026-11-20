import QtQuick
import "../rows/" as R
import "../../../services/settings/" as ST
import "../../../" as App

// Apariencia: animaciones y carpeta de wallpapers (el color de la shell se suma en el paso 1.3).
Page {
    pageId: "appearance"
    pageName: "Apariencia"
    subtitle: "Cómo se ve la shell."

    R.Section {
        text: "General"
    }
    R.SwitchRow {
        searchId: "animations"
        label: "Animaciones"
        hint: "Apagadas, las islas y los controles cambian al instante."
        keywords: "efectos movimiento transiciones"
        checked: ST.SettingsStore.appearance.animations
        defaultValue: true
        onToggled: c => ST.SettingsStore.appearance.animations = c
    }
    R.FileRow {
        searchId: "wallpaperDir"
        label: "Carpeta de wallpapers"
        hint: "De aquí salen las imágenes del selector (Super+W)."
        keywords: "fondo de pantalla imagenes"
        value: ST.SettingsStore.appearance.wallpaperDir
        defaultText: App.Config.wallpaperPicker.dir
        dialogTitle: "Elegir la carpeta de wallpapers"
        onPicked: p => ST.SettingsStore.appearance.wallpaperDir = p
    }
}
