.pragma library

// Fechas locales de las tareas. Sin zona horaria: "AAAA-MM-DD" (fecha) y "HH:MM" (hora).
// Así un día no salta de fecha según la zona (el mismo cuidado que con los eventos de todo el día).
// `ahora` es un Date o ms desde 1970; si falta, se usa el momento actual.
// Días de la semana: lunes = 1 … domingo = 7.

var DAYS_SHORT = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"];
var DAYS_FULL = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"];
var MONTHS_SHORT = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

function pad(n) {
    return n < 10 ? "0" + n : String(n);
}

function toDate(ahora) {
    if (ahora === undefined || ahora === null)
        return new Date();
    return ahora instanceof Date ? ahora : new Date(ahora);
}

// Date → "AAAA-MM-DD"
function keyOf(d) {
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
}

// "AAAA-MM-DD" → Date a medianoche local; null si no es una fecha válida
function parseKey(k) {
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(k || "");
    if (!m)
        return null;
    var d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    return keyOf(d) === k ? d : null;
}

function isKey(k) {
    return parseKey(k) !== null;
}

function todayKey(ahora) {
    return keyOf(toDate(ahora));
}

function addDays(k, n) {
    var d = parseKey(k);
    return keyOf(new Date(d.getFullYear(), d.getMonth(), d.getDate() + n));
}

// 1 = lunes … 7 = domingo
function weekday(k) {
    var d = parseKey(k);
    return ((d.getDay() + 6) % 7) + 1;
}

function isWorkday(k) {
    return weekday(k) <= 5;
}

// Último día laborable antes de k (el lunes cuenta desde el viernes)
function prevWorkday(k) {
    var p = addDays(k, -1);
    while (!isWorkday(p))
        p = addDays(p, -1);
    return p;
}

// Días entre dos fechas (b - a); un cambio de hora (DST) no cuenta
function diffDays(a, b) {
    var da = parseKey(a);
    var db = parseKey(b);
    return Math.round((Date.UTC(db.getFullYear(), db.getMonth(), db.getDate()) - Date.UTC(da.getFullYear(), da.getMonth(), da.getDate())) / 86400000);
}

// k está entre desde y hasta, ambos incluidos ("" = sin límite)
function inRange(k, desde, hasta) {
    if (!k)
        return false;
    return (!desde || k >= desde) && (!hasta || k <= hasta);
}

// Inicio y fin del día (ms)
function dayStart(k) {
    return parseKey(k).getTime();
}

function dayEnd(k) {
    return parseKey(addDays(k, 1)).getTime();
}

// "HH:MM" válido
function isTime(t) {
    return /^([01]\d|2[0-3]):[0-5]\d$/.test(t || "");
}

// Momento límite en ms; sin hora, el final del día. null si no hay fecha.
function dueMs(due, dueTime) {
    if (!isKey(due))
        return null;
    if (isTime(dueTime)) {
        var d = parseKey(due);
        var p = dueTime.split(":");
        return new Date(d.getFullYear(), d.getMonth(), d.getDate(), Number(p[0]), Number(p[1])).getTime();
    }
    return dayEnd(due);
}

// ¿La fecha límite ya pasó? Sin hora vence al terminar el día. Las hechas y canceladas no vencen.
function isOverdue(tarea, ahora) {
    if (!tarea || !tarea.due || tarea.status === "done" || tarea.status === "cancelled")
        return false;
    var ms = dueMs(tarea.due, tarea.dueTime);
    return ms !== null && ms <= toDate(ahora).getTime();
}

// "mié 18 nov" (con el año si no es el actual)
function shortDate(k, ahora) {
    var d = parseKey(k);
    var s = DAYS_SHORT[weekday(k) - 1] + " " + d.getDate() + " " + MONTHS_SHORT[d.getMonth()];
    return d.getFullYear() === toDate(ahora).getFullYear() ? s : s + " " + d.getFullYear();
}

// Texto corto de la fecha límite para la fila: "hoy 10:00", "mañana", "vie", "18 nov",
// "vencida ayer", "vencida hace 3 d". Vacío si no hay fecha.
function relative(due, dueTime, ahora) {
    if (!isKey(due))
        return "";
    var now = toDate(ahora);
    var today = keyOf(now);
    var time = isTime(dueTime) ? " " + dueTime : "";
    var diff = diffDays(today, due);
    if (diff < 0) {
        if (diff === -1)
            return "vencida ayer";
        return "vencida hace " + (-diff) + " d";
    }
    if (diff === 0) {
        // Hoy y la hora ya pasó: sigue siendo "hoy", pero marcada como vencida
        var past = time !== "" && dueMs(due, dueTime) <= now.getTime();
        return (past ? "vencida " : "") + "hoy" + time;
    }
    if (diff === 1)
        return "mañana" + time;
    if (diff < 7)
        return DAYS_SHORT[weekday(due) - 1] + time;
    var d = parseKey(due);
    var s = d.getDate() + " " + MONTHS_SHORT[d.getMonth()];
    return (d.getFullYear() === now.getFullYear() ? s : s + " " + d.getFullYear()) + time;
}

// Etiqueta de un día para los títulos de sección: "Hoy", "Mañana", "Ayer", "mié 18 nov"
function dayLabel(k, ahora) {
    var diff = diffDays(todayKey(ahora), k);
    if (diff === 0)
        return "Hoy";
    if (diff === 1)
        return "Mañana";
    if (diff === -1)
        return "Ayer";
    return shortDate(k, ahora);
}

// Minutos → "30 m", "2 h", "2 h 30 m"; vacío si es 0
function formatMinutes(n) {
    n = Math.round(Number(n) || 0);
    if (n <= 0)
        return "";
    var h = Math.floor(n / 60);
    var m = n % 60;
    if (h === 0)
        return m + " m";
    return m === 0 ? h + " h" : h + " h " + m + " m";
}

// "9", "9:30", "0930", "14.05" → "HH:MM"; "" si no es una hora
function normTime(text) {
    var m = /^(\d{1,2})(?:[:.]?(\d{2}))?$/.exec(String(text || "").trim());
    if (!m)
        return "";
    var h = Number(m[1]);
    var mi = m[2] === undefined ? 0 : Number(m[2]);
    return h > 23 || mi > 59 ? "" : pad(h) + ":" + pad(mi);
}

// "30", "30m", "45 min", "2h", "1.5h", "1h30", "1h 30m" → minutos; 0 si está vacío; -1 si no se entiende
function parseMinutes(text) {
    var s = String(text || "").trim().toLowerCase().replace(",", ".");
    if (s === "")
        return 0;
    var m = /^(\d+(?:\.\d+)?)\s*h(?:oras?)?(?:\s*(\d+)\s*(?:m|min)?)?$/.exec(s);
    if (m)
        return Math.round(Number(m[1]) * 60 + (m[2] ? Number(m[2]) : 0));
    m = /^(\d+)\s*(?:m|min|mins|minutos?)?$/.exec(s);
    return m ? Number(m[1]) : -1;
}

// ms → "hace un momento", "hace 5 min", "hace 3 h", "hace 2 días", "hace 3 semanas"
function ago(ms, ahora) {
    var diff = Math.max(0, toDate(ahora).getTime() - ms);
    var min = Math.floor(diff / 60000);
    if (min < 1)
        return "hace un momento";
    if (min < 60)
        return "hace " + min + " min";
    var h = Math.floor(min / 60);
    if (h < 24)
        return "hace " + h + " h";
    var d = Math.floor(h / 24);
    if (d === 1)
        return "ayer";
    if (d < 14)
        return "hace " + d + " días";
    if (d < 60)
        return "hace " + Math.floor(d / 7) + " semanas";
    return "hace " + Math.floor(d / 30) + " meses";
}

// ms → "10:30" (hora local)
function clock(ms) {
    var d = new Date(ms);
    return pad(d.getHours()) + ":" + pad(d.getMinutes());
}
