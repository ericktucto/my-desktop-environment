#!/usr/bin/env python3
"""Información de un link para las tareas de la shell (usa solo la librería estándar).

    links.py info <url>

Imprime un JSON con una línea: { ok, kind, label, title, state, error?, tokenInvalid? }
  kind:  github-pr | github-issue | gitlab-mr | gitlab-issue | jira | figma | gdoc | url
  label: etiqueta corta ("acme/api#412"); es la misma que calcula services/tasks/Links.js
  title: título de la página (og:title o <title>); para GitHub, el del PR o issue
  state: solo GitHub: open | closed | merged | draft

Para GitHub usa la API REST: sin login para repos públicos (60 consultas por hora). Con un token en
~/.config/stixshell/github-token (una línea) también ve los privados. Si el token no vale, se ignora y se
avisa con tokenInvalid.
"""
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

TIMEOUT = 6  # s
MAX_BYTES = 256 * 1024
TOKEN_FILE = os.path.expanduser("~/.config/stixshell/github-token")
UA = "stixshell-tasks/1.0"


def pretty(s):
    try:
        s = urllib.parse.unquote(s)
    except Exception:
        pass
    return re.sub(r"[-+_]+", " ", s).strip()


def link_info(url):
    """URL → (kind, label, extra) con las mismas reglas que Links.js."""
    m = re.match(r"^https?://(?:www\.)?github\.com/([^/\s]+)/([^/\s#?]+)/(pull|issues)/(\d+)", url, re.I)
    if m:
        kind = "github-pr" if m.group(3) == "pull" else "github-issue"
        return kind, f"{m.group(1)}/{m.group(2)}#{m.group(4)}", {"repo": f"{m.group(1)}/{m.group(2)}", "n": m.group(4), "api": "pulls" if m.group(3) == "pull" else "issues"}
    m = re.match(r"^https?://[^/\s]*gitlab[^/\s]*/(.+?)/-/(merge_requests|issues)/(\d+)", url, re.I)
    if m:
        issue = m.group(2) == "issues"
        return ("gitlab-issue" if issue else "gitlab-mr"), m.group(1) + ("#" if issue else "!") + m.group(3), {}
    m = re.match(r"^https?://[^/\s]+/browse/([A-Z][A-Z0-9_]+-\d+)", url)
    if m:
        return "jira", m.group(1), {}
    m = re.match(r"^https?://(?:[a-z0-9-]+\.)?figma\.com/(?:file|design|proto|board|make)/[^/\s?#]+(?:/([^/\s?#]+))?", url, re.I)
    if m:
        return "figma", "Figma · " + pretty(m.group(1)) if m.group(1) else "Figma", {}
    m = re.match(r"^https?://docs\.google\.com/(document|spreadsheets|presentation|forms)/", url, re.I)
    if m:
        names = {"document": "Google Docs", "spreadsheets": "Google Sheets", "presentation": "Google Slides", "forms": "Google Forms"}
        return "gdoc", names[m.group(1).lower()], {}
    if re.match(r"^https?://drive\.google\.com/", url, re.I):
        return "gdoc", "Google Drive", {}
    m = re.match(r"^file://(.*)$", url, re.I)
    if m:
        parts = [p for p in m.group(1).split("/") if p]
        return "url", pretty(parts[-1]) if parts else "archivo", {}
    host = re.match(r"^[a-z][a-z0-9+.-]*://([^/?#]+)", url, re.I)
    return "url", re.sub(r"^www\.", "", host.group(1).lower()) if host else url, {}


def read_token():
    try:
        with open(TOKEN_FILE) as f:
            return f.readline().strip()
    except OSError:
        return ""


def fetch(url, headers=None, limit=MAX_BYTES):
    req = urllib.request.Request(url, headers={"User-Agent": UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        data = r.read(limit)
        return r.headers, data, r.status


def github_state(extra, token):
    """Título y estado de un PR o issue. Devuelve (title, state, error, tokenInvalid)."""
    url = f"https://api.github.com/repos/{extra['repo']}/{extra['api']}/{extra['n']}"
    base = {"Accept": "application/vnd.github+json"}
    invalid = False
    for use_token in ([True, False] if token else [False]):
        headers = dict(base)
        if use_token:
            headers["Authorization"] = f"Bearer {token}"
        try:
            _, data, _ = fetch(url, headers, 2 * 1024 * 1024)
            j = json.loads(data.decode("utf-8", "replace"))
        except urllib.error.HTTPError as e:
            if e.code == 401 and use_token:
                invalid = True
                continue
            if e.code in (403, 429):
                return "", "", "rate-limit", invalid
            return "", "", f"http {e.code}", invalid
        except (urllib.error.URLError, TimeoutError, OSError):
            return "", "", "offline", invalid
        except ValueError:
            return "", "", "respuesta inválida", invalid
        state = j.get("state", "")
        if extra["api"] == "pulls":
            if j.get("merged") or j.get("merged_at"):
                state = "merged"
            elif j.get("draft"):
                state = "draft"
        return (j.get("title") or "").strip(), state, "", invalid
    return "", "", "no autorizado", invalid


def page_title(url):
    """og:title o <title> de la página (nada si no es HTML). Devuelve (title, error)."""
    if url.lower().startswith("file://"):
        return "", ""
    try:
        headers, data, _ = fetch(url)
    except urllib.error.HTTPError as e:
        return "", f"http {e.code}"
    except (urllib.error.URLError, TimeoutError, OSError):
        return "", "offline"
    ctype = headers.get("Content-Type", "")
    if "html" not in ctype.lower() and ctype != "":
        return "", ""
    charset = headers.get_content_charset()
    if not charset:
        m = re.search(rb"<meta[^>]+charset=[\"']?([a-zA-Z0-9_-]+)", data[:4096], re.I)
        charset = m.group(1).decode("ascii", "ignore") if m else "utf-8"
    try:
        text = data.decode(charset, "replace")
    except LookupError:
        text = data.decode("utf-8", "replace")
    m = re.search(r"<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"']([^\"']+)[\"']", text, re.I) or re.search(
        r"<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:title[\"']", text, re.I
    )
    if not m:
        m = re.search(r"<title[^>]*>(.*?)</title>", text, re.I | re.S)
    if not m:
        return "", ""
    title = re.sub(r"\s+", " ", html.unescape(m.group(1))).strip()
    return title[:200], ""


def info(url):
    url = url.strip()
    kind, label, extra = link_info(url)
    out = {"ok": True, "kind": kind, "label": label, "title": "", "state": ""}
    if kind in ("github-pr", "github-issue"):
        title, state, err, invalid = github_state(extra, read_token())
        out.update(title=title, state=state)
        if invalid:
            out["tokenInvalid"] = True
        if err:
            out.update(ok=False, error=err)
    elif kind == "url" and re.match(r"^https?://", url, re.I):
        # Jira, Figma y Google Docs piden login: su <title> sería genérico, se quedan con la etiqueta corta
        title, err = page_title(url)
        out["title"] = title
        if err:
            out.update(ok=False, error=err)
    return out


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "info":
        print(json.dumps({"ok": False, "error": "uso: links.py info <url>"}))
        return 2
    try:
        print(json.dumps(info(sys.argv[2]), ensure_ascii=False))
    except Exception as e:  # nunca romper la shell: se devuelve el error
        print(json.dumps({"ok": False, "error": str(e)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
