import QtQuick
import "../rows/" as R
import "../../../services/settings/" as ST
import "../../../services/theme/" as T
import "../../../" as App

// Apariencia: los colores de la shell (los mismos del selector de wallpapers, Super+W), las animaciones y la
// carpeta de wallpapers.
Page {
    id: page

    readonly property var theme: T.ThemeStore
    readonly property var cfg: App.Config.theme

    pageId: "appearance"
    pageName: "Apariencia"
    subtitle: "Cómo se ve la shell."

    R.Section {
        text: "Colores"
    }
    R.ChoiceRow {
        searchId: "colorMode"
        label: "Modo de color"
        hint: page.cfg.modes.find(m => m.id === page.theme.mode)?.hint ?? ""
        keywords: "tema acento wallpaper paleta matugen"
        options: page.cfg.modes
        value: page.theme.mode
        defaultValue: "scheme"
        onPicked: id => page.theme.setMode(id)
    }
    R.ColorRow {
        visible: page.theme.mode === "custom"
        searchId: "accent"
        label: "Acento propio"
        hint: "Un color «#rrggbb» (también con el gotero del selector de wallpapers)."
        keywords: "color acento principal"
        value: page.theme.color
        defaultValue: "#2979ff"
        onPicked: hex => page.theme.setColor(hex)
    }
    R.ChoiceRow {
        visible: page.theme.mode === "scheme"
        searchId: "scheme"
        label: "Estilo de la paleta"
        hint: "Cómo se saca la paleta de la imagen."
        keywords: "esquema suave fiel vibrante expresivo"
        options: page.cfg.schemes
        value: page.theme.scheme
        defaultValue: "scheme-tonal-spot"
        onPicked: id => page.theme.setScheme(id)
    }
    R.ChoiceRow {
        visible: page.theme.mode === "scheme"
        searchId: "tint"
        label: "Intensidad del borde"
        hint: "Qué tan marcado es el borde fino de color."
        keywords: "tinte sutil intensa borde"
        options: page.cfg.tints
        value: page.theme.tint
        defaultValue: "tinted"
        onPicked: id => page.theme.setTint(id)
    }

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
    R.ActionRow {
        searchId: "resetAppearance"
        label: "Restablecer la apariencia"
        hint: "Vuelve el modo de color, el acento, las animaciones y la carpeta a los valores de fábrica."
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: {
            ST.SettingsStore.resetSection("theme");
            ST.SettingsStore.resetSection("appearance");
        }
    }
}
