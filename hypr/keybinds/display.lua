local map = require("keybinds.repository")
map.group("Pantallas")

-- Modo de pantallas (como Win+P): espejo → extender → solo externo → solo portátil.
-- Lo hace la shell (Preferencias del sistema → Pantallas) y guarda la configuración.
map.add({ map.SUPER, map.SHIFT, "P" }, hl.dsp.exec_cmd("qs ipc call stixshell@display cycle"), nil,
    "Cambiar el modo de pantallas")
