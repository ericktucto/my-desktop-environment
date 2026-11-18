.pragma library
.import "Dates.js" as Dates
.import "Links.js" as Links

// Lenguaje natural en español para crear tareas:
//   "Revisar PR mañana 9am +trabajo #review p1 30m https://github.com/acme/api/pull/412"
// Entiende: +proyecto (o +"con espacios"), #etiqueta, p1–p4, fechas ("hoy", "mañana", "pasado mañana",
// "el viernes", "próximo lunes", "en 3 días", "15 dic", "15/12", "2026-12-15"), horas ("9am", "9:30",
// "a las 9"), "desde el lunes" (fecha de inicio), estimaciones ("30m", "2h", "1h30"), repetición
// ("cada lunes", "cada 2 semanas", "todos los días", "cada día laborable"), URLs y "/plantilla".
// Lo que no se entiende queda en el título. Puro (sin QML): se prueba con node.

// Separador antes y límite después de una palabra (el \b de JS no entiende acentos)
var PRE = "(^|[\\s,;(])";
var END = "(?=$|[\\s,;.!?)])";
var WORD = "A-Za-z0-9_\\u00C0-\\u00FF-";
var WD = "lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo";
var MONTH = "(?:enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre|ene|feb|mar|abr|may|jun|jul|ago|sep|set|oct|nov|dic)";

function norm(s) {
    return String(s === undefined || s === null ? "" : s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

// "miércoles" → 3 (lunes = 1)
function weekdayOf(word) {
    var i = ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"].indexOf(norm(word));
    return i + 1;
}

// "dic", "diciembre" → 11 (enero = 0)
function monthOf(word) {
    return ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"].indexOf(norm(word).slice(0, 3).replace("set", "sep"));
}

function addMonths(key, n) {
    var d = Dates.parseKey(key);
    var t = new Date(d.getFullYear(), d.getMonth() + n, 1);
    var last = new Date(t.getFullYear(), t.getMonth() + 1, 0).getDate();
    return Dates.keyOf(new Date(t.getFullYear(), t.getMonth(), Math.min(d.getDate(), last)));
}

// Año/mes/día → "AAAA-MM-DD", o "" si no existe ese día (30 de febrero)
function validKey(y, m, d) {
    var dt = new Date(y, m, d);
    return dt.getFullYear() === y && dt.getMonth() === m && dt.getDate() === d ? Dates.keyOf(dt) : "";
}

// Día y mes sin año: este año, o el siguiente si ya pasó
function dayMonth(d, m, now) {
    var today = Dates.keyOf(now);
    var k = validKey(now.getFullYear(), m, d);
    if (k !== "" && k < today)
        k = validKey(now.getFullYear() + 1, m, d);
    return k;
}

// Formas de escribir una fecha: { src (con grupos propios), fn(m, i, now) → "AAAA-MM-DD" o "" }.
// `i` es la posición del primer grupo propio en el resultado de la expresión.
var DATES = [
    {
        src: "(\\d{4})-(\\d{2})-(\\d{2})",
        fn: function (m, i) {
            return validKey(Number(m[i]), Number(m[i + 1]) - 1, Number(m[i + 2]));
        }
    },
    {
        src: "(\\d{1,2})\\/(\\d{1,2})(?:\\/(\\d{2,4}))?",
        fn: function (m, i, now) {
            var d = Number(m[i]);
            var mo = Number(m[i + 1]) - 1;
            if (m[i + 2] === undefined)
                return dayMonth(d, mo, now);
            var y = Number(m[i + 2]);
            return validKey(y < 100 ? 2000 + y : y, mo, d);
        }
    },
    {
        src: "(\\d{1,2})\\s+(?:de\\s+)?(" + MONTH + ")(?:\\s+(?:de\\s+)?(\\d{4}))?",
        fn: function (m, i, now) {
            var d = Number(m[i]);
            var mo = monthOf(m[i + 1]);
            return m[i + 2] === undefined ? dayMonth(d, mo, now) : validKey(Number(m[i + 2]), mo, d);
        }
    },
    {
        src: "en\\s+(\\d+|un|una)\\s+(d[ií]as?|semanas?|mes(?:es)?|a[ñn]os?)",
        fn: function (m, i, now) {
            var n = /^\d+$/.test(m[i]) ? Number(m[i]) : 1;
            var unit = norm(m[i + 1]).charAt(0);
            var today = Dates.keyOf(now);
            if (unit === "d")
                return Dates.addDays(today, n);
            if (unit === "s")
                return Dates.addDays(today, 7 * n);
            return addMonths(today, unit === "m" ? n : 12 * n);
        }
    },
    {
        src: "pasado\\s+ma[ñn]ana",
        fn: function (m, i, now) {
            return Dates.addDays(Dates.keyOf(now), 2);
        }
    },
    {
        src: "ma[ñn]ana",
        fn: function (m, i, now) {
            return Dates.addDays(Dates.keyOf(now), 1);
        }
    },
    {
        src: "hoy",
        fn: function (m, i, now) {
            return Dates.keyOf(now);
        }
    },
    {
        // "viernes" es el próximo viernes (hoy, si hoy es viernes); "próximo viernes" siempre es después de hoy
        src: "(?:(pr[óo]ximo|siguiente)\\s+)?(" + WD + ")",
        fn: function (m, i, now) {
            var today = Dates.keyOf(now);
            var diff = (weekdayOf(m[i + 1]) - Dates.weekday(today) + 7) % 7;
            if (diff === 0 && m[i] !== undefined)
                diff = 7;
            return Dates.addDays(today, diff);
        }
    }
];

// Horas: { src, fn(m, i) → "HH:MM" o "" }
function hhmm(h, mi) {
    return h > 23 || mi > 59 ? "" : Dates.pad(h) + ":" + Dates.pad(mi);
}

var TIMES = [
    {
        // 9am, 9:30pm, a las 9 am
        src: "(?:a\\s+las?\\s+)?(\\d{1,2})(?::(\\d{2}))?\\s*([ap])\\.?m\\.?",
        fn: function (m, i) {
            var h = Number(m[i]);
            if (h < 1 || h > 12)
                return "";
            h = h % 12 + (m[i + 2].toLowerCase() === "p" ? 12 : 0);
            return hhmm(h, m[i + 1] === undefined ? 0 : Number(m[i + 1]));
        }
    },
    {
        // 14:30, a las 9:30
        src: "(?:a\\s+las?\\s+)?(\\d{1,2}):(\\d{2})",
        fn: function (m, i) {
            return hhmm(Number(m[i]), Number(m[i + 1]));
        }
    },
    {
        // a las 9
        src: "a\\s+las?\\s+(\\d{1,2})",
        fn: function (m, i) {
            return hhmm(Number(m[i]), 0);
        }
    }
];

// Fecha + hora de hoy más allá del momento actual
function minutesOf(hhmmText) {
    var p = hhmmText.split(":");
    return Number(p[0]) * 60 + Number(p[1]);
}

// Primera coincidencia de `re` en `work` → { m, start, end }; `start` salta el separador inicial
function find(work, re) {
    var m = re.exec(work);
    if (!m)
        return null;
    return {
        m: m,
        start: m.index + m[1].length,
        end: m.index + m[0].length
    };
}

function blank(work, s, e) {
    var fill = "";
    for (var i = s; i < e; i++)
        fill += " ";
    return work.slice(0, s) + fill + work.slice(e);
}

// Todos los días que nombra un texto: "lunes y jueves" → [1, 4]
function weekdaysIn(text) {
    var out = [];
    var re = new RegExp("(" + WD + ")", "gi");
    var m;
    while ((m = re.exec(text)) !== null) {
        var d = weekdayOf(m[1]);
        if (out.indexOf(d) < 0)
            out.push(d);
    }
    return out.sort();
}

// "cada lunes y jueves", "cada 2 semanas", "cada día laborable"…
function repeatLabel(r) {
    if (!r)
        return "";
    var names = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"];
    var n = r.interval > 1 ? r.interval + " " : "";
    if (r.freq === "weekdays")
        return "cada día laborable";
    if (r.freq === "daily")
        return r.interval > 1 ? "cada " + n + "días" : "cada día";
    if (r.freq === "weekly") {
        if (r.days.length > 0 && r.interval <= 1) {
            var list = r.days.map(function (d) {
                return names[d - 1];
            });
            return "cada " + (list.length > 1 ? list.slice(0, -1).join(", ") + " y " + list[list.length - 1] : list[0]);
        }
        return r.interval > 1 ? "cada " + n + "semanas" : "cada semana";
    }
    if (r.freq === "monthly")
        return r.interval > 1 ? "cada " + n + "meses" : "cada mes";
    return r.interval > 1 ? "cada " + n + "años" : "cada año";
}

function mkRepeat(freq, interval, days) {
    return {
        freq: freq,
        interval: interval || 1,
        days: days || [],
        from: "due"
    };
}

// Busca la repetición. Devuelve { start, end, repeat } o null.
function findRepeat(work) {
    var f;
    f = find(work, new RegExp(PRE + "((?:cada\\s+d[ií]a\\s+(?:laborable|h[áa]bil)|(?:todos\\s+los\\s+)?d[ií]as\\s+(?:laborables|h[áa]biles)))" + END, "i"));
    if (f)
        return {
            start: f.start,
            end: f.end,
            repeat: mkRepeat("weekdays")
        };
    f = find(work, new RegExp(PRE + "(todos\\s+los\\s+d[ií]as|diari[oa](?:mente)?)" + END, "i"));
    if (f)
        return {
            start: f.start,
            end: f.end,
            repeat: mkRepeat("daily")
        };
    f = find(work, new RegExp(PRE + "((?:cada|todos\\s+los)\\s+(?:" + WD + ")(?:\\s*(?:,|y|e)\\s*(?:" + WD + "))*)" + END, "i"));
    if (f)
        return {
            start: f.start,
            end: f.end,
            repeat: mkRepeat("weekly", 1, weekdaysIn(f.m[2]))
        };
    f = find(work, new RegExp(PRE + "(cada\\s+(?:(\\d+)\\s+)?(d[ií]as?|semanas?|mes(?:es)?|a[ñn]os?))" + END, "i"));
    if (f) {
        var unit = norm(f.m[4]).charAt(0);
        return {
            start: f.start,
            end: f.end,
            repeat: mkRepeat(unit === "d" ? "daily" : unit === "s" ? "weekly" : unit === "m" ? "monthly" : "yearly", f.m[3] ? Number(f.m[3]) : 1)
        };
    }
    f = find(work, new RegExp(PRE + "(semanal|mensual|anual)(?:mente)?" + END, "i"));
    if (f)
        return {
            start: f.start,
            end: f.end,
            repeat: mkRepeat({
                s: "weekly",
                m: "monthly",
                a: "yearly"
            }[norm(f.m[2]).charAt(0)])
        };
    return null;
}

// Primera fecha "para" (due) o "desde" (start) del texto. Devuelve { start, end, key } o null.
function findDate(work, now, since) {
    var lead = since ? "desde\\s+(?:el\\s+)?" : "(?:(?:el|para\\s+el|para|este)\\s+)?";
    for (var i = 0; i < DATES.length; i++) {
        var f = find(work, new RegExp(PRE + lead + "(" + DATES[i].src + ")" + END, "i"));
        if (!f)
            continue;
        var key = DATES[i].fn(f.m, 3, now);
        if (key !== "")
            return {
                start: f.start,
                end: f.end,
                key: key
            };
    }
    return null;
}

function findTime(work) {
    for (var i = 0; i < TIMES.length; i++) {
        var f = find(work, new RegExp(PRE + "(" + TIMES[i].src + ")" + END, "i"));
        if (!f)
            continue;
        var t = TIMES[i].fn(f.m, 3);
        if (t !== "")
            return {
                start: f.start,
                end: f.end,
                time: t
            };
    }
    return null;
}

// Si no hay fecha, la de la repetición: el primer día que toca desde hoy
function firstRepeatDay(repeat, now) {
    var today = Dates.keyOf(now);
    if (repeat.freq === "weekdays")
        return Dates.isWorkday(today) ? today : Dates.addDays(today, 8 - Dates.weekday(today));
    if (repeat.freq === "weekly" && repeat.days.length > 0) {
        for (var i = 0; i < 7; i++) {
            var k = Dates.addDays(today, i);
            if (repeat.days.indexOf(Dates.weekday(k)) >= 0)
                return k;
        }
    }
    return today;
}

// Nombre escrito → { name, isNew } usando los proyectos que existen (sin acentos ni mayúsculas;
// sirve el comienzo del nombre si es único)
function resolveProject(typed, projects) {
    var t = norm(typed);
    var list = (projects || []).map(function (p) {
        return {
            name: p.name,
            n: norm(p.name)
        };
    });
    var exact = list.filter(function (p) {
        return p.n === t;
    });
    if (exact.length > 0)
        return {
            name: exact[0].name,
            isNew: false
        };
    var prefix = list.filter(function (p) {
        return p.n.indexOf(t) === 0;
    });
    if (prefix.length === 1)
        return {
            name: prefix[0].name,
            isNew: false
        };
    return {
        name: typed,
        isNew: true
    };
}

// Texto → { title, due, dueTime, start, project, newProject, tags, priority, estimate, repeat, links,
// template, spans }. `spans` dice qué parte del texto generó cada dato ({ kind, text, start, end }),
// para quitarlo con la × de su chip.
// opts: { now, projects: [{ name }], templates: [{ name }] }
function parse(text, opts) {
    opts = opts || {};
    var now = Dates.toDate(opts.now);
    text = String(text === undefined || text === null ? "" : text);
    var work = text;
    var spans = [];
    var r = {
        title: "",
        due: "",
        dueTime: "",
        start: "",
        project: null,
        newProject: false,
        tags: [],
        priority: 4,
        estimate: 0,
        repeat: null,
        links: [],
        template: "",
        spans: spans
    };

    function take(kind, s, e) {
        spans.push({
            kind: kind,
            text: text.slice(s, e),
            start: s,
            end: e
        });
        work = blank(work, s, e);
    }

    // URLs primero: un + o # dentro de un link no cuenta
    var urlRe = /(^|[\s(])((?:https?|file):\/\/[^\s)]+)/gi;
    var um;
    var urls = [];
    while ((um = urlRe.exec(work)) !== null) {
        var url = um[2].replace(/[.,;!?]+$/, "");
        var s0 = um.index + um[1].length;
        urls.push({
            url: url,
            s: s0,
            e: s0 + url.length
        });
    }
    urls.forEach(function (u) {
        take("link", u.s, u.e);
        if (r.links.indexOf(u.url) < 0)
            r.links.push(u.url);
    });

    // /plantilla al principio
    var tm = /^(\s*)\/([A-Za-z0-9_À-ÿ-]+)(?=\s|$)/.exec(work);
    if (tm) {
        var known = (opts.templates || []).find(function (t) {
            return norm(t.name) === norm(tm[2]);
        });
        if (known) {
            r.template = known.name;
            take("template", tm[1].length, tm[0].length);
        }
    }

    // Repetición
    var rep = findRepeat(work);
    if (rep) {
        r.repeat = rep.repeat;
        take("repeat", rep.start, rep.end);
    }

    // Inicio ("desde el lunes") y fecha límite
    var st = findDate(work, now, true);
    if (st) {
        r.start = st.key;
        take("start", st.start, st.end);
    }
    var due = findDate(work, now, false);
    if (due) {
        r.due = due.key;
        take("date", due.start, due.end);
    }

    // Hora
    var tf = findTime(work);
    if (tf) {
        r.dueTime = tf.time;
        take("time", tf.start, tf.end);
    }
    if (r.dueTime && !r.due) {
        // Solo la hora: hoy, o mañana si esa hora ya pasó
        var today = Dates.keyOf(now);
        r.due = minutesOf(r.dueTime) <= now.getHours() * 60 + now.getMinutes() ? Dates.addDays(today, 1) : today;
    }
    if (r.repeat && !r.due)
        r.due = firstRepeatDay(r.repeat, now);

    // Estimación: 30m, 45 min, 2h, 1h30
    var est = find(work, new RegExp(PRE + "(\\d+(?:[.,]\\d+)?\\s*h(?:\\s*\\d+\\s*(?:m|min)?)?|\\d+\\s*(?:m|min|mins))" + END, "i"));
    if (est) {
        var mins = Dates.parseMinutes(est.m[2]);
        if (mins > 0) {
            r.estimate = mins;
            take("estimate", est.start, est.end);
        }
    }

    // p1–p4
    var pr = find(work, new RegExp(PRE + "(p([1-4]))" + END, "i"));
    if (pr) {
        r.priority = Number(pr.m[3]);
        take("priority", pr.start, pr.end);
    }

    // +proyecto o +"nombre con espacios"
    var pj = find(work, new RegExp(PRE + "(\\+(?:\"([^\"]+)\"|([" + WORD + "]+)))" + END, "i"));
    if (pj) {
        var typed = (pj.m[3] || pj.m[4]).trim();
        var res = resolveProject(typed, opts.projects);
        r.project = res.name;
        r.newProject = res.isNew;
        take("project", pj.start, pj.end);
    }

    // #etiquetas (empiezan con letra: "#412" no es una etiqueta)
    var tagRe = new RegExp(PRE + "(#([A-Za-z_\\u00C0-\\u00FF][" + WORD + "]*))" + END, "i");
    var tg;
    while ((tg = find(work, tagRe)) !== null) {
        var tag = tg.m[3].toLowerCase();
        if (r.tags.indexOf(tag) < 0)
            r.tags.push(tag);
        take("tag", tg.start, tg.end);
    }

    spans.sort(function (a, b) {
        return a.start - b.start;
    });
    r.title = collapse(cut(text, spans));
    return r;
}

// El texto sin los tramos de `spans`
function cut(text, spans) {
    var out = "";
    var pos = 0;
    spans.slice().sort(function (a, b) {
        return a.start - b.start;
    }).forEach(function (s) {
        if (s.start >= pos) {
            out += text.slice(pos, s.start) + " ";
            pos = s.end;
        }
    });
    return out + text.slice(pos);
}

function collapse(s) {
    return s.replace(/\s+/g, " ").replace(/^[\s,;]+|[\s,;]+$/g, "").trim();
}

// Quita los tramos dados (los de un chip) y deja el resto del texto como estaba
function removeSpans(text, spans) {
    return collapse(cut(text, spans));
}

// Chips de lo que entendió: [{ id, kind, label, color, spans }] (spans = los tramos que quita su ×)
// kind: date | start | repeat | priority | estimate | project | tag | link | template
function chips(r, opts) {
    opts = opts || {};
    var now = Dates.toDate(opts.now);
    var out = [];
    function spansOf() {
        var kinds = Array.prototype.slice.call(arguments);
        return r.spans.filter(function (s) {
            return kinds.indexOf(s.kind) >= 0;
        });
    }
    if (r.template !== "")
        out.push({
            id: "template",
            kind: "template",
            label: "/" + r.template,
            spans: spansOf("template")
        });
    if (r.due !== "")
        out.push({
            id: "date",
            kind: "date",
            label: Dates.relative(r.due, r.dueTime, now).replace(/^vencida /, ""),
            spans: spansOf("date", "time")
        });
    if (r.start !== "")
        out.push({
            id: "start",
            kind: "start",
            label: "desde " + Dates.relative(r.start, "", now),
            spans: spansOf("start")
        });
    if (r.repeat)
        out.push({
            id: "repeat",
            kind: "repeat",
            label: repeatLabel(r.repeat),
            spans: spansOf("repeat")
        });
    if (r.estimate > 0)
        out.push({
            id: "estimate",
            kind: "estimate",
            label: Dates.formatMinutes(r.estimate),
            spans: spansOf("estimate")
        });
    if (r.priority < 4)
        out.push({
            id: "priority",
            kind: "priority",
            label: "p" + r.priority,
            spans: spansOf("priority")
        });
    if (r.project !== null)
        out.push({
            id: "project",
            kind: "project",
            label: "+" + r.project + (r.newProject ? " (nuevo)" : ""),
            spans: spansOf("project")
        });
    var tagSpans = spansOf("tag");
    r.tags.forEach(function (g, i) {
        out.push({
            id: "tag:" + g,
            kind: "tag",
            label: "#" + g,
            spans: tagSpans.filter(function (s) {
                return s.text.slice(1).toLowerCase() === g;
            })
        });
    });
    var linkSpans = spansOf("link");
    r.links.forEach(function (u) {
        out.push({
            id: "link:" + u,
            kind: "link",
            label: Links.linkInfo(u).label,
            spans: linkSpans.filter(function (s) {
                return s.text.replace(/[.,;!?]+$/, "") === u;
            })
        });
    });
    return out;
}
