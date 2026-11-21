local map = require("keybinds.repository")
map.group("Workspaces")

-- Los de 1 a 10 (Super+1…9, Super+0). La cantidad que se usa la elige Preferencias → Barra e isla: la shell la deja
-- en ~/.cache/stixshell/workspaces y se lee al pulsar (sin el archivo, valen los 10); los que pasan de ella no hacen nada.
local function count()
    local f = io.open(os.getenv("HOME") .. "/.cache/stixshell/workspaces", "r")
    local n = f and tonumber(f:read("l")) or 10
    if f then f:close() end
    return n
end

for n = 1, 10 do
    local key = tostring(n % 10)
    map.add({ map.SUPER, key }, function()
        if n <= count() then hl.dispatch(hl.dsp.focus({ workspace = n })) end
    end, nil, "Ir al workspace " .. n)
end

-- vista general de workspaces
map.add({ map.SUPER, "Tab" }, hl.dsp.exec_cmd("qs ipc call stixshell@workspaces toggle \"\""), nil,
    "Vista general de workspaces")

-- mandar al workspace
for n = 1, 10 do
    local key = tostring(n % 10)
    map.add({ map.SUPER, map.SHIFT, key }, function()
        if n <= count() then hl.dispatch(hl.dsp.window.move({ workspace = n, follow = false })) end
    end, nil, "Mandar al workspace " .. n)
end

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
