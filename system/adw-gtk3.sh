#!/bin/sh
# Prepara GTK para los colores del wallpaper (quickshell/scripts/theme.py). No usa sudo.
#   - descarga adw-gtk3 (el tema GTK3 que entiende los colores de libadwaita; no está en los repos de Void)
#     a ~/.local/share/themes
#   - pone adw-gtk3-dark, el modo oscuro y los íconos Papirus-Dark (en gtk-3.0, gtk-4.0 y gsettings)
#   - mueve a ~/.config/gtk-4.0/whitesur-backup los enlaces de WhiteSur que había en gtk-4.0
#   - pide a la shell que regenere los colores (escribe gtk-3.0/gtk.css y gtk-4.0/gtk.css)
# Las apps abiertas toman los colores al volver a abrirse.
# Uso: sh system/adw-gtk3.sh            (instalar y aplicar)
#      sh system/adw-gtk3.sh --restore  (volver a WhiteSur-Light, Papirus-Light y el modo claro)
set -e
THEMES="$HOME/.local/share/themes"
CFG="$HOME/.config"
BACKUP="$CFG/gtk-4.0/whitesur-backup"

set_ini() { # archivo clave valor
    [ -f "$1" ] || return 0
    if grep -q "^$2=" "$1"; then
        sed -i "s|^$2=.*|$2=$3|" "$1"
    else
        echo "$2=$3" >> "$1"
    fi
}

apply() { # tema íconos oscuro(1|0) esquema
    for v in gtk-3.0 gtk-4.0; do
        set_ini "$CFG/$v/settings.ini" gtk-theme-name "$1"
        set_ini "$CFG/$v/settings.ini" gtk-icon-theme-name "$2"
        set_ini "$CFG/$v/settings.ini" gtk-application-prefer-dark-theme "$3"
    done
    gsettings set org.gnome.desktop.interface gtk-theme "$1" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$2" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "$4" 2>/dev/null || true
}

if [ "$1" = "--restore" ]; then
    # Los gtk.css generados salen; los enlaces de WhiteSur vuelven
    for v in gtk-3.0 gtk-4.0; do
        [ -f "$CFG/$v/gtk.css" ] && [ ! -L "$CFG/$v/gtk.css" ] && rm "$CFG/$v/gtk.css"
    done
    if [ -d "$BACKUP" ]; then
        for f in "$BACKUP"/*; do
            mv "$f" "$CFG/gtk-4.0/"
        done
        rmdir "$BACKUP"
    fi
    apply WhiteSur-Light Papirus-Light 0 prefer-light
    echo "GTK vuelve a WhiteSur-Light"
    exit 0
fi

if [ ! -d "$THEMES/adw-gtk3-dark" ]; then
    echo "descargando adw-gtk3…"
    url=$(curl -fsSL https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | grep browser_download_url | grep 'tar.xz' | head -n 1 | cut -d '"' -f 4)
    [ -n "$url" ] || { echo "no encontré la descarga de adw-gtk3 (GitHub); no cambié nada"; exit 1; }
    mkdir -p "$THEMES"
    curl -fsSL "$url" | tar -xJ -C "$THEMES"
fi
[ -d "$THEMES/adw-gtk3-dark" ] || { echo "falta $THEMES/adw-gtk3-dark; no cambié nada"; exit 1; }

# gtk-4.0 tenía enlaces a WhiteSur: se apartan (no se borran)
mkdir -p "$BACKUP"
for n in gtk.css gtk-dark.css assets; do
    [ -L "$CFG/gtk-4.0/$n" ] && mv "$CFG/gtk-4.0/$n" "$BACKUP/"
done
rmdir "$BACKUP" 2>/dev/null || true

apply adw-gtk3-dark Papirus-Dark 1 prefer-dark
echo "GTK usa adw-gtk3-dark"
qs ipc call stixshell@theme regen >/dev/null 2>&1 || echo "con la shell corriendo: qs ipc call stixshell@theme regen"
