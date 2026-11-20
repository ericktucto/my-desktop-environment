import { loadLib, eq, done } from "./load.mjs";

const M = loadLib("services/tasks/Model.js");
const D = loadLib("services/tasks/Drop.js");
// Martes 17 nov 2026, 15:00
const NOW = new Date(2026, 10, 17, 15, 0);
const T = (id, f = {}) => M.normTask(Object.assign({ id, title: id, created: 1 }, f), NOW.getTime());

// dueToday: la hora se conserva solo si no pasó
eq("hora futura se conserva", D.dueToday(T("a", { due: "2026-11-16", dueTime: "18:00" }), NOW), { due: "2026-11-17", dueTime: "18:00" });
eq("hora pasada se quita", D.dueToday(T("a", { due: "2026-11-16", dueTime: "10:00" }), NOW), { due: "2026-11-17", dueTime: "" });
eq("sin hora", D.dueToday(T("a", { due: "2026-11-10" }), NOW), { due: "2026-11-17", dueTime: "" });

// listDrop en Hoy
const old = T("old", { due: "2026-11-16", dueTime: "10:00", start: "2026-11-01" });
const h1 = T("h1", { due: "2026-11-17" });
const h2 = T("h2", { due: "2026-11-17" });
const today = [{ key: "overdue", label: "Vencidas", tasks: [old] }, { key: "today", label: "Hoy", tasks: [h1, h2] }];
const man = { sort: "manual", now: NOW };
let r = D.listDrop("today", today, "old", "today", 1, man);
eq("vencida → hoy: fecha", r.changes, { due: "2026-11-17", dueTime: "" });
eq("vencida → hoy: lugar", [r.beforeId, r.afterId, r.label, r.noop], ["h2", "", "Movida a hoy", false]);
r = D.listDrop("today", today, "old", "today", 2, man);
eq("al final del grupo → afterId", [r.beforeId, r.afterId], ["", "h2"]);
eq("hoy → vencidas no vale", D.listDrop("today", today, "h1", "overdue", 0, man), null);
r = D.listDrop("today", today, "h1", "today", 1, man);
eq("misma sección, otro lugar", [r.noop, r.beforeId, r.afterId, r.changes], [false, "", "h2", {}]);
r = D.listDrop("today", today, "h1", "today", 0, man);
eq("misma sección, mismo lugar", r.noop, true);
r = D.listDrop("today", today, "h1", "today", 1, { sort: "due", now: NOW });
eq("sin orden manual: aviso", [r.noop, r.hint], [true, "Cambia a Orden manual para ordenar"]);
r = D.listDrop("today", today, "old", "today", 0, { sort: "due", now: NOW });
eq("sin orden manual cambia fecha pero no orden", [r.noop, r.beforeId, r.afterId, r.changes.due], [false, "", "", "2026-11-17"]);
eq("fecha de inicio queda antes: se conserva", r.changes.start, undefined);

// Próximos
const m1 = T("m1", { due: "2026-11-18", dueTime: "09:00" });
const late = T("late", { due: "2026-11-18", start: "2026-11-18" });
const up = [{ key: "2026-11-18", label: "Mañana", tasks: [m1, late] }, { key: "2026-11-19", label: "jue", tasks: [] }, { key: "2026-11-20", label: "vie", tasks: [] }];
r = D.listDrop("upcoming", up, "m1", "2026-11-19", 0, man);
eq("a un día vacío", [r.changes, r.beforeId, r.afterId, r.label], [{ due: "2026-11-19" }, "", "", "Movida a jue 19 nov"]);
r = D.listDrop("upcoming", up, "late", "2026-11-19", 0, man);
eq("a otro día", r.changes, { due: "2026-11-19" });
r = D.listDrop("upcoming", up, "late", "2026-11-18", 0, man);
r = D.listDrop("upcoming", [{ key: "2026-11-18", tasks: [m1] }, { key: "2026-11-17", tasks: [] }], "m1", "2026-11-17", 0, man);
eq("a hoy desde Próximos (fecha de un grupo)", r.changes.due, "2026-11-17");
// start posterior a la nueva fecha se quita
const s1 = T("s1", { due: "2026-11-20", start: "2026-11-19" });
r = D.listDrop("upcoming", [{ key: "2026-11-20", tasks: [s1] }, { key: "2026-11-18", tasks: [] }], "s1", "2026-11-18", 0, man);
eq("quita start", r.changes, { due: "2026-11-18", start: "" });

// Vistas de un solo grupo: no cambia de grupo
eq("proyecto: otro grupo no vale", D.listDrop("inbox", [{ key: "inbox", tasks: [h1] }], "h1", "otro", 0, man), null);
eq("id inexistente", D.listDrop("today", today, "zzz", "today", 0, man), null);

// sidebarDrop
const o = { now: NOW, projects: [{ id: "p_w", name: "Trabajo" }] };
const x = T("x", { due: "2026-11-20", project: "p_h", tags: ["bug"] });
eq("barra: hoy", D.sidebarDrop(x, "today", o), { kind: "update", changes: { due: "2026-11-17", dueTime: "" }, label: "Movida a hoy" });
eq("barra: hoy ya está", D.sidebarDrop(T("y", { due: "2026-11-17" }), "today", o), null);
eq("barra: próximos = mañana", D.sidebarDrop(x, "upcoming", o).changes, { due: "2026-11-18" });
eq("barra: próximos ya mañana", D.sidebarDrop(T("y", { due: "2026-11-18" }), "upcoming", o), null);
eq("barra: bandeja", D.sidebarDrop(x, "inbox", o).changes, { project: null });
eq("barra: bandeja sin proyecto", D.sidebarDrop(T("y"), "inbox", o), null);
eq("barra: proyecto", [D.sidebarDrop(x, "project:p_w", o).changes, D.sidebarDrop(x, "project:p_w", o).label], [{ project: "p_w" }, "Movida a +Trabajo"]);
eq("barra: mismo proyecto", D.sidebarDrop(x, "project:p_h", o), null);
eq("barra: etiqueta se agrega", D.sidebarDrop(x, "tag:infra", o).changes, { tags: ["bug", "infra"] });
eq("barra: etiqueta repetida", D.sidebarDrop(x, "tag:bug", o), null);
eq("barra: hechas", D.sidebarDrop(x, "done", o), { kind: "complete" });
eq("barra: hechas ya hecha", D.sidebarDrop(T("y", { status: "done" }), "done", o), null);
eq("barra: tablero no vale", D.sidebarDrop(x, "board", o), null);
eq("barra: start posterior", D.sidebarDrop(T("z", { due: "2026-11-25", start: "2026-11-24" }), "today", o).changes, { due: "2026-11-17", dueTime: "", start: "" });

// gapShift
eq("hueco: baja", [0, 1, 2, 3].map(i => D.gapShift(i, 0, 2, 50)), [0, -50, -50, 0]);
eq("hueco: sube", [0, 1, 2, 3].map(i => D.gapShift(i, 3, 1, 50)), [0, 50, 50, 0]);
eq("hueco: sin arrastre", D.gapShift(1, -1, -1, 50), 0);

// moveByOrder / moveTaskAfter
const pj = (id, order) => ({ id, name: id, order, created: order });
const ps = [pj("a", 1000), pj("b", 2000), pj("c", 3000)];
const ord = ts => ts.slice().sort((p, q) => p.order - q.order).map(p => p.id).join("");
eq("moveByOrder con proyectos", ord(M.moveByOrder(ps, "c", "a")), "cab");
eq("moveByOrder al final", ord(M.moveByOrder(ps, "a", "")), "bca");
const ts = [T("a", { order: 1000 }), T("b", { order: 2000 }), T("c", { order: 3000 })];
eq("moveTaskAfter", ord(M.moveTaskAfter(ts, "a", "b")), "bac");
eq("moveTaskAfter al final", ord(M.moveTaskAfter(ts, "a", "c")), "bca");
eq("moveTaskAfter ya está", ord(M.moveTaskAfter(ts, "b", "a")), "abc");
eq("moveTaskAfter a sí misma", M.moveTaskAfter(ts, "a", "a"), ts);

done();
