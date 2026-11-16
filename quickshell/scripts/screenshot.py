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

  screenshot.py ocr <imagen> [--crop x,y,w,h] [--lang spa+eng] [--upscale 1200]
      Lee el texto de la imagen: primero un código QR (pyzbar) y, si no hay, OCR con tesseract (en Void el
      programa se llama tesseract-ocr). Antes de leer se pasa a grises, se invierte si el fondo es oscuro y se
      agranda 2× si es chica. Responde con JSON: { ok, kind: "qr" | "text", text } o { ok: false, error }.
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


def ocr(args):
    src = args[0]
    crop = None
    lang = "spa+eng"
    upscale = 1200
    i = 1
    while i + 1 < len(args):
        if args[i] == "--crop":
            crop = [int(round(float(v))) for v in args[i + 1].split(",")]
        elif args[i] == "--lang":
            lang = args[i + 1]
        elif args[i] == "--upscale":
            upscale = int(args[i + 1])
        i += 2

    from PIL import Image, ImageOps, ImageStat

    img = Image.open(src).convert("RGB")
    if crop:
        x, y, w, h = crop
        img = img.crop((max(0, x), max(0, y), min(img.width, x + w), min(img.height, y + h)))

    # Código QR primero (uno por línea)
    try:
        from pyzbar import pyzbar

        codes = pyzbar.decode(img) or pyzbar.decode(ImageOps.invert(img))
        found = [c.data.decode("utf-8", "replace") for c in codes if c.type == "QRCODE"]
        if found:
            print(json.dumps({"ok": True, "kind": "qr", "text": "\n".join(found)}))
            return
    except ImportError:
        pass

    # En Void el programa se llama tesseract-ocr
    exe = shutil.which("tesseract") or shutil.which("tesseract-ocr")
    if not exe:
        print(json.dumps({"ok": False, "error": "Instala tesseract-ocr (y los idiomas spa y eng)"}))
        return
    have = subprocess.run([exe, "--list-langs"], capture_output=True, text=True).stdout.split()
    langs = [l for l in lang.split("+") if l in have]
    if not langs:
        print(json.dumps({"ok": False, "error": "Instala tesseract-ocr-spa o tesseract-ocr-eng"}))
        return

    # Tesseract lee mejor texto oscuro sobre claro y, hasta cierto tamaño, letras más grandes
    gray = ImageOps.autocontrast(img.convert("L"))
    if ImageStat.Stat(gray).mean[0] < 128:
        gray = ImageOps.invert(gray)

    def read(scale):
        g = gray if scale == 1 else gray.resize((gray.width * scale, gray.height * scale), Image.LANCZOS)
        g = ImageOps.expand(g, border=16, fill=255)
        work = src + ".ocr.png"
        g.save(work, "PNG")
        try:
            out = subprocess.run([exe, work, "stdout", "-l", "+".join(langs), "--psm", "3", "tsv"], capture_output=True, text=True, timeout=60)
        finally:
            os.remove(work)
        # tsv: nivel, página, bloque, párrafo, línea, palabra, x, y, w, h, confianza, texto
        words, confs = [], []
        for row in out.stdout.splitlines()[1:]:
            c = row.split("\t")
            if len(c) < 12 or c[0] != "5" or c[11].strip() == "":
                continue
            words.append((c[2], c[3], c[4], c[11]))
            confs.append(float(c[10]))
        lines, last = [], None
        for blk, par, line, w in words:
            key = (blk, par, line)
            if key != last:
                # Línea nueva; una línea en blanco entre bloques y párrafos distintos
                if last is not None and (blk, par) != last[:2]:
                    lines.append("")
                lines.append("")
                last = key
            lines[-1] = (lines[-1] + " " + w).strip()
        return "\n".join(lines).strip(), (sum(confs) / len(confs) if confs else 0)

    # Si es chica se prueba agrandada, y si la confianza no es buena también a su tamaño; gana la más segura
    best = read(2 if gray.width < upscale else 1)
    if gray.width < upscale and best[1] < 90:
        other = read(1)
        if other[1] > best[1]:
            best = other
    print(json.dumps({"ok": True, "kind": "text", "text": best[0]}))


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "freeze":
        freeze(a[1], a[2:])
    elif len(a) >= 2 and a[0] == "deliver":
        deliver(a[1:])
    elif len(a) >= 2 and a[0] == "ocr":
        ocr(a[1:])
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


main()
