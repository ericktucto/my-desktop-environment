local map = require("keybinds.repository")
local terminal = "kitty"

map.add({ map.SUPER, "T" }, hl.dsp.exec_cmd(terminal), nil, "Abrir la terminal")
map.add({ map.SUPER, "Q" }, hl.dsp.window.close(), nil, "Cerrar ventana activa")

-- menú de sesión
map.add({ map.SUPER, "Escape" }, hl.dsp.exec_cmd("qs ipc call stixshell@session toggle \"\""), nil, "Menú de sesión")
map.add({ "XF86PowerOff" }, hl.dsp.exec_cmd("qs ipc call stixshell@session toggle \"\""), nil,
    "Menú de sesión (botón de encendido)")

-- bloquear la pantalla
map.add({ map.SUPER, "L" }, hl.dsp.exec_cmd("qs ipc call stixshell@lock lock"), nil, "Bloquear la pantalla")

-- centro de control (brillo, volumen, micrófono, No molestar)
map.add({ map.SUPER, "C" }, hl.dsp.exec_cmd("qs ipc call stixshell@controlcenter toggle \"\""), nil, "Centro de control")

-- historial del portapapeles
map.add({ map.SUPER, "H" }, hl.dsp.exec_cmd("qs ipc call stixshell@clipboard toggle \"\""), nil,
    "Historial del portapapeles")

-- launcher
map.add({ map.SUPER, "R" }, hl.dsp.exec_cmd("qs ipc call stixshell@launcher toggle \"\""), nil, "Abrir el launcher")
map.add({ map.SUPER, "W" }, hl.dsp.exec_cmd("qs ipc call stixshell@wallpaper toggle \"\""), nil,
    "Abrir el selector de wallpapers")

-- grabador de pantalla (abre el menú; con una grabación en curso, la detiene)
map.add({ map.SUPER, "G" }, hl.dsp.exec_cmd("qs ipc call stixshell@recorder toggle \"\""), nil, "Grabar la pantalla")
