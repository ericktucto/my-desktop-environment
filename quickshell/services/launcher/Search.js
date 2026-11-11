.pragma library
.import "Calc.js" as Calc

// Búsqueda del launcher. Funciones puras: reciben todo lo que necesitan en `ctx` y devuelven filas.
//
// ctx = {
//   apps          lista de DesktopEntry visibles
//   favorites     ids de las apps favoritas
//   usage         { "app:firefox": veces, "emoji:🔥": veces }
//   emojis        [{ e, n, en, k, sn, se, s }]   (sn, se y s = nombre, nombre en inglés y todo, ya normalizados)
//   session       acciones de sesión [{ id, text, icon, confirm, confirmText }]
//   sessionWords  { id: "palabras clave" }
//   sessionGlyphs { id: código del glifo }
//   history       comandos recientes
//   canType       hay wtype (Enter escribe en la ventana activa; si no, copia)
//   maxResults
// }
//
// Fila: { kind, key, title, subtitle, icon | emoji | glyph, favId?, favorite?, ... }
//   kind: app | action | session | emoji | calc | terminal | history | hint

// Palabras en español (y alternativas) por categoría del .desktop: los datos de muchas apps están solo en inglés
var CATEGORY_WORDS = {
    WebBrowser: "navegador web internet",
    Network: "red internet",
    TerminalEmulator: "terminal consola",
    TextEditor: "editor texto",
    Development: "desarrollo programacion",
    IDE: "editor programacion",
    AudioVideo: "audio video multimedia",
    Audio: "audio musica sonido",
    Video: "video peliculas",
    Player: "reproductor",
    Graphics: "graficos imagen dibujo",
    ImageViewer: "visor imagenes fotos",
    Photography: "fotos camara",
    FileManager: "archivos explorador carpetas",
    Settings: "configuracion ajustes preferencias",
    Utility: "utilidad herramienta",
    Office: "oficina documentos",
    Game: "juego juegos",
    Emulator: "emulador juegos",
    System: "sistema",
    Archiving: "comprimir archivos",
    Chat: "mensajes chat",
    VideoConference: "videollamada reunion"
};

function categoryWords(app) {
    var cats = app.categories || [];
    var words = [];
    for (var i = 0; i < cats.length; i++)
        if (CATEGORY_WORDS.hasOwnProperty(cats[i]))
            words.push(CATEGORY_WORDS[cats[i]]);
    return words.join(" ");
}

function normalize(s) {
    return String(s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

function tokens(q) {
    return normalize(q).split(/\s+/).filter(function (t) {
        return t !== "";
    });
}

// Puntaje de un texto ya normalizado contra un token: empieza por (100), una palabra empieza por (80), contiene (60)
function textScore(text, token) {
    if (text.indexOf(token) === 0)
        return 100;
    if (text.indexOf(" " + token) >= 0)
        return 80;
    if (text.indexOf(token) >= 0)
        return 60;
    return -1;
}

// `fields`: [{ text, weight }] con el texto normalizado. weight 0 = es el nombre (puntúa por posición);
// weight > 0 = campo secundario (puntúa fijo si lo contiene). -1 si algún token no aparece en ningún campo.
function matchScore(fields, toks) {
    var total = 0;
    for (var i = 0; i < toks.length; i++) {
        var best = -1;
        for (var j = 0; j < fields.length; j++) {
            var f = fields[j];
            var s = f.weight === 0 ? textScore(f.text, toks[i]) : (f.text.indexOf(toks[i]) >= 0 ? f.weight : -1);
            if (s > best)
                best = s;
        }
        if (best < 0)
            return -1;
        total += best;
    }
    return Math.round(total / toks.length);
}

// Favoritos primero, luego mejor coincidencia, luego más usado, luego alfabético
function compare(a, b) {
    if (a.favorite !== b.favorite)
        return a.favorite ? -1 : 1;
    if (a.score !== b.score)
        return b.score - a.score;
    if (a.usage !== b.usage)
        return b.usage - a.usage;
    return normalize(a.title) < normalize(b.title) ? -1 : (normalize(a.title) > normalize(b.title) ? 1 : 0);
}

function appRows(toks, ctx) {
    var rows = [];
    for (var i = 0; i < ctx.apps.length; i++) {
        var app = ctx.apps[i];
        var kw = app.keywords ? app.keywords.join(" ") : "";
        var score = 0;
        if (toks.length > 0) {
            score = matchScore([
                {
                    text: normalize(app.name),
                    weight: 0
                },
                {
                    text: normalize(app.genericName + " " + kw + " " + categoryWords(app)),
                    weight: 40
                },
                {
                    text: normalize(app.comment),
                    weight: 20
                }
            ], toks);
            if (score < 0)
                continue;
        }
        rows.push({
            kind: "app",
            key: "app:" + app.id,
            title: app.name || app.id,
            subtitle: app.genericName || app.comment || "",
            icon: app.icon || "",
            favId: app.id,
            favorite: ctx.favorites.indexOf(app.id) >= 0,
            score: score,
            usage: ctx.usage["app:" + app.id] || 0,
            ref: app
        });
    }
    return rows;
}

// Acciones del .desktop: "Firefox · New Private Window"
function actionRows(toks, ctx) {
    var rows = [];
    for (var i = 0; i < ctx.apps.length; i++) {
        var app = ctx.apps[i];
        var acts = app.actions || [];
        for (var j = 0; j < acts.length; j++) {
            var score = matchScore([
                {
                    text: normalize(app.name + " " + acts[j].name),
                    weight: 0
                }
            ], toks);
            if (score < 0)
                continue;
            rows.push({
                kind: "action",
                key: "action:" + app.id + ":" + acts[j].id,
                title: app.name + " · " + acts[j].name,
                subtitle: "",
                icon: app.icon || acts[j].icon || "",
                favorite: false,
                // un poco por debajo de la app misma
                score: score - 10,
                usage: 0,
                ref: acts[j]
            });
        }
    }
    return rows;
}

function sessionRows(toks, ctx) {
    var rows = [];
    for (var i = 0; i < ctx.session.length; i++) {
        var a = ctx.session[i];
        var score = matchScore([
            {
                text: normalize(a.text),
                weight: 0
            },
            {
                text: normalize(ctx.sessionWords[a.id] || ""),
                weight: 40
            }
        ], toks);
        if (score < 0)
            continue;
        rows.push({
            kind: "session",
            key: "session:" + a.id,
            title: a.text,
            subtitle: "Acción de sesión",
            glyph: ctx.sessionGlyphs[a.id],
            id: a.id,
            confirm: a.confirm,
            confirmText: a.confirmText,
            favorite: false,
            score: score,
            usage: 0
        });
    }
    return rows;
}

function emojiRows(rest, ctx) {
    var toks = tokens(rest);
    var rows = [];
    for (var i = 0; i < ctx.emojis.length; i++) {
        var e = ctx.emojis[i];
        var score = 0;
        if (toks.length > 0) {
            score = matchScore([
                {
                    text: e.sn,
                    weight: 0
                },
                {
                    text: e.se,
                    weight: 0
                },
                {
                    text: e.s,
                    weight: 30
                }
            ], toks);
            if (score < 0)
                continue;
        }
        rows.push({
            kind: "emoji",
            key: "emoji:" + e.e,
            title: e.n,
            subtitle: e.en,
            emoji: e.e,
            text: e.e,
            favorite: false,
            score: score,
            usage: ctx.usage["emoji:" + e.e] || 0,
            order: i
        });
    }
    // Sin texto: los más usados primero y luego el orden de la base. Con texto, también por uso.
    rows.sort(function (a, b) {
        if (a.score !== b.score)
            return b.score - a.score;
        if (a.usage !== b.usage)
            return b.usage - a.usage;
        return a.order - b.order;
    });
    return rows;
}

function calcRows(rest, ctx) {
    if (rest.trim() === "")
        return [hint("Escribe una operación, por ejemplo (1,5+2)*3")];
    var r = Calc.evaluate(rest);
    if (!r.ok)
        return [hint("Sin resultado (la expresión está incompleta o no es válida)")];
    return [
        {
            kind: "calc",
            key: "calc",
            title: "= " + r.display,
            subtitle: ctx.canType ? "Enter: escribir en la ventana activa" : "Enter: copiar",
            glyph: 0xf00ec,
            text: r.display,
            favorite: false,
            score: 0,
            usage: 0
        }
    ];
}

function terminalRow(cmd) {
    return {
        kind: "terminal",
        key: "terminal",
        title: "Ejecutar «" + cmd + "» en la terminal",
        subtitle: "",
        glyph: 0xf018d,
        command: cmd,
        favorite: false,
        score: 0,
        usage: 0
    };
}

function hint(text) {
    return {
        kind: "hint",
        key: "hint",
        title: text,
        subtitle: "",
        favorite: false,
        score: 0,
        usage: 0
    };
}

function historyRows(rest, ctx) {
    var q = normalize(rest.trim());
    var rows = [];
    for (var i = 0; i < ctx.history.length; i++) {
        var c = ctx.history[i];
        if (q !== "" && normalize(c).indexOf(q) < 0)
            continue;
        if (c === rest.trim())
            continue;
        rows.push({
            kind: "history",
            key: "history:" + c,
            title: c,
            subtitle: "",
            glyph: 0xf02da,
            command: c,
            favorite: false,
            score: 0,
            usage: 0
        });
    }
    return rows;
}

// Texto del buscador → { mode, rows }
function results(query, ctx) {
    var m = /^\s*([ect]):\s?(.*)$/i.exec(query);
    if (m) {
        var prefix = m[1].toLowerCase();
        var rest = m[2];
        if (prefix === "e")
            return {
                mode: "emoji",
                rows: emojiRows(rest, ctx).slice(0, ctx.maxResults)
            };
        if (prefix === "c")
            return {
                mode: "calc",
                rows: calcRows(rest, ctx)
            };
        var rows = [];
        if (rest.trim() !== "")
            rows.push(terminalRow(rest.trim()));
        rows = rows.concat(historyRows(rest, ctx));
        if (rows.length === 0)
            rows.push(hint("Escribe un comando para ejecutarlo en la terminal"));
        return {
            mode: "term",
            rows: rows
        };
    }

    var toks = tokens(query);
    var all = appRows(toks, ctx);
    if (toks.length > 0)
        all = all.concat(actionRows(toks, ctx), sessionRows(toks, ctx));
    all.sort(compare);
    all = all.slice(0, ctx.maxResults);
    // Cualquier texto se puede ejecutar en la terminal (siempre al final)
    if (query.trim() !== "")
        all.push(terminalRow(query.trim()));
    return {
        mode: "apps",
        rows: all
    };
}
