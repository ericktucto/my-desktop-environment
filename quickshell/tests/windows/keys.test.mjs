import { loadLib, eq, done } from "../tasks/load.mjs";

const K = loadLib("services/keybinds/Keys.js");
const META = 0x10000000, CTRL = 0x04000000, ALT = 0x08000000, SHIFT = 0x02000000;

eq("Super+Q", K.fromEvent(0x51, META, 24), "SUPER + Q");
eq("Super+Shift+F", K.fromEvent(0x46, META | SHIFT, 41), "SUPER + SHIFT + F");
eq("orden de modificadores", K.fromEvent(0x56, SHIFT | ALT | CTRL | META, 55), "SUPER + CTRL + ALT + SHIFT + V");
eq("número con Shift (Qt da el símbolo)", K.fromEvent(0x21, META | SHIFT, 10), "SUPER + SHIFT + 1");
eq("cero", K.fromEvent(0x29, META, 19), "SUPER + 0");
eq("F5", K.fromEvent(0x01000034, 0, 71), "F5");
eq("F12", K.fromEvent(0x0100003b, ALT, 96), "ALT + F12");
eq("coma", K.fromEvent(0x2c, META, 59), "SUPER + comma");
eq("punto", K.fromEvent(0x2e, META | SHIFT, 60), "SUPER + SHIFT + period");
eq("Tab", K.fromEvent(0x01000001, ALT, 23), "ALT + Tab");
eq("flecha", K.fromEvent(0x01000012, META, 113), "SUPER + left");
eq("Print", K.fromEvent(0x01000009, 0, 107), "Print");
eq("solo un modificador", K.fromEvent(0x01000022, META, 133), "");
eq("solo Shift", K.fromEvent(0x01000020, SHIFT, 50), "");
eq("tecla sin nombre: por su código", K.fromEvent(0x01000099, 0, 200), "code:200");
eq("tecla desconocida sin código", K.fromEvent(0x01000099, 0, 0), "");

// símbolos con Shift y teclas de latam: por el código de la tecla física
eq("mayor que (Shift + punto)", K.fromEvent(0x3e, META | SHIFT, 94), "SUPER + SHIFT + code:94");
eq("ñ", K.fromEvent(0xd1, META, 47), "SUPER + code:47");
eq("dead acute", K.fromEvent(0x01001247, ALT, 34), "ALT + code:34");
eq("sin scancode", K.fromEvent(0x3e, META, 0), "");
eq("canon: comma = code:59", K.canon("SUPER + comma"), K.canon("super + code:59"));
eq("sameKey", K.sameKey("SUPER + SHIFT + period", "SHIFT + SUPER + code:60"), true);
eq("sameKey distinto", K.sameKey("SUPER + period", "SUPER + code:61"), false);

done();
