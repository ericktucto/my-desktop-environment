#!/usr/bin/env python3
"""Colores de la shell según el wallpaper (services/theme/ThemeStore.qml). Pillow saca los colores reales de la
imagen; de ellos salen «combinaciones» (un fondo y un acento, como «Lila + verde») y con la elegida se calculan
todos los colores de la shell y de las apps.

  theme.py apply --mode scheme --image <ruta> [--combo <id>|neutral] [--tint tinted|vivid] [--apps kitty,gtk]
      Del wallpaper. `--combo` elige la combinación (sin ella, o si ya no existe, la más parecida o la primera);
      `neutral` es la primera con el fondo del sistema. `--tint` es qué tan teñido sale el fondo (Sutil o Intensa).
      `--apps` son las apps que también toman el fondo (kitty y gtk); el acento lo toman todas.
  theme.py apply --mode accent --image <ruta>        (como `--mode scheme --combo neutral`)
  theme.py apply --mode custom --color rrggbb [--apps …]
      Solo el acento, el color elegido (no hace falta imagen ni Pillow).
  theme.py palette <ruta>                            (los colores de la imagen y sus combinaciones)

`apply` guarda ~/.cache/stixshell/theme.json (lo lee Theme.qml) y escribe, si existen sus carpetas:
  ~/.config/hypr/colors.lua · ~/.config/hypr/hyprlock-colors.conf · ~/.config/kitty/colors.conf
  ~/.config/gtk-3.0/gtk.css y ~/.config/gtk-4.0/gtk.css (solo si no son enlaces: ver system/adw-gtk3.sh)
Responde con JSON: { ok, error?, palette?, combos?, combo? }.
"""
import hashlib
import json
import math
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "stixshell")
CONFIG = os.path.join(HOME, ".config")
PALETTE_VERSION = 2


def fail(msg):
    print(json.dumps({"ok": False, "error": msg}))
    sys.exit(1)


# ── Color ──
def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def lum(h):
    def f(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (f(c) for c in rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def alpha(h, a):
    """#rrggbb con transparencia → #aarrggbb (así lo lee QML)."""
    return "#%02x%s" % (round(a * 255), h.lstrip("#"))


def rgba(h, a=1.0):
    """Para hyprlang: rgba(rrggbbaa)."""
    return "rgba(%s%02x)" % (h.lstrip("#")[-6:], round(a * 255))


def mix(a, b, t):
    ra, rb = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(round(x + (y - x) * t) for x, y in zip(ra, rb))


def _lin(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _gam(x):
    x = min(1.0, max(0.0, x))
    return round((12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055) * 255)


def oklab(h):
    r, g, b = (_lin(c) for c in rgb(h))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def oklch(h):
    L, a, b = oklab(h)
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def _linear_rgb(L, C, H):
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def _in_gamut(rgbv):
    return all(-1e-4 <= c <= 1 + 1e-4 for c in rgbv)


def from_oklch(L, C, H):
    """OKLCH → #rrggbb. Si no cabe en sRGB se baja el croma (el tono y el brillo se conservan)."""
    L = min(1.0, max(0.0, L))
    if not _in_gamut(_linear_rgb(L, C, H)):
        lo, hi = 0.0, C
        for _ in range(24):
            mid = (lo + hi) / 2
            if _in_gamut(_linear_rgb(L, mid, H)):
                lo = mid
            else:
                hi = mid
        C = lo
    return "#%02x%02x%02x" % tuple(_gam(c) for c in _linear_rgb(L, C, H))


def hue_diff(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def lighten_to(color, bg, ratio=3.0):
    """Sube el brillo de `color` (sin cambiar el tono) hasta que contraste `ratio` con `bg`."""
    if contrast(color, bg) >= ratio:
        return color
    L, C, H = oklch(color)
    out = color
    while L < 0.98 and contrast(out, bg) < ratio:
        L += 0.01
        out = from_oklch(L, C, H)
    return out


def hue_name(h):
    for limit, name in ((15, "rojo"), (40, "rojo"), (80, "naranja"), (115, "amarillo"), (170, "verde"), (200, "turquesa"), (235, "cian"), (280, "azul"), (325, "lila"), (345, "rosa")):
        if h < limit:
            return name
    return "rojo"


# ── Paleta de la imagen ──
def extract_palette(image):
    """Hasta 12 colores reales de la imagen: [{hex, share}], de mayor a menor presencia."""
    try:
        from PIL import Image
    except ImportError:
        fail("Instala python3-Pillow para usar los colores de la imagen")
    try:
        im = Image.open(image).convert("RGB")
    except Exception:
        fail("no se pudo leer la imagen")
    im.thumbnail((200, 200))
    q = im.quantize(colors=24, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()
    counts = q.getcolors() or []
    total = sum(c for c, _ in counts) or 1
    items = []
    for c, i in sorted(counts, reverse=True):
        items.append({"hex": "#%02x%02x%02x" % tuple(pal[i * 3 : i * 3 + 3]), "share": c / total})
    # Se juntan los casi iguales (se queda el que más pesa) hasta que sean 12 o menos
    thr = 0.035
    while True:
        kept = []
        for it in items:
            lab = oklab(it["hex"])
            for k in kept:
                if math.dist(lab, k["lab"]) < thr:
                    k["share"] += it["share"]
                    break
            else:
                kept.append({"hex": it["hex"], "share": it["share"], "lab": lab})
        if len(kept) <= 12:
            break
        thr += 0.01
    kept.sort(key=lambda k: k["share"], reverse=True)
    return [{"hex": k["hex"], "share": round(k["share"], 4)} for k in kept]


def families(pal):
    """Los colores con croma suficiente, agrupados por tono (±30°)."""
    fams = []
    for it in sorted(pal, key=lambda i: i["share"], reverse=True):
        L, C, H = oklch(it["hex"])
        if C < 0.04:
            continue
        m = {"hex": it["hex"], "share": it["share"], "L": L, "C": C, "h": H}
        for f in fams:
            if hue_diff(H, f["h"]) <= 30:
                f["members"].append(m)
                f["share"] += m["share"]
                break
        else:
            fams.append({"h": H, "share": m["share"], "members": [m]})
    for f in fams:
        f["maxC"] = max(m["C"] for m in f["members"])
        lit = [m for m in f["members"] if m["L"] >= 0.3] or f["members"]
        f["accent"] = max(lit, key=lambda m: m["C"])["hex"]
        f["rep"] = f["members"][0]["hex"]
        dark = [m for m in f["members"] if 0.18 <= m["L"] <= 0.30]
        f["dark"] = max(dark, key=lambda m: m["C"])["hex"] if dark else None
    return fams


def _bg_score(f):
    return f["share"] * (f["maxC"] + 0.05)


def _acc_score(f):
    return math.sqrt(f["share"]) * f["maxC"]


SYS_ISLAND = "#0a0a0f"
BLUE = "#2979ff"


def _own_accent(f):
    """El acento de una imagen de un solo tono: el mismo tono, más claro."""
    return from_oklch(0.78, min(0.15, max(0.08, f["maxC"] * 1.6)), f["h"])


def combos_of(pal):
    """Hasta 4 combinaciones de color y 2 con el fondo del sistema (neutras)."""
    fams = families(pal)
    vivid = [f for f in fams if f["maxC"] >= 0.08]
    out = []
    pairs = []
    for bg in sorted(fams, key=_bg_score, reverse=True)[:3]:
        # Otro tono y otro nombre: «Rojo + rojo» no se distingue
        accs = [f for f in vivid if f is not bg and hue_diff(f["h"], bg["h"]) >= 40 and hue_name(oklch(f["accent"])[2]) != hue_name(bg["h"])]
        if not accs:
            pairs.append((_bg_score(bg) * 0.5, bg, _own_accent(bg)))
        for a in accs:
            pairs.append((_bg_score(bg) * _acc_score(a), bg, a["accent"]))
    used = {}
    for _, bg, accent in sorted(pairs, key=lambda p: p[0], reverse=True):
        if len([o for o in out if o["bg"] != "none"]) >= 4 or used.get(bg["rep"], 0) >= 2:
            continue
        used[bg["rep"]] = used.get(bg["rep"], 0) + 1
        aname = hue_name(oklch(accent)[2])
        out.append({"bg": bg["rep"], "accent": accent, "name": (hue_name(bg["h"]), aname + (" claro" if aname == hue_name(bg["h"]) else "")), "fam": bg})
    # Neutras: el fondo del sistema y un color vivo de la imagen
    accs = [f["accent"] for f in sorted(vivid, key=_acc_score, reverse=True)[:2]]
    if not accs and fams:
        accs = [_own_accent(sorted(fams, key=_bg_score, reverse=True)[0])]
    if not accs:
        accs = [BLUE]
    for a in accs:
        out.append({"bg": "none", "accent": lighten_to(a, SYS_ISLAND), "name": ("neutro", hue_name(oklch(a)[2])), "fam": None})
    # Ids y nombres (los repetidos se distinguen por el orden)
    seen = {}
    res = []
    for c in out:
        name = "%s + %s" % (c["name"][0].capitalize(), c["name"][1])
        seen[name] = seen.get(name, 0) + 1
        if seen[name] > 1:
            name += " %d" % seen[name]
        fam = c["fam"]
        entry = {
            "id": "%s|%s" % (c["bg"].lstrip("#"), c["accent"].lstrip("#")),
            "bg": c["bg"],
            "accent": c["accent"],
            "name": name,
            "fam": {"h": fam["h"], "c": fam["maxC"], "dark": fam["dark"]} if fam else None,
        }
        entry["preview"] = {t: preview(shell_colors(entry["fam"], entry["accent"], t)) for t in TINTS}
        res.append(entry)
    return res


def pick_combo(combos, wanted):
    """La combinación pedida; si ya no existe, la más parecida; sin pedir nada, la primera."""
    if not wanted:
        return combos[0]
    if wanted == "neutral":
        return next((c for c in combos if c["bg"] == "none"), combos[0])
    for c in combos:
        if c["id"] == wanted:
            return c
    try:
        bgw, accw = wanted.split("|")
        accw = "#" + accw
        bgl = None if bgw == "none" else oklab("#" + bgw)
    except ValueError:
        return combos[0]

    def dist(c):
        d = math.dist(oklab(c["accent"]), oklab(accw))
        if bgl is None or c["bg"] == "none":
            return d + (0 if bgl is None and c["bg"] == "none" else 1)
        return d + math.dist(oklab(c["bg"]), bgl)

    return min(combos, key=dist)


def palette_of(image):
    """La paleta y las combinaciones de una imagen (con caché por ruta y fecha)."""
    try:
        st = os.stat(image)
    except OSError:
        fail("no se encontró la imagen")
    key = hashlib.sha1(("%d|%s|%d" % (PALETTE_VERSION, image, st.st_mtime_ns)).encode()).hexdigest()[:20]
    path = os.path.join(CACHE, "palettes", key + ".json")
    try:
        with open(path) as f:
            c = json.load(f)
        return c["palette"], c["combos"]
    except (OSError, ValueError, KeyError):
        pass
    pal = extract_palette(image)
    combos = combos_of(pal)
    try:
        write(path, json.dumps({"palette": pal, "combos": combos}))
    except OSError:
        pass
    return pal, combos


# ── Colores de la shell ──
# Intensidad del fondo: Sutil (tinted) o Intensa (vivid)
TINTS = ("tinted", "vivid")
BORDER_ALPHA = {"tinted": 0.35, "vivid": 0.60}
ACCENT_BORDER_ALPHA = 0.40


def preview(shell):
    return {k: shell[k] for k in ("island", "border", "text", "primary")} if "island" in shell else {"island": SYS_ISLAND, "border": shell["border"], "text": "#cdd6f4", "primary": shell["primary"]}


def shell_colors(fam, accent, tint):
    """Los colores de Theme.qml. `fam` = la familia del fondo ({h, c, dark}); sin ella (fondo del sistema) solo
    cambian el acento y su borde."""
    if fam is None:
        return {"primary": accent, "border": alpha(accent, ACCENT_BORDER_ALPHA)}
    if tint == "vivid":
        island = fam["dark"] or from_oklch(0.24, min(0.09, max(0.04, fam["c"] * 0.6)), fam["h"])
    else:
        island = from_oklch(0.16, min(0.035, fam["c"]), fam["h"])
    L, C, H = oklch(island)
    if C < 0.01:
        H = fam["h"]

    def tone(l, c):
        return from_oklch(l, c, H)

    text = lighten_to(tone(0.90, 0.015), island, 7.0)
    border = from_oklch(0.55, min(0.12, max(fam["c"], 0.04)), fam["h"])
    return {
        "island": island,
        "surfaceHigh": tone(min(L + 0.12, 0.5), C),
        "black": tone(0.10, 0.02),
        "text": text,
        "white": tone(0.96, 0.015),
        "gray": tone(0.80, 0.02),
        "subtext": tone(0.70, 0.02),
        "placeholder": tone(0.62, 0.02),
        "grayDark": tone(0.55, 0.02),
        "border": alpha(border, BORDER_ALPHA[tint]),
        "primary": lighten_to(accent, island, 3.0),
    }


# Los colores fijos del sistema (Theme.qml): sin fondo de la imagen solo cambia el acento
SYSTEM = {
    "surface_container_lowest": "#0a0a0f",
    "surface": "#121218",
    "surface_container_low": "#101015",
    "surface_container": "#16161d",
    "surface_container_high": "#1e1e26",
    "on_surface": "#cdd6f4",
    "on_surface_variant": "#b4bcd0",
    "outline": "#8a93a5",
    "outline_variant": "#3a3f4a",
    "error": "#ff5370",
}


def accent_data(accent, shell=None):
    """Roles de color para las apps (los mismos nombres de siempre): los del sistema con el acento o, con `shell`
    (colores de la shell con fondo), el fondo y el texto de la shell."""
    roles = dict(SYSTEM)
    if shell and "island" in shell:
        isl, high = shell["island"], shell["surfaceHigh"]
        roles.update(
            surface_container_lowest=isl,
            surface_container_low=isl,
            surface=mix(isl, high, 0.2),
            surface_container=mix(isl, high, 0.4),
            surface_container_high=high,
            on_surface=shell["text"],
            on_surface_variant=shell["gray"],
            outline=shell["subtext"],
            outline_variant=high,
        )
    roles["primary"] = accent
    roles["primary_container"] = mix(roles["surface_container_lowest"], accent, 0.35)
    return {"colors": {k: {"dark": {"color": v}} for k, v in roles.items()}}


def role(data, name):
    return data["colors"][name]["dark"]["color"]


# ── Apps ──
def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def hypr_files(sys_data, lock_data):
    d = os.path.join(CONFIG, "hypr")
    if not os.path.isdir(d):
        return
    active, inactive = rgba(role(sys_data, "primary")), rgba(role(sys_data, "outline_variant"))
    write(
        os.path.join(d, "colors.lua"),
        '-- Generado por scripts/theme.py (colores del wallpaper). No se commitea.\nreturn {\n    active = "%s",\n    inactive = "%s",\n}\n'
        % (active, inactive),
    )
    # En caliente, sin `hyprctl reload` (que volvería a aplicar todo hyprland.lua, espejo de monitor incluido)
    subprocess.run(
        ["hyprctl", "eval", 'hl.config({ general = { col = { active_border = "%s", inactive_border = "%s" } } })' % (active, inactive)],
        capture_output=True,
    )
    # El respaldo del bloqueo lleva siempre los colores de la shell
    write(
        os.path.join(d, "hyprlock-colors.conf"),
        "# Generado por scripts/theme.py (colores del wallpaper). No se commitea.\n"
        f"$surface = {rgba(role(lock_data, 'surface_container_lowest'))}\n"
        f"$accent = {rgba(role(lock_data, 'primary'))}\n"
        f"$text = {rgba(role(lock_data, 'on_surface'))}\n"
        f"$error = {rgba(role(lock_data, 'error'))}\n",
    )


def kitty_file(data):
    d = os.path.join(CONFIG, "kitty")
    if not os.path.isdir(d):
        return
    bg = role(data, "surface_container_lowest")
    fg = role(data, "on_surface")
    prim = role(data, "primary")
    # Los 16 colores: los de siempre (rojo, verde, amarillo, azul…) mezclados un poco con el acento
    fixed = ["#ff5370", "#00e676", "#ffb300", "#5c9cff", "#d580ff", "#1de9b6"]
    normal = [mix(c, prim, 0.2) for c in fixed]
    bright = [mix(c, "#ffffff", 0.25) for c in normal]
    lines = [
        "# Generado por scripts/theme.py (colores del wallpaper). No se commitea.",
        f"foreground {fg}",
        f"background {bg}",
        f"selection_foreground {bg}",
        f"selection_background {prim}",
        f"cursor {prim}",
        f"cursor_text_color {bg}",
        f"url_color {prim}",
        f"active_border_color {prim}",
        f"inactive_border_color {role(data, 'outline_variant')}",
        f"color0 {mix(bg, role(data, 'surface_container_high'), 0.5)}",
        f"color8 {role(data, 'outline')}",
        f"color7 {role(data, 'on_surface_variant')}",
        f"color15 {fg}",
    ]
    for i in range(6):
        lines.append(f"color{i + 1} {normal[i]}")
        lines.append(f"color{i + 9} {bright[i]}")
    write(os.path.join(d, "colors.conf"), "\n".join(lines) + "\n")
    subprocess.run(["pkill", "-USR1", "-x", "kitty"], capture_output=True)


def gtk_files(data, take_bg):
    r = lambda n: role(data, n)
    css = (
        "/* Generado por scripts/theme.py (colores del wallpaper). Pide adw-gtk3: system/adw-gtk3.sh */\n"
        f"@define-color accent_bg_color {mix(r('primary_container'), r('primary'), 0.35)};\n"
        "@define-color accent_fg_color #ffffff;\n"
        f"@define-color accent_color {r('primary')};\n"
    )
    # Sin el fondo de la imagen los fondos son los de adw-gtk3 (el sistema); solo se redefine el acento
    if take_bg:
        css += (
            f"@define-color window_bg_color {r('surface')};\n"
            f"@define-color window_fg_color {r('on_surface')};\n"
            f"@define-color view_bg_color {r('surface_container_lowest')};\n"
            f"@define-color view_fg_color {r('on_surface')};\n"
            f"@define-color headerbar_bg_color {r('surface_container')};\n"
            f"@define-color headerbar_fg_color {r('on_surface')};\n"
            f"@define-color headerbar_border_color {r('outline_variant')};\n"
            f"@define-color card_bg_color {r('surface_container_high')};\n"
            f"@define-color card_fg_color {r('on_surface')};\n"
            f"@define-color popover_bg_color {r('surface_container_high')};\n"
            f"@define-color popover_fg_color {r('on_surface')};\n"
            f"@define-color sidebar_bg_color {r('surface_container_low')};\n"
            f"@define-color sidebar_fg_color {r('on_surface')};\n"
            f"@define-color dialog_bg_color {r('surface_container')};\n"
            f"@define-color dialog_fg_color {r('on_surface')};\n"
            f"@define-color error_color {r('error')};\n"
        )
    # Solo con adw-gtk3 en uso: con otro tema (WhiteSur) estos colores lo desarmarían
    try:
        if "adw-gtk3" not in open(os.path.join(CONFIG, "gtk-3.0", "settings.ini")).read():
            return
    except OSError:
        return
    for v in ("gtk-3.0", "gtk-4.0"):
        d = os.path.join(CONFIG, v)
        p = os.path.join(d, "gtk.css")
        # Con un enlace (WhiteSur) escribir pisaría el tema: solo se escribe tras `system/adw-gtk3.sh`
        if os.path.isdir(d) and not os.path.islink(p):
            write(p, css)


def hex6(text):
    t = str(text).lstrip("#").lower()
    if len(t) != 6 or any(c not in "0123456789abcdef" for c in t):
        fail("color no válido (usa rrggbb)")
    return "#" + t


def apply(args):
    mode = args.get("mode") or ("scheme" if "image" in args else "custom")
    wanted = args.get("combo", "")
    if mode == "accent":
        # El modo de antes: el fondo del sistema y un color de la imagen
        mode, wanted = "scheme", wanted or "neutral"
    tint = args.get("tint", "vivid")
    if tint not in TINTS:
        tint = "vivid"
    apps = {a for a in args.get("apps", "").split(",") if a}
    color = ""
    pal, combos, combo = [], [], None
    if mode == "custom":
        # Sin imagen ni Pillow: el acento es exactamente el color elegido
        color = hex6(args.get("color", ""))
        shell = shell_colors(None, color, tint)
        accent = color
    else:
        if "image" not in args:
            fail("falta --image")
        mode = "scheme"
        pal, combos = palette_of(args["image"])
        combo = pick_combo(combos, wanted)
        shell = shell_colors(combo["fam"], combo["accent"], tint)
        accent = shell["primary"]
    # Las apps: los colores del sistema con el acento y, si la app lo pide, también el fondo de la imagen
    sys_data = accent_data(accent)
    full = accent_data(accent, shell)
    write(
        os.path.join(CACHE, "theme.json"),
        json.dumps(
            {
                "shell": shell,
                "mode": mode,
                "color": color,
                "image": args.get("image", ""),
                "combo": combo["id"] if combo else "",
                "wanted": wanted,
                "tint": tint,
                "apps": sorted(apps),
                "palette": pal,
                "combos": combos,
            }
        ),
    )
    jobs = (
        lambda: hypr_files(sys_data, full),
        lambda: kitty_file(full if "kitty" in apps else sys_data),
        lambda: gtk_files(full if "gtk" in apps else sys_data, "gtk" in apps and "island" in shell),
    )
    for job in jobs:
        try:
            job()
        except OSError:
            pass
    print(json.dumps({"ok": True, "palette": pal, "combos": combos, "combo": combo["id"] if combo else "", "color": color}))


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "palette":
        pal, combos = palette_of(a[1])
        print(json.dumps({"ok": True, "palette": pal, "combos": combos}))
    elif a and a[0] == "apply":
        args = {}
        i = 1
        while i + 1 < len(a):
            args[a[i].lstrip("-")] = a[i + 1]
            i += 2
        if "image" not in args and "color" not in args:
            fail("falta --image o --color")
        if args.get("mode") == "custom" and "color" not in args:
            fail("falta --color")
        apply(args)
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
