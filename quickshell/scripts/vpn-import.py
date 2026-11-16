#!/usr/bin/env python3
"""Importar una VPN de WireGuard a NetworkManager (NetworkStore).

  vpn-import.py qr <imagen>        lee el QR de la imagen e imprime su texto (código 2 si no hay QR)
  vpn-import.py check [--hint X]   la configuración por stdin → JSON {ok, name, endpoint, address, error}
  vpn-import.py import <nombre>    la configuración por stdin → crea la conexión → JSON {ok, name, error}

La configuración lleva la clave privada: se escribe en $XDG_RUNTIME_DIR/stixshell/vpn con permisos 600 solo
mientras dura la importación y se borra enseguida.
"""
import json
import os
import re
import subprocess
import sys
import warnings

warnings.filterwarnings("ignore")

RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "stixshell", "vpn")


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


def cmd_check(hint):
    text = sys.stdin.read()
    conf = parse(text)
    err = ""
    if not conf["interface"]:
        err = "No es una configuración de WireGuard"
    elif "privatekey" not in conf["interface"]:
        err = "Falta la PrivateKey en [Interface]"
    elif not conf["peers"] or "publickey" not in conf["peers"][0]:
        err = "Falta el [Peer] con su PublicKey"
    endpoint = conf["peers"][0].get("endpoint", "") if conf["peers"] else ""
    if hint:
        name = clean_name(hint)
    else:
        host = endpoint.rsplit(":", 1)[0].strip("[]") if endpoint else ""
        name = clean_name("wg-" + host) if host else "wg-vpn"
    print(json.dumps({"ok": err == "", "name": name, "endpoint": endpoint,
                      "address": conf["interface"].get("address", ""), "error": err}))
    return 0


def cmd_import(name):
    text = sys.stdin.read()
    name = unique_name(clean_name(name))
    os.makedirs(RUN, mode=0o700, exist_ok=True)
    path = os.path.join(RUN, name + ".conf")
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "w") as f:
            f.write(text if text.endswith("\n") else text + "\n")
        r = subprocess.run(["nmcli", "connection", "import", "type", "wireguard", "file", path],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print(json.dumps({"ok": False, "name": name, "error": (r.stderr or r.stdout).strip()}))
            return 0
        # Se conecta a mano: sin conexión automática
        subprocess.run(["nmcli", "connection", "modify", name, "connection.autoconnect", "no"], capture_output=True)
        print(json.dumps({"ok": True, "name": name, "error": ""}))
        return 0
    finally:
        try:
            os.remove(path)
        except OSError:
            pass


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "qr":
        return cmd_qr(a[1])
    if a and a[0] == "check":
        return cmd_check(a[a.index("--hint") + 1] if "--hint" in a and a.index("--hint") + 1 < len(a) else "")
    if len(a) >= 2 and a[0] == "import":
        return cmd_import(a[1])
    print(__doc__, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
