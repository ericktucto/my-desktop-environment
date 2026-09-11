local map = require("keybinds.repository")
local terminal = "kitty"

map.add({ map.SUPER, "T" }, hl.dsp.exec_cmd(terminal), nil, "Abrir la terminal")
map.add({ map.SUPER, "Q" }, hl.dsp.window.close(), nil, "Cerrar ventana activa")
map.add({ map.SUPER, map.SHIFT, "E" }, hl.dsp.exit(), nil, "Salir de Hyprland")

-- launcher
map.add({ map.SUPER, "R" }, hl.dsp.exec_cmd("qs ipc call stixshell@launcher toggle \"\""), nil, "Abrir el launcher")
map.add({ map.SUPER, "W" }, hl.dsp.exec_cmd("qs ipc call stixshell@wallpaper toggle \"\""), nil,
    "Abrir el selector de wallpapers")
