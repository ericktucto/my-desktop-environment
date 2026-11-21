.pragma library

// Apps predeterminadas (terminal, navegador, archivos): el comando de cada una. Puro, para probarlo con node.

// «foot -a stix» → ["foot", "-a", "stix"]; respeta comillas simples y dobles
function split(text) {
    var out = [], cur = "", quote = "", has = false;
    for (var i = 0; i < text.length; i++) {
        var c = text[i];
        if (quote !== "") {
            if (c === quote)
                quote = "";
            else
                cur += c;
        } else if (c === '"' || c === "'") {
            quote = c;
            has = true;
        } else if (c === " " || c === "\t") {
            if (cur !== "" || has)
                out.push(cur);
            cur = "";
            has = false;
        } else {
            cur += c;
        }
    }
    if (cur !== "" || has)
        out.push(cur);
    return out;
}

// Lo mismo al revés, para guardarlo en el archivo que lee Hyprland
function join(argv) {
    return argv.map(function (a) {
        return /^[A-Za-z0-9_\-.,:\/=@%+]+$/.test(a) ? a : "'" + a.replace(/'/g, "'\\''") + "'";
    }).join(" ");
}

// Comando de un tipo de app: el propio (texto) si lo hay; si no, el de la app elegida; si no, `fallback`.
// `entries` = [{ id, command }] de las apps instaladas de la categoría.
function resolve(customText, appId, entries, fallback) {
    var custom = split((customText || "").trim());
    if (custom.length > 0)
        return custom;
    if (appId) {
        for (var i = 0; i < entries.length; i++)
            if (entries[i].id === appId && entries[i].command.length > 0)
                return entries[i].command;
    }
    return fallback;
}

// Una terminal ejecutando `argv`. Con `hold`, la ventana queda abierta al terminar.
// kitty recibe el programa directo (y sabe --hold); las demás lo reciben tras `-e` y, con `hold`, dentro de una
// shell que espera un Enter.
function inTerminal(terminal, argv, hold) {
    var bin = terminal.length > 0 ? terminal[0].split("/").pop() : "";
    if (bin === "kitty")
        return terminal.concat(hold ? ["--hold"] : [], argv);
    if (hold)
        return terminal.concat(["-e", "sh", "-c", '"$@"; printf "\\nPulsa Enter para cerrar…"; read _', "_"], argv);
    return terminal.concat(["-e"], argv);
}
