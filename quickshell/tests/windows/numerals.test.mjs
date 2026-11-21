// node tests/windows/numerals.test.mjs
import { loadLib, eq, done } from "../tasks/load.mjs";

const N = loadLib("services/workspaces/Numerals.js");

eq("arábigo", N.label(3, "arabic"), "3");
eq("por defecto", N.label(7, ""), "7");
eq("japonés 1", N.label(1, "japanese"), "一");
eq("japonés 10", N.label(10, "japanese"), "十");
eq("romano 4", N.label(4, "roman"), "IV");
eq("romano 9", N.label(9, "roman"), "IX");
eq("fuera de rango", N.label(11, "roman"), "11");
done();
