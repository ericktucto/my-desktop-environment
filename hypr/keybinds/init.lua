require "keybinds.basic"
require "keybinds.workspaces"
require "keybinds.media"
require "keybinds.display"

-- Los atajos que no están en esos archivos y la lista para la shell
local map = require("keybinds.repository")
map.group("Ventanas")
map.add({ "ALT", "Tab" }, hl.dsp.window.cycle_next(), nil, "Ventana siguiente")
map.add({ "ALT", "SHIFT", "Tab" }, hl.dsp.window.cycle_next({ prev = true }), nil, "Ventana anterior")
map.add({ map.SUPER, "F" }, hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), nil, "Maximizar (alternar)")

-- Submapa vacío: la shell lo usa mientras graba una combinación nueva (Preferencias → Atajos), así ningún atajo
-- se dispara. Alt+F12 sale por si algo falla.
hl.define_submap("stix-record", "reset", function()
    hl.bind("ALT + F12", hl.dsp.submap("reset"))
end)

map.export()
