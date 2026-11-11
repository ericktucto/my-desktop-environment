#!/bin/sh
# Modo conservación del IdeaPad (limita la carga a ~60 % para cuidar la batería).
# El archivo `conservation_mode` del driver ideapad_acpi solo lo escribe root. Este script crea una
# regla de udev que, cuando el driver aparece, le da permiso de escritura al grupo `video` (tu usuario
# ya está en él por el brillo). Así el switch del panel de batería funciona sin sudo y también después de reiniciar.
# Se puede ejecutar varias veces.
# Uso: sudo sh system/conservation-mode.sh
set -e
RULE=/etc/udev/rules.d/90-stixshell-conservation.rules

mkdir -p /etc/udev/rules.d
cat > "$RULE" <<'EOF'
# stixshell: permiso de escritura (grupo video) para el modo conservación del IdeaPad
SUBSYSTEM=="platform", DRIVER=="ideapad_acpi", ACTION=="add|bind", RUN+="/bin/sh -c 'chgrp video /sys%p/conservation_mode; chmod g+w /sys%p/conservation_mode'"
EOF
echo "regla: $RULE"
udevadm control --reload

# Permiso inmediato, sin reiniciar
for f in /sys/bus/platform/drivers/ideapad_acpi/VPC2004:*/conservation_mode; do
    [ -e "$f" ] || continue
    chgrp video "$f"
    chmod g+w "$f"
    echo "permiso aplicado: $f"
    ls -l "$f"
done
