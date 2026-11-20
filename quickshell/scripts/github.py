#!/usr/bin/env python3
"""Cuenta de GitHub para la shell (Preferencias → Cuentas). Todo responde JSON. Solo librería estándar.
  github.py status
      { connected, login, name, avatar, error }  error: offline | invalid
  github.py save-token            (el token por la entrada estándar)
      Comprueba el token con GitHub y lo guarda en ~/.config/stixshell/github-token (permisos 600).
  github.py logout
      Borra el token guardado. { ok }
  github.py device-start <client_id>
      Empieza el login por código de dispositivo: { user_code, verification_uri, device_code, interval, expires_in }
  github.py device-poll <client_id> <device_code> <interval> <expires_in>
      Espera a que se acepte el código en github.com/login/device y guarda el token. Responde como `status`.
El token lo lee también scripts/links.py (estado de los PR e issues de las tareas).
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

TOKEN_FILE = os.path.expanduser("~/.config/stixshell/github-token")
TIMEOUT = 15
UA = "stixshell/1.0"


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))


def read_token():
    try:
        with open(TOKEN_FILE) as f:
            return f.read().strip()
    except OSError:
        return ""


def write_token(token):
    os.makedirs(os.path.dirname(TOKEN_FILE), exist_ok=True)
    tmp = TOKEN_FILE + ".tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(token + "\n")
    os.replace(tmp, TOKEN_FILE)


def request(url, data=None, token=None):
    headers = {"Accept": "application/json", "User-Agent": UA}
    if token:
        headers["Authorization"] = "Bearer " + token
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read().decode())


def whoami(token):
    """→ { connected, login, name, avatar, error } con ese token."""
    if not token:
        return {"connected": False, "login": "", "name": "", "avatar": "", "error": ""}
    try:
        j = request("https://api.github.com/user", token=token)
        return {"connected": True, "login": j.get("login", ""), "name": j.get("name") or "", "avatar": j.get("avatar_url", ""), "error": ""}
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            return {"connected": False, "login": "", "name": "", "avatar": "", "error": "invalid"}
        return {"connected": False, "login": "", "name": "", "avatar": "", "error": "offline"}
    except Exception:
        return {"connected": False, "login": "", "name": "", "avatar": "", "error": "offline"}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        out(whoami(read_token()))
    elif cmd == "save-token":
        token = sys.stdin.read().strip()
        st = whoami(token)
        if st["connected"]:
            write_token(token)
        out(st)
    elif cmd == "logout":
        try:
            os.remove(TOKEN_FILE)
        except OSError:
            pass
        out({"ok": True})
    elif cmd == "device-start":
        try:
            j = request("https://github.com/login/device/code", {"client_id": sys.argv[2], "scope": "repo read:user"})
            out(j if "device_code" in j else {"error": j.get("error_description") or j.get("error") or "No se pudo empezar"})
        except Exception as e:
            out({"error": "offline" if isinstance(e, urllib.error.URLError) else str(e)})
    elif cmd == "device-poll":
        client, device = sys.argv[2], sys.argv[3]
        interval, expires = int(sys.argv[4]), int(sys.argv[5])
        end = time.time() + expires
        while time.time() < end:
            time.sleep(interval)
            try:
                j = request("https://github.com/login/oauth/access_token", {"client_id": client, "device_code": device, "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
            except Exception:
                continue
            if "access_token" in j:
                write_token(j["access_token"])
                out(whoami(j["access_token"]))
                return
            err = j.get("error")
            if err == "slow_down":
                interval += 5
            elif err in ("expired_token", "access_denied"):
                out({"connected": False, "error": "denied" if err == "access_denied" else "expired"})
                return
        out({"connected": False, "error": "expired"})
    else:
        out({"error": "comando desconocido"})


if __name__ == "__main__":
    main()
