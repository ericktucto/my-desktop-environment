#!/usr/bin/env python3
"""Órdenes de nmcli que piden más que una línea (services/network/NetworkStore.qml). Todo responde JSON.

  net.py profile (--ssid <nombre> | --dev <dispositivo>)
      Perfil guardado de una red Wi-Fi (por SSID) o cableada (por dispositivo) y sus datos en vivo:
      { ok, found, uuid, name, method, addresses, gateway, dns, ignoreAutoDns, autoconnect, security,
        live: { device, ip, gateway, dns, mac } }
  net.py set-ip <uuid> --method auto|manual [--address 192.168.1.50/24] [--gateway 192.168.1.1]
                       --dns auto|"1.1.1.1,1.0.0.1" [--autoconnect yes|no] [--dev <dispositivo>]
      Valida y guarda; si hay dispositivo, aplica en caliente (reapply) o reconecta.
  net.py share <uuid>
      { ok, ssid, security: WPA|SAE|nopass, hidden, psk, payload } con la cadena WIFI:…;; del QR.
  net.py enterprise <ssid> --eap peap|ttls --phase2 mschapv2|pap --identity U [--anonymous A]
                           [--ca system|none|<archivo>] [--domain D] [--save-only]   (la contraseña por stdin)
      Crea el perfil 802.1X y conecta. { ok, uuid, error }.
  net.py portal-url <dirección de verificación>
      Página de inicio de sesión de un portal cautivo: { ok, url }. Pide la dirección de verificación sin seguir
      redirecciones y devuelve a dónde la manda el router (o la de un meta refresh); si responde otra cosa,
      la misma dirección. Sin respuesta, ok es false.
"""
import ipaddress
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


def out(obj):
    print(json.dumps(obj))


def nmcli(*args, stdin=None):
    return subprocess.run(["nmcli"] + list(args), capture_output=True, text=True, input=stdin)


def err_text(r):
    e = (r.stderr or r.stdout).strip()
    if re.search(r"not authorized|insufficient privileges|permission", e, re.I):
        return "Falta el permiso de NetworkManager (system/networkmanager.sh)"
    return e.splitlines()[-1][:120] if e else "No se pudo aplicar"


def opt(a, flag, default=""):
    return a[a.index(flag) + 1] if flag in a and a.index(flag) + 1 < len(a) else default


def get(uuid, *fields):
    """Valores de los campos de un perfil, en el mismo orden."""
    r = nmcli("-g", ",".join(fields), "connection", "show", "uuid", uuid)
    lines = r.stdout.split("\n")
    return [lines[i] if i < len(lines) else "" for i in range(len(fields))]


def profiles(kind):
    r = nmcli("-t", "-f", "NAME,UUID,TYPE", "connection", "show")
    rows = []
    for line in r.stdout.splitlines():
        # NAME puede traer ":" escapados con \; el UUID y el tipo no
        m = re.match(r"^(.*):([0-9a-f-]{36}):(\S+)$", line)
        if m and m.group(3) == kind:
            rows.append((m.group(1).replace("\\:", ":").replace("\\\\", "\\"), m.group(2)))
    return rows


def cmd_profile(a):
    ssid, dev = opt(a, "--ssid"), opt(a, "--dev")
    uuid, name = "", ""
    if ssid:
        for n, u in profiles("802-11-wireless"):
            if get(u, "802-11-wireless.ssid")[0] == ssid:
                uuid, name = u, n
                break
    elif dev:
        active = nmcli("-g", "GENERAL.CONNECTION", "device", "show", dev).stdout.strip()
        for n, u in profiles("802-3-ethernet"):
            if n == active or get(u, "connection.interface-name")[0] == dev:
                uuid, name = u, n
                if n == active:
                    break
    if not uuid:
        out({"ok": True, "found": False})
        return
    method, addrs, gw, dns, ignore, auto, key = get(
        uuid, "ipv4.method", "ipv4.addresses", "ipv4.gateway", "ipv4.dns", "ipv4.ignore-auto-dns", "connection.autoconnect",
        "802-11-wireless-security.key-mgmt")
    live = None
    live_dev = dev or nmcli("-g", "GENERAL.DEVICES", "connection", "show", "uuid", uuid).stdout.strip()
    if live_dev:
        r = nmcli("-g", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "device", "show", live_dev)
        f = r.stdout.split("\n")
        if len(f) >= 4 and f[0]:
            live = {"device": live_dev, "ip": f[0].replace("|", ", "), "gateway": f[1], "dns": f[2].replace("|", ", "), "mac": f[3].replace("\\:", ":")}
    out({
        "ok": True, "found": True, "uuid": uuid, "name": name, "method": method,
        "addresses": addrs.replace(" | ", ", ").replace("|", ", "), "gateway": gw,
        "dns": dns.replace("|", ", "), "ignoreAutoDns": ignore == "yes", "autoconnect": auto == "yes",
        "security": key, "live": live,
    })


def cmd_set_ip(uuid, a):
    method = opt(a, "--method", "auto")
    dns = opt(a, "--dns", "auto")
    args = []
    if method == "manual":
        addr, gw = opt(a, "--address"), opt(a, "--gateway")
        try:
            iface = ipaddress.ip_interface(addr)
            if iface.version != 4 or "/" not in addr:
                raise ValueError
        except ValueError:
            return out({"ok": False, "error": "La IP debe llevar el prefijo, por ejemplo 192.168.1.50/24"})
        if gw:
            try:
                if ipaddress.ip_address(gw) not in iface.network:
                    return out({"ok": False, "error": "La puerta de enlace no está en la misma red que la IP"})
            except ValueError:
                return out({"ok": False, "error": "La puerta de enlace no es una dirección válida"})
        args += ["ipv4.method", "manual", "ipv4.addresses", addr, "ipv4.gateway", gw]
    else:
        args += ["ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", ""]
    if dns == "auto":
        args += ["ipv4.dns", "", "ipv4.ignore-auto-dns", "no"]
    else:
        servers = [s.strip() for s in dns.split(",") if s.strip()]
        for s in servers:
            try:
                ipaddress.ip_address(s)
            except ValueError:
                return out({"ok": False, "error": "DNS no válido: " + s})
        if not servers:
            return out({"ok": False, "error": "Falta el servidor DNS"})
        args += ["ipv4.dns", ",".join(servers), "ipv4.ignore-auto-dns", "yes"]
    if opt(a, "--autoconnect"):
        args += ["connection.autoconnect", opt(a, "--autoconnect")]
    r = nmcli("connection", "modify", "uuid", uuid, *args)
    if r.returncode != 0:
        return out({"ok": False, "error": err_text(r)})
    dev = opt(a, "--dev")
    applied = "saved"
    if dev:
        # En caliente si se puede; si no, se reconecta (un segundo sin red)
        if nmcli("device", "reapply", dev).returncode == 0:
            applied = "reapplied"
        elif nmcli("connection", "up", "uuid", uuid).returncode == 0:
            applied = "reconnected"
        else:
            return out({"ok": False, "error": "Se guardó, pero no se pudo aplicar"})
    out({"ok": True, "applied": applied})


def wifi_escape(s):
    return re.sub(r'([\\;,:"])', r"\\\1", s)


def cmd_share(uuid):
    ssid, key, hidden = get(uuid, "802-11-wireless.ssid", "802-11-wireless-security.key-mgmt", "802-11-wireless.hidden")
    security = {"": "nopass", "none": "nopass", "sae": "SAE"}.get(key, "WPA")
    psk = ""
    if security != "nopass":
        r = nmcli("-s", "-g", "802-11-wireless-security.psk", "connection", "show", "uuid", uuid)
        psk = r.stdout.strip()
        if not psk:
            return out({"ok": False, "error": "La contraseña no está guardada"})
    payload = "WIFI:T:%s;S:%s;" % (security, wifi_escape(ssid))
    if psk:
        payload += "P:%s;" % wifi_escape(psk)
    if hidden == "yes":
        payload += "H:true;"
    payload += ";"
    out({"ok": True, "ssid": ssid, "security": security, "hidden": hidden == "yes", "psk": psk, "payload": payload})


def cmd_enterprise(ssid, a):
    password = sys.stdin.read().rstrip("\n")
    eap, phase2, ident = opt(a, "--eap", "peap"), opt(a, "--phase2", "mschapv2"), opt(a, "--identity")
    if not ident or not password:
        return out({"ok": False, "error": "Faltan el usuario o la contraseña"})
    # Un perfil anterior con el mismo nombre de red se reemplaza
    for n, u in profiles("802-11-wireless"):
        if get(u, "802-11-wireless.ssid")[0] == ssid:
            nmcli("connection", "delete", "uuid", u)
    dev = ""
    for line in nmcli("-t", "-f", "DEVICE,TYPE", "device").stdout.splitlines():
        d, _, t = line.partition(":")
        if t == "wifi":
            dev = d
            break
    args = ["connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "wifi-sec.key-mgmt", "wpa-eap",
            "802-1x.eap", eap, "802-1x.phase2-auth", phase2, "802-1x.identity", ident]
    if dev:
        args += ["ifname", dev]
    if opt(a, "--anonymous"):
        args += ["802-1x.anonymous-identity", opt(a, "--anonymous")]
    ca = opt(a, "--ca", "system")
    if ca == "system":
        args += ["802-1x.system-ca-certs", "yes"]
    elif ca != "none":
        args += ["802-1x.ca-cert", ca]
    if opt(a, "--domain"):
        args += ["802-1x.domain-suffix-match", opt(a, "--domain")]
    r = nmcli(*args)
    m = re.search(r"\(([0-9a-f-]{36})\)", r.stdout + r.stderr)
    if r.returncode != 0 or not m:
        return out({"ok": False, "error": err_text(r)})
    uuid = m.group(1)
    # La contraseña no va en la línea de órdenes: el editor de nmcli la lee por stdin y se guarda en el perfil
    nmcli("connection", "modify", "uuid", uuid, "802-1x.password-flags", "0")
    nmcli("connection", "edit", "uuid", uuid, stdin="set 802-1x.password %s\nsave\nquit\n" % password)
    if "--save-only" in a:
        return out({"ok": True, "uuid": uuid, "error": ""})
    up = nmcli("connection", "up", "uuid", uuid)
    if up.returncode != 0:
        return out({"ok": False, "uuid": uuid, "error": "No se pudo conectar: revisa el usuario y la contraseña"})
    out({"ok": True, "uuid": uuid, "error": ""})


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def cmd_portal_url(check):
    opener = urllib.request.build_opener(NoRedirect)
    req = urllib.request.Request(check, headers={"User-Agent": "Mozilla/5.0", "Cache-Control": "no-cache"})
    try:
        r = opener.open(req, timeout=5)
        status, headers, body = r.status, r.headers, r.read(65536).decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        status, headers, body = e.code, e.headers, e.read(65536).decode("utf-8", "replace")
    except (urllib.error.URLError, OSError, ValueError):
        return out({"ok": False, "url": ""})
    loc = headers.get("Location", "")
    if status in (301, 302, 303, 307, 308) and loc:
        return out({"ok": True, "url": urllib.parse.urljoin(check, loc)})
    m = re.search(r"http-equiv=[\"']?refresh[\"']?[^>]*content=[\"'][^\"']*url=([^\"'>\s]+)", body, re.I) or re.search(r"(?:window\.)?location(?:\.href)?\s*=\s*[\"']([^\"']+)[\"']", body, re.I)
    if m:
        return out({"ok": True, "url": urllib.parse.urljoin(check, m.group(1))})
    out({"ok": True, "url": check})


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "portal-url":
        return cmd_portal_url(a[1])
    if a and a[0] == "profile":
        return cmd_profile(a[1:])
    if len(a) >= 2 and a[0] == "set-ip":
        return cmd_set_ip(a[1], a[2:])
    if len(a) >= 2 and a[0] == "share":
        return cmd_share(a[1])
    if len(a) >= 2 and a[0] == "enterprise":
        return cmd_enterprise(a[1], a[2:])
    print(__doc__, file=sys.stderr)
    sys.exit(2)


main()
