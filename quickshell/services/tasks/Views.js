.pragma library
.import "Dates.js" as Dates

// Vistas de las tareas (Hoy, Próximos, Bandeja, proyectos, etiquetas, Tablero y Hechas), contadores y
// búsqueda. Se calcula todo junto una vez por cambio (no por fila). Puro, para probarlo con node.

function isActive(t) {
    return t.status === "todo" || t.status === "doing" || t.status === "blocked";
}

function isClosed(t) {
    return t.status === "done" || t.status === "cancelled";
}

// ── Orden ──
function byManual(a, b) {
    return (a.order - b.order) || (a.created - b.created);
}

// Las que tienen hora van por hora; las de todo el día después
function dueKey(t) {
    return t.due ? t.due + " " + (t.dueTime || "99:99") : "9999-99-99 99:99";
}

function byDue(a, b) {
    var x = dueKey(a);
    var y = dueKey(b);
    if (x !== y)
        return x < y ? -1 : 1;
    return (a.priority - b.priority) || byManual(a, b);
}

function byPriority(a, b) {
    if (a.priority !== b.priority)
        return a.priority - b.priority;
    return byDue(a, b);
}

function comparator(mode) {
    return mode === "due" ? byDue : (mode === "priority" ? byPriority : byManual);
}

function byCompleted(a, b) {
    return (b.completed - a.completed) || byManual(a, b);
}

// Todas las vistas de una vez. opts: { now, sort, upcomingDays }
function compute(tasks, projects, opts) {
    var now = Dates.toDate(opts.now);
    var today = Dates.keyOf(now);
    var cmp = comparator(opts.sort);
    var until = Dates.addDays(today, opts.upcomingDays || 7);
    var startOfToday = Dates.dayStart(today);

    var overdue = [];
    var todayList = [];
    var upcomingMap = {};
    var inbox = [];
    var closed = [];
    var board = {
        todo: [],
        doing: [],
        blocked: [],
        done: []
    };
    var byProject = {};
    var byTag = {};

    tasks.forEach(function (t) {
        if (!isActive(t)) {
            closed.push(t);
            if (t.status === "done" && t.completed >= startOfToday)
                board.done.push(t);
            return;
        }
        board[t.status].push(t);
        if (t.project)
            (byProject[t.project] || (byProject[t.project] = [])).push(t);
        else
            inbox.push(t);
        t.tags.forEach(function (g) {
            (byTag[g] || (byTag[g] = [])).push(t);
        });
        var started = !t.start || t.start <= today;
        if (Dates.isOverdue(t, now))
            overdue.push(t);
        else if (started && (t.due === today || t.status === "doing"))
            todayList.push(t);
        else if (t.due && t.due > today && t.due <= until)
            (upcomingMap[t.due] || (upcomingMap[t.due] = [])).push(t);
    });

    overdue.sort(cmp);
    todayList.sort(cmp);
    inbox.sort(cmp);
    ["todo", "doing", "blocked"].forEach(function (s) {
        board[s].sort(cmp);
    });
    board.done.sort(byCompleted);
    Object.keys(byProject).forEach(function (k) {
        byProject[k].sort(cmp);
    });
    Object.keys(byTag).forEach(function (k) {
        byTag[k].sort(cmp);
    });

    var upcoming = Object.keys(upcomingMap).sort().map(function (k) {
        return {
            key: k,
            label: Dates.dayLabel(k, now),
            tasks: upcomingMap[k].sort(cmp)
        };
    });
    var upcomingCount = 0;
    upcoming.forEach(function (g) {
        upcomingCount += g.tasks.length;
    });

    // Hechas: por día de cierre, la más reciente primero
    closed.sort(byCompleted);
    var doneGroups = [];
    var doneMap = {};
    closed.forEach(function (t) {
        var k = t.completed ? Dates.keyOf(new Date(t.completed)) : "";
        if (!doneMap[k]) {
            doneMap[k] = {
                key: k,
                label: k ? Dates.dayLabel(k, now) : "Sin fecha",
                tasks: []
            };
            doneGroups.push(doneMap[k]);
        }
        doneMap[k].tasks.push(t);
    });

    var estimate = 0;
    overdue.concat(todayList).forEach(function (t) {
        estimate += t.estimate;
    });

    var counts = {
        today: overdue.length + todayList.length,
        overdue: overdue.length,
        upcoming: upcomingCount,
        inbox: inbox.length,
        projects: {},
        tags: {}
    };
    Object.keys(byProject).forEach(function (k) {
        counts.projects[k] = byProject[k].length;
    });
    Object.keys(byTag).forEach(function (k) {
        counts.tags[k] = byTag[k].length;
    });

    return {
        todayKey: today,
        overdue: overdue,
        today: todayList,
        upcoming: upcoming,
        inbox: inbox,
        done: doneGroups,
        board: board,
        byProject: byProject,
        byTag: byTag,
        tagNames: Object.keys(byTag).sort(),
        counts: counts,
        todayEstimate: estimate
    };
}

// ── Búsqueda ──

// Minúsculas y sin acentos, para comparar
function norm(s) {
    return String(s === undefined || s === null ? "" : s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

// "revisar +trabajo #bug p1 vencidas en curso" → filtros y palabras
function parseQuery(text) {
    var q = {
        words: [],
        projects: [],
        tags: [],
        priorities: [],
        overdue: false,
        doing: false
    };
    var s = norm(text).replace(/\ben curso\b/g, "encurso");
    s.split(/\s+/).forEach(function (w) {
        if (!w)
            return;
        if (w.charAt(0) === "+" && w.length > 1)
            q.projects.push(w.slice(1));
        else if (w.charAt(0) === "#" && w.length > 1)
            q.tags.push(w.slice(1));
        else if (/^p[1-4]$/.test(w))
            q.priorities.push(Number(w.charAt(1)));
        else if (w === "vencidas" || w === "vencida")
            q.overdue = true;
        else if (w === "encurso")
            q.doing = true;
        else
            q.words.push(w);
    });
    return q;
}

function isEmptyQuery(q) {
    return q.words.length === 0 && q.projects.length === 0 && q.tags.length === 0 && q.priorities.length === 0 && !q.overdue && !q.doing;
}

// Texto de búsqueda → función(tarea) → bool. Los filtros se combinan con "y"; entre dos del mismo
// tipo ("p1 p2") basta uno.
function matcher(text, projects, now) {
    var q = parseQuery(text);
    var names = {};
    projects.forEach(function (p) {
        names[p.id] = norm(p.name);
    });
    return function (t) {
        if (q.overdue && !Dates.isOverdue(t, now))
            return false;
        if (q.doing && t.status !== "doing")
            return false;
        if (q.priorities.length && q.priorities.indexOf(t.priority) < 0)
            return false;
        if (q.projects.length) {
            var pn = t.project ? names[t.project] || "" : "bandeja";
            if (!q.projects.some(function (p) {
                return pn.indexOf(p) === 0;
            }))
                return false;
        }
        if (q.tags.length && !q.tags.some(function (g) {
            return t.tags.some(function (x) {
                return x.indexOf(g) === 0;
            });
        }))
            return false;
        if (q.words.length) {
            var hay = norm(t.title + " " + t.notes + " " + t.tags.join(" ") + " " + t.subtasks.map(function (s) {
                return s.title;
            }).join(" ") + " " + t.blockedReason);
            if (!q.words.every(function (w) {
                return hay.indexOf(w) >= 0;
            }))
                return false;
        }
        return true;
    };
}

// Búsqueda global: abiertas primero (en el orden elegido) y luego las cerradas, la más reciente primero
function search(tasks, projects, text, opts) {
    var now = Dates.toDate(opts.now);
    var match = matcher(text, projects, now);
    var open = tasks.filter(function (t) {
        return isActive(t) && match(t);
    }).sort(comparator(opts.sort));
    var closed = tasks.filter(function (t) {
        return isClosed(t) && match(t);
    }).sort(byCompleted);
    return open.concat(closed);
}

// ── Listas por vista ──

function projectName(projects, id) {
    var p = projects.find(function (x) {
        return x.id === id;
    });
    return p ? p.name : "";
}

// Vista → grupos [{ key, label, tasks }] sin los vacíos. `query` filtra dentro de la vista.
// view: today | upcoming | inbox | board | done | project:<id> | tag:<nombre>
function list(v, view, query, projects, now) {
    var groups;
    var i = String(view || "today").indexOf(":");
    var kind = i < 0 ? view : view.slice(0, i);
    var arg = i < 0 ? "" : view.slice(i + 1);
    if (kind === "upcoming")
        groups = v.upcoming;
    else if (kind === "inbox")
        groups = [
            {
                key: "inbox",
                label: "Bandeja",
                tasks: v.inbox
            }
        ];
    else if (kind === "done")
        groups = v.done;
    else if (kind === "board")
        groups = [
            {
                key: "todo",
                label: "Pendiente",
                tasks: v.board.todo
            },
            {
                key: "doing",
                label: "En curso",
                tasks: v.board.doing
            },
            {
                key: "blocked",
                label: "Bloqueada",
                tasks: v.board.blocked
            },
            {
                key: "done",
                label: "Hecha hoy",
                tasks: v.board.done
            }
        ];
    else if (kind === "project")
        groups = [
            {
                key: arg,
                label: projectName(projects, arg),
                tasks: v.byProject[arg] || []
            }
        ];
    else if (kind === "tag")
        groups = [
            {
                key: arg,
                label: "#" + arg,
                tasks: v.byTag[arg] || []
            }
        ];
    else
        groups = [
            {
                key: "overdue",
                label: "Vencidas",
                tasks: v.overdue
            },
            {
                key: "today",
                label: "Hoy",
                tasks: v.today
            }
        ];
    var match = query && !isEmptyQuery(parseQuery(query)) ? matcher(query, projects, now) : null;
    return groups.map(function (g) {
        return match ? {
            key: g.key,
            label: g.label,
            tasks: g.tasks.filter(match)
        } : g;
    }).filter(function (g) {
        return g.tasks.length > 0;
    });
}

// ── Standup ──

// Un renglón: "- Título (acme/api#412)"; los links de GitHub, GitLab o Jira van entre paréntesis
function standupLine(t, extra) {
    var labels = t.links.filter(function (l) {
        return l.kind !== "url";
    }).map(function (l) {
        return l.label;
    });
    var focus = t.focus && t.focus.minutes > 0 ? " · " + Dates.formatMinutes(t.focus.minutes) : "";
    return "- " + t.title + (labels.length > 0 ? " (" + labels.join(", ") + ")" : "") + focus + (extra ? " — " + extra : "");
}

// Markdown para el daily: lo de ayer, lo de hoy y lo bloqueado.
//  · Ayer: lo hecho desde el inicio del último día laborable (el lunes cuenta desde el viernes)
//    hasta antes de hoy.
//  · Hoy: lo que se ve en Hoy (vencidas, de hoy y en curso) y lo ya hecho hoy.
//  · Bloqueado: las bloqueadas, con su motivo.
function standup(tasks, now) {
    var d = Dates.toDate(now);
    var today = Dates.keyOf(d);
    var from = Dates.dayStart(Dates.prevWorkday(today));
    var startToday = Dates.dayStart(today);
    var yesterday = tasks.filter(function (t) {
        return t.status === "done" && t.completed >= from && t.completed < startToday;
    }).sort(function (a, b) {
        return a.completed - b.completed;
    });
    var doneToday = tasks.filter(function (t) {
        return t.status === "done" && t.completed >= startToday;
    }).sort(function (a, b) {
        return a.completed - b.completed;
    });
    var v = compute(tasks, [], {
        now: d,
        sort: "due",
        upcomingDays: 7
    });
    var todayList = v.overdue.concat(v.today);
    var blocked = tasks.filter(function (t) {
        return t.status === "blocked";
    }).sort(byManual);
    var out = [];
    if (yesterday.length > 0)
        out.push("**Ayer**", yesterday.map(function (t) {
            return standupLine(t);
        }).join("\n"), "");
    var hoy = todayList.map(function (t) {
        return standupLine(t);
    }).concat(doneToday.map(function (t) {
        return standupLine(t, "hecha");
    }));
    if (hoy.length > 0)
        out.push("**Hoy**", hoy.join("\n"), "");
    if (blocked.length > 0)
        out.push("**Bloqueado**", blocked.map(function (t) {
            return standupLine(t, t.blockedReason);
        }).join("\n"), "");
    return out.length === 0 ? "Sin novedades" : out.join("\n").replace(/\n+$/, "");
}
