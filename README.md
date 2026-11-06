# my-desktop-environment

Mi entorno de escritorio personal sobre **Hyprland**, con una shell propia hecha en **Quickshell (QML)** y la configuración de Hyprland escrita en **Lua**. Corre en **Void Linux**.

La shell es una barra de "pills" (islas) redondeadas sobre un wallpaper con esquinas redondeadas. Algunas pills se expanden en paneles: el launcher, el selector de wallpapers, el audio y las notificaciones.

## Contenido

```
.
├── hypr/            Configuración de Hyprland en Lua
│   ├── hyprland.lua   Monitor, entorno, opciones generales
│   ├── autostart.lua  Servicios que se lanzan al iniciar (portales, polkit, pipewire, qs)
│   └── keybinds/      Atajos de teclado
└── quickshell/      La shell
    ├── shell.qml      Ventanas: wallpaper, barra y popups
    ├── Config.qml     Tamaños, animaciones y fuentes
    ├── Theme.qml      Colores
    ├── Wallpaper.qml  Wallpaper actual (se recuerda entre sesiones)
    ├── assets/svg/    Íconos
    ├── components/    base · controls · indicators · pills · widgets · layouts
    └── services/      audio · notify · panels
```

## Funciones

- **Barra:** Workspaces y botón de Zoom a la izquierda, reloj en el centro, y a la derecha tray, audio, batería y notificaciones.
- **Isla central:** reloj; al abrirla es el **launcher de apps** o el **selector de wallpapers**.
- **Audio:** volumen real de salida y micrófono, mute, cambio de dispositivo, modo 150 %, rueda para el volumen y clic derecho para silenciar.
- **Notificaciones:** pill con campana y contador, popups con acciones, historial guardado en disco (solo se borra tú), modo No molestar y textos largos expandibles.
- **System tray:** íconos plegables y menú contextual propio.
- **Zoom:** lanza, enfoca o restaura Zoom (flatpak) aunque esté en segundo plano.
- **Wallpaper:** transición con fundido y esquinas redondeadas; todo configurable desde `Config.qml`.

## Atajos

| Atajo | Acción |
|---|---|
| `Super+T` | Abrir la terminal (kitty) |
| `Super+Q` | Cerrar la ventana activa |
| `Super+Shift+E` | Salir de Hyprland |
| `Super+R` | Launcher de apps |
| `Super+W` | Selector de wallpapers |
| `Super+1…4` | Ir al workspace |
| `Super+Shift+1…4` | Mandar la ventana al workspace |
| `Super+A` | Mandar/traer la ventana al stash |
| `Super+S` | Ver u ocultar el stash |
| `Super+F` | Maximizar |

El launcher y el selector se abren por IPC: `qs ipc call stixshell@launcher toggle ""` y `qs ipc call stixshell@wallpaper toggle ""`.
`Esc` o un clic fuera cierran cualquier panel.

## Requisitos

- **Hyprland** con soporte de configuración en Lua.
- **Quickshell 0.3.2** o más reciente (Qt 6).
- **PipeWire** y WirePlumber (audio).
- Fuentes: **Inter**, **JetBrainsMono Nerd Font** y **Symbols Nerd Font**.
- Wallpapers en `~/Pictures/Wallpapers` (`.jpg`, `.jpeg` o `.png`); la carpeta se cambia en `Config.wallpaperPicker.dir`.
- Opcional: **Zoom** por flatpak (`us.zoom.Zoom`) para el botón de Zoom.

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
- Log de la shell: `$(ls -td /run/user/$UID/quickshell/by-id/*/ | head -1)log.log`.

## Personalizar

- **Tamaños, animaciones y fuentes:** `quickshell/Config.qml`.
- **Colores:** `quickshell/Theme.qml`.
- **Nueva pill con panel:** basta con usar `Base.Island` con un `body`; se registra sola en `services/panels/PanelStore.qml` y la barra le da el foco y el "clic fuera".

---

## TODO

Lo que falta por terminar, ordenado por prioridad y comparado con otras shells de Quickshell (Caelestia, DankMaterialShell, Noctalia, illogical-impulse).
Ya está hecho: barra, launcher, wallpapers, audio, notificaciones, tray y Zoom.

### 🔴 Prioridad alta: lo básico de toda shell

#### OSD de volumen y brillo
- [ ] Mostrar un indicador flotante unos segundos al cambiar el volumen, el mute o el brillo.
- [ ] Teclas multimedia en Hyprland (`XF86AudioRaiseVolume`, `XF86MonBrightnessUp`…) que llamen a la shell por IPC.

> Módulos: `Quickshell.Services.Pipewire` (ya en `AudioStore`) y `IpcHandler`.

#### Brillo de pantalla
- [ ] Pill o sección con slider de brillo, reutilizando `components/controls/Slider.qml`.
- [ ] Rueda del mouse sobre la pill para subir o bajar.

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
- [ ] Bloquear, cerrar sesión, suspender, reiniciar y apagar.
- [ ] Atajo de teclado más IPC (`stixshell@session`).
- [ ] Pedir confirmación antes de apagar o reiniciar.

> En Void no hay `systemctl`: usar `loginctl poweroff|reboot|suspend` (elogind).

#### Pantalla de bloqueo e inactividad
- [ ] Pantalla de bloqueo propia con el estilo de la shell: reloj, wallpaper y campo de contraseña.
  - Alternativa: integrar `hyprlock`, que ya está instalado.
- [ ] Inactividad:
  - bloquear tras N minutos;
  - apagar la pantalla;
  - suspender, con valores distintos con cargador y con batería.
- [ ] Bloquear antes de suspender.

> Módulos: `Quickshell.Wayland` (`WlSessionLock`, `IdleMonitor`) y `Quickshell.Services.Pam`.
> También tienes `hypridle`, pero no se lanza en `autostart.lua`.

#### Control multimedia (MPRIS)
- [ ] Mostrar en la barra lo que está sonando: título y artista.
- [ ] Panel con carátula, play/pausa, anterior/siguiente y barra de progreso.

> Módulo: `Quickshell.Services.Mpris`. Tienes `playerctl` como respaldo.

---

### 🟡 Prioridad media: calidad de vida

#### Workspaces
- [ ] **Clic para cambiar de workspace.** Hoy los puntos no reaccionan.
- [ ] Rueda del mouse para pasar al siguiente o anterior.
- [ ] Cantidad dinámica en lugar de 4 fijos, por ejemplo mostrar hasta el último ocupado.
- [ ] Arrastrar ventanas entre workspaces. Es el `@todo` de `Workspaces.qml`.
- [ ] Opcional: íconos de las apps de cada workspace.

> Módulo: `Quickshell.Hyprland` (`Hyprland.dispatch`). Recuerda la sintaxis Lua de tu Hyprland.

#### Ventana activa
- [ ] Mostrar el título o el nombre de la app enfocada en la barra.

> `Hyprland.activeToplevel` o `ToplevelManager.activeToplevel`.

#### Calendario y fecha
- [ ] Mostrar la fecha en el reloj o en un tooltip.
- [ ] Calendario mensual en un panel.

#### Historial del portapapeles
- [ ] Lista de `cliphist` con búsqueda, dentro del launcher o en una pill propia.
- [ ] Lanzar `wl-paste --watch cliphist store` en `autostart.lua`.

> Tienes `cliphist` y `wl-copy`.

#### Capturas de pantalla
- [ ] Captura de región, ventana o pantalla completa, con una notificación y copia al portapapeles.
- [ ] Opcional: grabación de pantalla con un indicador en la barra.

> Tienes `slurp`, pero **falta `grim`** (y `wf-recorder` para grabar). Alternativa nativa: `ScreencopyView` de Quickshell.

#### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell.

#### Launcher
- [ ] Calculadora: escribir `=2+2` o una expresión.
- [ ] Acciones de sesión desde el launcher: apagar, bloquear…
- [ ] Apps favoritas o fijadas, y orden por uso.
- [ ] Opcional: selector de emojis.

#### Inhibidor de inactividad (modo "cafeína")
- [ ] Switch para que la pantalla no se bloquee ni se apague (películas, presentaciones).

> `IdleInhibitor` de `Quickshell.Wayland`.

#### Batería y energía
- [ ] Avisos de batería baja y crítica con notificación, y acción en nivel crítico.
- [ ] Opcional: perfiles de energía. **Falta** `power-profiles-daemon`.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

#### Panel de controles rápidos (Control Center)
- [ ] Un panel único con interruptores: Wi-Fi, Bluetooth, DND, cafeína, luz nocturna y mute del micrófono, más los sliders de volumen y brillo.

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
  Cuando confirmes que Esc cierra Audio, Notificaciones y el launcher, hay que quitar los viejos.

---

## Referencias
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
