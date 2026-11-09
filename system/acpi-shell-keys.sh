#!/bin/sh
# Void usa acpid, que por su cuenta apaga la laptop con el botón de encendido
# (`shutdown -P now`) y cambia el brillo con las teclas Fn. Este script hace que acpid
# no haga ninguna de las dos cosas mientras la shell (qs) esté corriendo: así el botón abre
# el menú de sesión y las teclas de brillo las maneja la shell. Sin qs, acpid vuelve a
# hacerlo como siempre.
# Se puede ejecutar varias veces: solo agrega lo que falta.
# Uso: sudo sh system/acpi-shell-keys.sh
set -e
F=/etc/acpi/handler.sh
[ -f "$F.bak" ] || cp "$F" "$F.bak"

# Botón de encendido
if grep -q 'stixshell: si la shell corre' "$F"; then
    echo "botón de encendido: ya aplicado"
else
    sed -i '/PBTN|PWRF)/a\                # stixshell: si la shell corre, ella maneja el botón (menú de sesión)\n                pgrep -x qs >/dev/null \&\& exit 0' "$F"
    echo "botón de encendido: aplicado"
fi

# Teclas de brillo
if grep -q 'stixshell-brillo' "$F"; then
    echo "brillo: ya aplicado"
else
    sed -i -e '/video\/brightnessdown)/a\        pgrep -x qs >/dev/null \&\& exit 0   # stixshell-brillo' \
           -e '/video\/brightnessup)/a\        pgrep -x qs >/dev/null \&\& exit 0   # stixshell-brillo' "$F"
    echo "brillo: aplicado"
fi

grep -n -B1 -A3 'stixshell' "$F"
