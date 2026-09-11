local map = require("keybinds.repository")

-- workspaces
map.add({ map.SUPER, "1" }, hl.dsp.focus({ workspace = 1 }), nil, "Ir al workspace 1")
map.add({ map.SUPER, "2" }, hl.dsp.focus({ workspace = 2 }), nil, "Ir al workspace 2")
map.add({ map.SUPER, "3" }, hl.dsp.focus({ workspace = 3 }), nil, "Ir al workspace 3")
map.add({ map.SUPER, "4" }, hl.dsp.focus({ workspace = 4 }), nil, "Ir al workspace 4")

-- mandar al workspace
map.add({ map.SUPER, map.SHIFT, "1" }, hl.dsp.window.move({ workspace = 1, follow = false }), nil,
    "Mandar al workspace 1")
map.add({ map.SUPER, map.SHIFT, "2" }, hl.dsp.window.move({ workspace = 2, follow = false }), nil,
    "Mandar al workspace 2")
map.add({ map.SUPER, map.SHIFT, "3" }, hl.dsp.window.move({ workspace = 3, follow = false }), nil,
    "Mandar al workspace 3")
map.add({ map.SUPER, map.SHIFT, "4" }, hl.dsp.window.move({ workspace = 4, follow = false }), nil,
    "Mandar al workspace 4")

-- Mandar ventana actual al stash (special workspace)
map.add({ map.SUPER, "A" }, function()
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
