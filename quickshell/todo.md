# TODO de la shell

Lo que falta por hacer, comparado con las shells de Quickshell más usadas: **Caelestia**, **DankMaterialShell**, **Noctalia** e **illogical-impulse** (end-4).
Está ordenado por prioridad; junto a cada tarea se indica qué módulo de Quickshell o qué herramienta sirve.
Lo que la shell ya hace está en el [README](../README.md).

## 🔴 Prioridad alta: lo básico de toda shell

### Preferencias del sistema (en curso, por fases; detalle en `plan.md`)
Hecha la Fase 1 (ventana, buscador, Apariencia, Luz nocturna, Energía y Acerca de).
- [ ] **Fase 2. Barra e isla:** clics y rueda de la isla central y de cada pill (la rueda: volumen, y con Shift brillo), pills visibles y su orden, reloj y workspaces.
- [ ] **Fase 3. Pantallas:** disposición, resolución, escala, rotación, espejo, perfiles automáticos y `Super+Shift+P`.
- [ ] **Fase 4. Atajos de teclado:** lista, editar grabando la combinación, conflictos y ayuda (`Super+/`).
- [ ] **Fase 5. Sonidos del sistema:** notificaciones, dispositivos, energía y acciones de la shell.
- [ ] **Fase 6. Cuentas:** Google y GitHub.
- [ ] **Fase 7. El resto de las pills:** Notificaciones, Bloqueo y reloj, Apps y launcher, Productividad.

### Brillo de pantalla
- [ ] Rueda del mouse sobre el reloj de la isla central para subir o bajar el volumen o el brillo (alternativa por decidir).

> Tienes `brightnessctl` y `/sys/class/backlight/amdgpu_bl0`.

### Productividad: tareas, temporizador y cronómetro
El panel **Productividad** (`Super+P` o clic izquierdo en el reloj) tiene la barra de pestañas **Calendario · Tareas · Temporizador · Cronómetro** (`Ctrl+Tab` recorre, `Ctrl+1…4` va directo).
- **Calendario:** vistas Mes, Semana, 3 días y Día, eventos de Google en solo lectura, feriados de Perú, crear evento con el formulario de Google y el próximo evento en el reloj.
- **Temporizador y cronómetro:** varios temporizadores a la vez con alarma (sonido y notificación crítica con +1, +5 y Detener), cronómetro con vueltas, pill en la barra que se expande como la de música, `tm:` en el launcher, Pomodoro (ciclos y avisos) y el foco por tarea (detalle, fila y Standup).
- **Tareas (completas):** vistas Hoy, Próximos, Bandeja, Tablero (por estado) y Hechas, proyectos y etiquetas, prioridades, estados, fechas, subtareas, notas en Markdown, links, deshacer, búsqueda, teclas estilo vim y arrastre con el mouse (ordenar, cambiar de día, de columna o de proyecto); captura en lenguaje natural (fila Añadir tarea, quick add `Super+Shift+T`, `td:` en el launcher y `scripts/task`), recordatorios con aviso, repetición, Tablero, tareas en el calendario y el reloj, resumen de la mañana, Standup, plantillas, archivo automático y estado de GitHub.

**Tareas: pendientes**
- [ ] **Google Tasks (sincronizar):** la API guarda solo título, notas, fecha (sin hora), subtareas y hecho; prioridad, etiquetas y repetición se quedarían locales.

**Google Calendar (escribir) y avisos**
- [ ] Crear, editar y borrar eventos desde el panel (hoy se crean en el formulario web de Google; pedirá reconectar con permiso de escritura).
- [ ] Aviso con notificación antes de cada evento, con el enlace de la reunión si lo tiene.

> Herramientas: `FileView`/`JsonAdapter` y `Process` de Quickshell.

---

## 🟡 Prioridad media: calidad de vida

### Historial del portapapeles
- [ ] Opcional: pegar solo al elegir en el portapapeles (ya hay `wtype`, falta hacerlo ahí) y más destinos para compartir (KDE Connect, LocalSend…).

### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell. Con eso, el menú de la ventana activa leería sus atajos de ahí en vez de `Config.activeWindow.hyprKeys` (hoy escritos a mano).

### Batería y energía
- [ ] Opcional: pasar a Ahorro al llegar a batería baja, mostrar el perfil en la pill y un atajo de teclado para cambiarlo.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

---

## 🟢 Prioridad baja / extras

- [ ] **Pill de la ventana activa, lo que quedó fuera:** el menú real de la app («Archivo, Editar…»; hoy no existe en Hyprland, solo si implementa `org_kde_kwin_appmenu`), un buscador de acciones tipo paleta de comandos y las acciones del menú también en la vista general de workspaces.
- [ ] **Multi-monitor:** hoy hay una sola barra (`PanelWindow`). Crear una por pantalla con `Variants { model: Quickshell.screens }`.
- [ ] **Monitor del sistema:** CPU, RAM, temperatura y disco, leyendo `/proc` y `/sys`. Para temperaturas detalladas falta `lm_sensors` (`sensors`).
- [ ] **Indicador de distribución del teclado** (us/es): evento `activelayout` de Hyprland.
- [ ] **Indicadores de privacidad:** avisar cuando el micrófono, la cámara o la pantalla están en uso. Para el micrófono, con `Pipewire.linkGroups`.
- [ ] **Clima:** consulta a wttr.in u Open-Meteo con `Process`/`curl`, en el panel de productividad (junto al calendario).
- [ ] **Agente de polkit propio** con el estilo de la shell, usando `Quickshell.Services.Polkit`. Hoy usas `hyprpolkitagent`.
- [ ] **Colores del wallpaper, lo que quedó fuera:** modo claro de la shell, Firefox (pywalfox), Neovim y apps Qt (`qt6ct`); y probar hyprlock con los colores nuevos.
- [ ] **Widgets de escritorio:** reloj grande sobre el wallpaper.
- [ ] **Huella digital en la pantalla de bloqueo:** solo si llegas a tener lector (esta laptop no lo tiene); sería con `Quickshell.Services.Pam`.
- [ ] **Panel de Wi-Fi, lo que quedó fuera:** velocidad ↓ ↑ (`/proc/net/dev`), latencia, canal, dBm y velocidad del enlace (`iw`). Necesitan polling: solo con el panel abierto. El último handshake y los bytes de la VPN piden `wg show` (root).
- [ ] **Visualizador de audio** (cava) en la isla o en el fondo.
- [ ] **Calendario, ideas que quedaron fuera:** vista Agenda (próximos 14 días), números de semana, horario laboral sombreado, gesto horizontal del touchpad para cambiar de período, cumpleaños de contactos con 🎂, "abrir Google en este día" y elegir los calendarios dentro del panel.

---

## Fuentes consultadas
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
