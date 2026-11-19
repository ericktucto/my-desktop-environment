pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../lock/" as LK
import "../../" as App
import "Dates.js" as Dates
import "Links.js" as Links
import "Model.js" as Model
import "Parse.js" as Parse
import "Reminders.js" as Reminders
import "Views.js" as Views

// Tareas: datos de ~/.config/stixshell/tasks.json, operaciones con deshacer, vistas e IPC.
// Los datos nunca se mutan: cada cambio crea objetos y arreglos nuevos, así la pila de deshacer solo
// guarda referencias. La lógica pura vive en Model.js y Views.js (se prueban con node: tests/tasks).
// Los formatos y las funciones públicas están fijados en plan.md → "Contratos".
Singleton {
    id: store

    readonly property var cfg: App.Config.tasks

    // ── Datos ──
    property var projects: []
    property var tasks: []
    property var templates: []
    // true cuando tasks.json ya se leyó (o se creó)
    property bool ready: false
    // Texto si tasks.json está roto; mientras tanto no se guarda nada
    property string error: ""

    // ── Deshacer ──
    property var undoStack: []
    readonly property bool canUndo: undoStack.length > 0
    // Texto del último cambio ("Tarea completada"), para el aviso de abajo
    property string lastAction: ""

    // Tras cada cambio guardado en memoria
    signal changed
    // Tras un cambio hecho por el usuario (no al recargar el archivo ni al deshacer); para el aviso
    signal acted(string label)
    // IPC `open`: abre Productividad → Tareas en esa vista
    signal openRequested(string view)
    // Tarea que el panel debe abrir en el detalle apenas pueda (desde el calendario)
    property string pendingDetail: ""
    // IPC `quickadd` (Super+Shift+T): abre o cierra el quick add
    signal quickAddRequested

    // ── Vistas (se calculan una vez por cambio, el reloj las refresca cada minuto) ──
    readonly property date now: clock.date
    readonly property string todayKey: Dates.keyOf(now)
    readonly property string sortMode: ST.SettingsStore.tasks.sort
    readonly property var views: Views.compute(tasks, projects, {
        now: now,
        sort: sortMode,
        upcomingDays: cfg.upcomingDays
    })

    readonly property var overdue: views.overdue
    readonly property var today: views.today
    readonly property var upcoming: views.upcoming
    readonly property var inbox: views.inbox
    readonly property var done: views.done
    readonly property var board: views.board
    readonly property var counts: views.counts
    // Minutos estimados de lo que se ve en Hoy (vencidas y de hoy)
    readonly property int todayEstimate: views.todayEstimate
    readonly property var tagNames: views.tagNames
    // Proyectos sin archivar, en su orden
    // Colores para elegir en un proyecto
    readonly property var projectColors: Model.COLORS
    readonly property var activeProjects: projects.filter(p => !p.archived).sort(Model.byOrder)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Consultas ──
    function get(id) {
        return tasks.find(t => t.id === id) ?? archived.find(t => t.id === id) ?? null;
    }

    function project(id) {
        return projects.find(p => p.id === id) ?? null;
    }

    function projectName(id) {
        return project(id)?.name ?? "";
    }

    // Vista → grupos [{ key, label, tasks }] sin vacíos. `query` filtra dentro de la vista.
    // view: today | upcoming | inbox | board | done | project:<id> | tag:<nombre>
    function list(view, query) {
        const groups = Views.list(views, view, query ?? "", projects, now);
        // Hechas con una búsqueda: también mira el archivo
        if (view === "done" && (query ?? "").trim() !== "" && archived.length > 0) {
            const old = Views.list(Views.compute(archived, projects, {
                now: now,
                sort: sortMode,
                upcomingDays: cfg.upcomingDays
            }), "done", query, projects, now);
            return groups.concat(old).sort((a, b) => a.key < b.key ? 1 : (a.key > b.key ? -1 : 0));
        }
        return groups;
    }

    // Búsqueda global (todas las vistas): +proyecto, #etiqueta, p1–p4, vencidas, en curso y palabras
    function search(text) {
        return Views.search(tasks, projects, text ?? "", {
            now: now,
            sort: sortMode
        });
    }

    // URL → { kind, label } por expresiones regulares (sin red)
    function linkInfo(url) {
        return Links.linkInfo(url);
    }

    // ── Cambios ──
    // Aplica un cambio: guarda el estado anterior para deshacer, avisa y programa el guardado
    function commit(label, newTasks, newProjects) {
        const stack = undoStack.slice(-(cfg.undoDepth - 1));
        stack.push({
            label: label,
            tasks: tasks,
            projects: projects
        });
        undoStack = stack;
        tasks = newTasks;
        projects = newProjects;
        lastAction = label;
        changed();
        acted(label);
        save();
    }

    // Cambia una tarea con fn(tarea) → tarea nueva (o null para no hacer nada)
    function change(id, label, fn) {
        if (error !== "")
            return false;
        unarchive(id);
        const i = tasks.findIndex(t => t.id === id);
        if (i < 0)
            return false;
        const next = fn(tasks[i]);
        if (!next)
            return false;
        const arr = tasks.slice();
        arr[i] = next;
        commit(label, arr, projects);
        return true;
    }

    function touch(t, fields) {
        return Object.assign({}, t, fields, {
            updated: Date.now()
        });
    }

    // Crea una tarea con los campos dados (title es obligatorio) y devuelve su id ("" si no se pudo)
    function add(fields) {
        if (error !== "")
            return "";
        const t = Model.makeTask(fields ?? {}, Date.now(), tasks);
        if (t.title === "")
            return "";
        if (t.project && !project(t.project))
            t.project = null;
        commit("Tarea creada", tasks.concat([t]), projects);
        return t.id;
    }

    // ── Captura en lenguaje natural ──
    // Texto → lo que entendió (ver Parse.js): título, fechas, +proyecto, #etiquetas, p1…
    function parseText(text) {
        return Parse.parse(text ?? "", {
            now: now,
            projects: activeProjects,
            templates: templates
        });
    }

    // Chips de lo entendido: [{ id, kind, label, spans }]
    function chipsFor(parsed) {
        return Parse.chips(parsed, {
            now: now
        });
    }

    // Texto sin los tramos de un chip (su ×)
    function removeChip(text, chip) {
        return Parse.removeSpans(text, chip.spans);
    }

    // Crea una tarea desde una frase y devuelve su id ("" si no hay título). `extra` trae los valores por
    // defecto de donde se crea (due, project = id, tags); lo que diga la frase manda. Un +proyecto que
    // no existe se crea en el mismo cambio, así un solo "Deshacer" lo deshace todo.
    function addFromText(text, extra) {
        if (error !== "")
            return "";
        const r = parseText(text);
        const fields = Object.assign({}, extra ?? {});
        // /plantilla: sus valores van debajo de lo que diga la frase
        const tp = r.template !== "" ? templates.find(t => t.name === r.template) : null;
        if (tp)
            Object.assign(fields, Model.templateFields(tp));
        let newProjects = projects;
        if (r.due !== "") {
            fields.due = r.due;
            fields.dueTime = r.dueTime;
        }
        if (r.start !== "")
            fields.start = r.start;
        if (r.priority < 4)
            fields.priority = r.priority;
        if (r.estimate > 0)
            fields.estimate = r.estimate;
        if (r.repeat)
            fields.repeat = r.repeat;
        if (r.tags.length > 0)
            fields.tags = (fields.tags ?? []).concat(r.tags);
        if (r.links.length > 0)
            fields.links = r.links;
        if (r.project !== null) {
            const found = activeProjects.find(p => Views.norm(p.name) === Views.norm(r.project));
            if (found) {
                fields.project = found.id;
            } else {
                const np = Model.makeProject(r.project, "", projects);
                newProjects = projects.concat([np]);
                fields.project = np.id;
            }
        }
                const fallback = r.links.length > 0 ? Links.linkInfo(r.links[0]).label : "";
        fields.title = tp ? (r.title !== "" ? tp.title + " " + r.title : tp.title) : (r.title !== "" ? r.title : fallback);
        const t = Model.makeTask(fields, Date.now(), tasks);
        if (t.title === "")
            return "";
        commit("Tarea creada", tasks.concat([t]), newProjects);
        refreshLinks(t.id, false, r.title === "" ? fallback : "");
        return t.id;
    }

    // ── Links: título de la página y estado en GitHub (scripts/links.py) ──
    readonly property string linksScript: Quickshell.shellPath("scripts/links.py")

    // Cambio sin pasar por deshacer (datos que llegan de internet): guarda y avisa, nada más
    function quietChange(id, fn) {
        const i = tasks.findIndex(t => t.id === id);
        if (i < 0 || error !== "")
            return;
        const next = fn(tasks[i]);
        if (!next)
            return;
        const arr = tasks.slice();
        arr[i] = next;
        tasks = arr;
        changed();
        save();
    }

    // Suma tiempo trabajado con el temporizador (Pomodoro). Sin deshacer: no es una edición del usuario.
    function addFocus(id, minutes, pomodoros) {
        quietChange(id, t => Model.addFocus(t, minutes, pomodoros, Date.now()));
    }

    // Trae el título de los links que aún no lo tienen (`force`: de todos). `retitle`: si el título de la
    // tarea sigue siendo ese texto (era solo el link), se cambia por el título de la página.
    function refreshLinks(id, force, retitle) {
        const t = get(id);
        if (!t)
            return;
        t.links.forEach(l => {
            if (!force && l.title !== "")
                return;
            run(["python3", linksScript, "info", l.url], out => applyLinkInfo(id, l.url, out, retitle ?? ""));
        });
    }

    function applyLinkInfo(id, url, out, retitle) {
        let j;
        try {
            j = JSON.parse(out);
        } catch (e) {
            return;
        }
        // Token de GitHub inválido: se usó la API pública; se avisa una sola vez
        if (j.tokenInvalid && !tokenWarned) {
            tokenWarned = true;
            Quickshell.execDetached(["notify-send", "-a", "Tareas", "-i", "dialog-warning", "El token de GitHub no vale", "Se usa la API pública (solo repos públicos). Revisa ~/.config/stixshell/github-token"]);
        }
        // Sin internet no se anota nada (se vuelve a intentar); otros errores (límite de consultas, 404)
        // solo marcan la hora para no insistir antes de tiempo
        if (!j.ok && j.error === "offline")
            return;
        quietChange(id, t => {
            if (!t.links.some(l => l.url === url))
                return null;
            const patch = {
                links: t.links.map(l => l.url === url ? Object.assign({}, l, j.ok ? {
                    title: j.title !== "" ? j.title : l.title,
                    state: j.state !== "" ? j.state : l.state,
                    checked: Date.now()
                } : {
                    checked: Date.now()
                }) : l)
            };
            if (j.ok && retitle !== "" && t.title === retitle && j.title !== "")
                patch.title = j.title;
            return Object.assign({}, t, patch);
        });
    }

    property bool tokenWarned: false

    // Vuelve a pedir el estado de los PR e issues de GitHub de esas tareas (abiertas) si tiene más de
    // `linkMaxAge` minutos. Como mucho `linkRefreshMax` por vez: sin token GitHub deja 60 consultas por hora.
    function refreshStale(ids) {
        const limit = Date.now() - cfg.linkMaxAge * 60000;
        let left = cfg.linkRefreshMax;
        for (const id of ids) {
            const t = tasks.find(x => x.id === id);
            if (!t || t.status === "done" || t.status === "cancelled")
                continue;
            for (const l of t.links) {
                if (left <= 0)
                    return;
                if ((l.kind === "github-pr" || l.kind === "github-issue") && l.checked < limit) {
                    left--;
                    run(["python3", linksScript, "info", l.url], out => applyLinkInfo(id, l.url, out, ""));
                    // Evita pedirlo dos veces mientras llega la respuesta
                    quietChange(id, x => Object.assign({}, x, {
                            links: x.links.map(y => y.url === l.url ? Object.assign({}, y, {
                                    checked: Date.now()
                                }) : y)
                        }));
                }
            }
        }
    }

    // Una tarea en una línea para el IPC y la terminal: id · título · fecha · +proyecto
    function lineOf(t) {
        const p = projectName(t.project);
        return [t.id, t.title, Dates.relative(t.due, t.dueTime, now), p !== "" ? "+" + p : ""].join(" · ");
    }

    // ── Resumen de la mañana ──
    // Al primer momento desde las 8:00 con la pantalla desbloqueada (al arrancar la shell o al desbloquear),
    // una vez por día: "Hoy: 5 tareas (2 vencidas) · 3 h 15 m" con el botón Abrir. La fecha del último se
    // guarda en settings.json (tasks.lastSummary); sin tareas para hoy no avisa y lo intenta más tarde.
    readonly property bool unlocked: !LK.LockStore.locked
    onUnlockedChanged: maybeSummary()

    function summaryText() {
        const c = counts;
        const n = c.today;
        let t = "Hoy: " + n + (n === 1 ? " tarea" : " tareas");
        if (c.overdue > 0)
            t += " (" + c.overdue + (c.overdue === 1 ? " vencida" : " vencidas") + ")";
        const est = Dates.formatMinutes(todayEstimate);
        return est !== "" ? t + " · " + est : t;
    }

    function maybeSummary() {
        if (!ready || error !== "" || !unlocked || now.getHours() < cfg.summaryHour)
            return;
        if (ST.SettingsStore.tasks.lastSummary === todayKey || counts.today === 0)
            return;
        ST.SettingsStore.tasks.lastSummary = todayKey;
        run(["notify-send", "-a", "Tareas", "-i", "checkbox", "-t", "10000", "-A", "open=Abrir", "Buenos días", summaryText()], out => {
            if (out.trim() === "open")
                openRequested("today");
        });
    }

    // ── Recordatorios ──
    // Cada minuto (y al leer el archivo, al arrancar o al despertar) se revisan los avisos pendientes.
    // Los que se perdieron en las últimas 12 h salen una vez con "(atrasado)"; los más viejos solo se
    // marcan como avisados. Marcar un aviso no entra en deshacer.
    onNowChanged: {
        checkReminders();
        maybeSummary();
        if (archiveDay !== todayKey)
            archiveOld();
    }

    function checkReminders() {
        if (!ready || error !== "")
            return;
        const nowMs = Date.now();
        const list = Reminders.due(tasks, nowMs);
        if (list.length === 0)
            return;
        const byTask = {};
        list.forEach(x => (byTask[x.task.id] = byTask[x.task.id] ?? []).push(x.reminder.id));
        for (const id in byTask)
            quietChange(id, t => Reminders.markFired(t, byTask[id], nowMs));
        // Una notificación por tarea; con muchas juntas, un solo resumen
        const shown = [];
        list.filter(x => !x.stale).forEach(x => {
            const f = shown.find(y => y.task.id === x.task.id);
            if (!f)
                shown.push(x);
            else if (x.ms > f.ms)
                shown[shown.indexOf(f)] = x;
        });
        if (shown.length > 5) {
            run(["notify-send", "-a", "Tareas", "-i", "checkbox", "-t", "0", "-A", "open=Abrir", shown.length + " recordatorios atrasados", shown.slice(0, 5).map(x => x.task.title).join(" · ") + " …"], out => {
                if (out.trim() === "open")
                    openRequested("today");
            });
            return;
        }
        shown.forEach(x => notifyReminder(x.task, x.late));
    }

    // El aviso: Hecha · Posponer 10 min · Mañana
    function notifyReminder(t, late) {
        const p = projectName(t.project);
        const when = t.dueTime !== "" ? "Vence " + Dates.relative(t.due, t.dueTime, now).replace(/^vencida /, "") : "Recordatorio";
        const body = (late ? "(atrasado) " : "") + when + (p !== "" ? " · +" + p : "");
        run(["notify-send", "-a", "Tareas", "-i", "checkbox", "-u", "normal", "-t", "30000", "-A", "done=Hecha", "-A", "snooze=Posponer 10 min", "-A", "tomorrow=Mañana", t.title, body], out => {
            const a = out.trim();
            if (a === "done")
                complete(t.id);
            else if (a === "snooze")
                snooze(t.id, 10);
            else if (a === "tomorrow")
                tomorrow(t.id);
        });
    }

    // Vuelve a avisar dentro de `minutes`
    function snooze(id, minutes) {
        return change(id, "Recordatorio pospuesto", t => Reminders.snooze(t, minutes, Date.now()));
    }

    // Pasa la fecha límite a mañana (con la misma hora) y reprograma los avisos
    function tomorrow(id) {
        const t = get(id);
        if (!t)
            return false;
        return change(id, "Tarea movida a mañana", x => Model.applyChanges(x, {
            due: Dates.addDays(todayKey, 1)
        }, Date.now()));
    }

    // ── Archivo: lo hecho hace más de `archiveDays` días pasa a tasks-archive.json ──
    // Al arrancar y una vez al día. La búsqueda de Hechas lo incluye; si se toca una tarea archivada
    // (reabrirla, editarla) vuelve a tasks.json.
    property var archived: []
    property bool archiveReady: false
    property string archiveDay: ""

    function loadArchive(text) {
        let list = [];
        try {
            const j = JSON.parse(text);
            list = (Array.isArray(j.tasks) ? j.tasks : []).filter(t => t && typeof t === "object").map(t => Model.normTask(t, Date.now()));
        } catch (e) {
            // Archivo roto: no se toca (no se pisa) y no se archiva más hasta arreglarlo
            archiveBroken = true;
            return;
        }
        archived = list;
        archiveReady = true;
        archiveOld();
    }
    property bool archiveBroken: false

    function writeArchive(list) {
        archived = list;
        archiveSelfWrite.restart();
        archiveFile.setText(JSON.stringify({
            version: Model.VERSION,
            tasks: list
        }, null, 2));
    }

    function archiveOld() {
        if (!ready || !archiveReady || archiveBroken || error !== "")
            return 0;
        archiveDay = todayKey;
        const limit = Date.now() - cfg.archiveDays * 86400000;
        const old = tasks.filter(t => (t.status === "done" || t.status === "cancelled") && t.completed > 0 && t.completed < limit);
        if (old.length === 0)
            return 0;
        // Primero el archivo y después tasks.json: si algo falla, quedan repetidas (se limpian al leer), no perdidas
        const have = new Set(archived.map(t => t.id));
        writeArchive(archived.concat(old.filter(t => !have.has(t.id))));
        const ids = new Set(old.map(t => t.id));
        tasks = tasks.filter(t => !ids.has(t.id));
        undoStack = [];
        changed();
        save();
        return old.length;
    }

    // Una tarea archivada vuelve a tasks.json (para reabrirla o editarla)
    function unarchive(id) {
        const t = archived.find(x => x.id === id);
        if (!t || archiveBroken || tasks.some(x => x.id === id))
            return false;
        writeArchive(archived.filter(x => x.id !== id));
        tasks = tasks.concat([t]);
        changed();
        save();
        return true;
    }

    Timer {
        id: archiveSelfWrite
        interval: 500
    }

    FileView {
        id: archiveFile
        path: store.cfg.archive
        printErrors: false
        onLoaded: store.loadArchive(text())
        // Sin archivo: no hay nada archivado todavía
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                store.archived = [];
                store.archiveReady = true;
                store.archiveOld();
            }
        }
    }

    // ── Plantillas ──
    // Guardar una tarea como plantilla (se pide por su nombre: "/release" en el quick add)
    function saveTemplate(id) {
        const t = get(id);
        if (!t || error !== "")
            return "";
        const tp = Model.makeTemplate(t, templates);
        templates = templates.concat([tp]);
        lastAction = "Plantilla /" + tp.name + " guardada";
        changed();
        acted(lastAction);
        save();
        return tp.name;
    }

    function removeTemplate(name) {
        if (!templates.some(t => t.name === name))
            return false;
        templates = templates.filter(t => t.name !== name);
        lastAction = "Plantilla /" + name + " eliminada";
        changed();
        acted(lastAction);
        save();
        return true;
    }

    // Tarea nueva desde una plantilla; `title` se agrega al título de la plantilla si no está vacío
    function applyTemplate(name, title) {
        if (!templates.some(t => t.name === name))
            return "";
        return addFromText("/" + name + (title ? " " + title : ""), {});
    }

    // ── Standup ──
    // Markdown con lo de ayer, lo de hoy y lo bloqueado (ver Views.standup)
    function standup() {
        return Views.standup(tasks, now);
    }

    // Lo copia al portapapeles y avisa
    function copyStandup() {
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "_", standup()]);
        Quickshell.execDetached(["notify-send", "-a", "Tareas", "-i", "checkbox", "-t", "3000", "Standup copiado", "Pégalo en el daily"]);
    }

    // Dónde cae una tarea nueva, para el aviso: "Hoy", "mañana", un proyecto o la Bandeja
    function whereIs(t) {
        const p = projectName(t.project);
        if (t.due === todayKey)
            return "Hoy";
        if (t.due !== "")
            return Dates.relative(t.due, t.dueTime, now);
        return p !== "" ? p : "Bandeja";
    }

    // Aviso "Tarea creada en Hoy" con el botón Deshacer (para el quick add, que cierra la isla)
    function notifyCreated(id) {
        const t = get(id);
        if (!t)
            return;
        run(["notify-send", "-a", "Tareas", "-i", "checkbox", "-t", "6000", "-A", "undo=Deshacer", "Tarea creada en " + whereIs(t), t.title], out => {
            if (out.trim() === "undo")
                undoCreated(id);
        });
    }

    // Deshace la creación de `id`: con "Deshacer" si fue lo último; si no, la borra
    function undoCreated(id) {
        if (!get(id))
            return;
        if (undoStack.length > 0 && undoStack[undoStack.length - 1].label === "Tarea creada")
            undo();
        else
            remove(id, "this");
    }

    function run(cmd, done) {
        const p = runner.createObject(store, {
            command: cmd,
            done: done
        });
        p.running = true;
    }

    Component {
        id: runner
        Process {
            id: rp
            property var done
            stdout: StdioCollector {
                onStreamFinished: {
                    if (rp.done)
                        rp.done(text);
                    rp.destroy();
                }
            }
        }
    }

    // Abre una tarea en el detalle de la pestaña Tareas (la isla pasa a esa pestaña)
    function openTask(id) {
        if (!get(id))
            return;
        pendingDetail = id;
        openRequested("");
    }

    // Cambia campos de una tarea (título, notas, prioridad, proyecto, fechas, etiquetas…)
    function update(id, changes) {
        return change(id, "Tarea editada", t => Model.applyChanges(t, changes, Date.now()));
    }

    function setStatus(id, status, reason) {
        // Completar una tarea que se repite: queda una copia hecha y la original pasa a su próxima fecha
        if (status === "done") {
            const r = get(id);
            if (r && r.repeat && completeRepeating(r))
                return true;
        }
        const labels = {
            todo: "Tarea reabierta",
            doing: "Tarea en curso",
            blocked: "Tarea bloqueada",
            done: "Tarea completada",
            cancelled: "Tarea cancelada"
        };
        return change(id, labels[status] ?? "Estado cambiado", t => t.status === status && (status !== "blocked" || (reason ?? "") === t.blockedReason) ? null : Model.applyStatus(t, status, reason ?? "", Date.now()));
    }

    function complete(id) {
        return setStatus(id, "done", "");
    }

    function reopen(id) {
        return setStatus(id, "todo", "");
    }

    // Próxima fecha límite de una tarea que se repite (hoy, según su regla); "" si no se repite
    function nextDate(t) {
        return Dates.nextOccurrence(t, Date.now());
    }

    function completeRepeating(t) {
        const nowMs = Date.now();
        const next = nextDate(t);
        if (next === "" || error !== "")
            return false;
        const res = Model.completeRepeating(t, next, nowMs, Model.uniqueId("t_", tasks));
        const arr = tasks.map(x => x.id === t.id ? res.next : x).concat([res.copy]);
        commit("Tarea completada · próxima " + Dates.relative(next, "", now), arr, projects);
        return true;
    }

    // mode: "this" | "all". Una tarea que se repite con "this" salta a su próxima fecha (sin hacerla);
    // con "all" (o si no se repite) se borra.
    function remove(id, mode) {
        const t = get(id);
        if (error !== "" || !t)
            return false;
        if (t.repeat && mode === "this") {
            const next = nextDate(t);
            if (next !== "") {
                change(id, "Repetición omitida · próxima " + Dates.relative(next, "", now), x => Model.skipRepeat(x, next, Date.now()));
                return true;
            }
        }
        commit("Tarea eliminada", tasks.filter(x => x.id !== id), projects);
        return true;
    }

    // Pone la tarea justo antes de `beforeId` ("" = al final) en el orden manual
    function move(id, beforeId) {
        if (error !== "")
            return false;
        const next = Model.moveTask(tasks, id, beforeId ?? "");
        if (next === tasks)
            return false;
        commit("Tarea movida", next, projects);
        return true;
    }

    // Lo mismo, pero justo después de `afterId`
    function moveAfter(id, afterId) {
        const sorted = tasks.slice().sort(Model.byOrder);
        const i = sorted.findIndex(t => t.id === afterId);
        if (i < 0)
            return false;
        let next = sorted[i + 1];
        if (next && next.id === id)
            next = sorted[i + 2];
        return move(id, next ? next.id : "");
    }

    // ── Subtareas ──
    function addSubtask(id, title) {
        const s = (title ?? "").trim();
        if (s === "")
            return false;
        return change(id, "Subtarea añadida", t => touch(t, {
            subtasks: t.subtasks.concat([
                {
                    id: Model.uniqueId("s_", t.subtasks),
                    title: s,
                    done: false
                }
            ])
        }));
    }

    function toggleSubtask(id, subId) {
        return change(id, "Subtarea cambiada", t => touch(t, {
            subtasks: t.subtasks.map(s => s.id === subId ? Object.assign({}, s, {
                    done: !s.done
                }) : s)
        }));
    }

    function removeSubtask(id, subId) {
        return change(id, "Subtarea eliminada", t => touch(t, {
            subtasks: t.subtasks.filter(s => s.id !== subId)
        }));
    }

    function moveSubtask(id, subId, index) {
        return change(id, "Subtarea movida", t => touch(t, {
            subtasks: Model.moveSubtask(t.subtasks, subId, index)
        }));
    }

    // ── Links ──
    // Acepta "github.com/a/b" sin esquema. false si no parece un link o ya está.
    function addLink(id, url) {
        const u = Links.normalizeUrl(url);
        if (u === "")
            return false;
        const ok = change(id, "Link añadido", t => t.links.some(l => l.url === u) ? null : touch(t, {
            links: t.links.concat([Links.makeLink(u)])
        }));
        if (ok)
            refreshLinks(id, false, "");
        return ok;
    }

    function removeLink(id, index) {
        return change(id, "Link eliminado", t => index < 0 || index >= t.links.length ? null : touch(t, {
            links: t.links.filter((l, i) => i !== index)
        }));
    }

    // ── Proyectos ──
    // Si ya hay uno con ese nombre (sin importar mayúsculas), devuelve el suyo
    function addProject(name, color) {
        const n = (name ?? "").trim();
        if (n === "" || error !== "")
            return "";
        const same = projects.find(p => !p.archived && Views.norm(p.name) === Views.norm(n));
        if (same)
            return same.id;
        const p = Model.makeProject(n, color ?? "", projects);
        commit("Proyecto creado", tasks, projects.concat([p]));
        return p.id;
    }

    // changes: name, color, icon, order, archived
    function updateProject(id, changes) {
        if (error !== "" || !project(id))
            return false;
        const keep = ["name", "color", "icon", "order", "archived"];
        const patch = {};
        keep.forEach(k => {
            if (changes[k] !== undefined)
                patch[k] = changes[k];
        });
        const next = projects.map((p, i) => p.id === id ? Model.normProject(Object.assign({}, p, patch), i) : p);
        commit("Proyecto editado", tasks, next);
        return true;
    }

    function archiveProject(id) {
        if (error !== "" || !project(id))
            return false;
        commit("Proyecto archivado", tasks, projects.map(p => p.id === id ? Object.assign({}, p, {
                archived: true
            }) : p));
        return true;
    }

    // ── Deshacer ──
    function undo() {
        if (error !== "" || undoStack.length === 0)
            return false;
        const stack = undoStack.slice();
        const last = stack.pop();
        undoStack = stack;
        tasks = last.tasks;
        projects = last.projects;
        lastAction = "";
        changed();
        save();
        return true;
    }

    // ── Archivo: carga y guardado ──
    function save() {
        if (ready && error === "")
            saveTimer.restart();
    }

    function flush() {
        saveTimer.stop();
        if (!ready || error !== "")
            return;
        selfWrite.restart();
        file.setText(JSON.stringify({
            version: Model.VERSION,
            projects: projects,
            tasks: tasks,
            templates: templates
        }, null, 2));
    }

    // text de tasks.json → datos, o el error con su línea. Un archivo vacío cuenta como sin tareas.
    function load(text) {
        if (text.trim() === "") {
            error = "";
            applyData({
                projects: [],
                tasks: [],
                templates: []
            });
            return;
        }
        let raw;
        try {
            raw = JSON.parse(text);
        } catch (e) {
            const line = Model.jsonErrorLine(text);
            error = "tasks.json tiene un error (línea " + (line > 0 ? line : 1) + ")";
            return;
        }
        const r = Model.normData(raw, Date.now());
        if (!r.ok) {
            error = "tasks.json: " + r.error;
            return;
        }
        error = "";
        applyData(r.data);
        backup();
    }

    function applyData(data) {
        saveTimer.stop();
        undoStack = [];
        lastAction = "";
        projects = data.projects;
        tasks = data.tasks;
        templates = data.templates;
        ready = true;
        changed();
        Qt.callLater(checkReminders);
        Qt.callLater(maybeSummary);
        Qt.callLater(archiveOld);
    }

    // Una copia diaria: tasks.json.bak se actualiza si tiene más de 24 h (antes de pisar nada)
    property string backupDay: ""
    function backup() {
        if (backupDay === todayKey)
            return;
        backupDay = todayKey;
        backupProc.command = ["sh", "-c", `f="$1"; b="$1.bak"; [ -s "$f" ] || exit 0; [ -n "$(find "$b" -mtime -1 2>/dev/null)" ] || cp -f "$f" "$b"`, "sh", cfg.file];
        backupProc.running = true;
    }

    Process {
        id: backupProc
    }

    // La carpeta debe existir antes de leer o escribir el archivo
    Process {
        running: true
        command: ["mkdir", "-p", cfg.file.substring(0, cfg.file.lastIndexOf("/"))]
        onExited: file.path = store.cfg.file
    }

    Timer {
        id: saveTimer
        interval: store.cfg.saveDelay
        onTriggered: store.flush()
    }

    // Ventana tras guardar durante la cual se ignoran los cambios del archivo (las escrituras propias
    // también lo disparan)
    Timer {
        id: selfWrite
        interval: 500
    }

    FileView {
        id: file
        // path se asigna cuando la carpeta ya existe
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onLoaded: store.load(text())
        onFileChanged: {
            if (!selfWrite.running)
                reload();
        }
        onSaved: selfWrite.restart()
        // Sin archivo: arranca vacío y se crea al primer cambio
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                store.error = "";
                store.applyData({
                    projects: [],
                    tasks: [],
                    templates: []
                });
            } else {
                store.error = "No se pudo leer tasks.json";
            }
        }
    }

    // Lo que esté pendiente se guarda al cerrar la shell
    Component.onDestruction: flush()

    // ── IPC ──
    IpcHandler {
        target: "stixshell@tasks"

        // Crea una tarea desde una frase (fechas, +proyecto, #etiqueta, p1, 30m, cada lunes…); devuelve su id
        function add(text: string): string {
            if (store.error !== "")
                return "error: " + store.error;
            const id = store.addFromText(text, {});
            return id !== "" ? id : "error: falta el título";
        }

        // Una tarea por línea: id · título · fecha · +proyecto
        function list(view: string): string {
            if (!store.ready)
                return "error: tasks.json aún no se leyó";
            const v = view === "" ? "today" : view;
            const lines = [];
            for (const g of store.list(v, ""))
                for (const t of g.tasks)
                    lines.push(store.lineOf(t));
            return lines.join("\n");
        }

        // Búsqueda global, con los mismos filtros que `/` en el panel: "+trabajo p1 vencidas revisar"
        function search(query: string): string {
            if (!store.ready)
                return "error: tasks.json aún no se leyó";
            return store.search(query).map(t => store.lineOf(t)).join("\n");
        }

        // Guarda una tarea como plantilla y devuelve su nombre
        function savetemplate(id: string): string {
            const n = store.saveTemplate(id);
            return n !== "" ? n : "error: no existe la tarea " + id;
        }

        // Una tarea nueva desde una plantilla: applytemplate release "v1.4"
        function applytemplate(name: string, title: string): string {
            const id = store.applyTemplate(name, title);
            return id !== "" ? id : "error: no existe la plantilla " + name;
        }

        // El Markdown del standup (ayer, hoy y bloqueado)
        function standup(): string {
            return store.standup();
        }

        // Abre una tarea en el detalle del panel
        function detail(id: string): string {
            if (!store.get(id))
                return "error: no existe la tarea " + id;
            store.openTask(id);
            return "ok";
        }

        // Abre o cierra el quick add (Super+Shift+T)
        function quickadd(): void {
            store.quickAddRequested();
        }

        // Pospone el aviso de una tarea `minutes` minutos
        function snooze(id: string, minutes: int): string {
            return store.snooze(id, minutes) ? "ok" : "error: no existe la tarea " + id;
        }

        // Mueve la fecha límite a mañana
        function tomorrow(id: string): string {
            return store.tomorrow(id) ? "ok" : "error: no existe la tarea " + id;
        }

        function done(id: string): string {
            if (!store.get(id))
                return "error: no existe la tarea " + id;
            return store.complete(id) ? "ok" : "error: ya estaba hecha";
        }

        function undo(): string {
            return store.undo() ? "ok" : "error: no hay nada que deshacer";
        }

        // Abre Productividad → Tareas en esa vista ("" = la última)
        function open(view: string): void {
            store.openRequested(view);
        }
    }
}
