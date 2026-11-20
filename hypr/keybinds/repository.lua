-- Registro de atajos: cada uno con su id (la combinación de fábrica), su descripción y su grupo.
-- Preferencias del sistema → Atajos puede cambiar o quitar un atajo: los cambios van en keybinds/user.lua
-- (generado por la shell, fuera de git): { ["SUPER + Q"] = "SUPER + SHIFT + Q", ["SUPER + L"] = false }.
-- La lista se exporta a ~/.cache/stixshell/keybinds.json para que la shell la muestre.
local S = {}

S.state = {}  -- id → { id, bind, default, description, group }
S.order = {}  -- ids en el orden en que se registraron
S.handles = {} -- id → atajo registrado en Hyprland
S.callbacks = {} -- id → { callback, opts }
S.group = "General"

local M = {}

M.SUPER = "SUPER"
M.SHIFT = "SHIFT"

local okUser, overrides = pcall(require, "keybinds.user")
if not okUser or type(overrides) ~= "table" then
    overrides = {}
end

-- Grupo de los atajos que se registren a continuación
function M.group(name)
    S.group = name
end

function M.add(bind, callback, opts, description)
    local id = type(bind) == "table" and table.concat(bind, " + ") or bind
    local active = id
    local ov = overrides[id]
    if ov == false then
        active = nil
    elseif type(ov) == "string" then
        active = ov
    end
    if not S.state[id] then
        table.insert(S.order, id)
    end
    S.state[id] = {
        id = id,
        bind = active,
        default = id,
        description = description,
        group = S.group,
    }
    S.callbacks[id] = { callback = callback, opts = opts }
    if active then
        S.handles[id] = hl.bind(active, callback, opts)
    end
end

-- Cambia un atajo en vivo: `new` = la combinación nueva, o nil para quitarlo
function M.rebind(id, new)
    local entry = S.state[id]
    local cb = S.callbacks[id]
    if not entry or not cb then
        return false
    end
    if S.handles[id] then
        S.handles[id]:remove()
        S.handles[id] = nil
    end
    if new and new ~= "" then
        S.handles[id] = hl.bind(new, cb.callback, cb.opts)
        entry.bind = new
    else
        entry.bind = nil
    end
    M.export()
    return true
end

local function esc(s)
    return (tostring(s):gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' end
        if c == "\\" then return "\\\\" end
        if c == "\n" then return "\\n" end
        return string.format("\\u%04x", string.byte(c))
    end))
end

-- Escribe ~/.cache/stixshell/keybinds.json con todos los atajos
function M.export()
    local out = {}
    for _, id in ipairs(S.order) do
        local e = S.state[id]
        table.insert(out, string.format('{"id":"%s","bind":%s,"default":"%s","description":"%s","group":"%s"}',
            esc(e.id), e.bind and ('"' .. esc(e.bind) .. '"') or "null", esc(e.default), esc(e.description or ""),
            esc(e.group)))
    end
    local dir = (os.getenv("HOME") or "") .. "/.cache/stixshell"
    local f = io.open(dir .. "/keybinds.json", "w")
    if f then
        f:write("[" .. table.concat(out, ",") .. "]\n")
        f:close()
    end
end

function M.state()
    return S.state
end

return M
