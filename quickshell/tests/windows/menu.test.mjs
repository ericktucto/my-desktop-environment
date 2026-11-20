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

done();
