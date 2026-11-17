// Carga un .js de la shell (con `.pragma library`) para probarlo con node: node tests/tasks/dates.test.mjs
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

// Soporta `.import "X.js" as Nombre` (relativo al archivo): Nombre queda como objeto global
export function loadLib(rel) {
    let src = fs.readFileSync(path.join(root, rel), "utf8").replace(/^\.pragma library\s*$/m, "");
    const ctx = vm.createContext({});
    src = src.replace(/^\.import "(.+?)" as (\w+)\s*$/gm, (_, file, name) => {
        ctx[name] = loadLib(path.join(path.dirname(rel), file));
        return "";
    });
    vm.runInContext(src, ctx);
    return ctx;
}

let failed = 0;
let total = 0;
export function eq(name, got, want) {
    total++;
    const g = JSON.stringify(got);
    const w = JSON.stringify(want);
    if (g !== w) {
        failed++;
        console.log(`✗ ${name}\n    obtuvo:   ${g}\n    esperaba: ${w}`);
    }
}
export function done() {
    console.log(failed === 0 ? `✓ ${total} pruebas` : `${failed} de ${total} fallaron`);
    process.exit(failed === 0 ? 0 : 1);
}
