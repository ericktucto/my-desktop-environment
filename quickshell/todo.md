# TODO de la shell

Lista de lo que le falta a la shell, comparada con las shells de Quickshell más usadas:
**Caelestia**, **DankMaterialShell**, **Noctalia** y **illogical-impulse** (end-4).
Está ordenada por prioridad. Junto a cada tarea se indica qué módulo de Quickshell o qué herramienta ya instalada sirve.

## Lo que ya tienes
- **Barra:**
  - Workspaces: 4 fijos; clic y rueda para cambiar, y vista general (clic derecho o `Super+Tab`) con ícono y título de cada ventana, donde se arrastran ventanas entre workspaces.
  - Zoom: lanzar, enfocar y restaurar desde la bandeja.
- **Isla central:**
  - Reloj.
  - Launcher de apps (`Super+R`).
  - Selector de wallpapers (`Super+W`).
  - Menú de sesión (`Super+Escape` o botón de encendido): bloquear, suspender, cerrar sesión, reiniciar y apagar, con teclado y confirmación.
- **Bloqueo e inactividad:** pantalla de bloqueo propia (`Super+L`) con contraseña PAM; atenúa, bloquea, apaga la pantalla y suspende por inactividad (distinto con batería y cargador); al cerrar la tapa bloquea y suspende.
- **Centro de control** (`Super+C` o clic derecho en el reloj):
  - No molestar.
  - Brillo.
  - Audio: volumen de salida y micrófono, mute, cambio de dispositivo y modo 150%.
- **OSD:** con las teclas de volumen, brillo y micrófono, la isla contraída muestra ícono, barra y porcentaje en lugar de la hora.
- **Batería y energía:** pill con el porcentaje; su panel muestra el estado (tiempo restante, consumo, salud), el modo cafeína, los tiempos de inactividad editables (batería y cargador), el brillo al atenuar y los avisos de batería baja. Todo se guarda en `~/.config/stixshell/settings.json`.
- **Notificaciones:**
  - Pill con campana y contador de no leídas.
  - Popups arriba a la derecha, con acciones y cierre automático.
  - Historial guardado en disco: solo se borra con el cierre de cada tarjeta o con Limpiar.
  - Modo No molestar (las críticas pasan).
  - Títulos y cuerpos largos con botón para expandir.
- **System tray:** se puede plegar y tiene menú contextual propio.
- **Wallpaper:** fondo con transición, radio y margen configurables.
- **Base:** `Config.qml` (tamaños, animaciones, fuentes) y `Theme.qml` (colores) centralizados, controles propios (Slider y Switch) y registro automático de pills con panel (`PanelStore`).
- **Código ordenado (deuda técnica resuelta):**
  - Sin `swaybg` ni logs de depuración.
  - Wallpaper guardado con `FileView`.
  - Colores en `Theme`; fuentes, tamaños y duraciones en `Config`.
  - Pills con panel registradas solas en `PanelStore`.
  - Launcher sin bugs de resaltado.

---

## 🔴 Prioridad alta: lo básico de toda shell

### OSD de volumen y brillo
- [x] OSD: con las teclas de volumen, brillo o micrófono, la hora de la isla central se reemplaza 1,5 s por ícono, barra y porcentaje.
- [x] Teclas de volumen, mute y micrófono en Hyprland (`hypr/keybinds/media.lua`), por IPC `stixshell@audio`.
- [x] Teclas de brillo (`XF86MonBrightnessUp/Down`), por IPC `stixshell@brightness`.

> Módulos: `Quickshell.Services.Pipewire` (ya en `AudioStore`) y `IpcHandler`.
> Cambios de volumen o brillo hechos desde otro programa (pavucontrol, `brightnessctl` a mano) no muestran el OSD: solo sale con las teclas.

### Brillo de pantalla
- [x] Slider de brillo en el centro de control (`Super+C`), con mínimo de 5 %.
- [ ] Rueda del mouse sobre el reloj de la isla central para subir o bajar el volumen o el brillo (alternativa por decidir).

> Tienes `brightnessctl` y `/sys/class/backlight/amdgpu_bl0`.

### Red (Wi-Fi)
- [ ] Indicador en la barra: conectado o desconectado, y la intensidad de la señal.
- [ ] Panel con la lista de redes, conectar y desconectar, y un switch para apagar el Wi-Fi.
- [ ] Pedir la contraseña con el `TextField` existente.

> Módulo: `Quickshell.Networking`, que viene en tu Quickshell 0.3.2. Respaldo: `nmcli`. NetworkManager está activo.

### Bluetooth
- [ ] Indicador en la barra: apagado, encendido o conectado.
- [ ] Panel con los dispositivos emparejados: conectar, desconectar, nivel de batería y un switch para apagarlo.

> Módulo: `Quickshell.Bluetooth`. `bluez` está activo.

### Menú de sesión y energía
- [x] Bloquear, cerrar sesión, suspender, reiniciar y apagar.
- [x] Atajo de teclado más IPC (`stixshell@session`).
- [x] Pedir confirmación antes de apagar o reiniciar.

> En Void no hay `systemctl`: usar `loginctl poweroff|reboot|suspend` (elogind).
> El botón de encendido lo reserva la shell con un inhibidor de elogind, y `system/acpi-shell-keys.sh` evita que acpid apague primero (que cambie el brillo y que suspenda al cerrar la tapa sin bloquear mientras corre la shell).

### Pantalla de bloqueo e inactividad
- [x] Pantalla de bloqueo propia (`Super+L`): wallpaper difuminado, reloj, fecha, usuario, contraseña con PAM, batería y botones de suspender, reiniciar y apagar. `hyprlock` queda de respaldo si la shell no corre.
- [x] Inactividad (`IdleStore`), con tiempos distintos con batería y con cargador (`Config.idle`): atenuar, bloquear, apagar la pantalla y suspender.
- [x] Bloquear antes de suspender, también al cerrar la tapa (hypridle).
- [x] Respetar el modo cafeína: pausa atenuar, bloquear, apagar la pantalla y suspender.
- [ ] Opcional: huella digital, Bloq Mayús y notificaciones en la pantalla de bloqueo.

> Módulos: `Quickshell.Wayland` (`WlSessionLock`, `IdleMonitor`) y `Quickshell.Services.Pam`.
> `hypridle` solo conecta el bloqueo con el sistema (`hypr/hypridle.conf`); los tiempos de inactividad los maneja la shell.
> Los videos en reproducción ya evitan el bloqueo, porque `IdleMonitor` respeta los inhibidores.

### Control multimedia (MPRIS)
- [ ] Mostrar en la barra lo que está sonando: título y artista.
- [ ] Panel con carátula, play/pausa, anterior/siguiente y barra de progreso.

> Módulo: `Quickshell.Services.Mpris`. Tienes `playerctl` como respaldo.

---

## 🟡 Prioridad media: calidad de vida

### Workspaces
- [x] Clic para cambiar de workspace.
- [x] Rueda del mouse para pasar al siguiente o anterior (se detiene en 1 y 4).
- [x] ~~Cantidad dinámica~~: descartado, se quedan 4 fijos.
- [x] Arrastrar ventanas entre workspaces, desde la vista general.
- [x] Ícono y título de cada ventana en la vista general (así se distinguen dos del mismo programa).

> Módulo: `Quickshell.Hyprland` (`Hyprland.dispatch`). Recuerda la sintaxis Lua de tu Hyprland.

### Ventana activa
- [ ] Mostrar el título o el nombre de la app enfocada en la barra.

> `Hyprland.activeToplevel` o `ToplevelManager.activeToplevel`.

### Calendario y fecha
- [ ] Mostrar la fecha en el reloj o en un tooltip.
- [ ] Calendario mensual en un panel.

### Historial del portapapeles
- [ ] Lista de `cliphist` con búsqueda, dentro del launcher o en una pill propia.
- [ ] Lanzar `wl-paste --watch cliphist store` en `autostart.lua`.

> Tienes `cliphist` y `wl-copy`.

### Capturas de pantalla
- [ ] Captura de región, ventana o pantalla completa, con una notificación y copia al portapapeles.
- [ ] Opcional: grabación de pantalla con un indicador en la barra.

> Tienes `slurp`, pero **falta `grim`** (y `wf-recorder` para grabar). Alternativa nativa: `ScreencopyView` de Quickshell.

### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell.

### Launcher
- [ ] Calculadora: escribir `=2+2` o una expresión.
- [ ] Acciones de sesión desde el launcher: apagar, bloquear…
- [ ] Apps favoritas o fijadas, y orden por uso.
- [ ] Opcional: selector de emojis.

### Inhibidor de inactividad (modo "cafeína")
- [x] Switch "No bloquear ni apagar" en el panel de la pill de batería (con una taza en la pill mientras está activo; no se guarda al reiniciar).

> `IdleInhibitor` de `Quickshell.Wayland`.

### Batería y energía
- [x] Avisos de batería baja (20 %), crítica (10 %) y suspensión (5 %), con umbrales configurables en el panel de la batería.
- [x] Panel de energía en la pill de batería: estado, tiempos de inactividad con batería y con cargador, brillo al atenuar y avisos.
- [ ] Opcional: perfiles de energía. **Falta** `power-profiles-daemon`.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

### Panel de controles rápidos (Control Center)
- [x] Centro de control en la isla central (`Super+C` o clic derecho en el reloj): No molestar, brillo, y salida y micrófono con mute, 150 % y dispositivos.
- [ ] Faltan en el centro de control: Wi-Fi, Bluetooth, luz nocturna y luz del teclado (`platform::kbd_backlight`).

---

## 🟢 Prioridad baja / extras

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

## 🧹 Deuda técnica

- [ ] **Esc duplicado:** `shell.qml` ya cierra cualquier panel con un `Shortcut`, pero siguen los manejadores viejos en `Island.qml` y `Wallpapers.qml`.
  Cuando confirmes que Esc cierra Notificaciones y el launcher, hay que quitar los viejos.

---

## Fuentes consultadas
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
