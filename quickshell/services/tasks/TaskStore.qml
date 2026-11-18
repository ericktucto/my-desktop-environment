pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../../" as App
import "Dates.js" as Dates
import "Links.js" as Links
import "Model.js" as Model
import "Parse.js" as Parse
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
        return tasks.find(t => t.id === id) ?? null;
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
        return Views.list(views, view, query ?? "", projects, now);
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
        // Solo un link: el título es su etiqueta corta (la fase 2.5 lo cambia por el título de la página)
        fields.title = r.title !== "" ? r.title : (r.links.length > 0 ? Links.linkInfo(r.links[0]).label : "");
        const t = Model.makeTask(fields, Date.now(), tasks);
        if (t.title === "")
            return "";
        commit("Tarea creada", tasks.concat([t]), newProjects);
        return t.id;
    }

    // Cambia campos de una tarea (título, notas, prioridad, proyecto, fechas, etiquetas…)
    function update(id, changes) {
        return change(id, "Tarea editada", t => Model.applyChanges(t, changes, Date.now()));
    }

    function setStatus(id, status, reason) {
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

    // mode: "this" | "all". Hasta la fase 3 (repetición) las dos borran la tarea.
    function remove(id, mode) {
        if (error !== "" || !get(id))
            return false;
        commit("Tarea eliminada", tasks.filter(t => t.id !== id), projects);
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
        return change(id, "Link añadido", t => t.links.some(l => l.url === u) ? null : touch(t, {
            links: t.links.concat([Links.makeLink(u)])
        }));
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
            for (const g of store.list(v, "")) {
                for (const t of g.tasks) {
                    const p = store.projectName(t.project);
                    lines.push([t.id, t.title, Dates.relative(t.due, t.dueTime, store.now), p !== "" ? "+" + p : ""].join(" · "));
                }
            }
            return lines.join("\n");
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
