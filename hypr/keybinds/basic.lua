local map = require("keybinds.repository")
local terminal = "kitty"

map.add({ map.SUPER, "T" }, hl.dsp.exec_cmd(terminal), nil, "Abrir la terminal")
map.add({ map.SUPER, "Q" }, hl.dsp.window.close(), nil, "Cerrar ventana activa")

-- pantalla completa (entra y sale con el mismo atajo) y ventanas flotantes con el mouse
map.add({ map.SUPER, map.SHIFT, "F" }, hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), nil,
    "Pantalla completa (entrar/salir)")
map.add({ map.SUPER, "V" }, hl.dsp.window.float({ action = "toggle" }), nil, "Ventana flotante (alternar)")
map.add({ map.SUPER, map.SHIFT, "V" }, hl.dsp.window.pin({ action = "toggle" }), nil,
    "Fijar en todos los workspaces (flotante)")
map.add({ map.SUPER, "CTRL", "V" }, hl.dsp.window.center(), nil, "Centrar ventana flotante")
map.add({ map.SUPER, map.SHIFT, "G" }, hl.dsp.group.toggle(), nil, "Agrupar en pestañas (alternar)")
map.add({ map.SUPER, "mouse:272" }, hl.dsp.window.drag(), { mouse = true }, "Mover ventana flotante")
map.add({ map.SUPER, "mouse:273" }, hl.dsp.window.resize(), { mouse = true }, "Redimensionar ventana flotante")

-- isla de la ventana activa: Super+. (acciones de la ventana) y Super+Shift+. (acciones de la app)
map.add({ map.SUPER, "period" }, hl.dsp.exec_cmd("qs ipc call stixshell@window toggle window"), nil,
    "Menú de la ventana activa")
map.add({ map.SUPER, map.SHIFT, "period" }, hl.dsp.exec_cmd("qs ipc call stixshell@window toggle app"), nil,
    "Menú de la app de la ventana activa")

-- preferencias del sistema (abre y cierra)
map.add({ map.SUPER, "comma" }, hl.dsp.exec_cmd("qs ipc call stixshell@settings toggle"), nil,
    "Preferencias del sistema")

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

-- productividad: calendario (y luego tareas y temporizador)
map.add({ map.SUPER, "P" }, hl.dsp.exec_cmd("qs ipc call stixshell@productivity toggle \"\""), nil, "Productividad (calendario)")

-- tareas: añadir una tarea desde cualquier lado (quick add)
map.add({ map.SUPER, map.SHIFT, "T" }, hl.dsp.exec_cmd("qs ipc call stixshell@tasks quickadd"), nil, "Añadir una tarea")

-- luz nocturna (wlsunset)
map.add({ map.SUPER, "N" }, hl.dsp.exec_cmd("qs ipc call stixshell@nightlight toggle"), nil, "Luz nocturna")

-- capturador de pantalla (área, ventana o pantalla; con Editor para anotar). Con el capturador abierto, lo cancela.
map.add({ "Print" }, hl.dsp.exec_cmd("qs ipc call stixshell@screenshot open"), nil, "Capturar la pantalla")
map.add({ map.SUPER, map.SHIFT, "S" }, hl.dsp.exec_cmd("qs ipc call stixshell@screenshot open"), nil,
    "Capturar la pantalla")
