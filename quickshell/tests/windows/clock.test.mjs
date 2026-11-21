// node tests/windows/clock.test.mjs
import { loadLib, eq, done } from "../tasks/load.mjs";

const C = loadLib("services/settings/Clock.js");
const d = new Date(2026, 10, 16, 17, 7, 9);
const am = new Date(2026, 10, 16, 0, 5, 0);

eq("C.time(d, true, false)", C.time(d, true, false), "05:07 PM");
eq("C.time(d, false, false)", C.time(d, false, false), "17:07");
eq("C.time(d, true, true)", C.time(d, true, true), "05:07:09 PM");
eq("C.time(d, false, true)", C.time(d, false, true), "17:07:09");
eq("C.time(am, true, false)", C.time(am, true, false), "12:05 AM");
eq("C.time(am, false, false)", C.time(am, false, false), "00:05");
eq("C.date(d, \"text\", false)", C.date(d, "text", false), "lun 16 nov");
eq("C.date(d, \"text\", true)", C.date(d, "text", true), "Lunes, 16 de noviembre");
eq("C.date(d, \"dmy\", true)", C.date(d, "dmy", true), "16/11/2026");
eq("C.date(d, \"mdy\", false)", C.date(d, "mdy", false), "11/16/2026");
eq("C.date(d, \"iso\", false)", C.date(d, "iso", false), "2026-11-16");
eq("C.date(d, \"\", false)", C.date(d, "", false), "lun 16 nov");
done();
