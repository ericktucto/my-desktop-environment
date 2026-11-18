import { loadLib, eq, done } from "./load.mjs";

const R = loadLib("services/tasks/Reminders.js");
const M = loadLib("services/tasks/Model.js");
// Martes 17 nov 2026, 09:30
const now = new Date(2026, 10, 17, 9, 30);
const N = now.getTime();
const T = f => M.normTask(Object.assign({ id: "t", title: "x" }, f), N);
const rem = (offset, extra = {}) => ({ id: "r" + offset, offset, at: "", firedAt: 0, ...extra });

// triggerMs / parseAt / atString
const at10 = new Date(2026, 10, 17, 10, 0).getTime();
eq("a la hora", R.triggerMs(T({ due: "2026-11-17", dueTime: "10:00" }), rem(0)), at10);
eq("10 min antes", R.triggerMs(T({ due: "2026-11-17", dueTime: "10:00" }), rem(10)), at10 - 600000);
eq("sin hora no avisa", R.triggerMs(T({ due: "2026-11-17" }), rem(0)), null);
eq("sin fecha no avisa", R.triggerMs(T({}), rem(0)), null);
eq("fijo", R.triggerMs(T({}), { ...rem(0), at: "2026-11-17T09:45" }), new Date(2026, 10, 17, 9, 45).getTime());
eq("fijo mal formado", R.triggerMs(T({ due: "2026-11-17", dueTime: "10:00" }), { ...rem(0), at: "mañana" }), null);
eq("atString", R.atString(new Date(2026, 10, 17, 9, 5).getTime()), "2026-11-17T09:05");
eq("parseAt ida y vuelta", R.parseAt(R.atString(N)), new Date(2026, 10, 17, 9, 30).getTime());

// label
eq("label 0", R.label(rem(0), now), "a la hora");
eq("label 5", R.label(rem(5), now), "5 min antes");
eq("label 60", R.label(rem(60), now), "1 h antes");
eq("label 90", R.label(rem(90), now), "1 h 30 m antes");
eq("label 1440", R.label(rem(1440), now), "1 día antes");
eq("label 2880", R.label(rem(2880), now), "2 días antes");
eq("label fijo hoy", R.label({ ...rem(0), at: "2026-11-17T09:45" }, now), "hoy 09:45");
eq("label fijo mañana", R.label({ ...rem(0), at: "2026-11-18T08:00" }, now), "mañana 08:00");

// due
const t1 = T({ id: "a", due: "2026-11-17", dueTime: "09:30", reminders: [rem(0)] });
const t2 = T({ id: "b", due: "2026-11-17", dueTime: "10:00", reminders: [rem(0)] });
const t3 = T({ id: "c", due: "2026-11-17", dueTime: "09:00", reminders: [rem(0), rem(30)] });
const t4 = T({ id: "d", due: "2026-11-17", dueTime: "09:00", reminders: [rem(0, { firedAt: 1 })] });
const t5 = T({ id: "e", due: "2026-11-17", dueTime: "09:00", reminders: [rem(0)], status: "done" });
const t6 = T({ id: "f", due: "2026-11-16", dueTime: "09:00", reminders: [rem(0)] });
const t7 = T({ id: "g", due: "2026-11-17", dueTime: "09:29", reminders: [rem(0)] });
const d = R.due([t1, t2, t3, t4, t5, t6, t7], N);
eq("toca ahora", d.map(x => x.task.id + ":" + x.reminder.offset), ["f:0", "c:30", "c:0", "g:0", "a:0"]);
eq("no toca todavía", d.some(x => x.task.id === "b"), false);
eq("ya avisado no repite", d.some(x => x.task.id === "d"), false);
eq("hecha no avisa", d.some(x => x.task.id === "e"), false);
eq("a tiempo no es atrasado", d.find(x => x.task.id === "a").late, false);
eq("1 min tarde no es atrasado", d.find(x => x.task.id === "g").late, false);
eq("30 min tarde: atrasado", d.find(x => x.task.id === "c" && x.reminder.offset === 0).late, true);
eq("ayer: atrasado y viejo", [d[0].late, d[0].stale], [true, true]);
eq("de hoy no es viejo", d.find(x => x.task.id === "c").stale, false);

// markFired / snooze / reschedule
const f = R.markFired(t3, ["r0"], N);
eq("markFired", f.reminders.map(r => r.firedAt), [N, 0]);
eq("markFired no muta", t3.reminders[0].firedAt, 0);
const s = R.snooze(t4, 10, N);
eq("snooze agrega fijo", s.reminders.length, 2);
eq("snooze a 10 min", s.reminders[1].at, "2026-11-17T09:40");
const s2 = R.snooze({ ...s, reminders: s.reminders.map(r => r.at ? { ...r, firedAt: N } : r) }, 10, N);
eq("snooze quita el fijo ya avisado", s2.reminders.filter(r => r.at).length, 1);
eq("snooze con tarea sin hora avisa", R.due([T({ reminders: R.snooze(T({ due: "2026-11-20" }), 5, N - 600000).reminders })], N).length, 1);
eq("reschedule", R.reschedule([rem(0, { firedAt: 5 }), { ...rem(0), at: "2026-11-17T09:45", firedAt: 5 }]).map(r => [r.at, r.firedAt]), [["", 0]]);

// Model: aviso por defecto y reprogramación
const nt = M.makeTask({ title: "x", due: "2026-11-18", dueTime: "09:00" }, N, []);
eq("hora → un aviso a la hora", nt.reminders.map(r => r.offset), [0]);
eq("sin hora → sin avisos", M.makeTask({ title: "x", due: "2026-11-18" }, N, []).reminders, []);
eq("avisos explícitos se respetan", M.makeTask({ title: "x", due: "2026-11-18", dueTime: "09:00", reminders: [rem(30)] }, N, []).reminders.map(r => r.offset), [30]);
eq("avisos vacíos explícitos", M.makeTask({ title: "x", due: "2026-11-18", dueTime: "09:00", reminders: [] }, N, []).reminders, []);
const a = M.applyChanges(T({ due: "2026-11-18" }), { dueTime: "10:00" }, N);
eq("ponerle hora agrega el aviso", a.reminders.map(r => r.offset), [0]);
const b = M.applyChanges(T({ due: "2026-11-18", dueTime: "10:00", reminders: [rem(0, { firedAt: 9 })] }), { dueTime: "11:00" }, N);
eq("cambiar la hora reprograma", b.reminders.map(r => r.firedAt), [0]);
const c = M.applyChanges(T({ due: "2026-11-18", dueTime: "10:00", reminders: [rem(0, { firedAt: 9 })] }), { priority: 2 }, N);
eq("otro cambio no reprograma", c.reminders.map(r => r.firedAt), [9]);
const e = M.applyChanges(T({ due: "2026-11-18", dueTime: "10:00", reminders: [rem(0)] }), { reminders: [] }, N);
eq("quitar los avisos se respeta", e.reminders, []);

done();
