import { loadLib, eq, done } from "../tasks/load.mjs";

const D = loadLib("services/timer/Duration.js");
const p = t => D.parse(t);

// Tiempos
eq("10 = minutos", p("10"), { ms: 600000, name: "" });
eq("10m", p("10m"), { ms: 600000, name: "" });
eq("10 min", p("10 min"), { ms: 600000, name: "" });
eq("90s", p("90s"), { ms: 90000, name: "" });
eq("1h30", p("1h30"), { ms: 5400000, name: "" });
eq("1h 30m", p("1h 30m"), { ms: 5400000, name: "" });
eq("1h", p("1h"), { ms: 3600000, name: "" });
eq("2 horas", p("2 horas"), { ms: 7200000, name: "" });
eq("1m30", p("1m30"), { ms: 90000, name: "" });
eq("1h 5m 10s", p("1h 5m 10s"), { ms: 3910000, name: "" });
eq("1.5h", p("1.5h"), { ms: 5400000, name: "" });
eq("0,5 (coma)", p("0,5"), { ms: 30000, name: "" });
eq("5:00", p("5:00"), { ms: 300000, name: "" });
eq("0:45", p("0:45"), { ms: 45000, name: "" });
eq("1:30:00", p("1:30:00"), { ms: 5400000, name: "" });
eq("mayúsculas", p("10M"), { ms: 600000, name: "" });
eq("30 horas", p("30h"), { ms: 108000000, name: "" });

// Nombre
eq("10m té", p("10m té"), { ms: 600000, name: "té" });
eq("25 leer", p("25 leer"), { ms: 1500000, name: "leer" });
eq("10 mate (no es 10 m)", p("10 mate"), { ms: 600000, name: "mate" });
eq("5 sopa (no es 5 s)", p("5 sopa"), { ms: 300000, name: "sopa" });
eq("1h30 horno", p("1h30 horno"), { ms: 5400000, name: "horno" });
eq("5:00 pasta al dente", p("5:00 pasta al dente"), { ms: 300000, name: "pasta al dente" });
eq("separador", p("10m - té"), { ms: 600000, name: "té" });
eq("dos números: el segundo es nombre", p("10 5"), { ms: 600000, name: "5" });

// Basura
eq("vacío", p(""), null);
eq("null", p(null), null);
eq("solo nombre", p("té"), null);
eq("0", p("0"), null);
eq("0m", p("0m"), null);
eq("segundos 60 en mm:ss", p("5:60"), null);
eq("más de 100 h", p("101h"), null);
eq("100 h justas", p("100h"), { ms: 360000000, name: "" });

// format
eq("format 4:59", D.format(299000), "4:59");
eq("format 0:05", D.format(5000), "0:05");
eq("format hora", D.format(3899000), "1:04:59");
eq("format ceros", D.format(0), "0:00");
eq("format negativo", D.format(-5), "0:00");
eq("format cs", D.format(750470, true), "12:30.47");
eq("format cs corto", D.format(1230, true), "0:01.23");
eq("format cs hora", D.format(3723450, true), "1:02:03.45");

// label
eq("label 4 min", D.label(240000), "4 min");
eq("label 1 h 30 min", D.label(5400000), "1 h 30 min");
eq("label 1 h", D.label(3600000), "1 h");
eq("label 45 s", D.label(45000), "45 s");
eq("label 4 min 30 s", D.label(270000), "4 min 30 s");

done();
