#!/usr/bin/env python3
"""Diálogo de GTK para elegir una carpeta. Imprime la ruta elegida; si se cancela, sale con código 1.

  pick-folder.py [carpeta inicial] [título]
"""
import os
import sys

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk  # noqa: E402

start = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~")
title = sys.argv[2] if len(sys.argv) > 2 else "Elegir carpeta"

dialog = Gtk.FileChooserDialog(title=title, action=Gtk.FileChooserAction.SELECT_FOLDER)
dialog.add_buttons("Cancelar", Gtk.ResponseType.CANCEL, "Elegir", Gtk.ResponseType.OK)
dialog.set_default_size(720, 480)
# La carpeta puede no existir todavía: se abre en la más cercana que sí exista
folder = start
while folder and not os.path.isdir(folder):
    folder = os.path.dirname(folder)
dialog.set_current_folder(folder or os.path.expanduser("~"))

if dialog.run() == Gtk.ResponseType.OK:
    print(dialog.get_filename())
    sys.exit(0)
sys.exit(1)
