# TODO de la shell

Lo que falta por hacer, comparado con las shells de Quickshell más usadas: **Caelestia**, **DankMaterialShell**, **Noctalia** e **illogical-impulse** (end-4).
Está ordenado por prioridad; junto a cada tarea se indica qué módulo de Quickshell o qué herramienta sirve.
Lo que la shell ya hace está en el [README](../README.md).

## 🔴 Prioridad alta: lo básico de toda shell

### Brillo de pantalla
- [ ] Rueda del mouse sobre el reloj de la isla central para subir o bajar el volumen o el brillo (alternativa por decidir).

> Tienes `brightnessctl` y `/sys/class/backlight/amdgpu_bl0`.

### Productividad: tareas, temporizador y cronómetro
El panel **Productividad** (`Super+P` o clic izquierdo en el reloj) tiene la barra de pestañas **Calendario · Tareas** (`Ctrl+Tab` alterna).
- **Calendario:** vistas Mes, Semana, 3 días y Día, eventos de Google en solo lectura, feriados de Perú, crear evento con el formulario de Google y el próximo evento en el reloj.
- **Tareas (fase 1 hecha):** vistas Hoy, Próximos, Bandeja, Tablero (por estado) y Hechas, proyectos y etiquetas, prioridades, estados, fechas, subtareas, notas en Markdown, links, deshacer, búsqueda y teclas estilo vim.

**Tareas, fase 2: captura**
- [ ] Lenguaje natural en español al crear (`mañana 9am +trabajo #bug p1 30m cada lunes` y URLs), con chips de lo que entendió. Analizador en `services/tasks/Parse.js`, probado con `node`.
- [ ] Quick add global con `Super+Shift+T` (una línea en la isla) y la sugerencia del link copiado en el portapapeles.
- [ ] Prefijo `td:` en el launcher.
- [ ] `scripts/links.py`: título de la página y estado de un PR o issue de GitHub.
- [ ] `scripts/task` para la terminal (`task "texto"` con el repo y la rama de git como link, `task hoy`, `task ls`).

**Tareas, fase 3: el tiempo**
- [ ] Recordatorios con notificación (Hecha · Posponer 10 min · Mañana), por defecto uno a la hora si la tarea tiene hora; los que se perdieron al dormir salen al despertar.
- [ ] Repetición (cada día, laborable, semana, mes, año o cada N; desde la fecha o desde que la completas) y borrar "solo esta vez" o "todas".
- [ ] Tablero Kanban con columnas por estado, arrastrando entre ellas, y el motivo al bloquear.

**Tareas, fase 4: integraciones y extras**
- [ ] Las tareas en el calendario (punto en el mes, fila con check en la lista del día y bloque en la cuadrícula).
- [ ] Contador de tareas en el hover del reloj y resumen de la mañana al primer desbloqueo.
- [ ] Standup (lo de ayer, lo de hoy y lo bloqueado, en Markdown al portapapeles), plantillas y archivo automático de lo hecho hace más de 30 días.
- [ ] Estado de PR e issues de GitHub (sin login para repos públicos; token opcional para los privados).
- [ ] Arrastrar para ordenar la lista con el mouse (hoy se ordena con `Alt+j`/`Alt+k`).
- [ ] **Google Tasks (sincronizar):** la API guarda solo título, notas, fecha (sin hora), subtareas y hecho; prioridad, etiquetas y repetición se quedarían locales.
- [ ] **Foco con el temporizador:** tiempo por tarea cuando exista la pestaña Temporizador.

**Fase 3: Temporizador y cronómetro**
- [ ] Temporizador con tiempos rápidos y uno a medida. Al terminar, notificación y sonido.
- [ ] Cronómetro con vueltas.
- [ ] Ambos siguen corriendo con el panel cerrado, y la isla muestra el tiempo.

**Fase 6: Google Calendar (escribir) y avisos**
- [ ] Crear, editar y borrar eventos desde el panel (hoy se crean en el formulario web de Google; pedirá reconectar con permiso de escritura).
- [ ] Aviso con notificación antes de cada evento, con el enlace de la reunión si lo tiene.

> Herramientas: `FileView`/`JsonAdapter` y `Process` de Quickshell.

---

## 🟡 Prioridad media: calidad de vida

### Historial del portapapeles
- [ ] Opcional: pegar solo al elegir en el portapapeles (ya hay `wtype`, falta hacerlo ahí) y más destinos para compartir (KDE Connect, LocalSend…).

### Ayuda de atajos de teclado
- [ ] Panel con todos los atajos (`Super+/`).
- [ ] `hypr/keybinds/repository.lua` ya guarda la descripción de cada atajo en `S.state`. Falta exportarlo a JSON y mostrarlo en la shell.

### Batería y energía
- [ ] Opcional: pasar a Ahorro al llegar a batería baja, mostrar el perfil en la pill y un atajo de teclado para cambiarlo.

> Módulo: `Quickshell.Services.UPower` (ya lo usas).

---

## 🟢 Prioridad baja / extras

- [ ] **Multi-monitor:** hoy hay una sola barra (`PanelWindow`). Crear una por pantalla con `Variants { model: Quickshell.screens }`.
- [ ] **Monitor del sistema:** CPU, RAM, temperatura y disco, leyendo `/proc` y `/sys`. Para temperaturas detalladas falta `lm_sensors` (`sensors`).
- [ ] **Indicador de distribución del teclado** (us/es): evento `activelayout` de Hyprland.
- [ ] **Indicadores de privacidad:** avisar cuando el micrófono, la cámara o la pantalla están en uso. Para el micrófono, con `Pipewire.linkGroups`.
- [ ] **Clima:** consulta a wttr.in u Open-Meteo con `Process`/`curl`, en el panel de productividad (junto al calendario).
- [ ] **Agente de polkit propio** con el estilo de la shell, usando `Quickshell.Services.Polkit`. Hoy usas `hyprpolkitagent`.
- [ ] **Colores del wallpaper, lo que quedó fuera:** modo claro de la shell, Firefox (pywalfox), Neovim y apps Qt (`qt6ct`); y probar hyprlock con los colores nuevos.
- [ ] **Widgets de escritorio:** reloj grande sobre el wallpaper.
- [ ] **Huella digital en la pantalla de bloqueo:** solo si llegas a tener lector (esta laptop no lo tiene); sería con `Quickshell.Services.Pam`.
- [ ] **Visualizador de audio** (cava) en la isla o en el fondo.
- [ ] **Calendario, ideas que quedaron fuera:** vista Agenda (próximos 14 días), números de semana, horario laboral sombreado, gesto horizontal del touchpad para cambiar de período, cumpleaños de contactos con 🎂, "abrir Google en este día" y elegir los calendarios dentro del panel.

---

## Fuentes consultadas
- [Caelestia shell: lista de funciones](https://github.com/caelestia-dots/shell)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Noctalia: documentación](https://docs.noctalia.dev/noctalia/)
- [illogical-impulse (end-4/dots-hyprland)](https://github.com/end-4/dots-hyprland)
- [Hyprland wiki: configuraciones de ejemplo](https://wiki.hypr.land/Configuring/Example-configurations/)
