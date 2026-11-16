# my-desktop-environment

Mi entorno de escritorio personal sobre **Hyprland**, con una shell propia hecha en **Quickshell (QML)** y la configuración de Hyprland escrita en **Lua**. Corre en **Void Linux**.

La shell es una barra de "pills" (islas) redondeadas sobre un wallpaper con esquinas redondeadas. Algunas pills se expanden en paneles: el launcher, el selector de wallpapers, el menú de sesión, los workspaces, el centro de control, la energía, el portapapeles, el grabador de pantalla y las notificaciones, y un capturador de pantalla con editor. Al bloquear, la shell muestra su propia pantalla de bloqueo.

## Contenido

```
.
├── hypr/            Configuración de Hyprland en Lua
│   ├── hyprland.lua   Monitor, entorno, opciones generales
│   ├── autostart.lua  Servicios que se lanzan al iniciar (portales, polkit, pipewire, portapapeles, qs)
│   ├── hyprlock.conf  Bloqueo de respaldo (colores de la shell), si la shell no corre
│   ├── hypridle.conf  Conecta el bloqueo con el sistema (antes de dormir)
│   └── keybinds/      Atajos de teclado
├── system/          Ajustes del sistema que necesitan root (acpid, modo conservación)
└── quickshell/      La shell
    ├── shell.qml      Ventanas: wallpaper, barra y popups
    ├── Config.qml     Tamaños, animaciones y fuentes
    ├── Theme.qml      Colores
    ├── Wallpaper.qml  Wallpaper actual (se recuerda entre sesiones)
    ├── todo.md        Lo que falta por hacer
    ├── assets/        Íconos (svg) y la base de emojis (emoji)
    ├── scripts/       Scripts de apoyo (código QR del portapapeles, base de emojis del launcher, grabador y capturador de pantalla, selector de carpeta o archivo, agente de Bluetooth e importar VPN)
    ├── components/    base · controls · indicators · layouts · lock · pills · widgets
    └── services/      audio · bluetooth · brightness · clipboard · idle · launcher · lock · media · network · notify · osd · power · recorder · region · screenshot · settings · share · theme · panels · session · windows · workspaces
```

## Funciones

- **Barra:** Workspaces, la ventana activa (ícono, nombre de la app y título; el clic central la cierra) y el botón de Zoom a la izquierda, reloj en el centro, y a la derecha tray, batería y notificaciones. Si suena algo, aparece la carátula en una pill redonda a la izquierda del reloj, y al grabar la pantalla, un contador a su derecha.
- **Isla central:** reloj; se abre con atajos y es el **launcher de apps** (`Super+R`), el **selector de wallpapers**, o el **menú de sesión** (bloquear, suspender, cerrar sesión, reiniciar y apagar; flechas + Enter, con confirmación en lo destructivo).
- **Workspaces:** puntos fijos (4); clic o rueda para cambiar y clic derecho o `Super+Tab` para la vista general, con una fila (ícono y título) por ventana, para distinguir por ejemplo dos Firefox, y arrastrar ventanas entre workspaces.
- **Centro de control** (`Super+C` o clic derecho en el reloj): una cuadrícula de casillas, slider de brillo, y salida y micrófono con mute, modo 150 % y cambio de dispositivo. Abajo, el botón de apagar (abre el menú de sesión), la batería (abre su panel) y el engranaje (abre `settings.json` en kitty con tu `$EDITOR`, o nvim). Las casillas que funcionan son Wi-Fi, Bluetooth, No molestar, Cafeína, Luz del teclado, Captura (abre el capturador) y Ahorro (perfil de ahorro hasta el próximo cambio de cargador, como `Fn+Q`); Luz nocturna se ve pero dice "Próximamente".
- **Red (Wi-Fi y VPN):** la casilla enciende y apaga el Wi-Fi; su flecha `›` abre la vista de red (mismo alto que las casillas, `‹` o Esc vuelven): las redes con su señal y candado (la conectada y las guardadas primero, las 6 mejores y "Mostrar todas"), clic para conectar o desconectar, la contraseña dentro de la misma fila (con ojo), `×` para olvidar una guardada (pide un segundo clic), "Buscar de nuevo" y "Red oculta". También la conexión por cable. **⚙ en una red guardada (o en la cableada)** abre sus detalles: IP, puerta de enlace, DNS y MAC en uso; dirección IP automática o manual (con validación); DNS automático, Cloudflare, Google, Quad9 o personalizado; conexión automática; **Compartir con QR** (el QR del Wi-Fi, con la contraseña oculta y [Copiar contraseña]) y Olvidar. **Redes de empresa (802.1X):** un clic abre un formulario (PEAP o TTLS con usuario y contraseña, identidad anónima, certificado del sistema, de un archivo o sin verificar, y dominio). Las interfaces de Docker (`docker0`, `br-*`, `veth*`) no se muestran. **VPN de WireGuard y OpenVPN:** lista con conectar o desconectar y borrar, y **Agregar VPN** desde un archivo `.conf` o `.ovpn`, una imagen con el QR, el portapapeles (una imagen con el QR o el texto) o una región de la pantalla (con el selector del grabador y `grim`); antes de agregarla se ve el tipo, el nombre (editable), el servidor, la dirección, si pasa **todo el tráfico** o solo ciertas redes y, en un `.ovpn` con `auth-user-pass`, el usuario y la contraseña; se importa sin conexión automática. Una VPN de todo el tráfico queda con `dns-priority` negativo: mientras está activa, solo se usa su DNS (sin fugas). Teclado: ↑ ↓, Enter y Supr (dos veces). Un ícono en la barra muestra la señal (o el cable) y un candado verde con la VPN activa, y un aviso con **Abrir** sale si la red pide iniciar sesión (portal cautivo).
- **Bluetooth:** la casilla enciende y apaga (y recuerda si lo dejaste apagado, porque BlueZ lo enciende en cada arranque); su flecha `›` abre la vista de Bluetooth, con el mismo alto que las casillas: switch, dispositivos emparejados (clic para conectar o desconectar, con su batería) y disponibles (clic para emparejar, buscando mientras la vista está abierta y hasta 60 s). Al conectar o emparejar, el dispositivo pasa a confiable y se reconecta solo. Las preguntas de emparejar (confirmar un código, escribir un PIN) salen en una tarjeta de la misma vista, gracias a un agente de BlueZ propio (`scripts/bt-agent.py`; Quickshell no trae uno). Con la vista abierta la laptop es visible para el celular. Cada fila tiene una `×` para olvidar (pide un segundo clic) y se renombra con doble clic o F2; teclado: ↑ ↓, Enter, Supr y F2, y Esc vuelve a las casillas. Con algo conectado aparece un ícono en la barra (con la batería si es un solo dispositivo) y hay avisos al conectar, desconectar y con la batería baja (15 %).
- **Energía** (pill de batería): estado, modo cafeína, perfil de energía distinto con batería y con cargador (Ahorro, Equilibrado o Rendimiento), que se aplica solo al enchufar o desenchufar, modo conservación (cargar hasta 60 %), tiempos de inactividad editables con batería y con cargador, brillo al atenuar y avisos de batería baja (20 %, 10 % y suspender al 5 %). Se guarda en `~/.config/stixshell/settings.json`, que también se puede editar a mano.
- **Launcher** (`Super+R`): busca apps sin tildes (por nombre, palabras clave y categoría) y las ordena con tus favoritos arriba (estrella o `Ctrl+D`) y las más usadas. También aparecen las acciones de las apps ("Firefox · New Private Window") y las de sesión (apagar, reiniciar, bloquear…). Prefijos: `e:` emojis, `c:` calculadora y `t:` ejecutar en la terminal (kitty con tu shell, para `sudo` y confirmaciones; guarda un historial). Las apps de terminal (nvim) se abren en kitty.
- **Reproductor** (MPRIS: Firefox, mpv…): a la izquierda del reloj, la carátula en una pill redonda con un anillo de progreso. Con la rueda sobre ella cambia el volumen del reproductor. Al hacer clic pasa al centro y se expande (el reloj se vuelve un círculo con un reloj analógico mini a su derecha; solo uno tiene el foco): fondo con la carátula difuminada y su color de acento, carátula a la derecha, título y artista, barra de progreso que se puede arrastrar, anterior, −5 s, play/pausa, +15 s, siguiente, aleatorio, repetir y el volumen del reproductor; con dos o más reproductores, fichas para elegir cuál. Teclado con el panel abierto: `Espacio` play/pausa, `←` −5 s, `→` +15 s, `↑` y `↓` volumen. En transmisiones sin duración sale "EN VIVO". Al terminar la canción la pill queda atenuada y, tras 5 min sin sonar, se oculta; si el reproductor se cierra, desaparece. Los botones que el reproductor no permite se ven atenuados. Si el archivo no tiene etiquetas (mpv), el título es el nombre del archivo; sin carátula, se muestra el ícono de la app.
- **Portapapeles** (`Super+H`): historial de `cliphist` en la isla central, con búsqueda y vista previa de texto e imágenes. Por elemento: copiar, eliminar, código QR (para pasar el texto al teléfono), compartir (hoy por Bluetooth; los destinos se agregan en `services/share/ShareStore.qml`), ejecutar en la terminal (kitty, con confirmación) y, en imágenes, abrir con otra aplicación. Las imágenes copiadas desde un gestor de archivos (Nemo guarda solo la ruta) también se muestran y copian como imagen, y los archivos de otro tipo (PDF, Word…), carpetas o varios archivos a la vez aparecen como una lista con ícono, tipo y tamaño (copiar, abrir con, compartir y eliminar). Arriba, Borrar todo.
- **OSD:** con las teclas de volumen, brillo y micrófono, la hora de la isla central se reemplaza unos segundos por ícono, barra y porcentaje.
- **Notificaciones:** pill con campana y contador, popups con acciones, historial guardado en disco (solo se borra tú), modo No molestar y textos largos expandibles.
- **Grabador de pantalla** (`Super+G`): el menú se abre en la isla central. Elige un monitor o una región (la flecha `›` de la casilla abre un selector sobre el escritorio: arrastra para marcar el área, muévela o cámbiale el tamaño desde los bordes, y **Aceptar** o Enter la confirma), si grabar el sonido interno y el micrófono (los dos a la vez se mezclan), y la carpeta (por defecto `~/Vídeos/Grabaciones`; el menú muestra solo su nombre y la ruta sale al pasar el mouse). Con Grabar o Enter hay una cuenta regresiva de 3 s y a la derecha del reloj aparece un contador con el tiempo; un clic en él, o `Super+G`, detiene y guarda, y sale un aviso con **Abrir** (el reproductor de video predeterminado, vía `gio open`) y **Carpeta** (el gestor de archivos predeterminado, con el video seleccionado). Mientras graba, No molestar está activo y la inactividad en pausa; suspender o apagar desde la shell guarda el video primero. Graba MP4 a 60 fps por la GPU (VA-API) y, si falla, por la CPU.
- **Capturador de pantalla** (`Impr Pant` o `Super+Shift+S`, o la casilla Captura del centro de control): `grim` congela la pantalla y se ve esa imagen quieta (un video detrás no cambia lo que se guarda). Abajo, una barra con **Área** (arrastra; al soltar se captura, y se puede mover o cambiar de tamaño antes con el Editor), **Ventana** (la de abajo del mouse se resalta; un clic captura su contenido), **Pantalla** (con un monitor captura al instante; con varios, clic en el monitor), **Texto** (marcas el área y se lee su texto con OCR, o su contenido si es un código QR; sale en una tarjeta editable donde corriges lo mal leído, y `Ctrl+Enter` o **Copiar** lo copia y cierra; **Abrir** si es un enlace), el **retardo** (0, 3 o 5 s; mientras cuenta sale un reloj con los segundos junto al de la hora, que un clic cancela, y no aparece en la captura; también se puede cambiar con el capturador abierto, para capturar un menú) y el switch **Editor**. Sin el Editor, al capturar se guarda un PNG en `~/Imágenes/Capturas` (cambia la carpeta en `settings.json`, `screenshot.folder`), se copia al portapapeles (y entra al historial) y sale un aviso con **Abrir**, **Carpeta** y **Editar**. Con el Editor, tras elegir el área se anota ahí mismo, **Texto** lee el área sin las anotaciones, y se termina con **Copiar** (`Ctrl+C`), **Guardar** (`Ctrl+S`) o **Listo** (Enter, guarda y copia): flecha `A`, rectángulo `R`, elipse `E`, línea `L`, lápiz `P`, resaltador `H`, texto `T` (Enter baja de línea; Esc termina), números `N` (se renumeran al borrar uno), pixelar o difuminar `B`, stickers `S` y mover o editar `V` (clic selecciona, arrastra mueve, las esquinas cambian el tamaño, la manija azul gira un sticker, doble clic edita un texto, `Supr` borra), con 7 colores, 3 grosores, relleno, fondo del texto, deshacer (`Ctrl+Z`) y rehacer (`Ctrl+Shift+Z`). Shift traza líneas a 45° y formas cuadradas. Los stickers son los emojis del launcher (con buscador) y los PNG o SVG de `~/.config/stixshell/stickers/` (o uno de cualquier carpeta con "Desde archivo…"). Esc va por partes: termina el texto, suelta la anotación, avisa "Esc otra vez para descartar" y cierra. **Editar** en el aviso vuelve a abrir esa imagen con el Editor y guarda `… editada.png` al lado.
- **System tray:** íconos plegables y menú contextual propio.
- **Zoom:** lanza, enfoca o restaura Zoom (flatpak) aunque esté en segundo plano.
- **Wallpaper:** transición con fundido y esquinas redondeadas; todo configurable desde `Config.qml`.
- **Colores del wallpaper** (matugen): una fila arriba del selector de wallpapers (`Super+W`) con el switch, el estilo (Suave, Fiel, Vibrante o Expresivo) y los colores que matugen encuentra en la imagen (el elegido manda y se recuerda por wallpaper). El acento (switches, sliders, botones), la isla, los bordes y los textos toman un tinte del wallpaper con un fundido de 600 ms; los colores con significado (rojo, ámbar, verde y naranja) y los blancos no cambian. También los toman los bordes de Hyprland, kitty, hyprlock y GTK. Apagado, todo vuelve al azul de siempre.

## Atajos

| Atajo | Acción |
|---|---|
| `Super+T` | Abrir la terminal (kitty) |
| `Super+Q` | Cerrar la ventana activa |
| `Super+Escape` o botón de encendido | Menú de sesión |
| `Super+L` | Bloquear la pantalla |
| `Super+Tab` | Vista general de workspaces |
| `Super+C` | Centro de control |
| `Super+G` | Menú del grabador de pantalla; con una grabación en curso, la detiene |
| `Impr Pant` o `Super+Shift+S` | Capturador de pantalla (con el capturador abierto o contando, lo cancela) |
| `Super+H` | Historial del portapapeles |
| Teclas de volumen, mute y brillo (Fn) | Subir, bajar y silenciar el audio, mute del micrófono y brillo; muestran el OSD |
| `Super+R` | Launcher de apps (abre y cierra) |
| Teclas multimedia (reproducir/pausa, siguiente, anterior) | Controlan el reproductor mostrado, también con la pantalla bloqueada |
| `Super+W` | Selector de wallpapers |
| `Super+1…4` | Ir al workspace |
| `Super+Shift+1…4` | Mandar la ventana al workspace |
| `Super+A` | Mandar/traer la ventana al stash |
| `Super+S` | Ver u ocultar el stash |
| `Super+F` | Maximizar |

El launcher, el selector, el menú de sesión y la vista de workspaces se abren por IPC: `qs ipc call stixshell@launcher toggle ""`, `stixshell@wallpaper`, `stixshell@session` y `stixshell@workspaces` (mismo `toggle ""`). También `stixshell@media playPause|next|previous|seek <seg>|toggle`, `stixshell@clipboard toggle ""`, `stixshell@recorder toggle ""|stop`, `stixshell@screenshot open|area|window|screen|text|cancel` y `edit <ruta>`, `stixshell@theme regen|toggle` y `scheme <id>`, `stixshell@bluetooth open|toggle`, `stixshell@network open|toggle`, `stixshell@controlcenter toggle`, `stixshell@audio up|down|mute|micMute` y `stixshell@brightness up|down`.
`Esc` o un clic fuera cierran cualquier panel. El bloqueo se dispara con `qs ipc call stixshell@lock lock`.

> Si la shell se cae estando bloqueado, Hyprland muestra su pantalla roja. Para recuperarte: `Ctrl+Alt+F2`, entra con tu usuario y ejecuta `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'` (o relanza `qs`); vuelve con `Ctrl+Alt+F1` (o la TTY de Hyprland) y desbloquea con tu contraseña.

> Desarrollo: Quickshell recarga solo al editar archivos, pero no reconoce una carpeta nueva (por ejemplo un servicio nuevo en `services/`) mientras corre. Si el IPC o el tipo no aparece, reinicia la shell (`pkill -x qs; qs`).

## Requisitos

Pensado para **Void Linux** (los nombres son de paquetes de xbps) en una laptop **Lenovo IdeaPad**; en otro equipo, lo del modo conservación no aplica.

### Paquetes

Todo de una vez (la lista completa que usa la shell):

```sh
sudo xbps-install -Su hyprland quickshell upower pipewire wireplumber brightnessctl libnotify \
    hypridle hyprlock elogind acpid eudev dbus hyprpolkitagent xdg-desktop-portal xdg-desktop-portal-hyprland \
    cliphist wl-clipboard wtype kitty xdg-utils glib gtk+3 file playerctl wf-recorder \
    python3 python3-gobject python3-qrcode python3-Pillow bluez bluez-obex blueman power-profiles-daemon \
    font-inter nerd-fonts-ttf noto-fonts-emoji
```

| Para qué | Paquetes | Si falta |
|---|---|---|
| **Base** | `hyprland` (con configuración en Lua), `quickshell` 0.3.2 o más reciente (Qt 6), `dbus`, `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent` | no arranca |
| **Audio** (control de volumen, OSD) | `pipewire`, `wireplumber` | sin volumen |
| **Brillo** | `brightnessctl`, con tu usuario en el grupo `video` | sin brillo |
| **Luz del teclado** | `brightnessctl`, con tu usuario en el grupo `input` | la casilla dice "No disponible" |
| **Batería y energía** | `upower`, `libnotify` (`notify-send`, avisos de batería baja), `power-profiles-daemon` | sin batería, avisos ni perfiles |
| **Bloqueo, inactividad y sesión** | `hypridle`, `hyprlock` (bloqueo de respaldo), `elogind` (`loginctl`, `elogind-inhibit`), `acpid`, `eudev` | no bloquea ni suspende |
| **Portapapeles** | `cliphist`, `wl-clipboard`, `file`, `xdg-utils` (`xdg-mime`), `glib` (`gio`), `gtk+3` (`gtk-launch`) | sin historial, "Abrir con" ni tipos de archivo |
| **Código QR** | `python3`, `python3-qrcode`, `python3-Pillow` | el botón QR avisa que falta |
| **Bluetooth** (casilla, vista y agente de emparejamiento) | `bluez`, `python3`, `python3-gobject`, `rfkill` (desbloquear), tu usuario en el grupo `bluetooth` | sin adaptador, la casilla dice "Sin adaptador"; sin `python3-gobject`, no se puede emparejar lo que pide un código |
| **Red (Wi-Fi y VPN)** | `NetworkManager` (activo por runit), `NetworkManager-openvpn` (VPN OpenVPN), `ca-certificates` (redes 802.1X con el certificado del sistema), `python3-pyzbar` (leer el QR), `grim` (QR en pantalla), `wl-clipboard`, `python3-gobject` (diálogo de archivos) y `libnotify` (aviso de portal cautivo) | sin NetworkManager, "Sin Wi-Fi"; sin `pyzbar`, no se leen QR (el `.conf` y el texto sí); sin `NetworkManager-openvpn`, un `.ovpn` dice "Instala NetworkManager-openvpn" |
| **Compartir por Bluetooth** | `bluez`, `bluez-obex`, `blueman` (`blueman-sendto`) | no aparece el destino Bluetooth |
| **Launcher y terminal** | `kitty` (`t:`, apps de terminal, ejecutar desde el portapapeles) | no abre terminales |
| **Multimedia** | `playerctl` (respaldo de las teclas multimedia si la shell no corre). Opcional: `mpv-mpris` (mpv no habla MPRIS sin él), que además hay que enlazar una vez: `mkdir -p ~/.config/mpv/scripts && ln -s /usr/lib/mpv-mpris/mpris.so ~/.config/mpv/scripts/` y reabrir mpv | sin él, mpv no se ve; las teclas solo funcionan con la shell |
| **Grabador de pantalla** | `wf-recorder`, `pipewire-pulse` con `pactl` (audio), `mesa-vaapi` (grabar con la GPU), `python3-gobject` y `gtk+3` (diálogo de carpeta) y `libnotify` (aviso) | sin `wf-recorder`, avisa "No se pudo grabar"; sin VA-API, graba por la CPU |
| **Capturador de pantalla** | `grim` (congelar la pantalla), `wl-clipboard` (copiar), `python3-Pillow` (recortar), `tesseract-ocr` con `tesseract-ocr-spa` y `tesseract-ocr-eng` (modo Texto; en Void el programa se llama `tesseract-ocr`), `python3-pyzbar` (QR), `hyprland` (`hyprctl`, para las ventanas), `libnotify` (aviso), `python3-gobject` (stickers desde archivo) y `noto-fonts-emoji` | sin `grim`, avisa "No se pudo capturar la pantalla"; sin Pillow, no se guarda |
| **Colores del wallpaper** | `matugen` (genera la paleta), `python3` y, para GTK, `adw-gtk3` (lo instala `system/adw-gtk3.sh`) | sin matugen, quedan los colores fijos y la fila lo avisa |
| **Escribir en la ventana activa** (emojis y calculadora del launcher) | `wtype` | opcional: sin él, se copian |
| **Fuentes** | `font-inter`, `nerd-fonts-ttf` (JetBrainsMono Nerd Font y Symbols Nerd Font), `noto-fonts-emoji` | íconos y emojis rotos |
| **Opcional** | Zoom por flatpak (`us.zoom.Zoom`) para su botón. `gtk4` solo para regenerar los emojis (`scripts/emoji-data.py`) | |

### Servicios (runit)

Activos con `sudo ln -s /etc/sv/<nombre> /var/service/`: `dbus`, `udevd`, `elogind`, `acpid`, `bluetoothd` y `power-profiles-daemon`. `upowerd` y `obexd` los inicia `dbus` cuando hacen falta.

### Ajustes de una vez (necesitan root)

- `sudo sh system/acpi-shell-keys.sh`: `acpid` deja de apagar con el botón de encendido, de cambiar el brillo y de suspender al cerrar la tapa sin bloquear (mientras la shell corre). Con esto el botón abre el menú de sesión, las teclas de brillo las maneja la shell y la tapa bloquea y suspende. Sin `qs`, vuelve a funcionar como siempre.
- `sh system/adw-gtk3.sh` (opcional, sin root): descarga adw-gtk3 y pasa GTK a oscuro (adw-gtk3-dark y Papirus-Dark) para que las apps tomen los colores del wallpaper; con `--restore` vuelve a WhiteSur-Light.
- `sudo sh system/conservation-mode.sh`: regla de udev para el modo conservación del IdeaPad ("Cargar hasta 60 %"). Solo IdeaPad.

- `sudo sh system/bluetooth-config.sh` (opcional): en `/etc/bluetooth/main.conf` pone `Experimental = true` (batería de los audífonos) y `Name = %h` (el celular ve el nombre del equipo, no "BlueZ 5.88"), y reinicia `bluetoothd`.

- `sudo sh system/networkmanager.sh` (opcional): una regla de polkit para que tu usuario (grupo `wheel`) maneje NetworkManager sin contraseña (agregar o borrar VPN, olvidar una red, conectar a una nueva), la orden de que NetworkManager ignore `docker*`, `br-*` y `veth*`, y que `/etc/resolv.conf` sea un enlace a `/run/NetworkManager/resolv.conf` (`rc-manager=symlink`; el archivo viejo queda como `resolv.conf.dhcpcd.bak`), sin lo cual el DNS de la VPN no se aplica. Recarga la configuración sin tumbar el Wi-Fi. Sin él todo funciona, pero esas acciones piden tu contraseña de administrador.

### Datos

- Wallpapers en `~/Pictures/Wallpapers` (`.jpg`, `.jpeg` o `.png`); la carpeta se cambia en `Config.wallpaperPicker.dir`.
- Para Bluetooth, empareja desde la vista de Bluetooth del centro de control (ya no hace falta `blueman-manager`).

## Instalación

```sh
git clone <este-repo> ~/proyectos/my-desktop-environment
ln -s ~/proyectos/my-desktop-environment/quickshell ~/.config/quickshell
ln -s ~/proyectos/my-desktop-environment/hypr ~/.config/hypr
ln -s ~/proyectos/my-desktop-environment/kitty ~/.config/kitty
```

`hypr/autostart.lua` lanza `qs` al iniciar Hyprland. Para probar la shell sin reiniciar: `qs`.
Quickshell recarga solo al guardar un archivo; si no lo hace, `touch quickshell/shell.qml`.

## Datos y registros

- Historial de notificaciones: `~/.local/state/quickshell/by-shell/*/notifications.json`.
- Wallpaper actual: `~/.cache/quickshell/wallpaper`.
- Historial del portapapeles: la base de `cliphist`. Las imágenes y los QR que se ven en el panel se decodifican a `$XDG_RUNTIME_DIR/stixshell/clipboard` (se vacía al arrancar la shell).
- Log de la shell: `$(ls -td /run/user/$UID/quickshell/by-id/*/ | head -1)log.log`.

## Personalizar

- **Tamaños, animaciones y fuentes:** `quickshell/Config.qml`.
- **Colores:** `quickshell/Theme.qml` (los fijos; con los colores del wallpaper encendidos, el tinte sale de `~/.cache/stixshell/theme.json`, que escribe `quickshell/scripts/theme.py`).
- **Nueva pill con panel:** basta con usar `Base.Island` con un `body`; se registra sola en `services/panels/PanelStore.qml` y la barra le da el foco y el "clic fuera".

## Notas de funcionamiento

- **Void y elogind:** no hay `systemctl`; se usa `loginctl poweroff|reboot|suspend`. El botón de encendido lo reserva la shell con un inhibidor de elogind (mientras `qs` corre), y `system/acpi-shell-keys.sh` evita que acpid apague primero.
- **Inactividad:** `hypridle` solo conecta el bloqueo con el sistema (`hypr/hypridle.conf`); los tiempos de atenuar, bloquear, apagar la pantalla y suspender los maneja la shell. Los videos en reproducción evitan el bloqueo, porque `IdleMonitor` respeta los inhibidores.
- **Música e inactividad:** mientras suena algún reproductor, no se suspende por inactividad (sí se atenúa, se bloquea y se apaga la pantalla). Cerrar la tapa y el aviso de batería al 5 % siguen suspendiendo.
- **Grabación:** `wf-recorder` corre aparte de la shell (`scripts/screen-record.py`), así que recargar `qs` no la corta; el estado queda en `$XDG_RUNTIME_DIR/stixshell/recorder.json`. Si grabas un monitor completo, la barra sale en el video (graba una región para evitarlo). Con el audio interno y el micrófono a la vez, se crea una salida temporal `stixshell_rec` en PipeWire que se quita al terminar.
- **Colores del wallpaper:** `scripts/theme.py` corre matugen una vez por cambio y escribe `~/.cache/stixshell/theme.json` (la shell), `hypr/colors.lua` (se aplica en caliente con `hyprctl eval`, sin `reload`), `hypr/hyprlock-colors.conf`, `kitty/colors.conf` (las ventanas abiertas se actualizan con SIGUSR1) y, solo con adw-gtk3 en uso, `gtk.css` de gtk-3.0 y gtk-4.0. Los archivos de `hypr/` y `kitty/` están en `.gitignore`. El acento es el tono 50 de la paleta del wallpaper (40 si el blanco no contrasta 3:1).
- **Capturas:** la pantalla congelada y lo anotado pasan por `$XDG_RUNTIME_DIR/stixshell/shot` y se borran al terminar. Una captura sin anotaciones es un recorte exacto de la imagen de `grim` (a la resolución real del monitor); con anotaciones se exporta lo dibujado sobre el área. Pixelar y difuminar quedan fijos en el PNG. El OCR invierte el fondo oscuro y agranda el texto chico antes de leerlo (prueba a 1× y 2× y se queda con la lectura más segura). Las ventanas salen de `hyprctl clients` (solo las visibles del monitor, las flotantes arriba) y se captura su contenido, sin el borde de Hyprland; si otra ventana la tapa, se ve lo que hay en ese rectángulo. El selector de región (`widgets/region`) lo comparten el grabador, la VPN y el capturador.
- **Bluetooth:** el agente de emparejamiento es un proceso de la shell (`scripts/bt-agent.py`). Si activas `blueman-applet`, este pasa a ser el agente por defecto y las preguntas salen en sus ventanas. Un dispositivo que pide un PIN o un código solo se puede emparejar con el agente corriendo.
- **Red:** el Wi-Fi sale de `Quickshell.Networking`; la VPN y las redes ocultas, de `nmcli` (Quickshell no cubre VPN). Las VPN se importan sin conexión automática y la configuración (con su clave privada) solo pasa por `$XDG_RUNTIME_DIR/stixshell/vpn` con permisos 600 mientras dura la importación. Los DNS de la VPN dependen de que `/etc/resolv.conf` siga a NetworkManager (`system/networkmanager.sh`); los detalles de una red avisan si no es así. Con una VPN de todo el tráfico solo se usa su DNS: si su servidor no responde, no hay DNS hasta desconectarla. Las contraseñas 802.1X y de OpenVPN quedan guardadas en el perfil de NetworkManager (la shell no es un agente de secretos); el PNG del QR del Wi-Fi vive en `$XDG_RUNTIME_DIR/stixshell/net` y se borra al cerrar la tarjeta. IPv6 manual, EAP-TLS, OpenConnect/L2TP y kill switch quedan fuera.
- **OSD:** solo sale con las teclas de volumen, brillo y micrófono; los cambios hechos desde otro programa (pavucontrol, `brightnessctl` a mano) no lo muestran.

## Pendiente

Lo que falta por hacer está en [`quickshell/todo.md`](quickshell/todo.md), ordenado por prioridad y comparado con otras shells de Quickshell, junto con las fuentes consultadas.
