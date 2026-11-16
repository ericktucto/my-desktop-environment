#!/usr/bin/env python3
"""Importar una VPN de WireGuard u OpenVPN a NetworkManager (NetworkStore).

  vpn-import.py qr <imagen>        lee el QR de la imagen e imprime su texto (código 2 si no hay QR)
  vpn-import.py check [--hint X]   la configuración por stdin → JSON {ok, type, name, endpoint, address,
                                   fullTunnel, allowed, needsAuth, error}
  vpn-import.py import <nombre> [--type wireguard|openvpn] [--path archivo] [--user U]
                                   la configuración por stdin → crea la conexión → JSON {ok, name, error}
                                   (con --user, la contraseña va en la segunda línea de stdin de OpenVPN: ver cmd_import)

La configuración de WireGuard lleva la clave privada: se escribe en $XDG_RUNTIME_DIR/stixshell/vpn con permisos
600 solo mientras dura la importación y se borra enseguida. Un .ovpn se importa desde su archivo original
(muchos apuntan a certificados de la misma carpeta); si vino del portapapeles, de una copia temporal.
Una VPN de todo el tráfico queda con ipv4.dns-priority y ipv6.dns-priority negativos: mientras está activa,
NetworkManager usa solo su DNS (sin fugas).
"""
import json
import os
import re
import subprocess
import sys
import warnings

warnings.filterwarnings("ignore")

RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "stixshell", "vpn")
DNS_PRIORITY = "-50"  # el valor por omisión; la shell manda el suyo con --dns-priority (Config.network.vpnDnsPriority)


def parse(text):
    """Secciones de la configuración: {"interface": {clave: valor}, "peers": [{clave: valor}]}."""
    iface, peers, cur = {}, [], None
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        low = line.lower()
        if low == "[interface]":
            cur = iface
        elif low == "[peer]":
            cur = {}
            peers.append(cur)
        elif "=" in line and cur is not None:
            k, v = line.split("=", 1)
            cur[k.strip().lower()] = v.strip()
    return {"interface": iface, "peers": peers}


def clean_name(name):
    """Nombre de conexión y de interfaz: letras, números, - y _, máximo 15 caracteres."""
    name = re.sub(r"[^A-Za-z0-9_-]", "-", name).strip("-_")
    return (name or "vpn")[:15].rstrip("-_") or "vpn"


def unique_name(name):
    out = subprocess.run(["nmcli", "-t", "-f", "NAME", "connection", "show"], capture_output=True, text=True).stdout
    taken = set(out.splitlines())
    if name not in taken:
        return name
    for i in range(2, 100):
        suffix = f"-{i}"
        cand = name[: 15 - len(suffix)] + suffix
        if cand not in taken:
            return cand
    return name


def cmd_qr(path):
    try:
        from PIL import Image
        from pyzbar.pyzbar import decode
    except ImportError:
        print("falta python3-pyzbar", file=sys.stderr)
        return 3
    try:
        results = decode(Image.open(path).convert("L"))
    except OSError as e:
        print(f"no se pudo abrir la imagen: {e}", file=sys.stderr)
        return 2
    texts = [r.data.decode("utf-8", "replace") for r in results]
    # El de WireGuard primero, si hay varios códigos
    texts.sort(key=lambda t: "[interface]" not in t.lower())
    if not texts:
        return 2
    sys.stdout.write(texts[0])
    return 0


def kind_of(text):
    low = text.lower()
    if "[interface]" in low:
        return "wireguard"
    if re.search(r"(?m)^\s*(client|remote\s+\S+|dev\s+tun|proto\s+(udp|tcp))", low):
        return "openvpn"
    return ""


def parse_ovpn(text):
    """remote, redirect-gateway y auth-user-pass de un .ovpn (las líneas dentro de <ca>… no cuentan)."""
    remote, full, auth = "", False, False
    inline = False
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].split(";", 1)[0].strip()
        if line.startswith("</"):
            inline = False
            continue
        if line.startswith("<"):
            inline = True
            continue
        if inline or not line:
            continue
        p = line.split()
        if p[0] == "remote" and len(p) >= 2 and not remote:
            remote = p[1] + (":" + p[2] if len(p) >= 3 else "")
        elif p[0] == "redirect-gateway":
            full = True
        elif p[0] == "auth-user-pass" and len(p) == 1:
            auth = True
    return remote, full, auth


def cmd_check(hint):
    text = sys.stdin.read()
    kind = kind_of(text)
    err, endpoint, address, full, allowed, auth = "", "", "", False, [], False
    if kind == "wireguard":
        conf = parse(text)
        if "privatekey" not in conf["interface"]:
            err = "Falta la PrivateKey en [Interface]"
        elif not conf["peers"] or "publickey" not in conf["peers"][0]:
            err = "Falta el [Peer] con su PublicKey"
        endpoint = conf["peers"][0].get("endpoint", "") if conf["peers"] else ""
        address = conf["interface"].get("address", "")
        for peer in conf["peers"]:
            for net in peer.get("allowedips", "").split(","):
                net = net.strip()
                if net.endswith("/0"):
                    full = True
                elif net:
                    allowed.append(net)
    elif kind == "openvpn":
        endpoint, full, auth = parse_ovpn(text)
        if not endpoint:
            err = "Falta la línea remote del servidor"
    else:
        err = "No es una configuración de WireGuard ni de OpenVPN"
    if hint:
        name = clean_name(hint)
    else:
        host = endpoint.rsplit(":", 1)[0].strip("[]") if endpoint else ""
        name = clean_name(("wg-" if kind == "wireguard" else "ovpn-") + host) if host else ("wg-vpn" if kind != "openvpn" else "ovpn-vpn")
    print(json.dumps({"ok": err == "", "type": kind, "name": name, "endpoint": endpoint, "address": address,
                      "fullTunnel": full, "allowed": allowed, "needsAuth": auth, "error": err}))
    return 0


def nmcli(*args, stdin=None):
    return subprocess.run(["nmcli"] + list(args), capture_output=True, text=True, input=stdin)


def arg_after(a, flag):
    return a[a.index(flag) + 1] if flag in a and a.index(flag) + 1 < len(a) else ""


def cmd_import(name, a):
    text = sys.stdin.read()
    kind = arg_after(a, "--type") or kind_of(text) or "wireguard"
    path_arg = arg_after(a, "--path")
    user = arg_after(a, "--user")
    # Con usuario, la primera línea de stdin es la contraseña y el resto la configuración
    password = ""
    if user and kind == "openvpn":
        password, _, text = text.partition("\n")
    prio = arg_after(a, "--dns-priority") or DNS_PRIORITY
    name = unique_name(clean_name(name))
    full = kind_of(text) == "wireguard" and any(
        n.strip().endswith("/0") for p in parse(text)["peers"] for n in p.get("allowedips", "").split(",")
    ) or (kind == "openvpn" and parse_ovpn(text)[1])
    made = ""
    path = path_arg
    try:
        if not path:
            os.makedirs(RUN, mode=0o700, exist_ok=True)
            path = os.path.join(RUN, name + (".ovpn" if kind == "openvpn" else ".conf"))
            made = path
            fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(text if text.endswith("\n") else text + "\n")
        r = nmcli("connection", "import", "type", kind, "file", path)
        out = (r.stderr or r.stdout).strip()
        if r.returncode != 0:
            if kind == "openvpn" and re.search(r"plugin|complemento|not supported|unknown|desconocid", out, re.I):
                out = "Instala NetworkManager-openvpn"
            print(json.dumps({"ok": False, "name": name, "error": out}))
            return 0
        m = re.search(r"\(([0-9a-f-]{36})\)", out)
        uuid = m.group(1) if m else ""
        ref = ["uuid", uuid] if uuid else [name]
        # El nombre que se eligió, y sin conexión automática (se conecta a mano)
        nmcli("connection", "modify", *ref, "connection.id", name, "connection.autoconnect", "no")
        if full:
            # Mientras esté activa, solo se usa el DNS de la VPN
            nmcli("connection", "modify", *ref, "ipv4.dns-priority", prio, "ipv6.dns-priority", prio)
        if user and kind == "openvpn":
            nmcli("connection", "modify", *ref, "vpn.user-name", user, "+vpn.data", "password-flags=0")
            # La contraseña no va en la línea de órdenes: el editor de nmcli la lee por stdin
            nmcli("connection", "edit", *ref, stdin="set vpn.secrets password=%s\nsave\nquit\n" % password)
        print(json.dumps({"ok": True, "name": name, "error": ""}))
        return 0
    finally:
        if made:
            try:
                os.remove(made)
            except OSError:
                pass


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "qr":
        return cmd_qr(a[1])
    if a and a[0] == "check":
        return cmd_check(arg_after(a, "--hint"))
    if len(a) >= 2 and a[0] == "import":
        return cmd_import(a[1], a[2:])
    print(__doc__, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
