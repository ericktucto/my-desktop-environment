.pragma library

// Calculadora del launcher (prefijo c:). Evaluador propio, sin eval.
// Operadores: + - * / % ^ y paréntesis. Funciones: sqrt, sin, cos, tan (radianes), log (base 10), ln,
// abs, round, floor, ceil. Constantes: pi, e. Acepta coma o punto decimal.

var FUNCTIONS = {
    sqrt: Math.sqrt,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    log: Math.log10,
    ln: Math.log,
    abs: Math.abs,
    round: Math.round,
    floor: Math.floor,
    ceil: Math.ceil
};
var CONSTANTS = {
    pi: Math.PI,
    e: Math.E
};

// Texto → lista de tokens { t: "num" | "id" | "op" | "(" | ")", v }
function tokenize(text) {
    var tokens = [];
    var i = 0;
    var s = text.toLowerCase();
    while (i < s.length) {
        var c = s[i];
        if (c === " " || c === "\t") {
            i++;
        } else if ((c >= "0" && c <= "9") || c === "." || c === ",") {
            var j = i;
            while (j < s.length && ((s[j] >= "0" && s[j] <= "9") || s[j] === "." || s[j] === ","))
                j++;
            var raw = s.substring(i, j).replace(",", ".");
            // "1.2.3" no es un número
            if (raw.split(".").length > 2 || raw === ".")
                return null;
            tokens.push({
                t: "num",
                v: parseFloat(raw)
            });
            i = j;
        } else if (c >= "a" && c <= "z") {
            var k = i;
            while (k < s.length && s[k] >= "a" && s[k] <= "z")
                k++;
            tokens.push({
                t: "id",
                v: s.substring(i, k)
            });
            i = k;
        } else if (c === "(" || c === ")") {
            tokens.push({
                t: c
            });
            i++;
        } else if ("+-*/%^".indexOf(c) >= 0) {
            tokens.push({
                t: "op",
                v: c
            });
            i++;
        } else if (c === "×") {
            tokens.push({
                t: "op",
                v: "*"
            });
            i++;
        } else if (c === "÷") {
            tokens.push({
                t: "op",
                v: "/"
            });
            i++;
        } else {
            return null;
        }
    }
    return tokens;
}

// Análisis descendente recursivo. Devuelve el número o lanza una excepción si la expresión no es válida.
function parse(tokens) {
    var pos = 0;

    function peek() {
        return tokens[pos];
    }
    function isOp(v) {
        var t = tokens[pos];
        return t && t.t === "op" && t.v === v;
    }

    function expr() {
        var left = term();
        while (isOp("+") || isOp("-")) {
            var op = tokens[pos++].v;
            var right = term();
            left = op === "+" ? left + right : left - right;
        }
        return left;
    }

    function term() {
        var left = unary();
        while (isOp("*") || isOp("/") || isOp("%")) {
            var op = tokens[pos++].v;
            var right = unary();
            left = op === "*" ? left * right : (op === "/" ? left / right : left % right);
        }
        return left;
    }

    function unary() {
        if (isOp("-")) {
            pos++;
            return -unary();
        }
        if (isOp("+")) {
            pos++;
            return unary();
        }
        return power();
    }

    // ^ asocia a la derecha: 2^3^2 = 2^(3^2); y 2^-1 funciona porque el exponente es un unario
    function power() {
        var base = primary();
        if (isOp("^")) {
            pos++;
            return Math.pow(base, unary());
        }
        return base;
    }

    function primary() {
        var t = peek();
        if (!t)
            throw new Error("incompleta");
        if (t.t === "num") {
            pos++;
            return t.v;
        }
        if (t.t === "(") {
            pos++;
            var v = expr();
            if (!peek() || peek().t !== ")")
                throw new Error("falta )");
            pos++;
            return v;
        }
        if (t.t === "id") {
            pos++;
            if (FUNCTIONS.hasOwnProperty(t.v)) {
                if (!peek() || peek().t !== "(")
                    throw new Error("falta (");
                pos++;
                var arg = expr();
                if (!peek() || peek().t !== ")")
                    throw new Error("falta )");
                pos++;
                return FUNCTIONS[t.v](arg);
            }
            if (CONSTANTS.hasOwnProperty(t.v))
                return CONSTANTS[t.v];
            throw new Error("desconocido");
        }
        throw new Error("inesperado");
    }

    var result = expr();
    if (pos < tokens.length)
        throw new Error("sobra");
    return result;
}

function format(v) {
    if (v === Infinity || v === -Infinity)
        return v < 0 ? "-∞" : "∞";
    // Hasta 12 cifras significativas, sin ceros ni exponente de más: 0.1+0.2 → 0.3
    var n = Number(v.toPrecision(12));
    var s = String(n);
    if (s.indexOf("e") >= 0)
        s = n.toLocaleString("en-US", {
            useGrouping: false,
            maximumFractionDigits: 12
        });
    return s;
}

// → { ok, value, display }. Si la expresión está incompleta o no es válida, ok es false.
function evaluate(text) {
    var empty = {
        ok: false,
        value: 0,
        display: ""
    };
    var tokens = tokenize(text);
    if (!tokens || tokens.length === 0)
        return empty;
    try {
        var v = parse(tokens);
        if (typeof v !== "number" || isNaN(v))
            return empty;
        return {
            ok: true,
            value: v,
            display: format(v)
        };
    } catch (e) {
        return empty;
    }
}
