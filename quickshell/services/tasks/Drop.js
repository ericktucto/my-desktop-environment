.pragma library
.import "Dates.js" as Dates

// Reglas de soltar una tarea arrastrada (lista, barra lateral y Tablero). Puro, para probarlo con node:
// no toca el store; devuelve lo que hay que cambiar y el store lo aplica en un solo `commit`.

var ORDER_HINT = "Cambia a Orden manual para ordenar";

// Fecha de hoy; la hora se conserva solo si todavía no llegó (si no, la tarea quedaría vencida)
function dueToday(task, now) {
    var today = Dates.todayKey(now);
    var ms = task.dueTime ? Dates.dueMs(today, task.dueTime) : null;
    return {
        due: today,
        dueTime: ms !== null && ms > Dates.toDate(now).getTime() ? task.dueTime : ""
    };
}

// Si la fecha de inicio queda después de la nueva fecha límite, se quita
function fixStart(task, changes) {
    var due = changes.due !== undefined ? changes.due : task.due;
    if (task.start && due && due < task.start)
        changes.start = "";
    return changes;
}

function dateLabel(key, now) {
    return "Movida a " + Dates.dayLabel(key, now).toLowerCase();
}

function indexOfIn(tasks, id) {
    for (var i = 0; i < tasks.length; i++)
        if (tasks[i].id === id)
            return i;
    return -1;
}

// Soltar en la lista. `groups` = [{ key, label, tasks }] tal como se ven; `targetKey` es el grupo donde
// se suelta e `index` la posición dentro de él sin contar la tarea que se arrastra.
// opts = { sort, now }. Devuelve null si no vale; si no hay nada que cambiar, `noop: true`
// (con `hint` cuando falta el orden manual).
// → { noop, hint, changes, beforeId, afterId, label }
function listDrop(view, groups, id, targetKey, index, opts) {
    var from = null;
    var to = null;
    groups.forEach(function (g) {
        if (g.key === targetKey)
            to = g;
        if (indexOfIn(g.tasks, id) >= 0)
            from = g;
    });
    if (!from || !to)
        return null;
    var task = from.tasks[indexOfIn(from.tasks, id)];
    var manual = opts.sort === "manual";
    var changes = {};
    var label = "Tarea movida";

    if (from !== to) {
        if (view === "today") {
            // A Vencidas no se puede soltar (el vencimiento sale de la fecha)
            if (to.key !== "today")
                return null;
            changes = dueToday(task, opts.now);
            label = "Movida a hoy";
        } else if (view === "upcoming") {
            if (!Dates.isKey(to.key))
                return null;
            changes = {
                due: to.key
            };
            label = dateLabel(to.key, opts.now);
        } else {
            return null;
        }
        fixStart(task, changes);
    }

    var rest = to.tasks.filter(function (t) {
        return t.id !== id;
    });
    var at = Math.max(0, Math.min(rest.length, index));
    var res = {
        noop: false,
        changes: changes,
        beforeId: "",
        afterId: "",
        label: label
    };
    if (manual) {
        if (at < rest.length)
            res.beforeId = rest[at].id;
        else if (rest.length > 0)
            res.afterId = rest[rest.length - 1].id;
    }
    if (from === to) {
        // Misma sección: sin orden manual solo hay aviso; con él, mismo lugar = nada
        if (!manual) {
            res.noop = true;
            res.hint = ORDER_HINT;
        } else if (at === indexOfIn(from.tasks, id)) {
            res.noop = true;
        }
    }
    return res;
}

// Soltar sobre una entrada de la barra lateral: Hoy, Próximos (mañana), Bandeja, proyecto, etiqueta
// u Hechas. opts = { now, projects }.
// → { kind: "update", changes, label } | { kind: "complete" } | null
function sidebarDrop(task, targetView, opts) {
    var now = opts.now;
    var upd = function (changes, label) {
        return {
            kind: "update",
            changes: fixStart(task, changes),
            label: label
        };
    };
    if (targetView === "today") {
        var c = dueToday(task, now);
        if (task.due === c.due && task.dueTime === c.dueTime)
            return null;
        return upd(c, "Movida a hoy");
    }
    if (targetView === "upcoming") {
        var tomorrow = Dates.addDays(Dates.todayKey(now), 1);
        if (task.due === tomorrow)
            return null;
        return upd({
            due: tomorrow
        }, "Movida a mañana");
    }
    if (targetView === "inbox")
        return task.project ? upd({
            project: null
        }, "Movida a Bandeja") : null;
    if (targetView.indexOf("project:") === 0) {
        var pid = targetView.slice(8);
        var p = (opts.projects || []).filter(function (x) {
            return x.id === pid;
        })[0];
        return task.project === pid ? null : upd({
            project: pid
        }, "Movida a +" + (p ? p.name : "proyecto"));
    }
    if (targetView.indexOf("tag:") === 0) {
        var tag = targetView.slice(4);
        if (task.tags.indexOf(tag) >= 0)
            return null;
        return upd({
            tags: task.tags.concat([tag])
        }, "#" + tag + " añadida");
    }
    if (targetView === "done")
        return task.status === "done" || task.status === "cancelled" ? null : {
            kind: "complete"
        };
    return null;
}

// Cuánto se corre la fila `i` para dejar el hueco cuando la fila `from` se arrastra sobre `to`
// (todas del alto `h`): 0, +h (baja) o -h (sube).
function gapShift(i, from, to, h) {
    if (from < 0 || to < 0 || i === from)
        return 0;
    if (from < to && i > from && i <= to)
        return -h;
    if (from > to && i >= to && i < from)
        return h;
    return 0;
}
