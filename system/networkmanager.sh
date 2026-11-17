#!/bin/sh
# Ajustes opcionales de NetworkManager para la vista de red de la shell:
#   - regla de polkit: tu usuario (grupo wheel) maneja las conexiones de NetworkManager sin pedir contraseña
#     (agregar o borrar una VPN, olvidar una red guardada, conectar a una red nueva)
#   - Docker: NetworkManager deja de gestionar docker0, br-* y veth* (así no salen en nmcli ni en la shell)
#   - DNS: /etc/resolv.conf pasa a ser un enlace a /run/NetworkManager/resolv.conf (rc-manager=symlink). Sin esto,
#     un archivo viejo de dhcpcd tapa el DNS que NetworkManager calcula, y el DNS de la VPN nunca se aplica.
#     El archivo anterior se guarda como /etc/resolv.conf.dhcpcd.bak.
#   - Internet: NetworkManager verifica cada 5 min (cada 10 s la shell, si hay portal) que hay salida, pidiendo un
#     archivo de texto a nmcheck.gnome.org. Sin esto siempre dice "conectado", y la shell no puede avisar de una red
#     que pide iniciar sesión (portal cautivo) ni de una sin internet. Para quitarlo: borra 92-stixshell-connectivity.conf.
# Aplica los cambios con `nmcli general reload conf` (no tumba el Wi-Fi). Se puede ejecutar varias veces.
# Uso: sudo sh system/networkmanager.sh
set -e
RULE=/etc/polkit-1/rules.d/50-stixshell-networkmanager.rules
CONF=/etc/NetworkManager/conf.d/90-stixshell-unmanaged.conf
DNSCONF=/etc/NetworkManager/conf.d/91-stixshell-dns.conf
NETCONF=/etc/NetworkManager/conf.d/92-stixshell-connectivity.conf

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

cat > "$DNSCONF" <<'EOT'
# stixshell: NetworkManager escribe /run/NetworkManager/resolv.conf y /etc/resolv.conf apunta ahí
[main]
rc-manager=symlink
EOT
echo "dns: $DNSCONF"

cat > "$NETCONF" <<'EOT'
# stixshell: verifica que hay internet (portal cautivo y "sin internet"). Misma dirección que Config.network.checkUrl.
[connectivity]
enabled=true
uri=http://nmcheck.gnome.org/check_network_status.txt
response=NetworkManager is online
interval=300
EOT
echo "internet: $NETCONF"

if [ ! -L /etc/resolv.conf ]; then
    [ -e /etc/resolv.conf.dhcpcd.bak ] || cp -p /etc/resolv.conf /etc/resolv.conf.dhcpcd.bak 2>/dev/null || true
    ln -sf /run/NetworkManager/resolv.conf /etc/resolv.conf
    echo "resolv.conf: ahora es un enlace a /run/NetworkManager/resolv.conf (copia en resolv.conf.dhcpcd.bak)"
fi

# polkit relee sus reglas solo; NetworkManager, con reload
if nmcli general reload conf 2>/dev/null; then
    echo "NetworkManager: configuración recargada"
else
    sv restart NetworkManager
    echo "NetworkManager reiniciado"
fi
