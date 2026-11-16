#!/usr/bin/env python3
"""Diálogo de GTK para elegir una carpeta o un archivo. Imprime la ruta elegida; si se cancela, sale con código 1.

  pick.py folder [inicio] [título]
  pick.py file   [inicio] [título] [patrón …]     patrones: "*.conf" "*.png" …
"""
import fnmatch
import os
import sys

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk  # noqa: E402

mode = sys.argv[1] if len(sys.argv) > 1 else "folder"
start = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else os.path.expanduser("~")
title = sys.argv[3] if len(sys.argv) > 3 else ("Elegir carpeta" if mode == "folder" else "Elegir archivo")
patterns = sys.argv[4:]

action = Gtk.FileChooserAction.SELECT_FOLDER if mode == "folder" else Gtk.FileChooserAction.OPEN
dialog = Gtk.FileChooserDialog(title=title, action=action)
dialog.add_buttons("Cancelar", Gtk.ResponseType.CANCEL, "Elegir", Gtk.ResponseType.OK)
dialog.set_default_size(720, 480)

if mode == "file" and patterns:
    flt = Gtk.FileFilter()
    flt.set_name(" ".join(patterns))
    for p in patterns:
        flt.add_pattern(p)
        flt.add_pattern(p.upper())
    dialog.add_filter(flt)
    everything = Gtk.FileFilter()
    everything.set_name("Todos los archivos")
    everything.add_pattern("*")
    dialog.add_filter(everything)

# La carpeta inicial puede no existir todavía: se abre en la más cercana que sí exista
folder = start
while folder and not os.path.isdir(folder):
    folder = os.path.dirname(folder)
dialog.set_current_folder(folder or os.path.expanduser("~"))

if dialog.run() == Gtk.ResponseType.OK:
    print(dialog.get_filename())
    sys.exit(0)
sys.exit(1)
