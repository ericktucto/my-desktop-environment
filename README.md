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
    ├── assets/        Íconos (svg) y la base de emojis (emoji)
    ├── scripts/       Scripts de apoyo (código QR del portapapeles, base de emojis del launcher)
    ├── components/    base · controls · indicators · pills · widgets · layouts
    └── services/      audio · brightness · clipboard · idle · launcher · lock · notify · osd · power · settings · share · panels · session · workspaces
```

## Funciones

- **Barra:** Workspaces y botón de Zoom a la izquierda, reloj en el centro, y a la derecha tray, batería y notificaciones.
- **Isla central:** reloj; se abre con atajos y es el **launcher de apps** (`Super+R`), el **selector de wallpapers**, o el **menú de sesión** (bloquear, suspender, cerrar sesión, reiniciar y apagar; flechas + Enter, con confirmación en lo destructivo).
- **Workspaces:** puntos fijos (4); clic o rueda para cambiar y clic derecho o `Super+Tab` para la vista general, con una fila (ícono y título) por ventana, para distinguir por ejemplo dos Firefox, y arrastrar ventanas entre workspaces.
- **Centro de control** (`Super+C` o clic derecho en el reloj): No molestar, slider de brillo, y salida y micrófono con mute, modo 150 % y cambio de dispositivo.
- **Energía** (pill de batería): estado, modo cafeína, perfil de energía distinto con batería y con cargador (Ahorro, Equilibrado o Rendimiento), que se aplica solo al enchufar o desenchufar, modo conservación (cargar hasta 60 %), tiempos de inactividad editables con batería y con cargador, brillo al atenuar y avisos de batería baja (20 %, 10 % y suspender al 5 %). Se guarda en `~/.config/stixshell/settings.json`, que también se puede editar a mano.
- **Launcher** (`Super+R`): busca apps sin tildes (por nombre, palabras clave y categoría) y las ordena con tus favoritos arriba (estrella o `Ctrl+D`) y las más usadas. También aparecen las acciones de las apps ("Firefox · New Private Window") y las de sesión (apagar, reiniciar, bloquear…). Prefijos: `e:` emojis, `c:` calculadora y `t:` ejecutar en la terminal (kitty con tu shell, para `sudo` y confirmaciones; guarda un historial). Las apps de terminal (nvim) se abren en kitty.
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
| `Super+W` | Selector de wallpapers |
| `Super+1…4` | Ir al workspace |
| `Super+Shift+1…4` | Mandar la ventana al workspace |
| `Super+A` | Mandar/traer la ventana al stash |
| `Super+S` | Ver u ocultar el stash |
| `Super+F` | Maximizar |

El launcher, el selector, el menú de sesión y la vista de workspaces se abren por IPC: `qs ipc call stixshell@launcher toggle ""`, `stixshell@wallpaper`, `stixshell@session` y `stixshell@workspaces` (mismo `toggle ""`). También `stixshell@clipboard toggle ""`, `stixshell@controlcenter toggle`, `stixshell@audio up|down|mute|micMute` y `stixshell@brightness up|down`.
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
    cliphist wl-clipboard wtype kitty xdg-utils glib gtk+3 file \
    python3 python3-qrcode python3-Pillow bluez bluez-obex blueman power-profiles-daemon \
    font-inter nerd-fonts-ttf noto-fonts-emoji
```

| Para qué | Paquetes | Si falta |
|---|---|---|
| **Base** | `hyprland` (con configuración en Lua), `quickshell` 0.3.2 o más reciente (Qt 6), `dbus`, `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent` | no arranca |
| **Audio** (control de volumen, OSD) | `pipewire`, `wireplumber` | sin volumen |
| **Brillo** | `brightnessctl`, con tu usuario en el grupo `video` | sin brillo |
| **Batería y energía** | `upower`, `libnotify` (`notify-send`, avisos de batería baja), `power-profiles-daemon` | sin batería, avisos ni perfiles |
| **Bloqueo, inactividad y sesión** | `hypridle`, `hyprlock` (bloqueo de respaldo), `elogind` (`loginctl`, `elogind-inhibit`), `acpid`, `eudev` | no bloquea ni suspende |
| **Portapapeles** | `cliphist`, `wl-clipboard`, `file`, `xdg-utils` (`xdg-mime`), `glib` (`gio`), `gtk+3` (`gtk-launch`) | sin historial, "Abrir con" ni tipos de archivo |
| **Código QR** | `python3`, `python3-qrcode`, `python3-Pillow` | el botón QR avisa que falta |
| **Compartir por Bluetooth** | `bluez`, `bluez-obex`, `blueman` (`blueman-sendto`) | no aparece el destino Bluetooth |
| **Launcher y terminal** | `kitty` (`t:`, apps de terminal, ejecutar desde el portapapeles) | no abre terminales |
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

---

## TODO

Lo que falta por terminar, ordenado por prioridad y comparado con otras shells de Quickshell (Caelestia, DankMaterialShell, Noctalia, illogical-impulse).
Ya está hecho: barra, launcher, wallpapers, menú de sesión, bloqueo e inactividad, workspaces (clic, rueda y vista general), centro de control con OSD, panel de energía, portapapeles, notificaciones, tray y Zoom.

### 🔴 Prioridad alta: lo básico de toda shell

#### OSD de volumen y brillo
- [x] OSD: con las teclas de volumen, brillo o micrófono, la hora de la isla central se reemplaza 1,5 s por ícono, barra y porcentaje.
- [x] Teclas de volumen, mute y micrófono en Hyprland (`hypr/keybinds/media.lua`), por IPC `stixshell@audio`.
- [x] Teclas de brillo (`XF86MonBrightnessUp/Down`), por IPC `stixshell@brightness`.

> Módulos: `Quickshell.Services.Pipewire` (ya en `AudioStore`) y `IpcHandler`.
> Cambios de volumen o brillo hechos desde otro programa (pavucontrol, `brightnessctl` a mano) no muestran el OSD: solo sale con las teclas.

#### Brillo de pantalla
- [x] Slider de brillo en el centro de control (`Super+C`), con mínimo de 5 %.
- [ ] Rueda del mouse sobre el reloj de la isla central para subir o bajar el volumen o el brillo (alternativa por decidir).

> Tienes `brightnessctl` y `/sys/class/backlight/amdgpu_bl0`.

#### Red (Wi-Fi)
- [ ] Indicador en la barra: conectado o desconectado, y la intensidad de la señal.
- [ ] Panel con la lista de redes, conectar y desconectar, y un switch para apagar el Wi-Fi.
- [ ] Pedir la contraseña con el `TextField` existente.

> Módulo: `Quickshell.Networking`, que viene en tu Quickshell 0.3.2. Respaldo: `nmcli`. NetworkManager está activo.

#### Bluetooth
- [ ] Indicador en la barra: apagado, encendido o conectado.
- [ ] Panel con los dispositivos emparejados: conectar, desconectar, nivel de batería y un switch para apagarlo.

> Módulo: `Quickshell.Bluetooth`. `bluez` está activo.

#### Menú de sesión y energía
- [x] Bloquear, cerrar sesión, suspender, reiniciar y apagar.
- [x] Atajo de teclado más IPC (`stixshell@session`).
- [x] Pedir confirmación antes de apagar o reiniciar.

> En Void no hay `systemctl`: usar `loginctl poweroff|reboot|suspend` (elogind).

#### Pantalla de bloqueo e inactividad
- [x] Pantalla de bloqueo propia (`Super+L`): wallpaper difuminado, reloj, fecha, usuario, contraseña con PAM, batería y botones de suspender, reiniciar y apagar. `hyprlock` queda de respaldo si la shell no corre.
- [x] Inactividad (`IdleStore`), con tiempos distintos con batería y con cargador (`Config.idle`): atenuar, bloquear, apagar la pantalla y suspender.
- [x] Bloquear antes de suspender, también al cerrar la tapa (hypridle).
- [x] Respetar el modo cafeína: pausa atenuar, bloquear, apagar la pantalla y suspender.
- [ ] Opcional: huella digital, Bloq Mayús y notificaciones en la pantalla de bloqueo.

> Módulos: `Quickshell.Wayland` (`WlSessionLock`, `IdleMonitor`) y `Quickshell.Services.Pam`.
> `hypridle` solo conecta el bloqueo con el sistema (`hypr/hypridle.conf`); los tiempos de inactividad los maneja la shell.
> Los videos en reproducción ya evitan el bloqueo, porque `IdleMonitor` respeta los inhibidores.

#### Control multimedia (MPRIS)
- [ ] Mostrar en la barra lo que está sonando: título y artista.
- [ ] Panel con carátula, play/pausa, anterior/siguiente y barra de progreso.

> Módulo: `Quickshell.Services.Mpris`. Tienes `playerctl` como respaldo.

---

### 🟡 Prioridad media: calidad de vida

#### Workspaces
- [x] Clic para cambiar de workspace.
- [x] Rueda del mouse para pasar al siguiente o anterior (se detiene en 1 y 4).
- [x] ~~Cantidad dinámica~~: descartado, se quedan 4 fijos.
- [x] Arrastrar ventanas entre workspaces, desde la vista general.
- [x] Ícono y título de cada ventana en la vista general (así se distinguen dos del mismo programa).

> Módulo: `Quickshell.Hyprland` (`Hyprland.dispatch`). Recuerda la sintaxis Lua de tu Hyprland.

#### Ventana activa
- [ ] Mostrar el título o el nombre de la app enfocada en la barra.

> `Hyprland.activeToplevel` o `ToplevelManager.activeToplevel`.

#### Calendario y fecha
- [ ] Mostrar la fecha en el reloj o en un tooltip.
- [ ] Calendario mensual en un panel.

#### Historial del portapapeles
- [x] Historial de `cliphist` en la isla central (`Super+H`): búsqueda, vista previa de texto e imágenes, copiar, eliminar y borrar todo.
- [x] Lanzar los dos `wl-paste --watch cliphist store` (texto e imagen) en `autostart.lua`.
- [x] Acciones: código QR del texto, compartir (por Bluetooth; la lista de destinos es ampliable), ejecutar en la terminal y, para imágenes, abrir con otra aplicación.
- [x] Imágenes copiadas desde un gestor de archivos (Nemo guarda solo la ruta): se muestran y se copian como imagen.
- [x] El QR declara UTF-8 (ECI), así que las tildes se leen bien en el teléfono.
- [x] Archivos copiados desde un gestor de archivos (Nemo guarda solo las rutas como texto): uno o varios, de cualquier tipo (PDF, Word, carpetas…). Se muestran con su ícono, tipo y tamaño; se pueden copiar (las rutas), abrir con otra app (uno solo), compartir por Bluetooth (varios a la vez, sin carpetas) y eliminar. Si una ruta ya no existe se marca; si ninguna existe, es un texto más.
- [ ] Opcional: pegar solo al elegir en el portapapeles (ya hay `wtype`, falta hacerlo ahí) y más destinos para compartir (KDE Connect, LocalSend…).

> Para el QR hace falta `python3-qrcode` y, para compartir por Bluetooth, `bluez-obex` (`sudo xbps-install -Su python3-qrcode bluez bluez-obex`).

#### Capturas de pantalla
- [ ] Captura de región, ventana o pantalla completa, con una notificación y copia al portapapeles.
- [ ] Opcional: grabación de pantalla con un indicador en la barra.

> Tienes `slurp`, pero **falta `grim`** (y `wf-recorder` para grabar). Alternativa nativa: `ScreencopyView` de Quickshell.

#### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell.

#### Launcher
- [x] Se abre solo con `Super+R` (ya no con el clic en el reloj), y `Super+R` también lo cierra.
- [x] Favoritos: cada app tiene una estrella (o `Ctrl+D`); los favoritos van arriba. Se guardan en `settings.json`.
- [x] Orden por uso, búsqueda sin tildes (nombre, palabras clave y categorías en español) y acciones de las apps ("Firefox · New Private Window").
- [x] Prefijos: `e:` emojis (base de GTK en español), `c:` calculadora y `t:` terminal (con historial de comandos).
- [x] Acciones de sesión como resultados más: apagar, reiniciar, bloquear… (apagar, reiniciar y cerrar sesión piden un segundo Enter).
- [x] Ejecutar en terminal: kitty con tu shell (`bash -ic`), así que `sudo` y las confirmaciones se responden en la ventana. Las apps con `Terminal=true` (nvim) se abren en kitty.
- [x] Emojis y resultados de la calculadora: se escriben en la ventana activa con `wtype`; sin `wtype` se copian.
- [x] `wtype` instalado: los emojis y la calculadora se escriben en la ventana activa.

#### Inhibidor de inactividad (modo "cafeína")
- [x] Switch "No bloquear ni apagar" en el panel de la pill de batería (con una taza en la pill mientras está activo; no se guarda al reiniciar).

> `IdleInhibitor` de `Quickshell.Wayland`.

#### Batería y energía
- [x] Avisos de batería baja (20 %), crítica (10 %) y suspensión (5 %), con umbrales configurables en el panel de la batería.
- [x] Panel de energía en la pill de batería: estado, tiempos de inactividad con batería y con cargador, brillo al atenuar y avisos.
- [x] Perfiles de energía (`power-profiles-daemon`) en el panel de la batería: un perfil para la batería y otro para el cargador (Ahorro, Equilibrado o Rendimiento), que se aplica solo al enchufar o desenchufar. Si algo lo cambia por fuera (Fn+Q, otra app), se respeta y el panel avisa.
- [x] Modo conservación del IdeaPad ("Cargar hasta 60 %") en el panel. Necesita `sudo sh system/conservation-mode.sh` una vez (regla udev que da permiso al grupo `video`; ya probado: el panel escribe 1 y 0).
- [ ] Opcional: pasar a Ahorro al llegar a batería baja, mostrar el perfil en la pill y un atajo de teclado para cambiarlo.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

#### Panel de controles rápidos (Control Center)
- [x] Centro de control en la isla central (`Super+C` o clic derecho en el reloj): No molestar, brillo, y salida y micrófono con mute, 150 % y dispositivos.
- [ ] Faltan en el centro de control: Wi-Fi, Bluetooth, luz nocturna y luz del teclado (`platform::kbd_backlight`).

---

### 🟢 Prioridad baja / extras

- [ ] **Multi-monitor:** hoy hay una sola barra (`PanelWindow`). Crear una por pantalla con `Variants { model: Quickshell.screens }`.
- [ ] **Monitor del sistema:** CPU, RAM, temperatura y disco, leyendo `/proc` y `/sys`. Para temperaturas detalladas falta `lm_sensors` (`sensors`).
- [ ] **Luz nocturna:** **falta** `hyprsunset` o `wlsunset`.
- [ ] **Indicador de distribución del teclado** (us/es): evento `activelayout` de Hyprland.
- [ ] **Indicadores de privacidad:** avisar cuando el micrófono, la cámara o la pantalla están en uso. Para el micrófono, con `Pipewire.linkGroups`.
- [ ] **Clima:** consulta a wttr.in u Open-Meteo con `Process`/`curl`, en el panel del reloj.
- [ ] **Agente de polkit propio** con el estilo de la shell, usando `Quickshell.Services.Polkit`. Hoy usas `hyprpolkitagent`.
- [ ] **Colores dinámicos según el wallpaper** (matugen): `Theme.qml` se generaría a partir del fondo.
- [ ] **Widgets de escritorio:** reloj grande sobre el wallpaper.
- [ ] **Visualizador de audio** (cava) en la isla o en el fondo.

---

### 🧹 Deuda técnica

- [ ] **Esc duplicado:** `shell.qml` ya cierra cualquier panel con un `Shortcut`, pero siguen los manejadores viejos en `Island.qml` y `Wallpapers.qml`.
  Cuando confirmes que Esc cierra Notificaciones y el launcher, hay que quitar los viejos.

---

## Referencias
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
