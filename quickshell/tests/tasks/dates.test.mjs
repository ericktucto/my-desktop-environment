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

done();
