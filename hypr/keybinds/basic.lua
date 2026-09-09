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

-- Mandar ventana actual al stash (special workspace)
map.add({ map.SUPER, "W" }, function()
    local win = hl.get_active_window()

    if not win then return nil end

    if win.workspace.name == "special:stash" then
        local current = hl.get_active_workspace()

        if not current then return nil end

        hl.dsp.window.move({
            workspace = tostring(current.id),
            window = win.address
        })
        hl.dsp.focus({ window = win.address })

        return nil
    end
    hl.dsp.window.move({ workspace = "special:stash" })
end, nil, "Toggle ventana stash <-> actual")

-- Ver/ocultar el stash
map.add({ map.SUPER, "S" }, hl.dsp.workspace.toggle_special("stash"), nil, "Ver/ocultar el stash")

-- launcher
map.add({ map.SUPER, "R" }, hl.dsp.exec_cmd("qs ipc call stixshell@launcher toggle \"\""), nil, "Abrir el launcher")
map.add({ map.SUPER, "W" }, hl.dsp.exec_cmd("qs ipc call stixshell@wallpaper toggle \"\""), nil,
    "Abrir el selector de wallpapers")
