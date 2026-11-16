#!/usr/bin/env python3
"""Colores dinámicos según el wallpaper (services/theme/ThemeStore.qml). matugen genera la paleta Material 3;
este script calcula con ella los colores de la shell y escribe los de las apps.

  theme.py apply --image <ruta> [--scheme scheme-tonal-spot] [--index 0]
  theme.py apply --color 2979ff [--scheme …]          (sin wallpaper: las apps vuelven al azul de siempre)
  theme.py sources <ruta>                             (los colores fuente que matugen encuentra en la imagen)

`apply` guarda ~/.cache/stixshell/theme.json (lo lee Theme.qml) y escribe, si existen sus carpetas:
  ~/.config/hypr/colors.lua · ~/.config/hypr/hyprlock-colors.conf · ~/.config/kitty/colors.conf
  ~/.config/gtk-3.0/gtk.css y ~/.config/gtk-4.0/gtk.css (solo si no son enlaces: ver system/adw-gtk3.sh)
Responde con JSON: { ok, error?, sources? }.
"""
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "stixshell")
CONFIG = os.path.join(HOME, ".config")


def fail(msg):
    print(json.dumps({"ok": False, "error": msg}))
    sys.exit(1)


def matugen(args):
    try:
        out = subprocess.run(["matugen"] + args, capture_output=True, text=True, timeout=30)
    except FileNotFoundError:
        fail("matugen no está instalado")
    except subprocess.TimeoutExpired:
        fail("matugen tardó demasiado")
    return out


def source_colors(image):
    out = matugen(["image", image, "--show-source-colors"])
    return [l.strip() for l in out.stdout.splitlines() if l.strip().startswith("#")][:4]


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


def contrast_with_white(h):
    return 1.05 / (lum(h) + 0.05)


def alpha(h, a):
    """#rrggbb con transparencia → #aarrggbb (así lo lee QML)."""
    return "#%02x%s" % (round(a * 255), h.lstrip("#"))


def rgba(h, a=1.0):
    """Para hyprlang: rgba(rrggbbaa)."""
    return "rgba(%s%02x)" % (h.lstrip("#"), round(a * 255))


def mix(a, b, t):
    ra, rb = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(round(x + (y - x) * t) for x, y in zip(ra, rb))


def generate(args):
    scheme = args.get("scheme", "scheme-tonal-spot")
    base = ["-t", scheme, "-m", "dark", "-j", "hex", "-q", "--dry-run"]
    if "image" in args:
        out = matugen(["image", args["image"]] + base + ["--source-color-index", str(args.get("index", 0))])
    else:
        out = matugen(["color", "hex", args["color"]] + base)
    try:
        data = json.loads(out.stdout)
    except ValueError:
        fail(out.stderr.strip().splitlines()[-1] if out.stderr.strip() else "matugen no pudo leer la imagen")
    return data


def tone(data, palette, n):
    return data["palettes"][palette][str(n)]["color"]


def role(data, name):
    return data["colors"][name]["dark"]["color"]


def shell_colors(data):
    text = role(data, "on_surface")
    accent = tone(data, "primary", 50)
    if contrast_with_white(accent) < 3.0:
        accent = tone(data, "primary", 40)
    return {
        "primary": accent,
        "island": role(data, "surface_container_lowest"),
        "surfaceHigh": role(data, "surface_container_highest"),
        "text": text,
        "gray": role(data, "on_surface_variant"),
        "subtext": role(data, "outline"),
        "placeholder": role(data, "outline"),
        "grayDark": tone(data, "neutral_variant", 50),
        "islandEdge": alpha(text, 0.10),
        "surface": alpha(text, 0.06),
        "surfaceHover": alpha(text, 0.08),
        "surfaceActive": alpha(text, 0.16),
        "track": alpha(text, 0.14),
    }


# ── Apps ──
def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def hypr_files(data):
    d = os.path.join(CONFIG, "hypr")
    if not os.path.isdir(d):
        return
    active, inactive = rgba(role(data, "primary")), rgba(role(data, "outline_variant"))
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
    write(
        os.path.join(d, "hyprlock-colors.conf"),
        "# Generado por scripts/theme.py (colores del wallpaper). No se commitea.\n"
        f"$surface = {rgba(role(data, 'surface_container_lowest'))}\n"
        f"$accent = {rgba(role(data, 'primary'))}\n"
        f"$text = {rgba(role(data, 'on_surface'))}\n"
        f"$error = {rgba(role(data, 'error'))}\n",
    )


def kitty_file(data):
    d = os.path.join(CONFIG, "kitty")
    if not os.path.isdir(d):
        return
    bg = role(data, "surface_container_lowest")
    fg = role(data, "on_surface")
    prim = role(data, "primary")
    # Los 16 colores: los de siempre (rojo, verde, amarillo, azul…) mezclados un poco con el acento del wallpaper
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
        f"color0 {role(data, 'surface_container_high')}",
        f"color8 {role(data, 'outline')}",
        f"color7 {role(data, 'on_surface_variant')}",
        f"color15 {fg}",
    ]
    for i in range(6):
        lines.append(f"color{i + 1} {normal[i]}")
        lines.append(f"color{i + 9} {bright[i]}")
    write(os.path.join(d, "colors.conf"), "\n".join(lines) + "\n")
    subprocess.run(["pkill", "-USR1", "-x", "kitty"], capture_output=True)


def gtk_files(data):
    r = lambda n: role(data, n)
    css = (
        "/* Generado por scripts/theme.py (colores del wallpaper). Pide adw-gtk3: system/adw-gtk3.sh */\n"
        f"@define-color accent_bg_color {mix(r('primary_container'), r('primary'), 0.35)};\n"
        "@define-color accent_fg_color #ffffff;\n"
        f"@define-color accent_color {r('primary')};\n"
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


def apply(args):
    data = generate(args)
    # Sin wallpaper (colores apagados) la shell usa sus colores fijos; solo las apps se regeneran
    shell = shell_colors(data) if "image" in args else {}
    sources = source_colors(args["image"]) if "image" in args else []
    write(
        os.path.join(CACHE, "theme.json"),
        json.dumps(
            {
                "shell": shell,
                "image": args.get("image", ""),
                "scheme": args.get("scheme", "scheme-tonal-spot"),
                "index": int(args.get("index", 0)),
                "sources": sources,
            }
        ),
    )
    for fn in (hypr_files, kitty_file, gtk_files):
        try:
            fn(data)
        except OSError:
            pass
    print(json.dumps({"ok": True, "sources": sources}))


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "sources":
        print(json.dumps({"ok": True, "sources": source_colors(a[1])}))
    elif a and a[0] == "apply":
        args = {}
        i = 1
        while i + 1 < len(a):
            args[a[i].lstrip("-")] = a[i + 1]
            i += 2
        if "image" not in args and "color" not in args:
            fail("falta --image o --color")
        apply(args)
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(2)


main()
