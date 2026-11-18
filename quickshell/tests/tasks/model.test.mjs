import { loadLib, eq, done } from "./load.mjs";

const M = loadLib("services/tasks/Model.js");
const NOW = new Date(2026, 10, 17, 9, 30).getTime();

// normTask rellena y limpia
const t = M.normTask({ title: "  Hola  ", priority: 9, tags: ["#Bug", "bug", " Infra "], due: "2026-02-30", dueTime: "10:00", status: "raro" }, NOW);
eq("título", t.title, "Hola");
eq("prioridad inválida", t.priority, 4);
eq("etiquetas", t.tags, ["bug", "infra"]);
eq("fecha inválida", t.due, "");
eq("hora sin fecha", t.dueTime, "");
eq("estado inválido", t.status, "todo");
eq("created por defecto", t.created, NOW);
eq("subtareas vacías", t.subtasks, []);
eq("repeat null", t.repeat, null);
eq("id con prefijo", /^t_[0-9a-z]{6}$/.test(t.id), true);
eq("conserva campos extra", M.normTask({ title: "x", futuro: 5 }, NOW).futuro, 5);

// hecha sin completed → completed = ahora
eq("done pone completed", M.normTask({ title: "x", status: "done" }, NOW).completed, NOW);
eq("todo quita completed", M.normTask({ title: "x", status: "todo", completed: 5 }, NOW).completed, 0);
eq("blockedReason solo bloqueada", M.normTask({ title: "x", status: "todo", blockedReason: "r" }, NOW).blockedReason, "");

// repeat y subtareas
eq("repeat válido", M.normTask({ title: "x", repeat: { freq: "weekly", days: [1, 9], interval: 0 } }, NOW).repeat, { freq: "weekly", interval: 1, days: [1], from: "due" });
eq("repeat inválido", M.normTask({ title: "x", repeat: { freq: "cada rato" } }, NOW).repeat, null);
eq("subtareas limpias", M.normTask({ title: "x", subtasks: [{ id: "s_1", title: "a", done: true }, { title: " " }, { title: "b" }] }, NOW).subtasks.map(s => [s.title, s.done]), [["a", true], ["b", false]]);

// links: acepta strings y calcula el tipo
const lk = M.normTask({ title: "x", links: ["https://github.com/a/b/pull/1", { url: "https://x.com" }] }, NOW).links;
eq("links desde texto", lk.map(l => l.kind), ["github-pr", "url"]);

// normData
let r = M.normData({ version: 1, projects: [{ id: "p_a", name: "Trabajo", color: "#4285f4" }], tasks: [{ title: "a", project: "p_a" }, { title: "b", project: "p_fantasma" }, { title: "c" }] }, NOW);
eq("normData ok", r.ok, true);
eq("proyecto inexistente → Bandeja", r.data.tasks.map(x => x.project), ["p_a", null, null]);
eq("orden asignado", r.data.tasks.map(x => x.order), [1000, 2000, 3000]);
eq("versión futura", M.normData({ version: 2 }, NOW).ok, false);
eq("no es objeto", M.normData([], NOW).ok, false);
eq("vacío", M.normData({}, NOW).data.tasks, []);
r = M.normData({ tasks: [{ id: "t_x", title: "a" }, { id: "t_x", title: "b" }] }, NOW);
eq("ids repetidos", r.data.tasks[0].id !== r.data.tasks[1].id, true);

// makeTask
const base = [M.normTask({ id: "t_1", title: "a", order: 5000 }, NOW)];
const nt = M.makeTask({ title: "nueva", priority: 2, id: "t_1", completed: 99 }, NOW, base);
eq("makeTask id nuevo", nt.id !== "t_1", true);
eq("makeTask al final", nt.order, 6000);
eq("makeTask ignora completed", nt.completed, 0);
eq("makeTask prioridad", nt.priority, 2);

// applyStatus / applyChanges
const a = M.normTask({ id: "t_a", title: "a", created: 1 }, NOW);
const b = M.applyStatus(a, "blocked", "credenciales", NOW + 1);
eq("bloquear", [b.status, b.blockedReason, b.completed], ["blocked", "credenciales", 0]);
const d = M.applyStatus(b, "done", "", NOW + 2);
eq("completar", [d.status, d.blockedReason, d.completed], ["done", "", NOW + 2]);
eq("estado inválido no cambia", M.applyStatus(a, "xx", "", NOW), a);
const c = M.applyChanges(a, { title: "b", id: "otro", created: 5, due: "2026-11-20", dueTime: "09:00", status: "doing" }, NOW + 5);
eq("applyChanges", [c.id, c.created, c.title, c.due, c.dueTime, c.status, c.updated], ["t_a", 1, "b", "2026-11-20", "09:00", "doing", NOW + 5]);
eq("applyChanges no muta", a.title, "a");
const c2 = M.applyChanges(a, { status: "done" }, NOW + 9);
eq("applyChanges done", [c2.status, c2.completed], ["done", NOW + 9]);

// moveTask
const mk = (id, order) => M.normTask({ id, title: id, order, created: order }, NOW);
const list = [mk("a", 1000), mk("b", 2000), mk("c", 3000)];
const ord = ts => ts.slice().sort((x, y) => x.order - y.order).map(x => x.id).join("");
eq("mover c antes de a", ord(M.moveTask(list, "c", "a")), "cab");
eq("mover a antes de c", ord(M.moveTask(list, "a", "c")), "bac");
eq("mover a al final", ord(M.moveTask(list, "a", "")), "bca");
eq("mover c antes de b", ord(M.moveTask(list, "c", "b")), "acb");
eq("destino inexistente", M.moveTask(list, "a", "zzz"), list);
eq("id inexistente", M.moveTask(list, "zzz", "a"), list);
eq("no muta", list.map(x => x.order), [1000, 2000, 3000]);
// espacio agotado → renumera
let tight = [mk("a", 1000), mk("b", 1000.0004), mk("c", 3000)];
eq("renumera si no hay espacio", ord(M.moveTask(tight, "c", "b")), "acb");
eq("renumerado de 1000 en 1000", M.moveTask(tight, "c", "b").map(x => x.order).sort((x, y) => x - y), [1000, 2000, 3000]);
// 50 movimientos seguidos al mismo hueco no rompen el orden
let many = list;
for (let i = 0; i < 50; i++) many = M.moveTask(many, "c", "b");
eq("muchos movimientos", ord(many), "acb");

// subtareas
const subs = [{ id: "s1" }, { id: "s2" }, { id: "s3" }];
eq("moveSubtask", M.moveSubtask(subs, "s3", 0).map(s => s.id), ["s3", "s1", "s2"]);
eq("moveSubtask fuera de rango", M.moveSubtask(subs, "s1", 99).map(s => s.id), ["s2", "s3", "s1"]);

// proyectos
const p = M.makeProject("  Casa ", "", [{ id: "p_1", order: 3000 }]);
eq("makeProject", [p.name, p.order, /^#[0-9a-f]{6}$/.test(p.color), p.archived], ["Casa", 4000, true, false]);

// jsonErrorLine
eq("json válido", M.jsonErrorLine('{"a": [1, 2, {"b": null}], "c": "x\\"y"}'), 0);
eq("json coma final", M.jsonErrorLine('{\n  "a": 1,\n  "b": 2,\n}'), 4);
eq("json sin cerrar", M.jsonErrorLine('{\n  "a": [1, 2\n'), 3);
eq("json basura", M.jsonErrorLine('{\n  "a": 1\n  "b": 2\n}'), 3);
eq("json vacío", M.jsonErrorLine(""), 1);
eq("json texto suelto", M.jsonErrorLine("hola"), 1);
eq("json comillas simples", M.jsonErrorLine("{\n'a': 1}"), 2);

// completeRepeating / skipRepeat
const rt = M.normTask({ id: "t_r", title: "Pagar luz", due: "2026-11-17", dueTime: "10:00", start: "2026-11-15", repeat: { freq: "monthly" }, status: "doing", subtasks: [{ id: "s1", title: "a", done: true }, { id: "s2", title: "b", done: false }], reminders: [{ id: "r1", offset: 0, firedAt: 5 }, { id: "r2", at: "2026-11-17T09:45", firedAt: 6 }], notes: "n", order: 3000 }, NOW);
const cr = M.completeRepeating(rt, "2026-12-17", NOW + 10, "t_copy");
eq("copia: hecha y sin repetir", [cr.copy.id, cr.copy.status, cr.copy.completed, cr.copy.repeat, cr.copy.repeatOf, cr.copy.due], ["t_copy", "done", NOW + 10, null, "t_r", "2026-11-17"]);
eq("copia conserva subtareas marcadas", cr.copy.subtasks.map(s => s.done), [true, false]);
eq("copia sin avisos", cr.copy.reminders, []);
eq("siguiente: misma id, a todo", [cr.next.id, cr.next.status, cr.next.completed, cr.next.due, cr.next.dueTime], ["t_r", "todo", 0, "2026-12-17", "10:00"]);
eq("siguiente: subtareas desmarcadas", cr.next.subtasks.map(s => s.done), [false, false]);
eq("siguiente: inicio corrido", cr.next.start, "2026-12-15");
eq("siguiente: avisos reprogramados", cr.next.reminders.map(r => [r.id, r.firedAt]), [["r1", 0]]);
eq("siguiente: recuerda el día del mes", cr.next.repeat.day, 17);
eq("siguiente: sigue repitiendo", cr.next.repeat.freq, "monthly");
eq("no muta la original", [rt.status, rt.due, rt.subtasks[0].done], ["doing", "2026-11-17", true]);
eq("skipRepeat", [M.skipRepeat(rt, "2026-12-17", NOW).due, M.skipRepeat(rt, "2026-12-17", NOW).status], ["2026-12-17", "todo"]);
eq("normRepeat conserva day", M.normTask({ title: "x", repeat: { freq: "monthly", day: 31 } }, NOW).repeat.day, 31);
eq("normRepeat descarta day inválido", M.normTask({ title: "x", repeat: { freq: "monthly", day: 40 } }, NOW).repeat.day, undefined);

done();
