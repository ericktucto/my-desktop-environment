.pragma library

// Links de las tareas: el tipo y la etiqueta corta se sacan de la URL con expresiones regulares
// (sin pedir nada a la red). El título y el estado de GitHub los trae scripts/links.py (fase 2 y 4).

var GDOC = {
    document: "Google Docs",
    spreadsheets: "Google Sheets",
    presentation: "Google Slides",
    forms: "Google Forms"
};

// Texto → URL completa, o "" si no parece un link. Acepta "github.com/a/b" sin esquema.
function normalizeUrl(text) {
    var s = String(text || "").trim();
    if (!s || /\s/.test(s))
        return "";
    if (/^(https?|file):\/\/\S+$/i.test(s))
        return s;
    if (/^[a-z0-9-]+(\.[a-z0-9-]+)+(:\d+)?([\/?#]\S*)?$/i.test(s))
        return "https://" + s;
    return "";
}

function hostOf(url) {
    var m = /^[a-z][a-z0-9+.-]*:\/\/([^\/?#]+)/i.exec(url);
    return m ? m[1].replace(/^www\./i, "").toLowerCase() : "";
}

function pretty(s) {
    try {
        s = decodeURIComponent(s);
    } catch (e) {}
    return s.replace(/[-+_]+/g, " ").trim();
}

// URL → { kind, label }
function linkInfo(url) {
    url = String(url || "").trim();
    var m;
    m = /^https?:\/\/(?:www\.)?github\.com\/([^\/\s]+)\/([^\/\s#?]+)\/(pull|issues)\/(\d+)/i.exec(url);
    if (m)
        return {
            kind: m[3] === "pull" ? "github-pr" : "github-issue",
            label: m[1] + "/" + m[2] + "#" + m[4]
        };
    m = /^https?:\/\/[^\/\s]*gitlab[^\/\s]*\/(.+?)\/-\/(merge_requests|issues)\/(\d+)/i.exec(url);
    if (m)
        return {
            kind: m[2] === "issues" ? "gitlab-issue" : "gitlab-mr",
            label: m[1] + (m[2] === "issues" ? "#" : "!") + m[3]
        };
    m = /^https?:\/\/[^\/\s]+\/browse\/([A-Z][A-Z0-9_]+-\d+)/.exec(url);
    if (m)
        return {
            kind: "jira",
            label: m[1]
        };
    m = /^https?:\/\/(?:[a-z0-9-]+\.)?figma\.com\/(?:file|design|proto|board|make)\/[^\/\s?#]+(?:\/([^\/\s?#]+))?/i.exec(url);
    if (m)
        return {
            kind: "figma",
            label: m[1] ? "Figma · " + pretty(m[1]) : "Figma"
        };
    m = /^https?:\/\/docs\.google\.com\/(document|spreadsheets|presentation|forms)\//i.exec(url);
    if (m)
        return {
            kind: "gdoc",
            label: GDOC[m[1].toLowerCase()]
        };
    if (/^https?:\/\/drive\.google\.com\//i.test(url))
        return {
            kind: "gdoc",
            label: "Google Drive"
        };
    m = /^file:\/\/(.*)$/i.exec(url);
    if (m) {
        var parts = m[1].split("/").filter(function (p) {
            return p !== "";
        });
        return {
            kind: "url",
            label: parts.length ? pretty(parts[parts.length - 1]) : "archivo"
        };
    }
    return {
        kind: "url",
        label: hostOf(url) || url
    };
}

// URL → link completo, como se guarda en la tarea
function makeLink(url) {
    var info = linkInfo(url);
    return {
        url: url,
        kind: info.kind,
        label: info.label,
        title: "",
        state: "",
        checked: 0
    };
}
