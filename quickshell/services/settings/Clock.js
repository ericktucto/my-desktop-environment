.pragma library

// Hora y fecha para toda la shell (reloj de la barra, fecha al pasar el mouse, bloqueo). Puro, para probarlo con node.
// Preferencias → Bloqueo y reloj: hour12, seconds y dateFormat (text | dmy | mdy | iso).

var DAYS = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"];
var MONTHS = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];

function pad(n) {
    return (n < 10 ? "0" : "") + n;
}

// "05:07 PM" · "17:07" · con segundos "05:07:09 PM"
function time(d, hour12, seconds) {
    var h = d.getHours();
    var t = pad(hour12 ? (h % 12 === 0 ? 12 : h % 12) : h) + ":" + pad(d.getMinutes()) + (seconds ? ":" + pad(d.getSeconds()) : "");
    return hour12 ? t + (h < 12 ? " AM" : " PM") : t;
}

// format "text": corta «lun 16 nov» o larga «Lunes, 16 de noviembre»; dmy «16/11/2026»; mdy «11/16/2026»; iso «2026-11-16»
function date(d, format, long) {
    var day = d.getDate(), month = d.getMonth() + 1, year = d.getFullYear();
    if (format === "dmy")
        return pad(day) + "/" + pad(month) + "/" + year;
    if (format === "mdy")
        return pad(month) + "/" + pad(day) + "/" + year;
    if (format === "iso")
        return year + "-" + pad(month) + "-" + pad(day);
    var name = DAYS[d.getDay()];
    if (long)
        return name.charAt(0).toUpperCase() + name.slice(1) + ", " + day + " de " + MONTHS[d.getMonth()];
    return name.slice(0, 3) + " " + day + " " + MONTHS[d.getMonth()].slice(0, 3);
}
