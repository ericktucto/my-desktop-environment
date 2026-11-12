# my-desktop-environment

Mi entorno de escritorio personal sobre **Hyprland**, con una shell propia hecha en **Quickshell (QML)** y la configuración de Hyprland escrita en **Lua**. Corre en **Void Linux**.

La shell es una barra de "pills" (islas) redondeadas sobre un wallpaper con esquinas redondeadas. Algunas pills se expanden en paneles: el launcher, el selector de wallpapers, el menú de sesión, los workspaces, el centro de control, la energía, el portapapeles y las notificaciones. Al bloquear, la shell muestra su propia pantalla de bloqueo.

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
    ├── scripts/       Scripts de apoyo (código QR del portapapeles, base de emojis del launcher)
    ├── components/    base · controls · indicators · layouts · lock · pills · widgets
    └── services/      audio · brightness · clipboard · idle · launcher · lock · media · notify · osd · power · settings · share · panels · session · workspaces
```

## Funciones

- **Barra:** Workspaces y botón de Zoom a la izquierda, reloj en el centro, y a la derecha tray, batería y notificaciones. Si suena algo, aparece la carátula en una pill redonda a la izquierda del reloj.
- **Isla central:** reloj; se abre con atajos y es el **launcher de apps** (`Super+R`), el **selector de wallpapers**, o el **menú de sesión** (bloquear, suspender, cerrar sesión, reiniciar y apagar; flechas + Enter, con confirmación en lo destructivo).
- **Workspaces:** puntos fijos (4); clic o rueda para cambiar y clic derecho o `Super+Tab` para la vista general, con una fila (ícono y título) por ventana, para distinguir por ejemplo dos Firefox, y arrastrar ventanas entre workspaces.
- **Centro de control** (`Super+C` o clic derecho en el reloj): una cuadrícula de casillas, slider de brillo, y salida y micrófono con mute, modo 150 % y cambio de dispositivo. Abajo, el botón de apagar (abre el menú de sesión), la batería (abre su panel) y el engranaje (abre `settings.json` en kitty con tu `$EDITOR`, o nvim). Las casillas que funcionan son No molestar, Cafeína, Luz del teclado y Ahorro (perfil de ahorro hasta el próximo cambio de cargador, como `Fn+Q`); Wi-Fi, Bluetooth, Luz nocturna y Captura se ven pero dicen "Próximamente".
- **Energía** (pill de batería): estado, modo cafeína, perfil de energía distinto con batería y con cargador (Ahorro, Equilibrado o Rendimiento), que se aplica solo al enchufar o desenchufar, modo conservación (cargar hasta 60 %), tiempos de inactividad editables con batería y con cargador, brillo al atenuar y avisos de batería baja (20 %, 10 % y suspender al 5 %). Se guarda en `~/.config/stixshell/settings.json`, que también se puede editar a mano.
- **Launcher** (`Super+R`): busca apps sin tildes (por nombre, palabras clave y categoría) y las ordena con tus favoritos arriba (estrella o `Ctrl+D`) y las más usadas. También aparecen las acciones de las apps ("Firefox · New Private Window") y las de sesión (apagar, reiniciar, bloquear…). Prefijos: `e:` emojis, `c:` calculadora y `t:` ejecutar en la terminal (kitty con tu shell, para `sudo` y confirmaciones; guarda un historial). Las apps de terminal (nvim) se abren en kitty.
- **Reproductor** (MPRIS: Firefox, mpv…): a la izquierda del reloj, la carátula en una pill redonda con un anillo de progreso. Con la rueda sobre ella cambia el volumen del reproductor. Al hacer clic pasa al centro y se expande (el reloj se vuelve un círculo con un reloj analógico mini a su derecha; solo uno tiene el foco): fondo con la carátula difuminada y su color de acento, carátula a la derecha, título y artista, barra de progreso que se puede arrastrar, anterior, −5 s, play/pausa, +15 s, siguiente, aleatorio, repetir y el volumen del reproductor; con dos o más reproductores, fichas para elegir cuál. Teclado con el panel abierto: `Espacio` play/pausa, `←` −5 s, `→` +15 s, `↑` y `↓` volumen. En transmisiones sin duración sale "EN VIVO". Al terminar la canción la pill queda atenuada y, tras 5 min sin sonar, se oculta; si el reproductor se cierra, desaparece. Los botones que el reproductor no permite se ven atenuados. Si el archivo no tiene etiquetas (mpv), el título es el nombre del archivo; sin carátula, se muestra el ícono de la app.
- **Portapapeles** (`Super+H`): historial de `cliphist` en la isla central, con búsqueda y vista previa de texto e imágenes. Por elemento: copiar, eliminar, código QR (para pasar el texto al teléfono), compartir (hoy por Bluetooth; los destinos se agregan en `services/share/ShareStore.qml`), ejecutar en la terminal (kitty, con confirmación) y, en imágenes, abrir con otra aplicación. Las imágenes copiadas desde un gestor de archivos (Nemo guarda solo la ruta) también se muestran y copian como imagen, y los archivos de otro tipo (PDF, Word…), carpetas o varios archivos a la vez aparecen como una lista con ícono, tipo y tamaño (copiar, abrir con, compartir y eliminar). Arriba, Borrar todo.
- **OSD:** con las teclas de volumen, brillo y micrófono, la hora de la isla central se reemplaza unos segundos por ícono, barra y porcentaje.
- **Notificaciones:** pill con campana y contador, popups con acciones, historial guardado en disco (solo se borra tú), modo No molestar y textos largos expandibles.
- **System tray:** íconos plegables y menú contextual propio.
- **Zoom:** lanza, enfoca o restaura Zoom (flatpak) aunque esté en segundo plano.
- **Wallpaper:** transición con fundido y esquinas redondeadas; todo configurable desde `Config.qml`.

## Atajos

| Atajo | Acción |
|---|---|
| `Super+T` | Abrir la terminal (kitty) |
| `Super+Q` | Cerrar la ventana activa |
| `Super+Escape` o botón de encendido | Menú de sesión |
| `Super+L` | Bloquear la pantalla |
| `Super+Tab` | Vista general de workspaces |
| `Super+C` | Centro de control |
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

El launcher, el selector, el menú de sesión y la vista de workspaces se abren por IPC: `qs ipc call stixshell@launcher toggle ""`, `stixshell@wallpaper`, `stixshell@session` y `stixshell@workspaces` (mismo `toggle ""`). También `stixshell@media playPause|next|previous|seek <seg>|toggle`, `stixshell@clipboard toggle ""`, `stixshell@controlcenter toggle`, `stixshell@audio up|down|mute|micMute` y `stixshell@brightness up|down`.
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
    cliphist wl-clipboard wtype kitty xdg-utils glib gtk+3 file playerctl \
    python3 python3-qrcode python3-Pillow bluez bluez-obex blueman power-profiles-daemon \
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
| **Compartir por Bluetooth** | `bluez`, `bluez-obex`, `blueman` (`blueman-sendto`) | no aparece el destino Bluetooth |
| **Launcher y terminal** | `kitty` (`t:`, apps de terminal, ejecutar desde el portapapeles) | no abre terminales |
| **Multimedia** | `playerctl` (respaldo de las teclas multimedia si la shell no corre). Opcional: `mpv-mpris` (mpv no habla MPRIS sin él), que además hay que enlazar una vez: `mkdir -p ~/.config/mpv/scripts && ln -s /usr/lib/mpv-mpris/mpris.so ~/.config/mpv/scripts/` y reabrir mpv | sin él, mpv no se ve; las teclas solo funcionan con la shell |
| **Escribir en la ventana activa** (emojis y calculadora del launcher) | `wtype` | opcional: sin él, se copian |
| **Fuentes** | `font-inter`, `nerd-fonts-ttf` (JetBrainsMono Nerd Font y Symbols Nerd Font), `noto-fonts-emoji` | íconos y emojis rotos |
| **Opcional** | Zoom por flatpak (`us.zoom.Zoom`) para su botón. `python3-gobject` y `gtk4` solo para regenerar los emojis (`scripts/emoji-data.py`) | |

### Servicios (runit)

Activos con `sudo ln -s /etc/sv/<nombre> /var/service/`: `dbus`, `udevd`, `elogind`, `acpid`, `bluetoothd` y `power-profiles-daemon`. `upowerd` y `obexd` los inicia `dbus` cuando hacen falta.

### Ajustes de una vez (necesitan root)

- `sudo sh system/acpi-shell-keys.sh`: `acpid` deja de apagar con el botón de encendido, de cambiar el brillo y de suspender al cerrar la tapa sin bloquear (mientras la shell corre). Con esto el botón abre el menú de sesión, las teclas de brillo las maneja la shell y la tapa bloquea y suspende. Sin `qs`, vuelve a funcionar como siempre.
- `sudo sh system/conservation-mode.sh`: regla de udev para el modo conservación del IdeaPad ("Cargar hasta 60 %"). Solo IdeaPad.

### Datos

- Wallpapers en `~/Pictures/Wallpapers` (`.jpg`, `.jpeg` o `.png`); la carpeta se cambia en `Config.wallpaperPicker.dir`.
- Para Bluetooth, empareja el teléfono una vez desde `blueman-manager`.

## Instalación

```sh
git clone <este-repo> ~/proyectos/my-desktop-environment
ln -s ~/proyectos/my-desktop-environment/quickshell ~/.config/quickshell
ln -s ~/proyectos/my-desktop-environment/hypr ~/.config/hypr
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
- **Colores:** `quickshell/Theme.qml`.
- **Nueva pill con panel:** basta con usar `Base.Island` con un `body`; se registra sola en `services/panels/PanelStore.qml` y la barra le da el foco y el "clic fuera".

## Notas de funcionamiento

- **Void y elogind:** no hay `systemctl`; se usa `loginctl poweroff|reboot|suspend`. El botón de encendido lo reserva la shell con un inhibidor de elogind (mientras `qs` corre), y `system/acpi-shell-keys.sh` evita que acpid apague primero.
- **Inactividad:** `hypridle` solo conecta el bloqueo con el sistema (`hypr/hypridle.conf`); los tiempos de atenuar, bloquear, apagar la pantalla y suspender los maneja la shell. Los videos en reproducción evitan el bloqueo, porque `IdleMonitor` respeta los inhibidores.
- **Música e inactividad:** mientras suena algún reproductor, no se suspende por inactividad (sí se atenúa, se bloquea y se apaga la pantalla). Cerrar la tapa y el aviso de batería al 5 % siguen suspendiendo.
- **OSD:** solo sale con las teclas de volumen, brillo y micrófono; los cambios hechos desde otro programa (pavucontrol, `brightnessctl` a mano) no lo muestran.

## Pendiente

Lo que falta por hacer está en [`quickshell/todo.md`](quickshell/todo.md), ordenado por prioridad y comparado con otras shells de Quickshell, junto con las fuentes consultadas.
