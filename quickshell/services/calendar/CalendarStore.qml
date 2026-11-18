pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../../" as App
import "../tasks/" as TK
import "../tasks/Dates.js" as TDates

// Calendario del panel Productividad: fechas, vistas, eventos de Google (scripts/gcal.py) y feriados.
// Las fechas se manejan como Date a medianoche local y, para indexar, como texto "AAAA-MM-DD" (`keyOf`).
Singleton {
    id: store

    readonly property var cfg: App.Config.calendar
    readonly property string script: Quickshell.shellPath("scripts/gcal.py")

    // ── Nombres ──
    readonly property var months: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var monthsShort: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    // Lunes primero
    readonly property var daysFull: ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    readonly property var daysShort: ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
    readonly property var daysMin: ["lu", "ma", "mi", "ju", "vi", "sá", "do"]

    // ── Estado ──
    readonly property string view: ST.SettingsStore.calendar.view
    property var selected: new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate())
    property bool pickerOpen: false
    // Evento desplegado en la lista (solo uno); se pliega al cambiar de día
    property string expandedId: ""
    onSelectedChanged: expandedId = ""

    function toggleEvent(ev) {
        if (ev.task) {
            TK.TaskStore.openTask(ev.taskId);
            return;
        }
        expandedId = expandedId === ev.id ? "" : ev.id;
    }

    // Clic en un bloque de la cuadrícula: elige su día y lo despliega en la lista
    function openEvent(ev, key) {
        if (ev.task) {
            TK.TaskStore.openTask(ev.taskId);
            return;
        }
        select(parseDay(key));
        expandedId = ev.id;
    }

    property bool hasClient: false
    property bool connected: false
    property string email: ""
    property bool loading: false
    property bool loggingIn: false
    // "" | no-client | no-token | expired | offline | texto de error
    property string error: ""
    property double updated: 0
    property var events: []
    property var calendars: []
    property var holidayList: []
    property string loadedMonth: ""       // mes (AAAA-MM) alrededor del que se pidió el rango
    property string loadedFrom: ""
    property string loadedTo: ""
    property double lastFetch: 0
    property bool again: false            // pidieron actualizar mientras cargaba

    // ── Reloj ──
    readonly property var now: clock.date
    readonly property string todayKey: keyOf(now)
    readonly property string selectedKey: keyOf(selected)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        property double last: 0
        onDateChanged: {
            const t = date.getTime();
            // Más tiempo del normal entre dos avisos: la laptop estaba suspendida
            if (last > 0 && t - last > store.cfg.resumeGap * 1000)
                store.refresh(false);
            last = t;
        }
    }

    // ── Fechas ──
    function pad(n) {
        return n < 10 ? "0" + n : String(n);
    }

    function keyOf(d) {
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
    }

    function parseDay(key) {
        const p = key.split("-");
        return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]));
    }

    function addDays(d, n) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
    }

    function addMonths(d, n) {
        const t = new Date(d.getFullYear(), d.getMonth() + n, 1);
        const last = new Date(t.getFullYear(), t.getMonth() + 1, 0).getDate();
        return new Date(t.getFullYear(), t.getMonth(), Math.min(d.getDate(), last));
    }

    // 0 = lunes … 6 = domingo
    function weekday(d) {
        return (d.getDay() + 6) % 7;
    }

    function monthKey(d) {
        return d.getFullYear() + "-" + pad(d.getMonth() + 1);
    }

    function shortDate(d) {
        return daysShort[weekday(d)] + " " + d.getDate() + " " + monthsShort[d.getMonth()];
    }

    function longDate(d) {
        return daysFull[weekday(d)] + ", " + d.getDate() + " de " + months[d.getMonth()].toLowerCase();
    }

    function time12(ms) {
        const d = new Date(ms);
        const h = d.getHours();
        return (h % 12 === 0 ? 12 : h % 12) + ":" + pad(d.getMinutes()) + " " + (h < 12 ? "AM" : "PM");
    }

    // "9:00 – 10:00 AM", "11:30 AM – 12:30 PM", "Todo el día"
    function timeLabel(ev) {
        if (ev.allDay)
            return "Todo el día";
        const a = time12(ev.start), b = time12(ev.end);
        const sd = new Date(ev.start), ed = new Date(ev.end);
        const sameDay = keyOf(sd) === keyOf(ed);
        const nextDay = keyOf(addDays(sd, 1)) === keyOf(ed);
        if (!sameDay && !nextDay)
            return sd.getDate() + " " + monthsShort[sd.getMonth()] + " " + a + " – " + ed.getDate() + " " + monthsShort[ed.getMonth()] + " " + b;
        if (a.slice(-2) === b.slice(-2) && sameDay)
            return a.slice(0, -3) + " – " + b;
        return a + " – " + b;
    }

    // ── Navegación ──
    function setView(v) {
        ST.SettingsStore.calendar.view = v;
        pickerOpen = false;
    }

    function select(d) {
        selected = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        ensureRange();
    }

    function goToday() {
        pickerOpen = false;
        select(new Date(now.getFullYear(), now.getMonth(), now.getDate()));
    }

    function shift(dir) {
        if (view === "month")
            select(addMonths(selected, dir));
        else
            select(addDays(selected, dir * (view === "week" ? 7 : view === "days3" ? 3 : 1)));
    }

    // Selector de mes y año
    function jumpTo(year, month) {
        const cur = year === now.getFullYear() && month === now.getMonth();
        pickerOpen = false;
        select(cur ? new Date(now.getFullYear(), now.getMonth(), now.getDate()) : new Date(year, month, 1));
    }

    // Se abre el panel: siempre en hoy
    function opened() {
        pickerOpen = false;
        selected = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        checkStatus();
        if (Date.now() - lastFetch > cfg.minGap * 1000)
            refresh(false);
        else
            ensureRange();
        ensureHolidays();
    }

    // Las seis semanas de la vista Mes (42 días, desde el lunes de la semana del día 1)
    readonly property var monthGrid: {
        const first = new Date(selected.getFullYear(), selected.getMonth(), 1);
        const start = addDays(first, -weekday(first));
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(addDays(start, i));
        return out;
    }

    // Los días de las vistas por horas
    readonly property var gridDays: {
        if (view === "week") {
            const start = addDays(selected, -weekday(selected));
            return [0, 1, 2, 3, 4, 5, 6].map(i => addDays(start, i));
        }
        if (view === "days3")
            return [0, 1, 2].map(i => addDays(selected, i));
        return [selected];
    }

    readonly property string title: {
        if (view === "month")
            return months[selected.getMonth()] + " " + selected.getFullYear();
        if (view === "day")
            return longDate(selected);
        const a = gridDays[0], b = gridDays[gridDays.length - 1];
        const sameMonth = a.getMonth() === b.getMonth() && a.getFullYear() === b.getFullYear();
        const sameYear = a.getFullYear() === b.getFullYear();
        const withYear = view === "week";
        if (sameMonth)
            return a.getDate() + " – " + b.getDate() + " " + monthsShort[b.getMonth()] + (withYear ? " " + b.getFullYear() : "");
        if (sameYear)
            return a.getDate() + " " + monthsShort[a.getMonth()] + " – " + b.getDate() + " " + monthsShort[b.getMonth()] + (withYear ? " " + b.getFullYear() : "");
        return a.getDate() + " " + monthsShort[a.getMonth()] + " " + a.getFullYear() + " – " + b.getDate() + " " + monthsShort[b.getMonth()] + " " + b.getFullYear();
    }

    // ── Eventos por día ──
    // día → [evento] (feriados y celebraciones incluidos). Un evento de varios días aparece en cada uno.
    readonly property var byDay: buildDays(events, holidayList, TK.TaskStore.tasks, TK.TaskStore.projects)

    function buildDays(evs, hols, tasks, projects) {
        const map = {};
        const put = (key, e) => {
            (map[key] = map[key] || []).push(e);
        };
        const fallback = String(App.Theme.primary);
        for (const h of hols) {
            put(h.date, {
                id: "h-" + h.date + h.title,
                title: h.title,
                allDay: true,
                holiday: h.kind === "holiday",
                observance: h.kind !== "holiday",
                color: String(h.kind === "holiday" ? App.Theme.red : App.Theme.amber),
                calName: "Feriados",
                start: 0,
                end: 0,
                segStart: 0,
                segEnd: 0,
                location: "",
                description: "",
                meet: "",
                link: ""
            });
        }
        for (const ev of evs) {
            const color = ev.color || fallback;
            if (ev.allDay) {
                let d = parseDay(ev.startDate);
                const last = ev.endDate;
                for (let i = 0; i < 62; i++) {
                    const k = keyOf(d);
                    if (k > last)
                        break;
                    put(k, Object.assign({}, ev, {
                        color: color,
                        segStart: 0,
                        segEnd: 0
                    }));
                    d = addDays(d, 1);
                }
            } else {
                const s = ev.start, e = Math.max(ev.end, ev.start);
                let d = new Date(new Date(s).getFullYear(), new Date(s).getMonth(), new Date(s).getDate());
                for (let i = 0; i < 62; i++) {
                    const dayStart = d.getTime();
                    const dayEnd = addDays(d, 1).getTime();
                    if (dayStart >= Math.max(e, s + 1))
                        break;
                    put(keyOf(d), Object.assign({}, ev, {
                        color: color,
                        segStart: Math.max(s, dayStart),
                        segEnd: Math.min(Math.max(e, s), dayEnd),
                        contStart: s < dayStart,
                        contEnd: e > dayEnd
                    }));
                    d = new Date(dayEnd);
                }
            }
        }
        // Las tareas con fecha límite que siguen abiertas: con hora, un bloque de 30 min; sin hora, todo el día
        for (const t of tasks) {
            if (t.due === "" || t.status === "done" || t.status === "cancelled")
                continue;
            const p = projects.find(x => x.id === t.project);
            const timed = t.dueTime !== "";
            const s = timed ? TDates.dueMs(t.due, t.dueTime) : 0;
            const dayEnd = timed ? TDates.dayEnd(t.due) : 0;
            put(t.due, {
                id: "task:" + t.id,
                task: true,
                taskId: t.id,
                taskTitle: t.title,
                title: "○ " + t.title,
                allDay: !timed,
                holiday: false,
                observance: false,
                color: p ? p.color : String(App.Theme.gray),
                calName: "Tareas",
                start: s,
                end: s + 1800000,
                segStart: s,
                segEnd: timed ? Math.min(s + 1800000, dayEnd) : 0,
                location: "",
                description: "",
                meet: "",
                link: ""
            });
        }
        for (const k in map) {
            map[k].sort((a, b) => {
                const ra = a.holiday ? 0 : a.observance ? 1 : a.allDay ? 2 : 3;
                const rb = b.holiday ? 0 : b.observance ? 1 : b.allDay ? 2 : 3;
                return ra - rb || a.segStart - b.segStart || a.title.localeCompare(b.title);
            });
        }
        return map;
    }

    function eventsOn(key) {
        return byDay[key] || [];
    }

    // Eventos de un día sin los feriados (para los puntos del mes)
    function dotsOn(key) {
        return eventsOn(key).filter(e => !e.holiday && !e.observance);
    }

    function isHoliday(key) {
        return eventsOn(key).some(e => e.holiday);
    }

    // ── Próximo evento (para el reloj) ──
    readonly property var next: {
        const t = now.getTime();
        const list = eventsOn(todayKey).concat(eventsOn(keyOf(addDays(now, 1)))).filter(e => !e.task && !e.allDay && e.segEnd > t && e.segStart < t + cfg.upcoming * 1000);
        list.sort((a, b) => ((a.segStart <= t) ? 0 : 1) - ((b.segStart <= t) ? 0 : 1) || a.segStart - b.segStart);
        return list.length > 0 ? list[0] : null;
    }

    function minutesText(ms) {
        const m = Math.max(1, Math.ceil(ms / 60000));
        if (m < 60)
            return m + " min";
        const h = Math.floor(m / 60), r = m % 60;
        return h + " h" + (r ? " " + r + " min" : "");
    }

    // "termina en 10 min" (en curso), "en 25 min" (próximo de hoy) o "" (ya pasó, otro día o todo el día)
    function countdown(ev) {
        if (ev.allDay || keyOf(new Date(ev.segStart)) !== todayKey)
            return "";
        const t = now.getTime();
        if (ev.segEnd <= t)
            return "";
        if (ev.segStart <= t)
            return "termina en " + minutesText(ev.segEnd - t);
        return "en " + minutesText(ev.segStart - t);
    }

    function isPast(ev) {
        return !ev.allDay && ev.segEnd <= now.getTime();
    }

    function isNow(ev) {
        return !ev.allDay && ev.segStart <= now.getTime() && ev.segEnd > now.getTime();
    }

    // Lo que dice el reloj con el mouse encima: "lun 16 nov" o "lun 16 nov · Reunión en 25 min"
    readonly property string hoverText: {
        let t = shortDate(now);
        const ev = next;
        if (ev) {
            const name = ev.title.length > cfg.titleMax ? ev.title.slice(0, cfg.titleMax - 1) + "…" : ev.title;
            t += " · " + name + " " + (ev.segStart <= now.getTime() ? "ahora" : "en " + minutesText(ev.segStart - now.getTime()));
        }
        // Tareas: "3 tareas hoy" y "1 vencida"
        const c = TK.TaskStore.counts;
        const todayCount = c.today - c.overdue;
        if (todayCount > 0)
            t += " · " + todayCount + (todayCount === 1 ? " tarea" : " tareas") + " hoy";
        if (c.overdue > 0)
            t += " · " + c.overdue + (c.overdue === 1 ? " vencida" : " vencidas");
        return t;
    }

    // ── Crear un evento: formulario de Google con el día y la hora ya puestos ──
    function stamp(ms) {
        const d = new Date(ms);
        return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + "T" + pad(d.getHours()) + pad(d.getMinutes()) + "00";
    }

    function newEventUrl(startMs, endMs) {
        let url = "https://calendar.google.com/calendar/render?action=TEMPLATE&dates=" + stamp(startMs) + "/" + stamp(endMs) + "&ctz=" + encodeURIComponent(cfg.timeZone);
        if (email)
            url += "&authuser=" + encodeURIComponent(email);
        return url;
    }

    // Desde el botón "+ Evento": la próxima hora en punto si el día elegido es hoy; si no, a las 9
    function newEventOnSelected() {
        let start;
        if (selectedKey === todayKey)
            start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours() + 1).getTime();
        else
            start = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate(), cfg.newEventHour).getTime();
        openUrl(newEventUrl(start, start + 3600000));
    }

    function openUrl(url) {
        Quickshell.execDetached(["xdg-open", url]);
    }

    function copyText(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // ── Procesos ──
    Component {
        id: runner
        Process {
            id: p
            property var done
            property string out: ""
            property bool outDone: false
            property bool exitDone: false
            property int code: -1
            stdout: StdioCollector {
                onStreamFinished: {
                    p.out = text;
                    p.outDone = true;
                    p.finish();
                }
            }
            onExited: function (exitCode, exitStatus) {
                p.code = exitCode;
                p.exitDone = true;
                p.finish();
            }
            function finish() {
                if (!outDone || !exitDone)
                    return;
                let json = null;
                try {
                    json = JSON.parse(out);
                } catch (e) {
                    json = null;
                }
                if (done)
                    done(json, code);
                destroy();
            }
        }
    }

    function run(cmd, done) {
        runner.createObject(store, {
            command: cmd,
            done: done
        }).running = true;
    }

    function checkStatus() {
        run(["python3", script, "status"], function (j) {
            if (!j)
                return;
            store.hasClient = j.client;
            store.connected = j.connected;
            if (j.email)
                store.email = j.email;
            // Sin sesión no se muestra lo que quedó guardado (otra cuenta, sesión borrada…)
            if (!j.connected && store.cfg.testSample === "" && store.events.length > 0) {
                store.events = [];
                store.calendars = [];
                store.updated = 0;
                store.loadedMonth = "";
                store.saveCache();
            }
        });
    }

    // Rango que se pide: el mes del día elegido, el anterior y el siguiente
    function rangeFor(d) {
        return {
            month: monthKey(d),
            from: keyOf(new Date(d.getFullYear(), d.getMonth() - 1, 1)),
            to: keyOf(new Date(d.getFullYear(), d.getMonth() + 2, 0))
        };
    }

    // Si lo que se mira queda fuera de lo cargado, se pide el rango nuevo
    function ensureRange() {
        ensureHolidays();
        if (monthKey(selected) !== loadedMonth && (connected || cfg.testSample !== ""))
            refresh(true);
    }

    function refresh(force) {
        if (loading) {
            again = true;
            return;
        }
        if (cfg.testSample === "" && (!hasClient || !connected)) {
            checkStatus();
            return;
        }
        loading = true;
        again = false;
        const r = rangeFor(selected);
        lastFetch = Date.now();
        const cmd = cfg.testSample !== "" ? ["cat", cfg.testSample] : ["python3", script, "events", "--from", r.from, "--to", r.to, "--skip-holidays"].filter(x => cfg.holidays !== "" || x !== "--skip-holidays");
        run(cmd, function (j, code) {
            store.loading = false;
            if (!j) {
                store.error = "No se pudo leer el calendario";
            } else if (!j.ok) {
                store.error = j.error || "Error";
                if (j.error === "no-client")
                    store.hasClient = false;
                else if (j.error === "no-token")
                    store.connected = false;
            } else {
                store.error = "";
                store.connected = true;
                store.hasClient = true;
                if (j.email)
                    store.email = j.email;
                store.events = j.events;
                store.calendars = j.calendars;
                store.updated = j.updated;
                store.loadedMonth = r.month;
                store.loadedFrom = r.from;
                store.loadedTo = r.to;
                store.saveCache();
            }
            if (store.again || (store.error === "" && monthKey(store.selected) !== store.loadedMonth))
                store.refresh(true);
        });
    }

    function login() {
        if (loggingIn)
            return;
        loggingIn = true;
        error = "";
        run(["python3", script, "login", "--timeout", String(cfg.loginTimeout)], function (j) {
            store.loggingIn = false;
            if (j && j.ok) {
                store.connected = true;
                store.hasClient = true;
                if (j.email)
                    store.email = j.email;
                store.refresh(true);
            } else {
                const e = j ? j.error : "No se pudo iniciar la conexión";
                store.error = e === "timeout" ? "No se completó la conexión" : e === "denied" ? "Cancelaste el permiso" : e;
                if (e === "no-client")
                    store.hasClient = false;
            }
        });
    }

    function logout() {
        run(["python3", script, "logout"], function () {
            store.connected = false;
            store.events = [];
            store.calendars = [];
            store.updated = 0;
            store.loadedMonth = "";
            store.error = "";
            store.email = "";
            store.saveCache();
        });
    }

    // ── Feriados ──
    property double holidaysUpdated: 0
    property double holidaysTried: 0

    function holidaysCover(year) {
        return holidayList.some(h => h.date.slice(0, 4) === String(year));
    }

    function ensureHolidays() {
        if (cfg.holidays === "" || holidaysBusy)
            return;
        const stale = Date.now() - holidaysUpdated > cfg.holidaysMaxAge * 86400000;
        const missing = !holidaysCover(selected.getFullYear());
        // Si Google no la tiene, no se insiste más de una vez por hora
        if ((stale || missing) && Date.now() - holidaysTried > 3600000)
            fetchHolidays();
    }

    property bool holidaysBusy: false

    function fetchHolidays() {
        holidaysBusy = true;
        holidaysTried = Date.now();
        run(["python3", script, "holidays", "--id", cfg.holidays], function (j) {
            store.holidaysBusy = false;
            if (j && j.ok) {
                store.holidayList = j.events;
                store.holidaysUpdated = j.updated;
                holidaysFile.setText(JSON.stringify({
                    version: 1,
                    id: store.cfg.holidays,
                    updated: j.updated,
                    events: j.events
                }));
            }
        });
    }

    // ── Cachés (abrir al instante y sin internet) ──
    FileView {
        id: cacheFile
        path: store.cfg.cache
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: holidaysFile
        path: store.cfg.holidaysCache
        blockLoading: true
        printErrors: false
    }

    function saveCache() {
        cacheFile.setText(JSON.stringify({
            version: 1,
            email: email,
            updated: updated,
            month: loadedMonth,
            from: loadedFrom,
            to: loadedTo,
            calendars: calendars,
            events: events
        }));
    }

    function loadCaches() {
        try {
            const c = JSON.parse(cacheFile.text());
            if (c.version === 1 && Array.isArray(c.events)) {
                events = c.events;
                calendars = c.calendars || [];
                updated = c.updated || 0;
                loadedMonth = c.month || "";
                loadedFrom = c.from || "";
                loadedTo = c.to || "";
                email = c.email || "";
            }
        } catch (e) {}
        try {
            const h = JSON.parse(holidaysFile.text());
            if (h.version === 1 && h.id === cfg.holidays && Array.isArray(h.events)) {
                holidayList = h.events;
                holidaysUpdated = h.updated || 0;
            }
        } catch (e) {}
    }

    // Actualización periódica (si calendar.refresh > 0)
    Timer {
        interval: Math.max(1, ST.SettingsStore.calendar.refresh) * 60000
        repeat: true
        running: ST.SettingsStore.calendar.refresh > 0
        onTriggered: store.refresh(false)
    }

    Component.onCompleted: {
        loadCaches();
        checkStatus();
        // Al iniciar la shell: una actualización (cuando status responda, si hay sesión)
        startTimer.start();
        ensureHolidays();
    }

    Timer {
        id: startTimer
        interval: 800
        onTriggered: store.refresh(true)
    }
}
