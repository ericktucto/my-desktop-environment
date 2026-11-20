-- ============================================
-- CONFIGURACIÓN MÍNIMA DE HYPRLAND EN LUA
-- ============================================

local autostart = require("autostart")


-- Variables
local mainMod = "SUPER"

local CURSOR_THEME = "Future-cursors"
local CURSOR_SIZE = "24"
hl.env("XCURSOR_THEME", CURSOR_THEME)
hl.env("XCURSOR_SIZE", CURSOR_SIZE)
hl.env("HYPRCURSOR_THEME", CURSOR_THEME)
hl.env("HYPRCURSOR_SIZE", CURSOR_SIZE)

require("keybinds")

-- Monitores: los de Preferencias del sistema → Pantallas (monitors.lua, generado y fuera de git).
-- Sin ese archivo quedan los de siempre: la laptop y el HDMI en espejo.
local monitorsOk = pcall(require, "monitors")
if not monitorsOk then
    hl.monitor({
        output = "eDP-1",
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1,
    })

    -- Monitor espejado
    hl.monitor({
        output = "HDMI-A-1",
        mode = "preferred",
        position = "auto",
        scale = 1,
        mirror = "eDP-1",
    })
end

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_CACHE_HOME", os.getenv("HOME") .. "/.cache/hypr")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.on('hyprland.start', function()
    autostart.start()
end)

-- ============================================
-- CONFIG GENERAL (efectos apagados para tus 8GB + Vega)
-- ============================================
hl.config({
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
    general = {
        gaps_in = 4,
        gaps_out = {
            left = 8,
            right = 8,
            bottom = 8,
            top = 0,
        },
        border_size = 1,
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        blur = { enabled = false },   -- blur come GPU/RAM
        shadow = { enabled = false }, -- sombras fuera
    },
    animations = {
        enabled = false, -- sin animaciones = más ligero
    },
    input = {
        follow_mouse = false,
        kb_layout = "latam", -- tu teclado (la-latin1 → latam en XKB)
    },
    misc = {
        disable_hyprland_logo = true,
        allow_session_lock_restore = true, -- si qs se cae estando bloqueado, se puede volver a bloquear
        --vfr = true,                   -- variable refresh, ahorra batería
    },
})

-- Colores del wallpaper: scripts/theme.py (de la shell) escribe colors.lua (fuera de git) y los aplica en caliente.
-- Sin ese archivo quedan los bordes por defecto de Hyprland.
local ok, colors = pcall(require, "colors")
if ok and type(colors) == "table" then
    hl.config({ general = { col = { active_border = colors.active, inactive_border = colors.inactive } } })
end

-- ============================================
-- KEYBINDS
-- ============================================
-- Keybinds para cambiar (opcional, además del clic)

hl.window_rule({ "maximize", "class:.*" })

-- Preferencias del sistema (ventana de la shell): flotante y centrada; el tamaño lo pone la shell (cabe en la pantalla)
hl.window_rule({
    name  = "stixshell-settings",
    match = { title = "^Preferencias del sistema$" },

    float  = true,
    center = true,
})

-- ============================================
-- MODO TABLET: ocultar/mostrar apps
-- ============================================

-- ============================================
-- CAMBIAR ENTRE VENTANAS
-- ============================================

-- ============================================
-- MAXIMIZE (entrar/salir de pantalla completa)
-- ============================================
