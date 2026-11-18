.pragma library
.import "Dates.js" as Dates
.import "Links.js" as Links
.import "Reminders.js" as Reminders

// Modelo de las tareas: valores por defecto, validación al leer tasks.json y cambios sin mutar.
// Todo es puro (sin QML) para probarlo con node. Si hace falta un campo nuevo, se agrega aquí con un
// valor por defecto al leer; nunca se renombra ni se quita (así un tasks.json viejo sigue funcionando).

var VERSION = 1;
var STATUSES = ["todo", "doing", "blocked", "done", "cancelled"];
var FREQS = ["daily", "weekdays", "weekly", "monthly", "yearly"];
var COLORS = ["#4285f4", "#ea4335", "#fbbc04", "#34a853", "#a142f4", "#ff6d01", "#46bdc6", "#7baaf7"];

// ── Ids: prefijo + 6 caracteres base36 al azar ──
function newId(prefix) {
    var s = "";
    for (var i = 0; i < 6; i++)
        s += Math.floor(Math.random() * 36).toString(36);
    return prefix + s;
}

function uniqueId(prefix, list) {
    var id;
    do
        id = newId(prefix);
    while (list.some(function (x) {
        return x.id === id;
    }));
    return id;
}

function str(v) {
    return typeof v === "string" ? v : (v === undefined || v === null ? "" : String(v));
}

function num(v, def) {
    v = Number(v);
    return isFinite(v) ? v : def;
}

// Etiquetas: sin "#", en minúsculas, sin repetir. Acepta un arreglo o texto "a, #b".
function normTags(tags) {
    if (typeof tags === "string")
        tags = tags.split(/[\s,]+/);
    if (!Array.isArray(tags))
        return [];
    var out = [];
    tags.forEach(function (t) {
        t = str(t).trim().replace(/^#+/, "").toLowerCase();
        if (t && out.indexOf(t) < 0)
            out.push(t);
    });
    return out;
}

function normRepeat(r) {
    if (!r || typeof r !== "object" || FREQS.indexOf(r.freq) < 0)
        return null;
    var days = Array.isArray(r.days) ? r.days.map(Number).filter(function (d) {
        return d >= 1 && d <= 7;
    }) : [];
    var out = {
        freq: r.freq,
        interval: Math.max(1, Math.round(num(r.interval, 1))),
        days: days,
        from: r.from === "done" ? "done" : "due"
    };
    // Día del mes al que vuelve una repetición mensual o anual (31 → el último día en meses cortos)
    var day = Math.round(num(r.day, 0));
    if (day >= 1 && day <= 31)
        out.day = day;
    return out;
}

function normReminders(list) {
    if (!Array.isArray(list))
        return [];
    return list.filter(function (r) {
        return r && typeof r === "object";
    }).map(function (r) {
        return {
            id: str(r.id) || newId("r_"),
            offset: Math.max(0, Math.round(num(r.offset, 0))),
            at: /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(str(r.at)) ? r.at : "",
            firedAt: num(r.firedAt, 0)
        };
    });
}

function normSubtasks(list) {
    if (!Array.isArray(list))
        return [];
    return list.filter(function (s) {
        return s && typeof s === "object" && str(s.title).trim() !== "";
    }).map(function (s) {
        return {
            id: str(s.id) || newId("s_"),
            title: str(s.title).trim(),
            done: s.done === true
        };
    });
}

function normLinks(list) {
    if (!Array.isArray(list))
        return [];
    var out = [];
    list.forEach(function (l) {
        if (typeof l === "string")
            l = {
                url: l
            };
        if (!l || typeof l !== "object" || !str(l.url).trim())
            return;
        var info = Links.linkInfo(l.url);
        out.push({
            url: str(l.url).trim(),
            kind: str(l.kind) || info.kind,
            label: str(l.label) || info.label,
            title: str(l.title),
            state: str(l.state),
            checked: num(l.checked, 0)
        });
    });
    return out;
}

// Completa y limpia una tarea; conserva los campos que no conoce.
function normTask(t, now) {
    now = now || Date.now();
    var o = Object.assign({}, t);
    o.id = str(t.id) || newId("t_");
    o.title = str(t.title).trim();
    o.notes = str(t.notes);
    o.status = STATUSES.indexOf(t.status) >= 0 ? t.status : "todo";
    o.blockedReason = o.status === "blocked" ? str(t.blockedReason) : "";
    var p = Math.round(num(t.priority, 4));
    o.priority = p >= 1 && p <= 4 ? p : 4;
    o.project = t.project ? str(t.project) : null;
    o.tags = normTags(t.tags);
    o.due = Dates.isKey(t.due) ? t.due : "";
    o.dueTime = o.due && Dates.isTime(t.dueTime) ? t.dueTime : "";
    o.start = Dates.isKey(t.start) ? t.start : "";
    o.reminders = normReminders(t.reminders);
    o.repeat = normRepeat(t.repeat);
    o.estimate = Math.max(0, Math.round(num(t.estimate, 0)));
    o.subtasks = normSubtasks(t.subtasks);
    o.links = normLinks(t.links);
    o.order = num(t.order, 0);
    o.repeatOf = str(t.repeatOf);
    o.created = num(t.created, now);
    o.updated = num(t.updated, o.created);
    o.completed = num(t.completed, 0);
    if ((o.status === "done" || o.status === "cancelled") && o.completed === 0)
        o.completed = now;
    if (o.status !== "done" && o.status !== "cancelled")
        o.completed = 0;
    return o;
}

function normProject(p, index) {
    return {
        id: str(p.id) || newId("p_"),
        name: str(p.name).trim() || "Proyecto",
        color: /^#[0-9a-f]{6}$/i.test(str(p.color)) ? p.color : COLORS[index % COLORS.length],
        icon: str(p.icon),
        order: num(p.order, (index + 1) * 1000),
        archived: p.archived === true
    };
}

function normTemplate(tp) {
    var p = Math.round(num(tp.priority, 4));
    return {
        id: str(tp.id) || newId("tp_"),
        name: str(tp.name).trim(),
        title: str(tp.title).trim(),
        project: tp.project ? str(tp.project) : null,
        tags: normTags(tp.tags),
        priority: p >= 1 && p <= 4 ? p : 4,
        estimate: Math.max(0, Math.round(num(tp.estimate, 0))),
        notes: str(tp.notes),
        subtasks: Array.isArray(tp.subtasks) ? tp.subtasks.map(str).filter(function (s) {
            return s.trim() !== "";
        }) : []
    };
}

// Objeto leído de tasks.json → { ok, error, data: { version, projects, tasks, templates } }
function normData(raw, now) {
    if (!raw || typeof raw !== "object" || Array.isArray(raw))
        return {
            ok: false,
            error: "el archivo no es un objeto"
        };
    var version = num(raw.version, 1);
    if (version > VERSION)
        return {
            ok: false,
            error: "versión " + version + " no soportada (esta shell entiende hasta la " + VERSION + ")"
        };
    var projects = (Array.isArray(raw.projects) ? raw.projects : []).filter(function (p) {
        return p && typeof p === "object";
    }).map(normProject);
    var tasks = (Array.isArray(raw.tasks) ? raw.tasks : []).filter(function (t) {
        return t && typeof t === "object";
    }).map(function (t) {
        return normTask(t, now);
    });
    var templates = (Array.isArray(raw.templates) ? raw.templates : []).filter(function (t) {
        return t && typeof t === "object";
    }).map(normTemplate);
    // Ids repetidos o proyecto que ya no existe
    var seen = {};
    var ids = {};
    projects.forEach(function (p) {
        ids[p.id] = true;
    });
    var maxOrder = 0;
    tasks.forEach(function (t) {
        if (t.order > maxOrder)
            maxOrder = t.order;
    });
    tasks = tasks.map(function (t) {
        var fix = {};
        if (seen[t.id])
            fix.id = uniqueId("t_", tasks);
        if (t.project && !ids[t.project])
            fix.project = null;
        if (t.order === 0) {
            maxOrder += 1000;
            fix.order = maxOrder;
        }
        seen[fix.id || t.id] = true;
        return Object.keys(fix).length ? Object.assign({}, t, fix) : t;
    });
    return {
        ok: true,
        error: "",
        data: {
            version: VERSION,
            projects: projects,
            tasks: tasks,
            templates: templates
        }
    };
}

// ── Cambios (siempre devuelven un objeto nuevo) ──

// Tarea nueva; `order` la deja al final de la lista
function makeTask(fields, now, existing) {
    var maxOrder = 0;
    existing.forEach(function (t) {
        if (t.order > maxOrder)
            maxOrder = t.order;
    });
    var f = Object.assign({}, fields, {
        id: uniqueId("t_", existing),
        created: now,
        updated: now,
        completed: 0,
        order: maxOrder + 1000
    });
    var t = normTask(f, now);
    // Con hora, avisa a la hora por defecto
    if (t.dueTime && t.reminders.length === 0 && fields.reminders === undefined)
        t.reminders = [Reminders.make(0)];
    return t;
}

// Cambia el estado: pone o quita `completed` y el motivo del bloqueo
function applyStatus(task, status, reason, now) {
    if (STATUSES.indexOf(status) < 0)
        return task;
    var done = status === "done" || status === "cancelled";
    return Object.assign({}, task, {
        status: status,
        blockedReason: status === "blocked" ? str(reason) : "",
        completed: done ? now : 0,
        updated: now
    });
}

// Aplica cambios de campos (no toca id ni created) y limpia el resultado
function applyChanges(task, changes, now) {
    var merged = Object.assign({}, task, changes);
    merged.id = task.id;
    merged.created = task.created;
    merged.updated = now;
    var out = normTask(merged, now);
    if (changes.reminders === undefined) {
        // Otra fecha u hora: los avisos se reprograman; si aparece una hora y no hay avisos, uno a la hora
        if (task.due !== out.due || task.dueTime !== out.dueTime)
            out.reminders = Reminders.reschedule(out.reminders);
        if (!task.dueTime && out.dueTime && out.reminders.length === 0)
            out.reminders = [Reminders.make(0)];
    }
    if (changes.status !== undefined && changes.status !== task.status)
        out = applyStatus(out, out.status, changes.blockedReason, now);
    return out;
}

// Completar una tarea que se repite: devuelve { copy, next }. `copy` es una copia hecha (queda en
// Hechas y en el standup) y `next` es la misma tarea con la próxima fecha, sin subtareas marcadas y con
// los avisos reprogramados.
function completeRepeating(task, nextDue, now, copyId) {
    var copy = Object.assign({}, task, {
        id: copyId,
        status: "done",
        blockedReason: "",
        completed: now,
        updated: now,
        repeat: null,
        repeatOf: task.id,
        reminders: []
    });
    return {
        copy: copy,
        next: skipRepeat(task, nextDue, now)
    };
}

// La tarea que se repite pasa a su próxima fecha (sin hacerla)
function skipRepeat(task, nextDue, now) {
    var repeat = Object.assign({}, task.repeat);
    if (!repeat.day && task.due)
        repeat.day = Dates.parseKey(task.due).getDate();
    var start = task.start;
    if (start && task.due)
        start = Dates.addDays(start, Dates.diffDays(task.due, nextDue));
    return Object.assign({}, task, {
        due: nextDue,
        start: start,
        status: "todo",
        blockedReason: "",
        completed: 0,
        updated: now,
        repeat: repeat,
        subtasks: task.subtasks.map(function (s) {
            return Object.assign({}, s, {
                done: false
            });
        }),
        reminders: Reminders.reschedule(task.reminders)
    });
}

function makeProject(name, color, projects) {
    var maxOrder = 0;
    projects.forEach(function (p) {
        if (p.order > maxOrder)
            maxOrder = p.order;
    });
    return normProject({
        id: uniqueId("p_", projects),
        name: name,
        color: color,
        order: maxOrder + 1000
    }, projects.length);
}

function byOrder(a, b) {
    return (a.order - b.order) || (a.created - b.created);
}

// Pone la tarea `id` justo antes de `beforeId` ("" = al final). Usa el promedio de los vecinos y,
// cuando el espacio se agota, renumera todo de 1000 en 1000.
function moveTask(tasks, id, beforeId) {
    var list = tasks.slice().sort(byOrder);
    var from = list.findIndex(function (t) {
        return t.id === id;
    });
    if (from < 0 || id === beforeId)
        return tasks;
    var moving = list.splice(from, 1)[0];
    var to = beforeId ? list.findIndex(function (t) {
        return t.id === beforeId;
    }) : list.length;
    if (to < 0)
        return tasks;
    var prev = to > 0 ? list[to - 1].order : null;
    var next = to < list.length ? list[to].order : null;
    var order;
    if (prev === null && next === null)
        order = 1000;
    else if (prev === null)
        order = next - 1000;
    else if (next === null)
        order = prev + 1000;
    else
        order = (prev + next) / 2;
    if (prev !== null && next !== null && next - prev < 0.001) {
        list.splice(to, 0, moving);
        var pos = {};
        list.forEach(function (t, i) {
            pos[t.id] = (i + 1) * 1000;
        });
        return tasks.map(function (t) {
            return Object.assign({}, t, {
                order: pos[t.id]
            });
        });
    }
    return tasks.map(function (t) {
        return t.id === id ? Object.assign({}, t, {
            order: order
        }) : t;
    });
}

// Mueve la subtarea `subId` a la posición `index` (0 = primera)
function moveSubtask(subtasks, subId, index) {
    var list = subtasks.slice();
    var from = list.findIndex(function (s) {
        return s.id === subId;
    });
    if (from < 0)
        return subtasks;
    var s = list.splice(from, 1)[0];
    list.splice(Math.max(0, Math.min(list.length, index)), 0, s);
    return list;
}

// Línea (desde 1) donde falla un JSON; 0 si es válido. JSON.parse de Qt no da la posición.
function jsonErrorLine(text) {
    var i = 0;
    var n = text.length;
    function fail() {
        throw i;
    }
    function ws() {
        while (i < n && " \t\r\n".indexOf(text.charAt(i)) >= 0)
            i++;
    }
    function string() {
        if (text.charAt(i) !== '"')
            fail();
        i++;
        while (i < n && text.charAt(i) !== '"') {
            if (text.charAt(i) === "\n")
                fail();
            if (text.charAt(i) === "\\")
                i++;
            i++;
        }
        if (i >= n)
            fail();
        i++;
    }
    function value() {
        ws();
        var c = text.charAt(i);
        if (c === "{") {
            i++;
            ws();
            if (text.charAt(i) === "}") {
                i++;
                return;
            }
            for (;;) {
                ws();
                string();
                ws();
                if (text.charAt(i) !== ":")
                    fail();
                i++;
                value();
                ws();
                if (text.charAt(i) === ",") {
                    i++;
                    continue;
                }
                if (text.charAt(i) === "}") {
                    i++;
                    return;
                }
                fail();
            }
        }
        if (c === "[") {
            i++;
            ws();
            if (text.charAt(i) === "]") {
                i++;
                return;
            }
            for (;;) {
                value();
                ws();
                if (text.charAt(i) === ",") {
                    i++;
                    continue;
                }
                if (text.charAt(i) === "]") {
                    i++;
                    return;
                }
                fail();
            }
        }
        if (c === '"')
            return string();
        var m = /^(-?\d+(\.\d+)?([eE][+-]?\d+)?|true|false|null)/.exec(text.substr(i, 40));
        if (!m)
            fail();
        i += m[0].length;
    }
    try {
        value();
        ws();
        if (i < n)
            fail();
        return 0;
    } catch (e) {
        if (typeof e !== "number")
            throw e;
        var line = 1;
        for (var k = 0; k < Math.min(e, n); k++)
            if (text.charAt(k) === "\n")
                line++;
        return line;
    }
}
