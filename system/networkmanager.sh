#!/bin/sh
# Ajustes opcionales de NetworkManager para la vista de red de la shell:
#   - regla de polkit: tu usuario (grupo wheel) maneja las conexiones de NetworkManager sin pedir contraseña
#     (agregar o borrar una VPN, olvidar una red guardada, conectar a una red nueva)
#   - Docker: NetworkManager deja de gestionar docker0, br-* y veth* (así no salen en nmcli ni en la shell)
# Aplica los cambios con `nmcli general reload conf` (no tumba el Wi-Fi). Se puede ejecutar varias veces.
# Uso: sudo sh system/networkmanager.sh
set -e
RULE=/etc/polkit-1/rules.d/50-stixshell-networkmanager.rules
CONF=/etc/NetworkManager/conf.d/90-stixshell-unmanaged.conf

mkdir -p /etc/polkit-1/rules.d /etc/NetworkManager/conf.d

cat > "$RULE" <<'EOT'
// stixshell: los usuarios de wheel manejan NetworkManager sin contraseña (sesión local y activa)
polkit.addRule(function (action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") === 0 && subject.isInGroup("wheel") && subject.local && subject.active)
        return polkit.Result.YES;
});
EOT
echo "polkit: $RULE"

cat > "$CONF" <<'EOT'
# stixshell: las interfaces virtuales de Docker no las gestiona NetworkManager
[keyfile]
unmanaged-devices=interface-name:docker*;interface-name:br-*;interface-name:veth*
EOT
echo "docker: $CONF"

# polkit relee sus reglas solo; NetworkManager, con reload
if nmcli general reload conf 2>/dev/null; then
    echo "NetworkManager: configuración recargada"
else
    sv restart NetworkManager
    echo "NetworkManager reiniciado"
fi
