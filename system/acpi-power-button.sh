#!/bin/sh
# Void usa acpid, que apaga la laptop (`shutdown -P now`) al pulsar el botón de encendido,
# además de elogind. Este script hace que acpid no apague mientras la shell (qs) esté
# corriendo: así el botón solo abre el menú de sesión. Sin qs, vuelve a apagar.
# Uso: sudo sh system/acpi-power-button.sh
set -e
F=/etc/acpi/handler.sh
grep -q 'stixshell' "$F" && { echo "ya aplicado"; exit 0; }
cp "$F" "$F.bak"
sed -i '/PBTN|PWRF)/a\                # stixshell: si la shell corre, ella maneja el botón (menú de sesión)\n                pgrep -x qs >/dev/null \&\& exit 0' "$F"
sed -n 22,32p "$F"
