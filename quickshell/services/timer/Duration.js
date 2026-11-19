.pragma library

// Tiempos del temporizador y del cronómetro. Puro (sin QML): se prueba con node tests/timer/duration.test.mjs

var SECOND = 1000;
var MINUTE = 60000;
var HOUR = 3600000;
// Más que esto no es un temporizador
var MAX = 100 * HOUR;

var UNIT = /^\s*(\d+(?:\.\d+)?)\s*(horas?|hrs?|h|minutos?|mins?|m|segundos?|segs?|s)?(?![a-záéíóúñ])/i;

function rank(unit) {
    if (!unit)
        return 0;
    var c = unit.charAt(0).toLowerCase();
    return c === "h" ? 3 : (c === "m" ? 2 : 1);
}

function pad(n) {
    return n < 10 ? "0" + n : String(n);
}

// "10", "10m", "90s", "1h30", "1h 30m", "1.5h", "5:00" (mm:ss), "1:30:00", seguidos de un nombre opcional:
// "10m té", "25 leer". Un número solo son minutos; tras "h" son minutos y tras "m", segundos.
// → { ms, name }, o null si no se entiende.
function parse(text) {
    var s = String(text || "").trim().replace(",", ".");
    if (s === "")
        return null;
    var ms = 0;
    var rest = "";
    var m = /^(\d+):(\d{1,2})(?::(\d{1,2}))?(?![\d:])\s*(.*)$/.exec(s);
    if (m) {
        var a = Number(m[1]);
        var b = Number(m[2]);
        var c = m[3] !== undefined ? Number(m[3]) : -1;
        if (c >= 0) {
            if (b >= 60 || c >= 60)
                return null;
            ms = a * HOUR + b * MINUTE + c * SECOND;
        } else {
            if (b >= 60)
                return null;
            ms = a * MINUTE + b * SECOND;
        }
        rest = m[4];
    } else {
        var pos = 0;
        var last = 4;
        var n = 0;
        while (true) {
            var t = UNIT.exec(s.substring(pos));
            if (!t)
                break;
            var unit = t[2] ? rank(t[2]) : (n === 0 ? 2 : (last === 3 ? 2 : (last === 2 ? 1 : 0)));
            // Tras una unidad sin siguiente (o repetida) ya empieza el nombre
            if (unit === 0 || (n > 0 && unit >= last))
                break;
            ms += Number(t[1]) * (unit === 3 ? HOUR : (unit === 2 ? MINUTE : SECOND));
            // Un número sin unidad cierra el tiempo
            last = t[2] ? unit : 0;
            pos += t[0].length;
            n++;
        }
        if (n === 0)
            return null;
        rest = s.substring(pos);
    }
    ms = Math.round(ms);
    if (ms <= 0 || ms > MAX)
        return null;
    return {
        ms: ms,
        name: rest.replace(/^[\s\-–—:·]+/, "").trim()
    };
}

// ms → "4:59", "1:04:59"; con `cs` (centésimas), "12:30.47"
function format(ms, cs) {
    var v = Math.max(0, Math.floor(ms));
    var total = Math.floor(v / SECOND);
    var h = Math.floor(total / 3600);
    var min = Math.floor(total / 60) % 60;
    var sec = total % 60;
    var out = h > 0 ? h + ":" + pad(min) + ":" + pad(sec) : min + ":" + pad(sec);
    if (cs)
        out += "." + pad(Math.floor((v % SECOND) / 10));
    return out;
}

// ms → "4 min", "1 h 30 min", "45 s", "4 min 30 s"
function label(ms) {
    var total = Math.max(0, Math.round(ms / SECOND));
    var h = Math.floor(total / 3600);
    var min = Math.floor(total / 60) % 60;
    var sec = total % 60;
    if (h > 0)
        return h + " h" + (min > 0 ? " " + min + " min" : "");
    if (min > 0)
        return min + " min" + (sec > 0 ? " " + sec + " s" : "");
    return sec + " s";
}
