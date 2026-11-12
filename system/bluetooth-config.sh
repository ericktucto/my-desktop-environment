#!/bin/sh
# Ajustes opcionales de BlueZ (/etc/bluetooth/main.conf) para la vista de Bluetooth de la shell:
#   Experimental = true   batería de los audífonos y otros dispositivos que no sean ratones
#   Name = %h             el celular ve la laptop con el nombre del equipo, no como "BlueZ 5.88"
# Guarda una copia (main.conf.bak) la primera vez, solo cambia lo que falta y reinicia bluetoothd.
# Se puede ejecutar varias veces.
# Uso: sudo sh system/bluetooth-config.sh
set -e
CONF=/etc/bluetooth/main.conf

[ -f "$CONF" ] || { echo "no existe $CONF (¿está instalado bluez?)"; exit 1; }
[ -f "$CONF.bak" ] || cp "$CONF" "$CONF.bak"

changed=0
# set_option clave valor: descomenta o reemplaza `clave = ...` dentro de [General]
set_option() {
    key="$1"
    value="$2"
    if grep -Eq "^[[:space:]]*$key[[:space:]]*=[[:space:]]*$value[[:space:]]*$" "$CONF"; then
        echo "ya está: $key = $value"
        return
    fi
    if grep -Eq "^[#[:space:]]*$key[[:space:]]*=" "$CONF"; then
        # primera línea (comentada o no) de esa clave
        sed -i "0,/^[#[:space:]]*$key[[:space:]]*=.*/s//$key = $value/" "$CONF"
    else
        sed -i "0,/^\[General\]/s//[General]\n$key = $value/" "$CONF"
    fi
    echo "puesto: $key = $value"
    changed=1
}

set_option Experimental true
set_option Name '%h'

if [ "$changed" = 1 ]; then
    sv restart bluetoothd
    echo "bluetoothd reiniciado"
else
    echo "nada que cambiar"
fi
