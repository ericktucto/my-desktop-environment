#!/usr/bin/env python3
"""Apoyo del capturador de pantalla (services/screenshot/ScreenshotStore.qml).

  screenshot.py freeze <carpeta> <monitor>…
      Captura cada monitor con grim en <carpeta>/<monitor>.png y responde con JSON:
      { "focused": "eDP-1", "windows": [ { monitor, x, y, w, h, class, title } … ] }
      Las ventanas son las visibles (workspace activo de su monitor), de la de más arriba a la de más abajo,
      con x e y relativas a su monitor (px lógicos, como los de Hyprland).

  screenshot.py deliver <imagen> [--crop x,y,w,h] [--dest ruta] [--copy]
      Recorta (px reales de la imagen), guarda en <ruta> (si no existe, se agrega " 2", " 3"… al nombre) y
      copia al portapapeles con wl-copy. Responde con JSON: { "dest": ruta o "", "w": ancho, "h": alto }.
"""
import json
import os
import shutil
import subprocess
import sys


def hypr(what):
    out = subprocess.run(["hyprctl", "-j", what], capture_output=True, text=True, timeout=5)
    return json.loads(out.stdout)


def freeze(folder, outputs):
    # La carpeta es solo de la shell: se parte de cero
    shutil.rmtree(folder, ignore_errors=True)
    os.makedirs(folder, mode=0o700, exist_ok=True)
    for name in outputs:
        subprocess.run(["grim", "-o", name, os.path.join(folder, name + ".png")], check=True)

    monitors = hypr("monitors")
    clients = hypr("clients")
    by_id = {m["id"]: m for m in monitors}
    focused = next((m["name"] for m in monitors if m.get("focused")), outputs[0] if outputs else "")

    shown = []
    for c in clients:
        m = by_id.get(c.get("monitor"))
        if m is None or not c.get("mapped", True) or c.get("hidden"):
            continue
        ws = c.get("workspace", {}).get("id")
        special = m.get("specialWorkspace", {}).get("id", 0)
        # Visible: el workspace activo del monitor, o el especial (stash) si está abierto
        if ws != m.get("activeWorkspace", {}).get("id") and not (special and ws == special):
            continue
        shown.append(
            (
                0 if c.get("floating") else 1,
                c.get("focusHistoryID", 99),
                {
                    "monitor": m["name"],
                    "x": c["at"][0] - m["x"],
                    "y": c["at"][1] - m["y"],
                    "w": c["size"][0],
                    "h": c["size"][1],
                    "class": c.get("class", ""),
                    "title": c.get("title", ""),
                },
            )
        )
    # Las flotantes van sobre las demás; entre iguales, la de foco más reciente arriba
    shown.sort(key=lambda t: (t[0], t[1]))
    print(json.dumps({"focused": focused, "windows": [t[2] for t in shown]}))


def unique(path):
    if not os.path.exists(path):
        return path
    base, ext = os.path.splitext(path)
    n = 2
    while os.path.exists(f"{base} {n}{ext}"):
        n += 1
    return f"{base} {n}{ext}"


def deliver(args):
    src = args[0]
    crop = None
    dest = ""
    copy = False
    i = 1
    while i < len(args):
        if args[i] == "--crop":
            crop = [int(round(float(v))) for v in args[i + 1].split(",")]
            i += 2
        elif args[i] == "--dest":
            dest = args[i + 1]
            i += 2
        elif args[i] == "--copy":
            copy = True
            i += 1
        else:
            i += 1

    from PIL import Image

    img = Image.open(src)
    if crop:
        x, y, w, h = crop
        x0, y0 = max(0, x), max(0, y)
        x1, y1 = min(img.width, x + w), min(img.height, y + h)
        img = img.crop((x0, y0, x1, y1))
    img = img.convert("RGB")
    work = src + ".out.png"
    img.save(work, "PNG")

    final = ""
    if dest:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        final = unique(dest)
        shutil.copyfile(work, final)
    if copy:
        with open(work, "rb") as f:
            subprocess.run(["wl-copy", "--type", "image/png"], stdin=f, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(work)
    print(json.dumps({"dest": final, "w": img.width, "h": img.height}))


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "freeze":
        freeze(a[1], a[2:])
    elif len(a) >= 2 and a[0] == "deliver":
        deliver(a[1:])
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


main()
