local map = require("keybinds.repository")
local terminal = "kitty"

map.add({ map.SUPER, "T" }, hl.dsp.exec_cmd(terminal), nil, "Abrir la terminal")
map.add({ map.SUPER, "Q" }, hl.dsp.window.close(), nil, "Cerrar ventana activa")
map.add({ map.SUPER, map.SHIFT, "E" }, hl.dsp.exit(), nil, "Salir de Hyprland")

-- workspaces
map.add({ map.SUPER, "1" }, hl.dsp.focus({ workspace = 1 }), nil, "Ir al workspace 1")
map.add({ map.SUPER, "2" }, hl.dsp.focus({ workspace = 2 }), nil, "Ir al workspace 2")
map.add({ map.SUPER, "3" }, hl.dsp.focus({ workspace = 3 }), nil, "Ir al workspace 3")
map.add({ map.SUPER, "4" }, hl.dsp.focus({ workspace = 4 }), nil, "Ir al workspace 4")
