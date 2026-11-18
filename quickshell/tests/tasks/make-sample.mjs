// Genera un tasks.json de ejemplo (30 tareas con fechas relativas a hoy) para probar la shell:
//   node tests/tasks/make-sample.mjs > ~/.config/stixshell/tasks.json
const day = (n = 0) => {
    const d = new Date();
    d.setDate(d.getDate() + n);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
};
const ago = (days, h = 12) => {
    const d = new Date();
    d.setDate(d.getDate() - days);
    d.setHours(h, 0, 0, 0);
    return d.getTime();
};
const now = Date.now();
const projects = [
    { id: "p_work01", name: "Trabajo", color: "#4285f4", icon: "", order: 1000, archived: false },
    { id: "p_home01", name: "Personal", color: "#34a853", icon: "", order: 2000, archived: false },
    { id: "p_side01", name: "Side project", color: "#a142f4", icon: "", order: 3000, archived: false },
];
let n = 0;
const t = f => ({ id: "t_s" + String(++n).padStart(5, "0"), title: "", notes: "", status: "todo", blockedReason: "", priority: 4, project: null, tags: [], due: "", dueTime: "", start: "", reminders: [], repeat: null, estimate: 0, subtasks: [], links: [], order: n * 1000, repeatOf: "", created: now - n * 3600e3, updated: now - n * 3600e3, completed: 0, ...f });
const sub = (title, done = false) => ({ id: "s_" + Math.random().toString(36).slice(2, 8), title, done });
const tasks = [
    t({ title: "Responder a QA", project: "p_work01", priority: 1, due: day(-1), links: [{ url: "https://github.com/acme/api/issues/88" }] }),
    t({ title: "Enviar factura de octubre", project: "p_work01", priority: 2, due: day(-3), estimate: 15 }),
    t({ title: "Renovar dominio", project: "p_side01", due: day(-2), tags: ["infra"] }),
    t({ title: "Revisar PR #412", project: "p_work01", priority: 2, status: "doing", due: day(0), dueTime: "23:30", estimate: 30, tags: ["review", "backend"], subtasks: [sub("Leer cambios", true), sub("Correr tests", true), sub("Comentar"), sub("Aprobar"), sub("Mergear")], links: [{ url: "https://github.com/acme/api/pull/412" }], notes: "## Revisar\n- Mirar la migración\n- **Ojo** con el timeout" }),
    t({ title: "Standup del equipo", project: "p_work01", due: day(0), dueTime: "09:00", estimate: 15 }),
    t({ title: "Pagar luz", project: "p_home01", due: day(0), repeat: { freq: "monthly", interval: 1, days: [], from: "due" } }),
    t({ title: "Deploy a staging", project: "p_work01", status: "blocked", blockedReason: "faltan credenciales", due: day(0), tags: ["infra"], estimate: 45 }),
    t({ title: "Comprar café", project: "p_home01", due: day(0), estimate: 20 }),
    t({ title: "Escribir el changelog", project: "p_work01", priority: 3, due: day(1), dueTime: "10:00", estimate: 60, tags: ["docs"] }),
    t({ title: "Cita con el dentista", project: "p_home01", due: day(2), dueTime: "16:30" }),
    t({ title: "Preparar demo", project: "p_work01", priority: 1, due: day(3), estimate: 120, subtasks: [sub("Guion"), sub("Datos de prueba")] }),
    t({ title: "Diseño del logo", project: "p_side01", due: day(4), links: [{ url: "https://www.figma.com/design/AbC123/Logo-v2" }] }),
    t({ title: "Llamar a mamá", project: "p_home01", due: day(5), repeat: { freq: "weekly", interval: 1, days: [7], from: "due" } }),
    t({ title: "Actualizar dependencias", project: "p_work01", due: day(6), tags: ["infra", "bug"], estimate: 90 }),
    t({ title: "Planificar el Q1", project: "p_work01", due: day(12), priority: 2 }),
    t({ title: "Leer el RFC de auth", project: "p_work01", links: [{ url: "https://docs.google.com/document/d/abc/edit" }], tags: ["docs"] }),
    t({ title: "Probar Bun en el side project", project: "p_side01", tags: ["idea"] }),
    t({ title: "Ordenar el escritorio", project: "p_home01", priority: 4 }),
    t({ title: "Arreglar el login con Google", project: "p_work01", priority: 1, status: "doing", tags: ["bug"], links: [{ url: "https://acme.atlassian.net/browse/AUTH-231" }] }),
    t({ title: "Empieza el jueves", project: "p_work01", due: day(7), start: day(3) }),
    t({ title: "Idea: modo oscuro automático" }),
    t({ title: "Comprar un teclado nuevo", notes: "Revisar reseñas en [Rtings](https://rtings.com)" }),
    t({ title: "Ver la serie recomendada" }),
    t({ title: "Migrar la base a Postgres 17", project: "p_work01", priority: 3, status: "blocked", blockedReason: "espera al DBA", tags: ["infra"] }),
    t({ title: "Entregar el informe", project: "p_work01", status: "done", completed: ago(0, 9), due: day(0) }),
    t({ title: "Pagar el internet", project: "p_home01", status: "done", completed: ago(0, 8) }),
    t({ title: "Revisar correos", status: "done", completed: ago(1, 17) }),
    t({ title: "Subir el release 1.4", project: "p_work01", status: "done", completed: ago(1, 12), tags: ["release"] }),
    t({ title: "Reunión cancelada", project: "p_work01", status: "cancelled", completed: ago(2) }),
    t({ title: "Archivo de prueba (hecha hace 31 días)", status: "done", completed: ago(31) }),
    t({ title: "Hacer backup del NAS", project: "p_home01", status: "done", completed: ago(5), repeatOf: "t_s00006" }),
];
console.log(JSON.stringify({ version: 1, projects, tasks, templates: [] }, null, 2));
