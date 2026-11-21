local map = require("keybinds.repository")
map.group("Multimedia")

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

-- Brillo. Sin respaldo: si la shell no corre, acpid (handler.sh) ya maneja estas teclas.
-- Para que acpid no lo haga también mientras qs corre: sudo sh system/acpi-shell-keys.sh
map.add({ "XF86MonBrightnessUp" }, hl.dsp.exec_cmd("qs ipc call stixshell@brightness up"),
    { locked = true, repeating = true }, "Subir el brillo")
map.add({ "XF86MonBrightnessDown" }, hl.dsp.exec_cmd("qs ipc call stixshell@brightness down"),
    { locked = true, repeating = true }, "Bajar el brillo")

-- Reproductor multimedia (MPRIS). Llaman a la shell por IPC; si no corre, `playerctl` hace lo mismo.
-- locked: también con la pantalla bloqueada.
local function player(fn, fallback)
    return hl.dsp.exec_cmd("sh -c 'qs ipc call stixshell@media " .. fn .. " || playerctl " .. fallback .. "'")
end

map.add({ "XF86AudioPlay" }, player("playPause", "play-pause"), { locked = true }, "Reproducir o pausar")
map.add({ "XF86AudioPause" }, player("playPause", "play-pause"), { locked = true }, "Reproducir o pausar")
map.add({ "XF86AudioNext" }, player("next", "next"), { locked = true }, "Canción siguiente")
map.add({ "XF86AudioPrev" }, player("previous", "previous"), { locked = true }, "Canción anterior")

-- Shift avisa a la shell mientras está pulsado: la rueda sobre el reloj (isla central) cambia el brillo con
-- Shift, y la barra no recibe los modificadores del teclado. Solo avisa con el cursor sobre la barra (arriba,
-- 44 px = Config.bar.exclusiveZone), para no lanzar procesos con cada mayúscula que se escribe.
-- non_consuming: Shift sigue llegando a las apps.
local BAR_HEIGHT = 44
local shiftSent = false

local function cursorOnBar()
    local c, m = hl.get_cursor_pos(), hl.get_active_monitor()
    return c and m and c.y >= m.y and c.y < m.y + BAR_HEIGHT
end

for _, key in ipairs({ "Shift_L", "Shift_R" }) do
    hl.bind(key, function()
        if not shiftSent and cursorOnBar() then
            shiftSent = true
            hl.exec_cmd("qs ipc call stixshell@island shift true")
        end
    end, { non_consuming = true })
    hl.bind(key, function()
        if shiftSent then
            shiftSent = false
            hl.exec_cmd("qs ipc call stixshell@island shift false")
        end
    end, { release = true, non_consuming = true })
end
