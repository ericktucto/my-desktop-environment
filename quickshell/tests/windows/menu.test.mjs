import { loadLib, eq, done } from "../tasks/load.mjs";

const M = loadLib("services/windows/WindowMenu.js");
const A = "56326aad8b90";

eq("sel", M.sel("0x" + A), "address:0x" + A);
eq("sel sin 0x", M.sel(A), "address:0x" + A);
eq("move a un workspace", M.move(A, 2), 'hl.dsp.window.move({ workspace = 2, window = "address:0x' + A + '", follow = false })');
eq("move al stash", M.move(A, "special:stash"), 'hl.dsp.window.move({ workspace = "special:stash", window = "address:0x' + A + '", follow = false })');
eq("float", M.toggleFloat(A), 'hl.dsp.window.float({ action = "toggle", window = "address:0x' + A + '" })');
eq("pin", M.pin(A), 'hl.dsp.window.pin({ action = "toggle", window = "address:0x' + A + '" })');
eq("maximizar", M.maximize(A), 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = "address:0x' + A + '" })');
eq("pantalla completa", M.fullscreen(A), 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle", window = "address:0x' + A + '" })');
eq("cerrar", M.close(A), 'hl.dsp.window.close({ window = "address:0x' + A + '" })');
eq("monitor", M.moveToMonitor(A, "HDMI-A-1"), 'hl.dsp.window.move({ monitor = "HDMI-A-1", window = "address:0x' + A + '" })');
eq("atajo", M.sendShortcut(A, "CTRL+SHIFT+c"), 'hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "C", window = "address:0x' + A + '" })');

eq("parseKeys", M.parseKeys("CTRL+SHIFT+C"), { mods: "CTRL SHIFT", key: "C" });
eq("parseKeys sin modificador", M.parseKeys("F5"), { mods: "", key: "F5" });
eq("parseKeys minúsculas", M.parseKeys("ctrl+t"), { mods: "CTRL", key: "T" });

const cfg = {
    shortcuts: [{ label: "Copiar", keys: "CTRL+C" }],
    appShortcuts: { kitty: { replace: true, items: [{ label: "Copiar", keys: "CTRL+SHIFT+C" }] }, firefox: { replace: false, items: [{ label: "Recargar", keys: "F5" }] } }
};
eq("atajos comunes", M.shortcutsFor("gedit", cfg).length, 1);
eq("atajos que reemplazan", M.shortcutsFor("kitty", cfg).map(s => s.keys), ["CTRL+SHIFT+C"]);
eq("atajos que suman", M.shortcutsFor("Firefox", cfg).map(s => s.keys), ["CTRL+C", "F5"]);
eq("sin appId", M.shortcutsFor("", cfg).length, 1);

eq("stash: va al stash", M.stashTarget({ workspace: { name: "2" } }, 2), "special:stash");
eq("stash: vuelve", M.stashTarget({ workspace: { name: "special:stash" } }, 3), 3);
eq("stash: sin info", M.stashTarget(null, 1), "special:stash");

// keyLabels
eq("keyLabels Super+Shift+F", M.keyLabels("SUPER+SHIFT+F"), ["Super", "⇧", "F"]);
eq("keyLabels con rango", M.keyLabels("SUPER+SHIFT+1…4"), ["Super", "⇧", "1…4"]);
eq("keyLabels code:", M.keyLabels("SUPER+SHIFT+code:94"), ["Super", "⇧", "<"]);
eq("keyLabels code desconocido", M.keyLabels("code:200"), ["Tecla 200"]);
eq("keyLabels ñ", M.keyLabels("SUPER + code:47"), ["Super", "ñ"]);
eq("keyLabels Print", M.keyLabels("Print"), ["Impr"]);
eq("keyLabels period", M.keyLabels("SUPER+period"), ["Super", "."]);
eq("keyLabels minúscula", M.keyLabels("ctrl+t"), ["Ctrl", "T"]);
eq("keyLabels F5", M.keyLabels("F5"), ["F5"]);
eq("keyLabels vacío", M.keyLabels(""), []);

// indexOfLetter / assignMnemonics / underline
eq("indexOfLetter", M.indexOfLetter("Fijar", "j"), 2);
eq("indexOfLetter con acento", M.indexOfLetter("Atajos Pestaña", "n"), 12);
eq("indexOfLetter ausente", M.indexOfLetter("Fijar", "z"), -1);
eq("mnemónicos: primera libre", M.assignMnemonics(["Deshacer", "Copiar", "Cortar", "Pegar"], []), [0, 0, 1, 0]);
eq("mnemónicos: respeta usadas", M.assignMnemonics(["Editar", "Abrir"], ["e"]), [1, 0]);
eq("mnemónicos: salta signos y se agota", M.assignMnemonics(["--", "aa", "a"], []), [-1, 0, -1]);
eq("underline", M.underline("Fijar", 2), "Fi<u>j</u>ar");
eq("underline escapa", M.underline("A&B <x>", 0), "<u>A</u>&amp;B &lt;x&gt;");
eq("underline sin índice", M.underline("Fijar", -1), "Fijar");

done();
