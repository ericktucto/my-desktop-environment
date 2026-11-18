import { loadLib, eq, done } from "./load.mjs";

const P = loadLib("services/tasks/Parse.js");
// Martes 17 nov 2026, 09:30
const now = new Date(2026, 10, 17, 9, 30);
const projects = [{ name: "Trabajo" }, { name: "Personal" }, { name: "Side project" }];
const templates = [{ name: "release" }];
const p = t => P.parse(t, { now, projects, templates });
const pick = (t, ...keys) => Object.fromEntries(keys.map(k => [k, p(t)[k]]));

// ── Fechas ──
eq("hoy", pick("pagar luz hoy", "title", "due"), { title: "pagar luz", due: "2026-11-17" });
eq("mañana", pick("Llamar a mamá mañana", "title", "due"), { title: "Llamar a mamá", due: "2026-11-18" });
eq("manana sin tilde", p("x manana").due, "2026-11-18");
eq("pasado mañana", pick("x pasado mañana", "title", "due"), { title: "x", due: "2026-11-19" });
eq("el viernes", pick("Deploy el viernes", "title", "due"), { title: "Deploy", due: "2026-11-20" });
eq("viernes a secas", p("Deploy viernes").due, "2026-11-20");
eq("hoy es martes: martes = hoy", p("x martes").due, "2026-11-17");
eq("próximo martes = +7", p("x próximo martes").due, "2026-11-24");
eq("lunes", p("x el lunes").due, "2026-11-23");
eq("miércoles con tilde", p("x miércoles").due, "2026-11-18");
eq("miercoles sin tilde", p("x miercoles").due, "2026-11-18");
eq("sábado", p("x sábado").due, "2026-11-21");
eq("para el viernes", pick("Informe para el viernes", "title", "due"), { title: "Informe", due: "2026-11-20" });
eq("en 3 días", pick("x en 3 días", "title", "due"), { title: "x", due: "2026-11-20" });
eq("en 1 día", p("x en 1 dia").due, "2026-11-18");
eq("en 2 semanas", p("x en 2 semanas").due, "2026-12-01");
eq("en un mes", p("x en un mes").due, "2026-12-17");
eq("en un año", p("x en un año").due, "2027-11-17");
eq("15 dic", pick("x 15 dic", "title", "due"), { title: "x", due: "2026-12-15" });
eq("15 de diciembre", p("x 15 de diciembre").due, "2026-12-15");
eq("fecha pasada → año siguiente", p("x 3 mar").due, "2027-03-03");
eq("hoy mismo día-mes", p("x 17 nov").due, "2026-11-17");
eq("con año", p("x 3 de marzo de 2028").due, "2028-03-03");
eq("15/12", p("x 15/12").due, "2026-12-15");
eq("15/12/2027", p("x 15/12/2027").due, "2027-12-15");
eq("15/12/27", p("x 15/12/27").due, "2027-12-15");
eq("ISO", p("x 2026-12-25").due, "2026-12-25");
eq("30 feb no existe", pick("x 30 feb", "due", "title"), { due: "", title: "x 30 feb" });
eq("setiembre", p("x 5 set").due, "2027-09-05");
eq("mayúsculas", p("x MAÑANA").due, "2026-11-18");

// ── Horas ──
eq("9am", pick("x mañana 9am", "due", "dueTime", "title"), { due: "2026-11-18", dueTime: "09:00", title: "x" });
eq("9:30", p("x mañana 9:30").dueTime, "09:30");
eq("2pm", p("x mañana 2pm").dueTime, "14:00");
eq("12am", p("x mañana 12am").dueTime, "00:00");
eq("12pm", p("x mañana 12pm").dueTime, "12:00");
eq("9:30 pm", p("x mañana 9:30 pm").dueTime, "21:30");
eq("14:05", p("x mañana 14:05").dueTime, "14:05");
eq("a las 9", pick("Reunión mañana a las 9", "dueTime", "title"), { dueTime: "09:00", title: "Reunión" });
eq("a las 9:30", p("x a las 9:30 mañana").dueTime, "09:30");
eq("a las 5pm", p("x mañana a las 5pm").dueTime, "17:00");
eq("9 a secas no es hora", pick("Leer capítulo 9", "dueTime", "due", "title"), { dueTime: "", due: "", title: "Leer capítulo 9" });
eq("25:00 no es hora", p("x 25:00").dueTime, "");
eq("solo hora futura → hoy", pick("x 6pm", "due", "dueTime"), { due: "2026-11-17", dueTime: "18:00" });
eq("solo hora pasada → mañana", pick("x 8am", "due", "dueTime"), { due: "2026-11-18", dueTime: "08:00" });

// ── Inicio ──
eq("desde el lunes", pick("Preparar demo desde el lunes", "start", "due", "title"), { start: "2026-11-23", due: "", title: "Preparar demo" });
eq("desde mañana hasta viernes", pick("x desde mañana el viernes", "start", "due"), { start: "2026-11-18", due: "2026-11-20" });
eq("desde 20 dic", p("x desde el 20 dic").start, "2026-12-20");

// ── Estimación ──
eq("30m", pick("x 30m", "estimate", "title"), { estimate: 30, title: "x" });
eq("45 min", p("x 45 min").estimate, 45);
eq("2h", p("x 2h").estimate, 120);
eq("1h30", p("x 1h30").estimate, 90);
eq("1.5h", p("x 1.5h").estimate, 90);
eq("9am no es estimación", pick("x mañana 9am", "estimate"), { estimate: 0 });
eq("5 metros no es estimación", pick("comprar 5 metros", "estimate", "title"), { estimate: 0, title: "comprar 5 metros" });

// ── Prioridad, proyecto y etiquetas ──
eq("p1", pick("x p1", "priority", "title"), { priority: 1, title: "x" });
eq("P2 mayúscula", p("x P2").priority, 2);
eq("p5 no existe", pick("x p5", "priority", "title"), { priority: 4, title: "x p5" });
eq("proyecto existente", pick("x +trabajo", "project", "newProject", "title"), { project: "Trabajo", newProject: false, title: "x" });
eq("proyecto sin acento ni mayúsculas", p("x +PERSONAL").project, "Personal");
eq("proyecto por prefijo único", pick("x +side", "project", "newProject"), { project: "Side project", newProject: false });
eq("proyecto nuevo", pick("x +casa", "project", "newProject"), { project: "casa", newProject: true });
eq("proyecto entre comillas", pick('x +"Side project"', "project", "newProject"), { project: "Side project", newProject: false });
eq("etiquetas", pick("x #bug #Infra #bug", "tags", "title"), { tags: ["bug", "infra"], title: "x" });
eq("#412 no es etiqueta", pick("Revisar PR #412", "tags", "title"), { tags: [], title: "Revisar PR #412" });
eq("C# no es etiqueta", pick("aprender C# hoy", "tags", "title"), { tags: [], title: "aprender C#" });
eq("etiqueta con tilde", p("x #diseño").tags, ["diseño"]);

// ── Repetición ──
eq("cada lunes", pick("Standup cada lunes", "repeat", "due", "title"), { repeat: { freq: "weekly", interval: 1, days: [1], from: "due" }, due: "2026-11-23", title: "Standup" });
eq("cada lunes y jueves", p("x cada lunes y jueves").repeat.days, [1, 4]);
eq("cada lunes, miércoles y viernes", p("x cada lunes, miércoles y viernes").repeat.days, [1, 3, 5]);
eq("todos los lunes", p("x todos los lunes").repeat.days, [1]);
eq("cada día", pick("x cada día", "repeat", "due"), { repeat: { freq: "daily", interval: 1, days: [], from: "due" }, due: "2026-11-17" });
eq("todos los días", p("x todos los días").repeat.freq, "daily");
eq("cada 3 días", p("x cada 3 días").repeat, { freq: "daily", interval: 3, days: [], from: "due" });
eq("cada semana", p("x cada semana").repeat.freq, "weekly");
eq("cada 2 semanas", p("x cada 2 semanas").repeat, { freq: "weekly", interval: 2, days: [], from: "due" });
eq("cada mes", p("x cada mes").repeat.freq, "monthly");
eq("cada 2 meses", p("x cada 2 meses").repeat.interval, 2);
eq("cada año", p("x cada año").repeat.freq, "yearly");
eq("cada día laborable", p("x cada día laborable").repeat.freq, "weekdays");
eq("mensual", p("pagar luz mensual").repeat.freq, "monthly");
eq("repetición con fecha", pick("x cada lunes desde mañana", "due", "start"), { due: "2026-11-23", start: "2026-11-18" });
eq("repetición no es fecha", pick("x cada viernes", "due"), { due: "2026-11-20" });
eq("laborable un domingo → lunes", P.parse("x cada día laborable", { now: new Date(2026, 10, 22, 10) }).due, "2026-11-23");

// ── URLs ──
const url = "https://github.com/acme/api/pull/412";
eq("url sola", pick(url, "title", "links"), { title: "", links: [url] });
eq("url con texto", pick(`Revisar PR ${url} mañana`, "title", "links", "due"), { title: "Revisar PR", links: [url], due: "2026-11-18" });
eq("+ y # dentro de una url no cuentan", pick("x https://a.com/b?c=+d#frag p1", "tags", "project", "priority", "links"), { tags: [], project: null, priority: 1, links: ["https://a.com/b?c=+d#frag"] });
eq("url con punto final", p("ver https://a.com/x.").links, ["https://a.com/x"]);
eq("dos urls", p("x https://a.com https://b.com").links.length, 2);
eq("fecha dentro de url no cuenta", pick("x https://a.com/mañana/viernes", "due"), { due: "" });

// ── Plantillas ──
eq("plantilla", pick("/release v1.4", "template", "title"), { template: "release", title: "v1.4" });
eq("plantilla desconocida queda en el título", pick("/nada x", "template", "title"), { template: "", title: "/nada x" });
eq("ruta no es plantilla", pick("ver /etc/hosts", "template", "title"), { template: "", title: "ver /etc/hosts" });

// ── Todo junto ──
const full = p(`Revisar PR mañana 9am +trabajo #review p1 30m ${url}`);
eq("frase completa", [full.title, full.due, full.dueTime, full.project, full.tags, full.priority, full.estimate, full.links], ["Revisar PR", "2026-11-18", "09:00", "Trabajo", ["review"], 1, 30, [url]]);
eq("título vacío", p("mañana p1").title, "");
eq("sin nada", pick("Comprar pan", "title", "due", "priority", "project", "tags"), { title: "Comprar pan", due: "", priority: 4, project: null, tags: [] });
eq("vacío", p("").title, "");
eq("solo espacios", p("   ").title, "");
eq("palabra que parece fecha pero no", p("Marzo es el mes").due, "");
eq("mar como mes sin día", p("ver mar").due, "");

// ── Spans y chips ──
const sp = p("Revisar mañana 9am +trabajo p1");
eq("spans ordenados", sp.spans.map(s => [s.kind, s.text]), [["date", "mañana"], ["time", "9am"], ["project", "+trabajo"], ["priority", "p1"]]);
eq("spans con posiciones", sp.spans.every(s => "Revisar mañana 9am +trabajo p1".slice(s.start, s.end) === s.text), true);
const ch = P.chips(sp, { now });
eq("chips", ch.map(c => [c.kind, c.label]), [["date", "mañana 09:00"], ["priority", "p1"], ["project", "+Trabajo"]]);
eq("quitar chip de fecha quita fecha y hora", P.removeSpans("Revisar mañana 9am +trabajo p1", ch[0].spans), "Revisar +trabajo p1");
eq("quitar chip de prioridad", P.removeSpans("Revisar mañana 9am +trabajo p1", ch[1].spans), "Revisar mañana 9am +trabajo");
eq("chip de proyecto nuevo", P.chips(p("x +casa"), { now }).map(c => c.label), ["+casa (nuevo)"]);
eq("chip de etiquetas", P.chips(p("x #a #b"), { now }).map(c => [c.label, c.spans.length]), [["#a", 1], ["#b", 1]]);
eq("chip de link", P.chips(p(url), { now }).map(c => c.label), ["acme/api#412"]);
eq("chip de repetición", P.chips(p("x cada lunes"), { now }).map(c => c.label), ["lun", "cada lunes"]);
eq("chip de inicio", P.chips(p("x desde el lunes"), { now }).map(c => c.label), ["desde lun"]);
eq("repeatLabel", [P.repeatLabel({ freq: "weekly", interval: 1, days: [1, 4] }), P.repeatLabel({ freq: "weekdays", interval: 1, days: [] }), P.repeatLabel({ freq: "monthly", interval: 2, days: [] })], ["cada lunes y jueves", "cada día laborable", "cada 2 meses"]);
eq("fecha vencida no dice vencida en chip", P.chips(P.parse("x 8am", { now }), { now })[0].label, "mañana 08:00");

done();
