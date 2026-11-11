local M = {}

function M.start()
    -- ══ ENTORNO (siempre primero) ══
    hl.exec_cmd('dbus-update-activation-environment --all')

    -- ══ PORTALES (crítico que estén antes que apps GTK) ══
    hl.exec_cmd('/usr/libexec/xdg-desktop-portal-hyprland')
    hl.exec_cmd('/usr/libexec/xdg-desktop-portal')

    -- ══ POLKIT (para privilegios: brightness, etc.) ══
    hl.exec_cmd('hyprpolkitagent')

    -- ══ AUDIO ══
    hl.exec_cmd('pipewire')
    hl.exec_cmd('pipewire-pulse')
    hl.exec_cmd('wireplumber')

    -- ══ RED (applet de NetworkManager) ══
    --hl.exec_cmd('nm-applet')

    -- ══ BLUETOOTH (opcional) ══
    --hl.exec_cmd('blueman-applet')

    -- ══ BLOQUEO (hypridle: bloquea antes de dormir; la shell maneja la inactividad) ══
    hl.exec_cmd('hypridle')

    -- ══ PORTAPAPELES (historial de la shell: un vigilante por tipo, para que las imágenes no se guarden como HTML) ══
    hl.exec_cmd('wl-paste --type text --watch cliphist store')
    hl.exec_cmd('wl-paste --type image --watch cliphist store')

    -- ══ SHELL ══
    hl.exec_cmd('qs')
end

return M
