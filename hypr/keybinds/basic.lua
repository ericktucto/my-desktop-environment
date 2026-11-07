local map = require("keybinds.repository")
local terminal = "kitty"

map.add({ map.SUPER, "T" }, hl.dsp.exec_cmd(terminal), nil, "Abrir la terminal")
map.add({ map.SUPER, "Q" }, hl.dsp.window.close(), nil, "Cerrar ventana activa")

-- menú de sesión
map.add({ map.SUPER, "Escape" }, hl.dsp.exec_cmd("qs ipc call stixshell@session toggle \"\""), nil, "Menú de sesión")
map.add({ "XF86PowerOff" }, hl.dsp.exec_cmd("qs ipc call stixshell@session toggle \"\""), nil,
    "Menú de sesión (botón de encendido)")

-- launcher
map.add({ map.SUPER, "R" }, hl.dsp.exec_cmd("qs ipc call stixshell@launcher toggle \"\""), nil, "Abrir el launcher")
map.add({ map.SUPER, "W" }, hl.dsp.exec_cmd("qs ipc call stixshell@wallpaper toggle \"\""), nil,
    "Abrir el selector de wallpapers")
