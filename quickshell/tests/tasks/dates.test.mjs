import { loadLib, eq, done } from "./load.mjs";

const D = loadLib("services/tasks/Dates.js");
// Martes 17 nov 2026, 09:30 (hora local)
const now = new Date(2026, 10, 17, 9, 30);

eq("keyOf", D.keyOf(now), "2026-11-17");
eq("parseKey ok", D.keyOf(D.parseKey("2026-02-28")), "2026-02-28");
eq("parseKey inexistente", D.parseKey("2026-02-30"), null);
eq("parseKey basura", D.parseKey("mañana"), null);
eq("addDays mes", D.addDays("2026-11-30", 1), "2026-12-01");
eq("addDays año", D.addDays("2026-12-31", 1), "2027-01-01");
eq("addDays negativo", D.addDays("2026-03-01", -1), "2026-02-28");
eq("weekday martes", D.weekday("2026-11-17"), 2);
eq("weekday domingo", D.weekday("2026-11-22"), 7);
eq("weekday lunes", D.weekday("2026-11-16"), 1);
eq("prevWorkday lunes", D.prevWorkday("2026-11-16"), "2026-11-13");
eq("prevWorkday martes", D.prevWorkday("2026-11-17"), "2026-11-16");
eq("prevWorkday domingo", D.prevWorkday("2026-11-22"), "2026-11-20");
eq("diffDays", D.diffDays("2026-11-17", "2026-11-20"), 3);
eq("diffDays negativo", D.diffDays("2026-11-17", "2026-11-10"), -7);
eq("inRange dentro", D.inRange("2026-11-18", "2026-11-17", "2026-11-24"), true);
eq("inRange borde", D.inRange("2026-11-24", "2026-11-17", "2026-11-24"), true);
eq("inRange fuera", D.inRange("2026-11-25", "2026-11-17", "2026-11-24"), false);
eq("inRange vacía", D.inRange("", "2026-11-17", ""), false);
eq("inRange sin límite", D.inRange("2030-01-01", "2026-11-17", ""), true);
eq("isTime", [D.isTime("09:30"), D.isTime("9:30"), D.isTime("24:00"), D.isTime("")], [true, false, false, false]);

// relative
eq("hoy sin hora", D.relative("2026-11-17", "", now), "hoy");
eq("hoy con hora futura", D.relative("2026-11-17", "10:00", now), "hoy 10:00");
eq("hoy con hora pasada", D.relative("2026-11-17", "08:00", now), "vencida hoy 08:00");
eq("mañana", D.relative("2026-11-18", "", now), "mañana");
eq("mañana con hora", D.relative("2026-11-18", "09:00", now), "mañana 09:00");
eq("viernes", D.relative("2026-11-20", "", now), "vie");
eq("en 6 días", D.relative("2026-11-23", "", now), "lun");
eq("en 7 días", D.relative("2026-11-24", "", now), "24 nov");
eq("otro año", D.relative("2027-01-05", "", now), "5 ene 2027");
eq("ayer", D.relative("2026-11-16", "", now), "vencida ayer");
eq("hace 3 días", D.relative("2026-11-14", "", now), "vencida hace 3 d");
eq("sin fecha", D.relative("", "", now), "");
eq("acepta ms", D.relative("2026-11-17", "", now.getTime()), "hoy");

// isOverdue
eq("vencida ayer", D.isOverdue({ due: "2026-11-16", status: "todo" }, now), true);
eq("hoy sin hora no vence", D.isOverdue({ due: "2026-11-17", dueTime: "", status: "todo" }, now), false);
eq("hoy hora pasada vence", D.isOverdue({ due: "2026-11-17", dueTime: "08:00", status: "todo" }, now), true);
eq("hoy hora futura", D.isOverdue({ due: "2026-11-17", dueTime: "18:00", status: "todo" }, now), false);
eq("hecha no vence", D.isOverdue({ due: "2026-11-01", status: "done" }, now), false);
eq("sin fecha", D.isOverdue({ due: "", status: "todo" }, now), false);

// textos
eq("shortDate", D.shortDate("2026-11-18", now), "mié 18 nov");
eq("shortDate otro año", D.shortDate("2027-01-05", now), "mar 5 ene 2027");
eq("dayLabel hoy", D.dayLabel("2026-11-17", now), "Hoy");
eq("dayLabel mañana", D.dayLabel("2026-11-18", now), "Mañana");
eq("dayLabel ayer", D.dayLabel("2026-11-16", now), "Ayer");
eq("dayLabel otro", D.dayLabel("2026-11-20", now), "vie 20 nov");
eq("minutos 30", D.formatMinutes(30), "30 m");
eq("minutos 120", D.formatMinutes(120), "2 h");
eq("minutos 150", D.formatMinutes(150), "2 h 30 m");
eq("minutos 0", D.formatMinutes(0), "");

// normTime / parseMinutes / ago / clock
eq("normTime 9", D.normTime("9"), "09:00");
eq("normTime 9:30", D.normTime("9:30"), "09:30");
eq("normTime 0930", D.normTime("0930"), "09:30");
eq("normTime 14.05", D.normTime("14.05"), "14:05");
eq("normTime 25", D.normTime("25"), "");
eq("normTime 9:75", D.normTime("9:75"), "");
eq("normTime texto", D.normTime("tarde"), "");
eq("normTime vacío", D.normTime(""), "");
const pm = t => D.parseMinutes(t);
eq("minutos vacío", pm(""), 0);
eq("minutos 30", pm("30"), 30);
eq("minutos 30m", pm("30m"), 30);
eq("minutos 45 min", pm("45 min"), 45);
eq("minutos 2h", pm("2h"), 120);
eq("minutos 1.5h", pm("1.5h"), 90);
eq("minutos 1,5h", pm("1,5h"), 90);
eq("minutos 1h30", pm("1h30"), 90);
eq("minutos 1h 30m", pm("1h 30m"), 90);
eq("minutos basura", pm("mucho"), -1);
const t0 = now.getTime();
eq("ago ahora", D.ago(t0 - 20e3, now), "hace un momento");
eq("ago min", D.ago(t0 - 5 * 60e3, now), "hace 5 min");
eq("ago h", D.ago(t0 - 3 * 3600e3, now), "hace 3 h");
eq("ago ayer", D.ago(t0 - 30 * 3600e3, now), "ayer");
eq("ago días", D.ago(t0 - 4 * 86400e3, now), "hace 4 días");
eq("ago semanas", D.ago(t0 - 21 * 86400e3, now), "hace 3 semanas");
eq("ago meses", D.ago(t0 - 90 * 86400e3, now), "hace 3 meses");
eq("clock", D.clock(new Date(2026, 10, 17, 9, 5).getTime()), "09:05");

// ── Repetición ──
const rp = (r, due, done = now.getTime(), extra = {}) => D.nextOccurrence({ due, repeat: { interval: 1, days: [], from: "due", ...r }, ...extra }, done);
eq("no se repite", D.nextOccurrence({ due: "2026-11-17", repeat: null }, now.getTime()), "");
eq("cada día", rp({ freq: "daily" }, "2026-11-17"), "2026-11-18");
eq("cada 3 días", rp({ freq: "daily", interval: 3 }, "2026-11-17"), "2026-11-20");
eq("laborable de jueves", rp({ freq: "weekdays" }, "2026-11-19"), "2026-11-20");
eq("laborable de viernes → lunes", rp({ freq: "weekdays" }, "2026-11-20", new Date(2026, 10, 20, 9).getTime()), "2026-11-23");
eq("cada semana", rp({ freq: "weekly" }, "2026-11-17"), "2026-11-24");
eq("cada 2 semanas", rp({ freq: "weekly", interval: 2 }, "2026-11-17"), "2026-12-01");
eq("lunes y jueves: de lunes a jueves", rp({ freq: "weekly", days: [1, 4] }, "2026-11-16", new Date(2026, 10, 16, 9).getTime()), "2026-11-19");
eq("lunes y jueves: de jueves al lunes", rp({ freq: "weekly", days: [1, 4] }, "2026-11-19", new Date(2026, 10, 19, 9).getTime()), "2026-11-23");
eq("cada 2 semanas lunes y jueves, de jueves", rp({ freq: "weekly", interval: 2, days: [1, 4] }, "2026-11-19", new Date(2026, 10, 19, 9).getTime()), "2026-11-30");
eq("cada mes", rp({ freq: "monthly" }, "2026-11-17"), "2026-12-17");
eq("mensual el 31 → último día", rp({ freq: "monthly" }, "2026-01-31", new Date(2026, 0, 31, 9).getTime()), "2026-02-28");
eq("mensual vuelve al 31 con day", rp({ freq: "monthly", day: 31 }, "2026-02-28", new Date(2026, 1, 28, 9).getTime()), "2026-03-31");
eq("cada año", rp({ freq: "yearly" }, "2026-11-17"), "2027-11-17");
eq("año bisiesto 29 feb", rp({ freq: "yearly" }, "2028-02-29", new Date(2028, 1, 29, 9).getTime()), "2029-02-28");
eq("cada 2 meses", rp({ freq: "monthly", interval: 2 }, "2026-11-17"), "2027-01-17");
eq("diaria atrasada salta a lo futuro", rp({ freq: "daily" }, "2026-11-10"), "2026-11-18");
eq("semanal atrasada", rp({ freq: "weekly" }, "2026-10-01"), "2026-11-19");
eq("completada antes de tiempo", rp({ freq: "daily" }, "2026-11-20"), "2026-11-21");
eq("desde que la completo", rp({ freq: "weekly", from: "done" }, "2026-11-10"), "2026-11-24");
eq("desde que la completo, diaria", rp({ freq: "daily", from: "done", interval: 2 }, "2026-11-01"), "2026-11-19");
eq("sin fecha cuenta desde hoy", D.nextOccurrence({ due: "", repeat: { freq: "daily", interval: 1, days: [], from: "due" } }, now.getTime()), "2026-11-18");
eq("cruza el año", rp({ freq: "daily" }, "2026-12-31", new Date(2026, 11, 31, 9).getTime()), "2027-01-01");

done();
