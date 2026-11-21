.pragma library

// Disposición de monitores: tamaños lógicos, pegar un monitor arrastrado al borde de otro y el lado del externo.
// Puro, para probarlo con node. Un rect es { x, y, w, h } en píxeles lógicos (como los de Hyprland).

// Tamaño lógico de un monitor: sus píxeles entre la escala, con ancho y alto cambiados si está girado 90° o 270°
function rectOf(m) {
    var w = m.width / m.scale, h = m.height / m.scale;
    if (m.transform % 2 === 1) {
        var t = w;
        w = h;
        h = t;
    }
    return { x: m.x, y: m.y, w: Math.round(w), h: Math.round(h) };
}

// Alinea `pos` (de un tramo de largo `size`) con el borde o el centro del otro tramo si queda a menos de `th`;
// y lo deja tocando al otro tramo (que se solapen al menos 1 px), para que el mouse pueda cruzar
function align(pos, size, oPos, oSize, th) {
    var best = pos, bd = th + 1;
    [oPos, oPos + oSize - size, oPos + Math.round((oSize - size) / 2)].forEach(function (c) {
        var d = Math.abs(pos - c);
        if (d < bd) {
            bd = d;
            best = c;
        }
    });
    return Math.max(oPos - size + 1, Math.min(oPos + oSize - 1, best));
}

// Pega `moved` al lado más cercano de alguno de `others`. Devuelve { x, y }.
function snap(moved, others, th) {
    var best = { x: moved.x, y: moved.y }, bd = Infinity;
    function consider(x, y) {
        var d = Math.abs(x - moved.x) + Math.abs(y - moved.y);
        if (d < bd) {
            bd = d;
            best = { x: Math.round(x), y: Math.round(y) };
        }
    }
    others.forEach(function (o) {
        var y = align(moved.y, moved.h, o.y, o.h, th);
        consider(o.x + o.w, y);
        consider(o.x - moved.w, y);
        var x = align(moved.x, moved.w, o.x, o.w, th);
        consider(x, o.y + o.h);
        consider(x, o.y - moved.h);
    });
    return best;
}

// Corre todos para que el de más arriba a la izquierda quede en 0,0. `rects` = { nombre: rect }
function normalize(rects) {
    var minX = Infinity, minY = Infinity, out = {};
    Object.keys(rects).forEach(function (n) {
        minX = Math.min(minX, rects[n].x);
        minY = Math.min(minY, rects[n].y);
    });
    Object.keys(rects).forEach(function (n) {
        var r = rects[n];
        out[n] = { x: r.x - minX, y: r.y - minY, w: r.w, h: r.h };
    });
    return out;
}

// En qué lado del portátil está el externo: left | right | top | bottom
function sideOf(ext, lap) {
    if (ext.x >= lap.x + lap.w)
        return "right";
    if (ext.x + ext.w <= lap.x)
        return "left";
    if (ext.y + ext.h <= lap.y)
        return "top";
    return "bottom";
}

// Dónde va el externo para estar de ese lado del portátil (que está en 0,0). Alineado por arriba o por la izquierda.
function place(side, ext, lap) {
    if (side === "left")
        return { x: -ext.w, y: 0 };
    if (side === "top")
        return { x: 0, y: -ext.h };
    if (side === "bottom")
        return { x: 0, y: lap.h };
    return { x: lap.w, y: 0 };
}
