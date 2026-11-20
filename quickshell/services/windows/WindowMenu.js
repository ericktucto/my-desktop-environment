.pragma library

// Acciones de ventana para el menú de la pill de la ventana activa. Puro, para probarlo con node:
// cada función devuelve el texto Lua que se manda a `Hyprland.dispatch` (API Lua de Hyprland 0.56).
// Todas apuntan a una ventana por su dirección, no a la enfocada.

function sel(address) {
    return "address:0x" + String(address).replace(/^0x/, "");
}

function win(address) {
    return 'window = "' + sel(address) + '"';
}

// workspace: número o "special:stash". Sin seguir la ventana (como Super+Shift+N)
function move(address, workspace) {
    var ws = typeof workspace === "number" ? String(workspace) : '"' + workspace + '"';
    return "hl.dsp.window.move({ workspace = " + ws + ", " + win(address) + ", follow = false })";
}

function toggleFloat(address) {
    return 'hl.dsp.window.float({ action = "toggle", ' + win(address) + " })";
}

function pin(address) {
    return 'hl.dsp.window.pin({ action = "toggle", ' + win(address) + " })";
}

function center(address) {
    return "hl.dsp.window.center({ " + win(address) + " })";
}

// Maximizar (como Super+F) y pantalla completa de verdad
function maximize(address) {
    return 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", ' + win(address) + " })";
}

function fullscreen(address) {
    return 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle", ' + win(address) + " })";
}

function close(address) {
    return "hl.dsp.window.close({ " + win(address) + " })";
}

function kill(address) {
    return "hl.dsp.window.kill({ " + win(address) + " })";
}

function moveToMonitor(address, monitor) {
    return 'hl.dsp.window.move({ monitor = "' + monitor + '", ' + win(address) + " })";
}

function sendShortcut(address, keys) {
    var k = parseKeys(keys);
    return 'hl.dsp.send_shortcut({ mods = "' + k.mods + '", key = "' + k.key + '", ' + win(address) + " })";
}

// Actúa sobre la ventana activa (la fija quien llama enfocándola antes)
function groupToggle() {
    return "hl.dsp.group.toggle()";
}

function focus(address) {
    return "hl.dsp.focus({ " + win(address) + " })";
}

// "CTRL+SHIFT+C" → { mods: "CTRL SHIFT", key: "C" }
function parseKeys(text) {
    var parts = String(text).split("+").map(function (s) {
        return s.trim();
    }).filter(function (s) {
        return s !== "";
    });
    var key = parts.length > 0 ? parts[parts.length - 1] : "";
    return {
        mods: parts.slice(0, -1).map(function (m) {
            return m.toUpperCase();
        }).join(" "),
        key: key.length === 1 ? key.toUpperCase() : key
    };
}

// Lista de atajos de una app: la común, o la suya si `replace`, más los extra.
// cfg = { shortcuts: [{ label, keys }], appShortcuts: { appId: { replace, items } } }
function shortcutsFor(appId, cfg) {
    var base = cfg.shortcuts || [];
    var app = (cfg.appShortcuts || {})[String(appId || "").toLowerCase()];
    if (!app)
        return base;
    return app.replace ? app.items : base.concat(app.items);
}

// A dónde manda el botón «stash»: al stash o, si ya está ahí, de vuelta al workspace actual
function stashTarget(info, currentId) {
    var name = info && info.workspace ? info.workspace.name : "";
    return name === "special:stash" ? currentId : "special:stash";
}

// ── Atajos a la vista ──
var KEY_NAMES = {
    SUPER: "Super",
    CTRL: "Ctrl",
    CONTROL: "Ctrl",
    ALT: "Alt",
    SHIFT: "⇧",
    PRINT: "Impr",
    PERIOD: ".",
    COMMA: ",",
    SLASH: "/",
    MINUS: "-",
    EQUAL: "=",
    RETURN: "Enter",
    ENTER: "Enter",
    TAB: "Tab",
    ESCAPE: "Esc",
    SPACE: "Espacio"
};

// "SUPER+SHIFT+F" → ["Super", "⇧", "F"] (para dibujar cada tecla en su cajita)
function keyLabels(text) {
    return String(text || "").split("+").map(function (s) {
        return s.trim();
    }).filter(function (s) {
        return s !== "";
    }).map(function (k) {
        var up = k.toUpperCase();
        if (up === "MOUSE:272")
            return "Clic izq.";
        if (up === "MOUSE:273")
            return "Clic der.";
        if (up === "MOUSE:274")
            return "Clic central";
        if (KEY_NAMES[up])
            return KEY_NAMES[up];
        return k.length === 1 ? up : k;
    });
}

// Letra sin acento y en minúscula (para comparar mnemónicos)
function norm(ch) {
    return ch.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

function isLetterOrDigit(ch) {
    return /^[a-z0-9]$/.test(norm(ch));
}

// Índice de la primera aparición de `letter` en `label` (sin distinguir acentos ni mayúsculas); -1 si no está
function indexOfLetter(label, letter) {
    var l = norm(String(letter || ""));
    if (l === "")
        return -1;
    var s = String(label);
    for (var i = 0; i < s.length; i++)
        if (norm(s.charAt(i)) === l)
            return i;
    return -1;
}

// Para cada nombre, el índice de su letra subrayada: la primera libre (que no esté en `used` ni la haya
// tomado otro nombre). -1 si no queda ninguna.
function assignMnemonics(labels, used) {
    var taken = {};
    (used || []).forEach(function (u) {
        taken[norm(String(u))] = true;
    });
    return labels.map(function (label) {
        var s = String(label);
        for (var i = 0; i < s.length; i++) {
            if (!isLetterOrDigit(s.charAt(i)))
                continue;
            var n = norm(s.charAt(i));
            if (!taken[n]) {
                taken[n] = true;
                return i;
            }
        }
        return -1;
    });
}

function escapeHtml(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Texto con la letra `index` subrayada, para Text.StyledText
function underline(label, index) {
    var s = String(label);
    if (index < 0 || index >= s.length)
        return escapeHtml(s);
    return escapeHtml(s.slice(0, index)) + "<u>" + escapeHtml(s.charAt(index)) + "</u>" + escapeHtml(s.slice(index + 1));
}
