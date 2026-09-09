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

    -- ══ NOTIFICACIONES ══
    hl.exec_cmd('mako')

    -- ══ RED (applet de NetworkManager) ══
    --hl.exec_cmd('nm-applet')

    -- ══ BLUETOOTH (opcional) ══
    --hl.exec_cmd('blueman-applet')

    -- ══ SHELL ══
    hl.exec_cmd('qs')
end

return M
