local map = require("keybinds.repository")

local mirrored = false
local function toggleMirror()
    mirrored = not mirrored
    hl.monitor({
        output = "HDMI-A-1",
        mode = "preferred",
        position = "auto",
        scale = 1,
        mirror = mirrored and "eDP-1" or "",
    })
end

map.add({ map.SUPER, map.SHIFT, "P" }, toggleMirror, nil, "Toggle Espejar")
