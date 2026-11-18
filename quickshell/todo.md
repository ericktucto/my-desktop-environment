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
- **Tareas (completas):** vistas Hoy, Próximos, Bandeja, Tablero (por estado) y Hechas, proyectos y etiquetas, prioridades, estados, fechas, subtareas, notas en Markdown, links, deshacer, búsqueda y teclas estilo vim; captura en lenguaje natural (fila Añadir tarea, quick add `Super+Shift+T`, `td:` en el launcher y `scripts/task`), recordatorios con aviso, repetición, Tablero, tareas en el calendario y el reloj, resumen de la mañana, Standup, plantillas, archivo automático y estado de GitHub.

**Tareas: pendientes**
- [ ] Arrastrar para ordenar la lista con el mouse (hoy se ordena con `Alt+j`/`Alt+k`).
- [ ] **Google Tasks (sincronizar):** la API guarda solo título, notas, fecha (sin hora), subtareas y hecho; prioridad, etiquetas y repetición se quedarían locales.
- [ ] **Foco con el temporizador:** tiempo por tarea cuando exista la pestaña Temporizador.

**Temporizador y cronómetro**
- [ ] Temporizador con tiempos rápidos y uno a medida. Al terminar, notificación y sonido.
- [ ] Cronómetro con vueltas.
- [ ] Ambos siguen corriendo con el panel cerrado, y la isla muestra el tiempo.

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
