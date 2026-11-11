#!/usr/bin/env python3
"""Base de emojis para el launcher (prefijo e:), sacada de la que trae GTK4.

Uso: python3 scripts/emoji-data.py [idioma] > assets/emoji/es.json     (idioma por defecto: es)

Lee /usr/share/gtk-4.0/emoji/<idioma>.gresource (nombres en ese idioma, nombres y palabras clave en inglés)
y escribe una lista JSON: [{ "e": "🔥", "n": "fuego", "en": "fire", "k": ["flame", "tool"] }, …].
Los emojis con tono de piel vienen con el marcador U+1F3FB: se deja solo el emoji base y se quitan los repetidos.
El resultado se guarda en el repo, así el launcher no depende de GTK ni de Python al arrancar.
"""
import json
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

lang = sys.argv[1] if len(sys.argv) > 1 else "es"
res = Gio.Resource.load(f"/usr/share/gtk-4.0/emoji/{lang}.gresource")
name = res.enumerate_children("/org/gtk/libgtk/emoji/", 0)[0]
data = res.lookup_data("/org/gtk/libgtk/emoji/" + name, 0)
# (codepoints, nombre en inglés, nombre en el idioma, palabras clave en inglés, orden)
items = GLib.Variant.new_from_bytes(GLib.VariantType.new("a(aussasu)"), data, False).unpack()

TONE_MARK = 0x1F3FB
out, seen = [], set()
for cps, en, local, keywords, _order in items:
    emoji = "".join(chr(c) for c in cps if c != TONE_MARK)
    if not emoji or emoji in seen:
        continue
    seen.add(emoji)
    out.append({"e": emoji, "n": local or en, "en": en, "k": list(keywords)})

json.dump(out, sys.stdout, ensure_ascii=False, separators=(",", ":"))
sys.stdout.write("\n")
