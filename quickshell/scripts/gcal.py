#!/usr/bin/env python3
"""Google Calendar para el panel de productividad (services/calendar/CalendarStore.qml). Todo responde JSON.

  gcal.py status
      { client, connected, email }. `client`: existe client.json; `connected`: hay sesión guardada.
  gcal.py login [--timeout 180]
      OAuth de app de escritorio (PKCE, servidor local en 127.0.0.1). Abre el navegador y guarda token.json.
      { ok, email, error }   error: no-client | timeout | denied | offline | <texto>
  gcal.py logout
      Revoca el permiso en Google y borra token.json. { ok }
  gcal.py events --from AAAA-MM-DD --to AAAA-MM-DD [--skip-holidays]
      Eventos de los calendarios marcados en Google (días from..to, ambos incluidos).
      { ok, updated, email, calendars: [{ id, name, color }],
        events: [{ id, cal, calName, title, allDay, start, end, startDate, endDate, location, description,
                   color, meet, link }], error }
      Con día entero: startDate y endDate (el último día, incluido); si no: start y end en ms desde 1970.
      error: no-client | no-token | expired | offline | <texto>
  gcal.py holidays --id <id del calendario público>
      Feriados y celebraciones de un calendario público de Google (sin login).
      { ok, updated, events: [{ date, title, kind: holiday | observance }], error }

Los archivos van en ~/.config/stixshell/google (STIXSHELL_GOOGLE_DIR lo cambia):
  client.json  cliente OAuth de tipo "App de escritorio" (se descarga de Google Cloud)
  token.json   sesión guardada por este script (permisos 600)
"""
import base64
import hashlib
import html
import json
import os
import re
import secrets
import subprocess
import sys
import time
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, quote, urlencode, urlparse

import requests

SCOPE = "https://www.googleapis.com/auth/calendar.readonly"
AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
REVOKE_URL = "https://oauth2.googleapis.com/revoke"
API = "https://www.googleapis.com/calendar/v3"
TIMEOUT = 15
HOLIDAY_ID = "#holiday@group.v.calendar.google.com"
HOLIDAY_WORDS = {"día festivo", "dia festivo", "holiday", "public holiday", "feriado", "festivo"}
MEET_RE = re.compile(r"https://(?:meet\.google\.com/[a-z\-]+|[\w.\-]*zoom\.us/j/\S+|teams\.microsoft\.com/l/meetup-join/\S+|teams\.live\.com/meet/\S+)")


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))


def now_ms():
    return int(time.time() * 1000)


class CalError(Exception):
    def __init__(self, code):
        super().__init__(code)
        self.code = code


# ───────────────────────── archivos ─────────────────────────

def gdir():
    return os.environ.get("STIXSHELL_GOOGLE_DIR") or os.path.expanduser("~/.config/stixshell/google")


def client_path():
    return os.path.join(gdir(), "client.json")


def token_path():
    return os.path.join(gdir(), "token.json")


def load_client():
    try:
        with open(client_path()) as f:
            data = json.load(f)
    except (OSError, ValueError):
        raise CalError("no-client")
    c = data.get("installed") or data.get("web") or data
    if not c.get("client_id"):
        raise CalError("no-client")
    return c


def load_token():
    try:
        with open(token_path()) as f:
            t = json.load(f)
    except (OSError, ValueError):
        raise CalError("no-token")
    if not t.get("refresh_token"):
        raise CalError("no-token")
    return t


def save_token(t):
    os.makedirs(gdir(), mode=0o700, exist_ok=True)
    os.chmod(gdir(), 0o700)
    tmp = token_path() + ".tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(t, f)
    os.replace(tmp, token_path())


# ───────────────────────── red ─────────────────────────

def http(method, url, **kw):
    try:
        return requests.request(method, url, timeout=TIMEOUT, **kw)
    except (requests.ConnectionError, requests.Timeout):
        raise CalError("offline")
    except requests.RequestException as e:
        raise CalError(str(e)[:120])


def token_request(client, data):
    body = {"client_id": client["client_id"], **data}
    if client.get("client_secret"):
        body["client_secret"] = client["client_secret"]
    r = http("POST", client.get("token_uri") or TOKEN_URL, data=body)
    try:
        j = r.json()
    except ValueError:
        j = {}
    if r.status_code != 200:
        if j.get("error") == "invalid_grant":
            raise CalError("expired")
        raise CalError(j.get("error_description") or j.get("error") or "HTTP %d" % r.status_code)
    return j


def access_token():
    """access_token vigente (lo renueva con el refresh_token si hace falta)."""
    client = load_client()
    t = load_token()
    if t.get("access_token") and t.get("expires_at", 0) - 60 > time.time():
        return t["access_token"], t
    j = token_request(client, {"grant_type": "refresh_token", "refresh_token": t["refresh_token"]})
    t["access_token"] = j["access_token"]
    t["expires_at"] = time.time() + int(j.get("expires_in", 3600))
    save_token(t)
    return t["access_token"], t


def api_get(path, params=None):
    tok, _ = access_token()
    r = http("GET", API + path, params=params, headers={"Authorization": "Bearer " + tok})
    if r.status_code in (401, 403):
        try:
            reason = r.json().get("error", {}).get("errors", [{}])[0].get("reason", "")
        except (ValueError, IndexError, AttributeError):
            reason = ""
        if r.status_code == 401:
            raise CalError("expired")
        if reason in ("accessNotConfigured", "SERVICE_DISABLED"):
            raise CalError("Activa Google Calendar API en tu proyecto de Google Cloud")
        raise CalError("Google negó el acceso (%s)" % (reason or r.status_code))
    if r.status_code != 200:
        raise CalError("Google respondió HTTP %d" % r.status_code)
    return r.json()


# ───────────────────────── eventos ─────────────────────────

def plain(text):
    """Descripción de Google (a veces con HTML) a texto plano."""
    if not text:
        return ""
    t = re.sub(r"(?i)<br\s*/?>|</p>|</div>|</li>", "\n", text)
    t = re.sub(r"(?i)<a\s[^>]*href=\"([^\"]+)\"[^>]*>(.*?)</a>", lambda m: m.group(2) if m.group(2) == m.group(1) else "%s (%s)" % (m.group(2), m.group(1)), t, flags=re.S)
    t = re.sub(r"<[^>]+>", "", t)
    t = html.unescape(t)
    return re.sub(r"\n{3,}", "\n\n", t).strip()


def meet_link(ev, description):
    if ev.get("hangoutLink"):
        return ev["hangoutLink"]
    for ep in (ev.get("conferenceData") or {}).get("entryPoints", []):
        if ep.get("entryPointType") == "video" and ep.get("uri"):
            return ep["uri"]
    m = MEET_RE.search(ev.get("location") or "") or MEET_RE.search(ev.get("description") or "") or MEET_RE.search(description)
    return m.group(0).rstrip(".,;)>\"'") if m else ""


def parse_dt(s):
    return int(datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp() * 1000)


def normalize_event(ev, cal, palette):
    """Evento de la API → el formato del script. None si no se debe mostrar."""
    if ev.get("status") == "cancelled":
        return None
    if ev.get("eventType") in ("birthday", "workingLocation"):
        return None
    for a in ev.get("attendees") or []:
        if a.get("self") and a.get("responseStatus") == "declined":
            return None
    start, end = ev.get("start") or {}, ev.get("end") or {}
    description = plain(ev.get("description"))
    color = cal.get("color", "")
    cid = ev.get("colorId")
    if cid and cid in palette:
        color = palette[cid]
    base = {
        "id": ev.get("id", ""),
        "cal": cal["id"],
        "calName": cal["name"],
        "title": ev.get("summary") or "(Sin título)",
        "location": (ev.get("location") or "").strip(),
        "description": description,
        "color": color,
        "meet": meet_link(ev, description),
        "link": ev.get("htmlLink", ""),
    }
    if "date" in start:
        last = datetime.strptime(end.get("date", start["date"]), "%Y-%m-%d") - timedelta(days=1)
        last_s = max(last.strftime("%Y-%m-%d"), start["date"])
        return {**base, "allDay": True, "startDate": start["date"], "endDate": last_s, "start": 0, "end": 0}
    if "dateTime" in start:
        return {**base, "allDay": False, "startDate": "", "endDate": "", "start": parse_dt(start["dateTime"]), "end": parse_dt(end.get("dateTime", start["dateTime"]))}
    return None


def local_midnight(day):
    return datetime.strptime(day, "%Y-%m-%d").astimezone()


def cmd_events(a):
    d_from, d_to = opt(a, "--from"), opt(a, "--to")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", d_from) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", d_to):
        return {"ok": False, "error": "Falta --from y --to (AAAA-MM-DD)"}
    t_min = local_midnight(d_from).isoformat()
    t_max = (local_midnight(d_to) + timedelta(days=1)).isoformat()
    skip_holidays = "--skip-holidays" in a

    lst = api_get("/users/me/calendarList", {"minAccessRole": "reader", "maxResults": 250})
    cals, email = [], ""
    for c in lst.get("items", []):
        if c.get("primary"):
            email = c.get("id", "")
        if not c.get("selected"):
            continue
        cid = c.get("id", "")
        if cid.startswith("addressbook#") or (skip_holidays and cid.endswith(HOLIDAY_ID)):
            continue
        cals.append({"id": cid, "name": c.get("summaryOverride") or c.get("summary") or cid, "color": c.get("backgroundColor", "")})
    try:
        colors = api_get("/colors").get("event", {})
        palette = {k: v.get("background", "") for k, v in colors.items()}
    except CalError:
        palette = {}

    events = []
    for cal in cals:
        token = None
        while True:
            params = {"singleEvents": "true", "orderBy": "startTime", "timeMin": t_min, "timeMax": t_max, "maxResults": 250}
            if token:
                params["pageToken"] = token
            page = api_get("/calendars/%s/events" % quote(cal["id"], safe=""), params)
            for ev in page.get("items", []):
                n = normalize_event(ev, cal, palette)
                if n:
                    events.append(n)
            token = page.get("nextPageToken")
            if not token:
                break
    if email:
        try:
            t = load_token()
            if t.get("email") != email:
                t["email"] = email
                save_token(t)
        except CalError:
            pass
    return {"ok": True, "updated": now_ms(), "email": email, "calendars": cals, "events": events}


# ───────────────────────── feriados ─────────────────────────

def parse_ics(text):
    lines = []
    for raw in text.replace("\r\n", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    events, cur = [], None
    for ln in lines:
        if ln == "BEGIN:VEVENT":
            cur = {}
        elif ln == "END:VEVENT":
            if cur is not None and "start" in cur:
                events.append(cur)
            cur = None
        elif cur is not None and ":" in ln:
            key, val = ln.split(":", 1)
            name = key.split(";")[0]
            if name == "DTSTART" and "VALUE=DATE" in key:
                cur["start"] = val
            elif name == "DTEND" and "VALUE=DATE" in key:
                cur["end"] = val
            elif name == "SUMMARY":
                cur["title"] = unescape_ics(val)
            elif name == "DESCRIPTION":
                cur["desc"] = unescape_ics(val)
    return events


def unescape_ics(v):
    return v.replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def cmd_holidays(a):
    cid = opt(a, "--id")
    if not cid:
        return {"ok": False, "error": "Falta --id"}
    r = http("GET", "https://calendar.google.com/calendar/ical/%s/public/basic.ics" % quote(cid, safe=""))
    if r.status_code != 200:
        return {"ok": False, "error": "No se encontró el calendario de feriados (HTTP %d)" % r.status_code}
    r.encoding = "utf-8"
    result = []
    for e in parse_ics(r.text):
        try:
            d0 = datetime.strptime(e["start"], "%Y%m%d")
            d1 = datetime.strptime(e.get("end", e["start"]), "%Y%m%d")
        except ValueError:
            continue
        first = (e.get("desc") or "").split("\n")[0].strip().lower()
        kind = "holiday" if first in HOLIDAY_WORDS else "observance"
        day = d0
        while day < max(d1, d0 + timedelta(days=1)):
            result.append({"date": day.strftime("%Y-%m-%d"), "title": e.get("title", ""), "kind": kind})
            day += timedelta(days=1)
    result.sort(key=lambda x: (x["date"], x["kind"] != "holiday", x["title"]))
    return {"ok": True, "updated": now_ms(), "events": result}


# ───────────────────────── sesión ─────────────────────────

PAGE = """<!doctype html><html lang="es"><meta charset="utf-8"><title>Stixshell</title>
<body style="font-family:sans-serif;background:#0a0a0f;color:#cdd6f4;display:grid;place-items:center;height:100vh;margin:0">
<div style="text-align:center"><h2>%s</h2><p>%s</p></div></body></html>"""


def cmd_login(a):
    client = load_client()
    timeout = int(opt(a, "--timeout", "180"))
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(64)).rstrip(b"=").decode()
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(16)
    result = {}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            q = parse_qs(urlparse(self.path).query)
            if urlparse(self.path).path != "/" or ("code" not in q and "error" not in q):
                self.send_response(404)
                self.end_headers()
                return
            if q.get("state", [""])[0] != state:
                body, ok = PAGE % ("No se pudo conectar", "La respuesta no coincide. Vuelve a intentarlo desde la shell."), False
            elif "error" in q:
                result["error"] = "denied"
                body, ok = PAGE % ("No se conectó", "Cancelaste el permiso. Puedes cerrar esta pestaña."), False
            else:
                result["code"] = q["code"][0]
                body, ok = PAGE % ("Listo", "Tu calendario ya está conectado. Puedes cerrar esta pestaña."), True
            data = body.encode()
            self.send_response(200 if ok else 400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    server.timeout = 1
    redirect = "http://127.0.0.1:%d" % server.server_port
    url = (client.get("auth_uri") or AUTH_URL) + "?" + urlencode({
        "client_id": client["client_id"], "redirect_uri": redirect, "response_type": "code", "scope": SCOPE,
        "access_type": "offline", "prompt": "consent", "state": state,
        "code_challenge": challenge, "code_challenge_method": "S256",
    })
    try:
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    except OSError:
        subprocess.Popen(["firefox", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    deadline = time.time() + timeout
    while time.time() < deadline and "code" not in result and "error" not in result:
        server.handle_request()
    server.server_close()
    if "code" not in result:
        return {"ok": False, "error": result.get("error", "timeout")}
    j = token_request(client, {"grant_type": "authorization_code", "code": result["code"], "code_verifier": verifier, "redirect_uri": redirect})
    if not j.get("refresh_token"):
        return {"ok": False, "error": "Google no entregó la sesión; revoca el acceso en myaccount.google.com/permissions y reintenta"}
    save_token({"access_token": j["access_token"], "refresh_token": j["refresh_token"], "expires_at": time.time() + int(j.get("expires_in", 3600)), "scope": j.get("scope", ""), "email": ""})
    email = ""
    try:
        for c in api_get("/users/me/calendarList", {"minAccessRole": "reader", "maxResults": 250}).get("items", []):
            if c.get("primary"):
                email = c.get("id", "")
        t = load_token()
        t["email"] = email
        save_token(t)
    except CalError:
        pass
    return {"ok": True, "email": email}


def cmd_logout(a):
    try:
        t = load_token()
        try:
            requests.post(REVOKE_URL, data={"token": t["refresh_token"]}, timeout=TIMEOUT)
        except requests.RequestException:
            pass
    except CalError:
        pass
    try:
        os.remove(token_path())
    except OSError:
        pass
    return {"ok": True}


def cmd_status(a):
    try:
        load_client()
        has_client = True
    except CalError:
        has_client = False
    try:
        t = load_token()
        return {"client": has_client, "connected": True, "email": t.get("email", "")}
    except CalError:
        return {"client": has_client, "connected": False, "email": ""}


def opt(a, flag, default=""):
    return a[a.index(flag) + 1] if flag in a and a.index(flag) + 1 < len(a) else default


COMMANDS = {"status": cmd_status, "login": cmd_login, "logout": cmd_logout, "events": cmd_events, "holidays": cmd_holidays}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        out({"ok": False, "error": "Uso: gcal.py status|login|logout|events|holidays"})
        return 2
    try:
        out(COMMANDS[sys.argv[1]](sys.argv[2:]))
    except CalError as e:
        out({"ok": False, "error": e.code})
    except Exception as e:  # noqa: BLE001: la shell solo necesita el texto
        out({"ok": False, "error": "%s: %s" % (type(e).__name__, str(e)[:120])})
    return 0


if __name__ == "__main__":
    sys.exit(main())
