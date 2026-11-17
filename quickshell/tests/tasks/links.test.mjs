import { loadLib, eq, done } from "./load.mjs";

const L = loadLib("services/tasks/Links.js");
const k = u => L.linkInfo(u);

eq("github pr", k("https://github.com/acme/api/pull/412"), { kind: "github-pr", label: "acme/api#412" });
eq("github pr con sufijo", k("https://github.com/acme/api/pull/412/files#diff"), { kind: "github-pr", label: "acme/api#412" });
eq("github issue", k("https://github.com/acme/api/issues/7"), { kind: "github-issue", label: "acme/api#7" });
eq("github repo", k("https://github.com/acme/api"), { kind: "url", label: "github.com" });
eq("gitlab mr", k("https://gitlab.com/group/sub/proj/-/merge_requests/15"), { kind: "gitlab-mr", label: "group/sub/proj!15" });
eq("gitlab issue", k("https://gitlab.example.org/g/p/-/issues/3"), { kind: "gitlab-issue", label: "g/p#3" });
eq("jira", k("https://acme.atlassian.net/browse/PROJ-123"), { kind: "jira", label: "PROJ-123" });
eq("figma", k("https://www.figma.com/design/AbC123/Landing-page-v2?node-id=1"), { kind: "figma", label: "Figma · Landing page v2" });
eq("figma sin nombre", k("https://www.figma.com/file/AbC123"), { kind: "figma", label: "Figma" });
eq("gdoc", k("https://docs.google.com/document/d/abc/edit"), { kind: "gdoc", label: "Google Docs" });
eq("gsheet", k("https://docs.google.com/spreadsheets/d/abc/edit"), { kind: "gdoc", label: "Google Sheets" });
eq("drive", k("https://drive.google.com/file/d/abc/view"), { kind: "gdoc", label: "Google Drive" });
eq("url genérica", k("https://www.ejemplo.com/a/b?x=1"), { kind: "url", label: "ejemplo.com" });
eq("file", k("file:///home/erick/notas/plan%20v2.md"), { kind: "url", label: "plan v2.md" });

eq("normalizeUrl ok", L.normalizeUrl("https://a.com/x"), "https://a.com/x");
eq("normalizeUrl sin esquema", L.normalizeUrl("github.com/a/b"), "https://github.com/a/b");
eq("normalizeUrl texto", L.normalizeUrl("hola mundo"), "");
eq("normalizeUrl palabra", L.normalizeUrl("hola"), "");
eq("normalizeUrl vacío", L.normalizeUrl("  "), "");

const m = L.makeLink("https://github.com/acme/api/pull/412");
eq("makeLink", m, { url: "https://github.com/acme/api/pull/412", kind: "github-pr", label: "acme/api#412", title: "", state: "", checked: 0 });

done();
