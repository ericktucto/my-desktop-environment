import { loadLib, eq, done } from "./load.mjs";

const M = loadLib("services/tasks/Model.js");
const V = loadLib("services/tasks/Views.js");
// Martes 17 nov 2026, 09:30
const NOW = new Date(2026, 10, 17, 9, 30);
const ms = (d, h = 12) => new Date(2026, 10, d, h).getTime();
let n = 0;
const T = f => M.normTask(Object.assign({ id: "t" + ++n, title: "t" + n, order: n * 1000, created: n }, f), NOW.getTime());

const projects = [{ id: "p_w", name: "Trabajo", color: "#4285f4", order: 1000, archived: false }, { id: "p_h", name: "Personal", color: "#34a853", order: 2000, archived: false }];
const tasks = [
    T({ id: "vieja", title: "Responder a QA", due: "2026-11-16", priority: 1, project: "p_w" }),
    T({ id: "hoyhora", title: "Revisar PR", due: "2026-11-17", dueTime: "10:00", priority: 2, project: "p_w", tags: ["review"], estimate: 30 }),
    T({ id: "hoypasada", title: "Standup", due: "2026-11-17", dueTime: "08:00" }),
    T({ id: "hoy", title: "Pagar luz", due: "2026-11-17", project: "p_h", estimate: 90 }),
    T({ id: "curso", title: "Refactor login", status: "doing", tags: ["bug"] }),
    T({ id: "bloq", title: "Deploy", status: "blocked", blockedReason: "credenciales", due: "2026-11-18", tags: ["infra"] }),
    T({ id: "futura", title: "Empieza el jueves", due: "2026-11-17", start: "2026-11-19" }),
    T({ id: "man", title: "Mañana", due: "2026-11-18", dueTime: "09:00", project: "p_h" }),
    T({ id: "lejos", title: "Dentro de 10 días", due: "2026-11-27" }),
    T({ id: "sinfecha", title: "Algún día" }),
    T({ id: "hecha1", title: "Hecha hoy", status: "done", completed: ms(17, 8), project: "p_w" }),
    T({ id: "hecha2", title: "Hecha ayer", status: "done", completed: ms(16) }),
    T({ id: "canc", title: "Cancelada", status: "cancelled", completed: ms(16, 15) }),
];
const v = V.compute(tasks, projects, { now: NOW, sort: "due", upcomingDays: 7 });
const ids = l => l.map(t => t.id);

eq("vencidas (por hora)", ids(v.overdue), ["vieja", "hoypasada"]);
eq("hoy", ids(v.today), ["hoyhora", "hoy", "curso"]);
eq("próximos agrupados", v.upcoming.map(g => [g.key, g.label, ids(g.tasks)]), [["2026-11-18", "Mañana", ["man", "bloq"]]]);
eq("próximos excluye a 10 días", v.upcoming.some(g => g.key === "2026-11-27"), false);
eq("bandeja", ids(v.inbox), ["hoypasada", "futura", "bloq", "lejos", "curso", "sinfecha"]);
eq("start futuro no está en Hoy", ids(v.today).includes("futura") || ids(v.overdue).includes("futura"), false);
eq("hechas: grupos por día", v.done.map(g => [g.key, g.label, ids(g.tasks)]), [["2026-11-17", "Hoy", ["hecha1"]], ["2026-11-16", "Ayer", ["canc", "hecha2"]]]);
eq("tablero", [ids(v.board.todo).length, ids(v.board.doing), ids(v.board.blocked), ids(v.board.done)], [8, ["curso"], ["bloq"], ["hecha1"]]);
eq("por proyecto", ids(v.byProject.p_w), ["vieja", "hoyhora"]);
eq("por etiqueta", ids(v.byTag.bug), ["curso"]);
eq("etiquetas", v.tagNames, ["bug", "infra", "review"]);
eq("contadores", [v.counts.today, v.counts.overdue, v.counts.upcoming, v.counts.inbox], [5, 2, 2, 6]);
eq("contador proyecto", v.counts.projects, { p_w: 2, p_h: 2 });
eq("contador etiqueta", v.counts.tags, { review: 1, bug: 1, infra: 1 });
eq("estimación de hoy", v.todayEstimate, 120);

// orden manual
const vm = V.compute(tasks, projects, { now: NOW, sort: "manual", upcomingDays: 7 });
eq("manual por order", ids(vm.today), ["hoyhora", "hoy", "curso"]);
const vp = V.compute(tasks, projects, { now: NOW, sort: "priority", upcomingDays: 7 });
eq("prioridad", ids(vp.overdue), ["vieja", "hoypasada"]);
eq("prioridad hoy", ids(vp.today), ["hoyhora", "hoy", "curso"]);

// otro día: la de "mañana" ya es de hoy y lo de ayer sigue vencido
const v2 = V.compute(tasks, projects, { now: new Date(2026, 10, 18, 7, 0), sort: "due", upcomingDays: 7 });
eq("al día siguiente", [ids(v2.overdue), ids(v2.today)], [["vieja", "hoypasada", "hoyhora", "hoy", "futura"], ["man", "bloq", "curso"]]);

// listas por vista
const L = (view, q) => V.list(v, view, q, projects, NOW).map(g => [g.key, ids(g.tasks)]);
eq("list hoy", L("today"), [["overdue", ["vieja", "hoypasada"]], ["today", ["hoyhora", "hoy", "curso"]]]);
eq("list proyecto", L("project:p_h"), [["p_h", ["hoy", "man"]]]);
eq("list etiqueta", L("tag:infra"), [["infra", ["bloq"]]]);
eq("list inbox", L("inbox").length, 1);
eq("list proyecto vacío", L("project:nada"), []);
eq("list board", L("board").map(g => g[0]), ["todo", "doing", "blocked", "done"]);
eq("list con búsqueda", L("today", "revisar"), [["today", ["hoyhora"]]]);
eq("list sin resultados", L("today", "zzz"), []);

// búsqueda
const S = q => ids(V.search(tasks, projects, q, { now: NOW, sort: "due" }));
eq("buscar palabra", S("login"), ["curso"]);
eq("sin acentos", S("MANANA"), ["man"]);
eq("filtro proyecto", S("+trabajo"), ["vieja", "hoyhora", "hecha1"]);
eq("filtro proyecto parcial", S("+pers"), ["hoy", "man"]);
eq("filtro bandeja", S("+bandeja").includes("sinfecha"), true);
eq("filtro etiqueta", S("#bug"), ["curso"]);
eq("filtro prioridad", S("p1"), ["vieja"]);
eq("p1 o p2", S("p1 p2"), ["vieja", "hoyhora"]);
eq("vencidas", S("vencidas"), ["vieja", "hoypasada"]);
eq("en curso", S("en curso"), ["curso"]);
eq("combinados", S("+trabajo p2 revisar"), ["hoyhora"]);
eq("nota y subtareas", V.search([T({ id: "n1", title: "x", notes: "llamar a Pepe" }), T({ id: "n2", title: "y", subtasks: [{ title: "comprar leche" }] })], [], "leche", { now: NOW }).map(t => t.id), ["n2"]);
eq("cerradas al final", S("hecha").map(x => x), ["hecha1", "hecha2"]);
eq("vacío = todo", S("").length, tasks.length);
eq("parseQuery", V.parseQuery("Revisar +Trabajo #Bug p1 en curso vencidas"), { words: ["revisar"], projects: ["trabajo"], tags: ["bug"], priorities: [1], overdue: true, doing: true });

done();
