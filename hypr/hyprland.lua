-- ============================================
-- CONFIGURACIÓN MÍNIMA DE HYPRLAND EN LUA
-- ============================================

local autostart = require("autostart")


-- Variables
local mainMod = "SUPER"
require("keybinds.basic")

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
-- Lanzar el DAEMON de pyprland al inicio (con guarda anti-duplicado)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

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
        gaps_out = 8,
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
        --vfr = true,                   -- variable refresh, ahorra batería
    },
})

-- ============================================
-- KEYBINDS
-- ============================================
-- Keybinds para cambiar (opcional, además del clic)

hl.window_rule({ "maximize", "class:.*" })

-- ============================================
-- MODO TABLET: ocultar/mostrar apps
-- ============================================

-- ============================================
-- CAMBIAR ENTRE VENTANAS
-- ============================================
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }))

-- ============================================
-- MAXIMIZE (entrar/salir de pantalla completa)
-- ============================================
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
