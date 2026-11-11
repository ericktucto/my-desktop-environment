# TODO de la shell

Lo que falta por hacer, comparado con las shells de Quickshell más usadas: **Caelestia**, **DankMaterialShell**, **Noctalia** e **illogical-impulse** (end-4).
Está ordenado por prioridad; junto a cada tarea se indica qué módulo de Quickshell o qué herramienta sirve.
Lo que la shell ya hace está en el [README](../README.md).

## 🔴 Prioridad alta: lo básico de toda shell

### Brillo de pantalla
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

### Pantalla de bloqueo e inactividad
- [ ] Opcional: huella digital, Bloq Mayús y notificaciones en la pantalla de bloqueo.

> Módulos: `Quickshell.Wayland` (`WlSessionLock`, `IdleMonitor`) y `Quickshell.Services.Pam`.

### Control multimedia (MPRIS)
- [ ] Mostrar en la barra lo que está sonando: título y artista.
- [ ] Panel con carátula, play/pausa, anterior/siguiente y barra de progreso.

> Módulo: `Quickshell.Services.Mpris`. Tienes `playerctl` como respaldo.

---

## 🟡 Prioridad media: calidad de vida

### Ventana activa
- [ ] Mostrar el título o el nombre de la app enfocada en la barra.

> `Hyprland.activeToplevel` o `ToplevelManager.activeToplevel`.

### Calendario y fecha
- [ ] Mostrar la fecha en el reloj o en un tooltip.
- [ ] Calendario mensual en un panel.

### Historial del portapapeles
- [ ] Opcional: pegar solo al elegir en el portapapeles (ya hay `wtype`, falta hacerlo ahí) y más destinos para compartir (KDE Connect, LocalSend…).

### Capturas de pantalla
- [ ] Captura de región, ventana o pantalla completa, con una notificación y copia al portapapeles.
- [ ] Opcional: grabación de pantalla con un indicador en la barra.

> Tienes `slurp`, pero **falta `grim`** (y `wf-recorder` para grabar). Alternativa nativa: `ScreencopyView` de Quickshell.

### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell.

### Batería y energía
- [ ] Opcional: pasar a Ahorro al llegar a batería baja, mostrar el perfil en la pill y un atajo de teclado para cambiarlo.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

### Panel de controles rápidos (Control Center)
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

## Fuentes consultadas
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
