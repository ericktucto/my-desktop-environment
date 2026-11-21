// node tests/windows/snap.test.mjs
import { loadLib, eq, done } from "../tasks/load.mjs";

const S = loadLib("services/display/Snap.js");
const plain = x => JSON.parse(JSON.stringify(x));
const lap = { x: 0, y: 0, w: 1920, h: 1080 };

eq("rectOf escala", plain(S.rectOf({ width: 2880, height: 1800, scale: 1.5, transform: 0, x: 0, y: 0 })), { x: 0, y: 0, w: 1920, h: 1200 });
eq("rectOf girado", plain(S.rectOf({ width: 1920, height: 1080, scale: 1, transform: 1, x: 5, y: 6 })), { x: 5, y: 6, w: 1080, h: 1920 });

// suelto a la derecha, un poco separado y desalineado: se pega al borde y se alinea por arriba
eq("pegado a la derecha", plain(S.snap({ x: 1990, y: 30, w: 1280, h: 720 }, [lap], 60)), { x: 1920, y: 0 });
// suelto a la izquierda
eq("pegado a la izquierda", plain(S.snap({ x: -1300, y: 200, w: 1280, h: 720 }, [lap], 60)), { x: -1280, y: 180 });
// encima, alineado por el centro
eq("arriba y centrado", plain(S.snap({ x: 300, y: -800, w: 1280, h: 720 }, [lap], 60)), { x: 320, y: -720 });
// debajo, lejos de los bordes: conserva la x
eq("debajo", plain(S.snap({ x: 100, y: 1200, w: 800, h: 600 }, [lap], 10)), { x: 100, y: 1080 });
// sin solaparse en el otro eje: se corre para tocar
eq("toca al otro", plain(S.snap({ x: 1925, y: 2000, w: 1280, h: 720 }, [lap], 10)), { x: 1920, y: 1079 });

eq("normalize", plain(S.normalize({ a: { x: 0, y: 0, w: 10, h: 10 }, b: { x: -20, y: 5, w: 20, h: 10 } })), { a: { x: 20, y: 0, w: 10, h: 10 }, b: { x: 0, y: 5, w: 20, h: 10 } });

eq("lado derecho", S.sideOf({ x: 1920, y: 0, w: 1280, h: 720 }, lap), "right");
eq("lado izquierdo", S.sideOf({ x: -1280, y: 0, w: 1280, h: 720 }, lap), "left");
eq("lado arriba", S.sideOf({ x: 0, y: -720, w: 1280, h: 720 }, lap), "top");
eq("lado abajo", S.sideOf({ x: 0, y: 1080, w: 1280, h: 720 }, lap), "bottom");
eq("place izquierda", plain(S.place("left", { w: 1280, h: 720 }, lap)), { x: -1280, y: 0 });
eq("place derecha", plain(S.place("right", { w: 1280, h: 720 }, lap)), { x: 1920, y: 0 });
done();
