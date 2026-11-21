.pragma library

// Una pulsación de Qt → la combinación de Hyprland ("SUPER + SHIFT + F"). Puro, para probarlo con node.
// Solo las teclas que Hyprland reconoce por su nombre: letras, números, F1–F12, flechas y las más usadas.

var MOD_META = 0x10000000;
var MOD_CTRL = 0x04000000;
var MOD_ALT = 0x08000000;
var MOD_SHIFT = 0x02000000;

var NAMED = {
    0x01000000: "Escape",
    0x01000001: "Tab",
    0x01000002: "Tab",
    0x01000003: "BackSpace",
    0x01000004: "Return",
    0x01000005: "Return",
    0x01000006: "Insert",
    0x01000007: "Delete",
    0x01000009: "Print",
    0x01000010: "Home",
    0x01000011: "End",
    0x01000012: "left",
    0x01000013: "up",
    0x01000014: "right",
    0x01000015: "down",
    0x01000016: "Prior",
    0x01000017: "Next",
    0x20: "space",
    0x2c: "comma",
    0x2e: "period",
    0x2f: "slash",
    0x2d: "minus",
    0x3d: "equal",
    0x3b: "semicolon",
    0x27: "apostrophe",
    0x5b: "bracketleft",
    0x5d: "bracketright",
    0x5c: "backslash",
    0x60: "grave"
};

// Teclas que solo son modificadores (Shift, Ctrl, Alt, Meta, Super)
function isModifierKey(key) {
    return key === 0x01000020 || key === 0x01000021 || key === 0x01000022 || key === 0x01000023 || key === 0x01000053 || key === 0x01000054;
}

// Nombre de la tecla, o "" si no se reconoce. scanCode = código xkb (evdev + 8): la fila de números se lee por
// él, porque con Shift Qt da el símbolo ("!") y no el "1".
function keyName(key, scanCode) {
    if (scanCode >= 10 && scanCode <= 19)
        return String((scanCode - 9) % 10);
    if (key >= 0x41 && key <= 0x5a)
        return String.fromCharCode(key);
    if (key >= 0x30 && key <= 0x39)
        return String.fromCharCode(key);
    if (key >= 0x01000030 && key <= 0x0100003b)
        return "F" + (key - 0x01000030 + 1);
    if (NAMED[key])
        return NAMED[key];
    // Un símbolo con Shift (`>`, `{`), ñ, ´, ¿… que Hyprland no conoce por su nombre: por el código de la tecla
    // física (xkb), que Hyprland acepta como `code:60` y no depende de la distribución
    if (scanCode >= 8 && scanCode <= 255)
        return "code:" + scanCode;
    return "";
}

// Los nombres de Hyprland que son la misma tecla física que un `code:N` en la distribución latam
var NAME_CODES = { apostrophe: 20, comma: 59, period: 60, minus: 61 };

// La forma canónica de una combinación para compararlas: "SUPER + comma" y "super + code:59" son la misma
function canon(bind) {
    return String(bind).toLowerCase().replace(/\s+/g, "").split("+").map(function (p) {
        return NAME_CODES[p] ? "code:" + NAME_CODES[p] : p;
    }).sort().join("+");
}

function sameKey(a, b) {
    return canon(a) === canon(b);
}

// → "SUPER + SHIFT + F", o "" si es solo un modificador o una tecla desconocida
function fromEvent(key, modifiers, scanCode) {
    if (isModifierKey(key))
        return "";
    var name = keyName(key, scanCode);
    if (name === "")
        return "";
    var parts = [];
    if (modifiers & MOD_META)
        parts.push("SUPER");
    if (modifiers & MOD_CTRL)
        parts.push("CTRL");
    if (modifiers & MOD_ALT)
        parts.push("ALT");
    if (modifiers & MOD_SHIFT)
        parts.push("SHIFT");
    parts.push(name);
    return parts.join(" + ");
}
