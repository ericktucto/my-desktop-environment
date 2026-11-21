// node tests/windows/apps.test.mjs
import { loadLib, eq, done } from "../tasks/load.mjs";

const A = loadLib("services/apps/Apps.js");
const plain = x => JSON.parse(JSON.stringify(x));

eq("separa", plain(A.split("foot -a stix")), ["foot", "-a", "stix"]);
eq("comillas", plain(A.split("sh -c 'echo hola' \"a b\"")), ["sh", "-c", "echo hola", "a b"]);
eq("vacío", plain(A.split("   ")), []);
eq("join simple", A.join(["foot", "-a", "x y"]), "foot -a 'x y'");
const entries = [{ id: "foot", command: ["foot"] }, { id: "org.wezfurlong.wezterm", command: ["wezterm", "start"] }];
eq("propio gana", plain(A.resolve("alacritty -o x", "foot", entries, ["kitty"])), ["alacritty", "-o", "x"]);
eq("app elegida", plain(A.resolve("", "org.wezfurlong.wezterm", entries, ["kitty"])), ["wezterm", "start"]);
eq("app que ya no existe", plain(A.resolve("", "borrada", entries, ["kitty"])), ["kitty"]);
eq("fallback", plain(A.resolve("", "", entries, ["xdg-open"])), ["xdg-open"]);
eq("kitty directo", plain(A.inTerminal(["kitty"], ["nvim", "a"], false)), ["kitty", "nvim", "a"]);
eq("kitty hold", plain(A.inTerminal(["/usr/bin/kitty"], ["ls"], true)), ["/usr/bin/kitty", "--hold", "ls"]);
eq("otra terminal", plain(A.inTerminal(["foot"], ["nvim"], false)), ["foot", "-e", "nvim"]);
eq("otra terminal hold", plain(A.inTerminal(["foot"], ["ls"], true)).slice(0, 4), ["foot", "-e", "sh", "-c"]);
done();
