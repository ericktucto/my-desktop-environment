.pragma library

// El texto de un workspace según el estilo de numeración. Puro, para probarlo con node.
var JAPANESE = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
var ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];

// kind: arabic | japanese | roman
function label(n, kind) {
    if (n < 1 || n > 10)
        return String(n);
    if (kind === "japanese")
        return JAPANESE[n - 1];
    if (kind === "roman")
        return ROMAN[n - 1];
    return String(n);
}
