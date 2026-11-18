.pragma library
.import "Dates.js" as Dates

// Recordatorios de las tareas. Cada uno es { id, offset, at, firedAt }:
//   offset = minutos antes de la fecha límite con hora (0 = a la hora); at = "AAAA-MM-DDTHH:MM" fijo
//   (lo crea "Posponer"); firedAt = ms del último aviso (0 = pendiente).
// Una tarea sin hora solo avisa con los de `at`. Puro (sin QML): se prueba con node.

var MINUTE = 60000;
// Un aviso que llega con más de esto de retraso sale marcado "(atrasado)"
var LATE_AFTER = 5 * MINUTE;
// Los avisos perdidos hace más que esto no se muestran (se marcan como avisados y ya)
var MAX_AGE = 12 * 3600000;

// Las opciones que ofrece el detalle (minutos antes)
var PRESETS = [0, 5, 10, 30, 60, 1440];

function newId() {
    var s = "";
    for (var i = 0; i < 6; i++)
        s += Math.floor(Math.random() * 36).toString(36);
    return "r_" + s;
}

// "AAAA-MM-DDTHH:MM" → ms (hora local), o null
function parseAt(at) {
    var m = /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})$/.exec(at || "");
    return m ? Dates.dueMs(m[1], m[2]) : null;
}

// ms → "AAAA-MM-DDTHH:MM" (hora local)
function atString(ms) {
    var d = new Date(ms);
    return Dates.keyOf(d) + "T" + Dates.pad(d.getHours()) + ":" + Dates.pad(d.getMinutes());
}

// Cuándo avisa el recordatorio `r` de la tarea (ms), o null si no puede (sin hora y sin `at`)
function triggerMs(task, r) {
    if (r.at)
        return parseAt(r.at);
    if (!task.due || !task.dueTime)
        return null;
    return Dates.dueMs(task.due, task.dueTime) - r.offset * MINUTE;
}

function make(offset) {
    return {
        id: newId(),
        offset: offset,
        at: "",
        firedAt: 0
    };
}

// "a la hora", "10 min antes", "1 h antes", "1 día antes", "hoy 10:35" (los fijos)
function label(r, ahora) {
    if (r.at) {
        var p = r.at.split("T");
        return Dates.relative(p[0], p[1], ahora).replace(/^vencida /, "");
    }
    if (r.offset === 0)
        return "a la hora";
    if (r.offset % 1440 === 0)
        return (r.offset === 1440 ? "1 día" : r.offset / 1440 + " días") + " antes";
    return (r.offset < 60 ? r.offset + " min" : Dates.formatMinutes(r.offset)) + " antes";
}

// Avisos que ya tocan: [{ task, reminder, ms, late, stale }] (late: llegó con retraso; stale: de hace
// más de 12 h, solo se marca como avisado). Las hechas y las canceladas no avisan.
function due(tasks, nowMs) {
    var out = [];
    tasks.forEach(function (t) {
        if (t.status === "done" || t.status === "cancelled")
            return;
        t.reminders.forEach(function (r) {
            if (r.firedAt > 0)
                return;
            var ms = triggerMs(t, r);
            if (ms === null || ms > nowMs)
                return;
            out.push({
                task: t,
                reminder: r,
                ms: ms,
                late: nowMs - ms > LATE_AFTER,
                stale: nowMs - ms > MAX_AGE
            });
        });
    });
    return out.sort(function (a, b) {
        return a.ms - b.ms;
    });
}

// La tarea con esos recordatorios marcados como avisados
function markFired(task, ids, ms) {
    return Object.assign({}, task, {
        reminders: task.reminders.map(function (r) {
            return ids.indexOf(r.id) >= 0 ? Object.assign({}, r, {
                firedAt: ms
            }) : r;
        })
    });
}

// Posponer: quita los fijos ya avisados y agrega uno nuevo a `minutes` desde ahora
function snooze(task, minutes, nowMs) {
    var keep = task.reminders.filter(function (r) {
        return !(r.at && r.firedAt > 0);
    });
    var r = make(0);
    r.at = atString(nowMs + minutes * MINUTE);
    return Object.assign({}, task, {
        reminders: keep.concat([r])
    });
}

// Al cambiar la fecha o la hora: los avisos se reprograman (los fijos se descartan)
function reschedule(reminders) {
    return reminders.filter(function (r) {
        return !r.at;
    }).map(function (r) {
        return Object.assign({}, r, {
            firedAt: 0
        });
    });
}
