local map = require("keybinds.repository")

-- Teclas multimedia. Llaman a la shell por IPC (así respetan el tope de 100 %/150 %);
-- si la shell no corre, `wpctl` hace lo mismo directamente.
-- locked: también funcionan con la pantalla bloqueada. repeating: mantener pulsado repite.
local function audio(fn, fallback)
    return hl.dsp.exec_cmd("sh -c 'qs ipc call stixshell@audio " .. fn .. " || " .. fallback .. "'")
end

local sink = "@DEFAULT_AUDIO_SINK@"
local source = "@DEFAULT_AUDIO_SOURCE@"

map.add({ "XF86AudioRaiseVolume" }, audio("up", "wpctl set-volume -l 1 " .. sink .. " 5%+"),
    { locked = true, repeating = true }, "Subir el volumen")
map.add({ "XF86AudioLowerVolume" }, audio("down", "wpctl set-volume " .. sink .. " 5%-"),
    { locked = true, repeating = true }, "Bajar el volumen")
map.add({ "XF86AudioMute" }, audio("mute", "wpctl set-mute " .. sink .. " toggle"),
    { locked = true }, "Silenciar el audio")
map.add({ "XF86AudioMicMute" }, audio("micMute", "wpctl set-mute " .. source .. " toggle"),
    { locked = true }, "Silenciar el micrófono")
