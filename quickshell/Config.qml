pragma Singleton
import Quickshell
import QtQuick

// Configuración de tamaños. Se lee como App.Config.pill.height, etc.
Singleton {
    id: root

    // Escala de las animaciones (1 = normales, 0 = sin animaciones); la fija SettingsStore (Preferencias → Apariencia)
    property real animScale: 1

    // ===== Wallpaper de fondo =====
    readonly property QtObject wallpaper: QtObject {
        readonly property int radius: 16
        readonly property int marginTop: 0
        readonly property int marginRight: 0
        readonly property int marginBottom: 0
        readonly property int marginLeft: 0
    }

    // ===== Selector de wallpapers =====
    readonly property QtObject wallpaperPicker: QtObject {
        readonly property int spacingCell: 12
        readonly property int imgWidth: 200
        readonly property int imgHeight: imgWidth * 9 / 16
        readonly property int borderImg: 4
        readonly property int radius: 8
        readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"   // carpeta de wallpapers
        readonly property int themeRow: 44                // fila de colores del wallpaper (arriba del grid)
        readonly property int tintRow: 36                 // fila «Colorear» (Neutro, Teñido, Intenso)
    }

    // ===== Barra =====
    readonly property QtObject bar: QtObject {
        readonly property int marginLeft: 8
        readonly property int marginRight: 12
        readonly property int spacing: 8             // separación entre pills
        readonly property int gapBelow: 8            // aire debajo de las pills
        readonly property int exclusiveZone: root.pill.top + root.pill.height + gapBelow
    }

    // ===== Bluetooth (vista del centro de control, services/bluetooth) =====
    readonly property QtObject bluetooth: QtObject {
        readonly property int rowHeight: 52
        readonly property int scanTimeout: 60000     // ms buscando dispositivos nuevos
        readonly property int armDelay: 3000         // ms tras arrancar antes de recordar los cambios de encendido y avisar
        readonly property int messageTime: 3000      // "No se pudo conectar"
        readonly property int lowBattery: 15         // % para el aviso de batería baja
        // Glifo (fuente de íconos) según el `icon` que da BlueZ
        readonly property var glyphs: ({
                "phone": 0xf03f2,
                "input-mouse": 0xf037d,
                "input-gaming": 0xf0297,
                "audio-headset": 0xf02cb,
                "audio-headphones": 0xf02cb,
                "input-keyboard": 0xf030c,
                "audio-card": 0xf04c3,
                "computer": 0xf0322
            })
        readonly property int glyphDefault: 0xf00af
    }

    // ===== Red: Wi-Fi y VPN (vista del centro de control, services/network) =====
    readonly property QtObject network: QtObject {
        readonly property int rowHeight: 52
        readonly property int ring: 110              // anillo de señal del panel de la pill
        readonly property int messageTime: 3000      // "Contraseña incorrecta", "No se pudo conectar la VPN"
        readonly property int refreshDebounce: 400   // ms tras un evento de nmcli monitor antes de releer las VPN
        // Interfaces virtuales (Docker y similares): no se muestran
        readonly property var ignoredDevices: /^(docker|br-|veth|virbr|lo$)/
        readonly property string portalUrl: "http://neverssl.com"        // respaldo si no se averigua la página del router
        // Dirección que verifica NetworkManager (system/networkmanager.sh); el router la intercepta y nos da su página
        readonly property string checkUrl: "http://nmcheck.gnome.org/check_network_status.txt"
        readonly property int recheck: 10000         // ms entre verificaciones mientras hay portal o sin internet
        readonly property int limitedDelay: 5000     // ms en "limited" antes de decir "Sin internet"
        readonly property int pskTimeout: 30000      // ms esperando que conecte con la contraseña
        // Solo para probar sin un portal real: "" | "portal" | "limited"
        readonly property string testConnectivity: ""
        // Señal en cuatro niveles (de menos a más), con alerta, sin conexión, cable, candado, VPN y ojo
        readonly property var signalGlyphs: [0xf091f, 0xf0922, 0xf0925, 0xf0928]
        readonly property var signalGlyphsAlert: [0xf0920, 0xf0923, 0xf0926, 0xf0929]
        readonly property int glyphAlert: 0xf0026
        readonly property int glyphOff: 0xf092e
        readonly property int glyphWired: 0xf0200
        readonly property int glyphLock: 0xf033e
        readonly property int glyphVpn: 0xf0582
        readonly property int glyphEye: 0xf06d0
        readonly property int glyphGear: 0xf0493
        readonly property int glyphQr: 0xf0432
        // DNS que se pueden elegir en los detalles de una red ("Automático" y "Personalizado" van aparte)
        readonly property var dnsPresets: [
            {
                label: "Cloudflare",
                dns: "1.1.1.1,1.0.0.1"
            },
            {
                label: "Google",
                dns: "8.8.8.8,8.8.4.4"
            },
            {
                label: "Quad9",
                dns: "9.9.9.9,149.112.112.112"
            }
        ]
        // Prioridad del DNS de una VPN de todo el tráfico (negativa = solo se usa el suyo); la aplica scripts/vpn-import.py
        readonly property int vpnDnsPriority: -50
    }

    // ===== Luz nocturna (wlsunset) =====
    readonly property QtObject nightLight: QtObject {
        readonly property int tempMin: 2500          // K de noche (el slider)
        readonly property int tempMax: 5500
        readonly property int tempStep: 100
        readonly property int temperature: 4000      // por defecto
        readonly property int dayTemperature: 6500   // sin filtro; de aquí parte la transición
        readonly property string start: "19:00"     // horas fijas: empieza a entibiar
        readonly property string end: "07:00"
        readonly property int transition: 1800      // s que tarda en pasar de día a noche y al revés
        readonly property int timeStep: 15          // min de cada paso de las horas
        readonly property int previewTime: 3000     // ms de vista previa al cambiar la temperatura de día
        readonly property int tick: 60000           // revisión: pausa vencida, cambio de día, reintentos
        readonly property int restartDelay: 3000    // ms antes de relanzar hyprsunset si se cierra solo
        // Si no se encuentra la zona horaria (Lima)
        readonly property real latitude: -12.05
        readonly property real longitude: -77.05
        readonly property int glyph: 0xf0594
    }

    // ===== Pill de la ventana activa =====
    readonly property QtObject activeWindow: QtObject {
        readonly property int maxWidth: 300          // la pill no pasa de este ancho (los paneles del centro empiezan en x ≈ 520)
        readonly property int iconSize: 16
        readonly property int tooltipDelay: 600
        readonly property int panelWidth: 380        // ancho de la isla de menús (clic izquierdo o derecho)
        readonly property int killConfirmMs: 3000    // «Forzar cierre» espera este tiempo el segundo clic
        // Atajos de Hyprland que se muestran junto a cada acción de la pestaña «Ventana» (a mano: si se cambia
        // uno en hypr/keybinds hay que cambiarlo también aquí)
        readonly property var hyprKeys: ({
                float: "SUPER+V",
                pin: "SUPER+SHIFT+V",
                center: "SUPER+CTRL+V",
                maximize: "SUPER+F",
                fullscreen: "SUPER+SHIFT+F",
                group: "SUPER+SHIFT+G",
                capture: "Print",
                close: "SUPER+Q",
                moveTo: "SUPER+SHIFT+1…4",
                stash: "SUPER+A"
            })
        // Letra subrayada (la que ejecuta la fila con el teclado) de cada acción de la pestaña «Ventana»
        readonly property var windowMnemonics: ({
                float: "f",
                pin: "j",
                center: "c",
                maximize: "m",
                fullscreen: "p",
                group: "g",
                capture: "t",
                monitor: "o",
                close: "e",
                kill: "z"
            })
        // Atajos que el menú «App» manda a la ventana (formato "CTRL+SHIFT+C")
        readonly property var shortcuts: [
            { label: "Deshacer", keys: "CTRL+Z" },
            { label: "Rehacer", keys: "CTRL+SHIFT+Z" },
            { label: "Cortar", keys: "CTRL+X" },
            { label: "Copiar", keys: "CTRL+C" },
            { label: "Pegar", keys: "CTRL+V" },
            { label: "Seleccionar todo", keys: "CTRL+A" },
            { label: "Buscar", keys: "CTRL+F" },
            { label: "Guardar", keys: "CTRL+S" }
        ]
        // Ajustes por app (appId en minúsculas): `replace` cambia la lista común por `items`; si no, se suman
        readonly property var appShortcuts: ({
                "kitty": {
                    replace: true,
                    items: [
                        { label: "Copiar", keys: "CTRL+SHIFT+C" },
                        { label: "Pegar", keys: "CTRL+SHIFT+V" },
                        { label: "Buscar", keys: "CTRL+SHIFT+H" },
                        { label: "Nueva pestaña", keys: "CTRL+SHIFT+T" },
                        { label: "Nueva ventana", keys: "CTRL+SHIFT+N" }
                    ]
                },
                "firefox": {
                    replace: false,
                    // Atajo de cada acción del .desktop (solo para mostrarlo)
                    actionKeys: { "new-window": "CTRL+N", "new-private-window": "CTRL+SHIFT+P" },
                    items: [
                        { label: "Nueva pestaña", keys: "CTRL+T" },
                        { label: "Cerrar pestaña", keys: "CTRL+W" },
                        { label: "Reabrir pestaña", keys: "CTRL+SHIFT+T" },
                        { label: "Recargar", keys: "F5" },
                        { label: "Historial", keys: "CTRL+H" },
                        { label: "Descargas", keys: "CTRL+SHIFT+Y" }
                    ]
                }
            })
    }

    // ===== Pills =====
    readonly property QtObject pill: QtObject {
        readonly property int top: 8
        readonly property int height: 28
        readonly property int paddingX: 16           // padding horizontal con la pill cerrada
        readonly property int contentSpacing: 8      // entre ícono y texto
        readonly property int padding: 36            // padding con la pill abierta (estándar)
        readonly property int radiusExpanded: 32
        readonly property int iconSize: 16           // ícono de las pills plegadas (Zoom, Notificaciones)
    }

    // ===== Tamaño de cada pill abierta =====
    readonly property QtObject panel: QtObject {
        readonly property int launcherWidth: 480
        readonly property int launcherHeight: 600
        readonly property int wallpapersWidth: 800
        readonly property int controlCenterWidth: 460
        readonly property int notificationsWidth: 420
        readonly property int batteryWidth: 420
        readonly property int clipboardWidth: 880
        readonly property int clipboardHeight: 520
        readonly property int recorderWidth: 460
        readonly property int productivityWidth: 680
        readonly property int networkWidth: 440
    }

    // ===== Fuentes =====
    readonly property QtObject fontSize: QtObject {
        readonly property int xs: 11
        readonly property int sm: 12
        readonly property int md: 13
        readonly property int lg: 14
        readonly property int icon: 16
        readonly property int iconLg: 18
    }

    // ===== Fuentes (familias) =====
    readonly property QtObject fonts: QtObject {
        readonly property string text: "Inter"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property string icons: "Symbols Nerd Font"
    }

    // ===== Launcher =====
    readonly property QtObject launcher: QtObject {
        readonly property int rowHeight: 52
        readonly property int iconSize: 32
        readonly property int searchHeight: 40
        readonly property int historyMax: 20        // comandos recordados en t:
        readonly property int pasteDelay: 150       // ms entre cerrar la isla y escribir con wtype
        readonly property int emojiSize: 24
        readonly property int maxResults: 60
        readonly property int helpHeight: 22        // pie de ayuda
    }

    // ===== Workspaces =====
    readonly property QtObject workspaces: QtObject {
        readonly property int count: 4
        readonly property int dotSize: 10
        readonly property int activeWidth: 20
        readonly property int spacing: 10
        readonly property int wheelStep: 120        // angleDelta por paso de rueda (el touchpad acumula)
        // Vista general: una tarjeta por workspace, con una fila (ícono + título) por ventana
        readonly property int cardWidth: 200
        readonly property int cardSpacing: 12
        readonly property int cardPadding: 10
        readonly property int cardRadius: 20
        readonly property int headerHeight: 22      // fila del número de workspace
        readonly property int rowHeight: 28
        readonly property int rowSpacing: 4
        readonly property int iconSize: 20
        readonly property int minRows: 2            // alto mínimo de las tarjetas (en filas)
        readonly property int maxRows: 6            // más ventanas → la última fila dice "+N más"
    }

    // ===== Radios pequeños (tarjetas, resaltados) =====
    readonly property QtObject radius: QtObject {
        readonly property int sm: 6
        readonly property int md: 8
    }

    // ===== System tray =====
    readonly property QtObject tray: QtObject {
        readonly property int iconSize: 16
        // Menú contextual
        readonly property int menuMinWidth: 200
        readonly property int menuItemHeight: 28
        readonly property int menuPadding: 6
        readonly property int menuIndent: 12        // sangría de los submenús
    }

    // ===== Zoom =====
    readonly property QtObject zoom: QtObject {
        readonly property string appId: "us.zoom.Zoom"
        // Ícono de respaldo si el tema no lo encuentra (flatpak)
        readonly property string fallbackIcon: "file:///var/lib/flatpak/exports/share/icons/hicolor/64x64/apps/us.zoom.Zoom.png"
    }

    // ===== Notificaciones =====
    readonly property QtObject notifications: QtObject {
        readonly property int popupWidth: 380
        readonly property int popupTimeout: 5000     // ms, si la app no indica uno
        readonly property int maxPopups: 3           // popups simultáneos (el resto solo va al historial)
        readonly property int spacing: 8             // entre tarjetas
        readonly property int imageSize: 40          // círculo de imagen/ícono de la tarjeta
        readonly property int appIconSize: 22        // ícono de app dentro del círculo
        readonly property int cardRadius: 20         // radio de las tarjetas
        readonly property int cardPadding: 14        // padding interno de la tarjeta
        readonly property int closeSize: 24          // botón cerrar de la tarjeta
        readonly property int headerHeight: 40       // alto de la fila de botones del panel
        readonly property int headerIconSize: 18     // ícono de los botones del encabezado
        readonly property int summaryLines: 1        // título plegado
        readonly property int bodyLines: 3           // cuerpo plegado en el historial
        readonly property int popupBodyLines: 2      // cuerpo plegado en los popups
        readonly property int expandedMaxHeight: 240 // alto máx. del cuerpo expandido (luego scroll)
        readonly property int listMaxHeight: 560     // alto máx. de la lista del panel (luego scroll)
        readonly property int clearConfirm: 3000     // ms que el botón Limpiar espera el segundo clic
    }

    // ===== Menú de sesión =====
    readonly property QtObject session: QtObject {
        readonly property int buttonSize: 88        // botón cuadrado redondeado
        readonly property int iconSize: 32
        readonly property int spacing: 16           // entre botones
        readonly property int labelGap: 10          // entre botón y texto
        readonly property int labelHeight: 18
        readonly property int defaultIndex: 4       // 4 = Apagar
        readonly property int confirmTimeout: 3000  // ms del "¿Apagar?"
        readonly property int suspendDelay: 1000    // ms entre bloquear y suspender
        readonly property bool dryRun: false        // true = solo registra el comando en el log (para probar)
        // tamaño de la isla abierta (5 botones + padding estándar)
        readonly property int width: 5 * buttonSize + 4 * spacing + 2 * root.pill.padding
        readonly property int height: buttonSize + labelGap + labelHeight + 2 * root.pill.padding
    }

    // ===== OSD (volumen/brillo en la isla central contraída) =====
    readonly property QtObject osd: QtObject {
        readonly property int timeout: 1500         // ms visible desde la última tecla
        readonly property int iconSize: 16
        readonly property int barWidth: 96
        readonly property int barHeight: 6
        readonly property int percentWidth: 36      // ancho fijo del "100%", para que la pill no tiemble
        // Estirado al seguir pulsando con el nivel en el tope (volumen o brillo)
        readonly property int edgeStep: 12          // px de exceso por pulsación en el tope
        readonly property int edgeMax: 16           // px máximos que crece la isla
        readonly property real edgeResistance: 0.55 // la goma: cada pulsación estira menos
        readonly property int edgeHold: 250         // ms estirada tras la última pulsación
    }

    // ===== Brillo de pantalla =====
    readonly property QtObject brightness: QtObject {
        readonly property real min: 0.05            // nunca por debajo (pantalla negra)
        readonly property real keyStep: 0.05        // paso de las teclas
        readonly property int writeDelay: 30        // ms para agrupar escrituras al arrastrar el slider
    }

    // ===== Pantalla de bloqueo =====
    readonly property QtObject lock: QtObject {
        readonly property int clockSize: 96
        readonly property int dateSize: 20
        readonly property int userSize: 16
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 48
        readonly property real blur: 1.0            // 0..1
        readonly property int blurMax: 64
        readonly property real dim: 0.45            // oscurecido del wallpaper
        readonly property int powerSpacing: 24
        readonly property int confirmTimeout: 3000  // ms del "¿Apagar?"
        readonly property int errorShake: 300       // ms de la sacudida al fallar la contraseña
        readonly property int margin: 24
        // Notificaciones, Bloq Mayús/Num y música del bloqueo
        readonly property int notifyWidth: 380
        readonly property int notifyMax: 4          // apps (tarjetas); el resto, "+N más"
        readonly property int notifyMaxAge: 86400   // s: solo las no leídas de las últimas 24 h
        readonly property int keyPoll: 2000         // ms entre lecturas de Bloq Mayús, Bloq Num y la tapa
        readonly property int mediaArt: 48
        readonly property var laptopOutputs: /^eDP/ // las notificaciones salen en la pantalla de la laptop
        readonly property string lidState: "/proc/acpi/button/lid/LID/state"
        // > 0 = al bloquear se desbloquea solo a los N s (solo para probar sin quedarte fuera)
        readonly property int testAutoUnlock: 0
    }

    // ===== Calendario (panel Productividad, scripts/gcal.py) =====
    readonly property QtObject calendar: QtObject {
        readonly property int viewHeight: 320        // zona de la vista (mes u horas); igual en las cuatro
        readonly property int listHeight: 200        // lista de eventos del día elegido
        readonly property int headerHeight: 32
        readonly property int hourHeight: 32         // alto de una hora en la cuadrícula
        readonly property int gutterWidth: 44        // columna de las horas
        readonly property int dots: 3                // puntos de color por día en la vista Mes
        readonly property int minGap: 60             // s: al abrir no se repite la llamada antes de esto
        readonly property int loginTimeout: 180      // s esperando que aceptes en el navegador
        readonly property int resumeGap: 180         // s sin tick del reloj = la laptop despertó
        readonly property int upcoming: 7200         // s hacia adelante para el aviso del reloj
        readonly property int titleMax: 24           // letras del evento en el reloj
        readonly property int defaultStartHour: 8    // hora inicial de la cuadrícula si el día no tiene eventos
        readonly property int newEventHour: 9        // hora de un evento nuevo en un día que no es hoy
        readonly property string timeZone: "America/Lima"
        // Calendario público de feriados de Google (vacío = sin feriados)
        readonly property string holidays: "es.pe#holiday@group.v.calendar.google.com"
        readonly property int holidaysMaxAge: 7      // días antes de volver a bajarlos
        readonly property string cache: Quickshell.cachePath("calendar.json")
        readonly property string holidaysCache: Quickshell.cachePath("holidays.json")
        // Ruta a un JSON de eventos de ejemplo (solo para probar sin Google); vacío = Google
        readonly property string testSample: ""
    }

    // ===== Tareas (pestaña del panel Productividad, services/tasks/TaskStore.qml) =====
    readonly property QtObject tasks: QtObject {
        readonly property int panelWidth: 860        // ancho de la isla en la pestaña Tareas
        readonly property int sidebarWidth: 190
        readonly property int quickWidth: 560        // ancho de la isla en el quick add (Super+Shift+T)
        readonly property int rowHeight: 44
        readonly property int undoTime: 5000         // ms que dura el aviso "Deshacer"
        readonly property int undoDepth: 20          // cambios que se pueden deshacer
        readonly property int archiveDays: 30        // lo completado hace más se archiva
        readonly property int upcomingDays: 7        // días de la vista Próximos
        readonly property int summaryHour: 8         // hora desde la que sale el resumen de la mañana
        readonly property int linkMaxAge: 30         // min: el estado de un PR de GitHub se vuelve a pedir pasado este tiempo
        readonly property int linkRefreshMax: 8      // links que se refrescan de una vez al abrir el panel
        readonly property int saveDelay: 400         // ms de espera antes de guardar tras un cambio
        readonly property string file: Quickshell.env("HOME") + "/.config/stixshell/tasks.json"
        readonly property string archive: Quickshell.env("HOME") + "/.config/stixshell/tasks-archive.json"
        // Color por prioridad (p4 = sin prioridad, sin color)
        readonly property var priorityColors: ({
                "1": "#ff1744",
                "2": "#ffb300",
                "3": "#2979ff",
                "4": ""
            })
    }

    // ===== Temporizador y cronómetro (pestañas de Productividad, services/timer/TimerStore.qml) =====
    readonly property QtObject timer: QtObject {
        readonly property var presets: [1, 3, 5, 10, 15, 25, 30, 60]   // min: tiempos rápidos
        readonly property int recents: 3             // últimos tiempos a medida que se recuerdan
        readonly property int tick: 250              // ms entre actualizaciones con un temporizador en marcha
        readonly property int stopwatchTick: 50      // ms entre actualizaciones del cronómetro a la vista
        readonly property int ringEvery: 3000        // ms entre repeticiones del sonido de la alarma
        readonly property int ringFor: 60            // s que suena como máximo si no la atiendes
        readonly property int saveDelay: 400         // ms de espera antes de guardar tras un cambio
        readonly property int maxTimers: 12
        readonly property string systemSound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        readonly property string file: Quickshell.env("HOME") + "/.config/stixshell/timers.json"
        // Pomodoro (min): trabajo, descanso corto y largo, y cada cuántos tramos de trabajo viene el largo
        readonly property QtObject pomodoro: QtObject {
            readonly property int work: 25
            readonly property int short: 5
            readonly property int long: 15
            readonly property int every: 4
        }
    }

    // ===== Inactividad (segundos; 0 = nunca) =====
    readonly property QtObject idle: QtObject {
        readonly property QtObject battery: QtObject {
            readonly property int dim: 270
            readonly property int lock: 300
            readonly property int screenOff: 330
            readonly property int suspend: 900
        }
        readonly property QtObject ac: QtObject {
            readonly property int dim: 570
            readonly property int lock: 600
            readonly property int screenOff: 660
            readonly property int suspend: 0
        }
        readonly property real dimLevel: 0.10       // brillo al atenuar
        // Valores que recorren los botones − y + del panel de batería (segundos)
        readonly property var steps: [30, 60, 90, 120, 150, 180, 240, 270, 300, 330, 360, 420, 480, 540, 570, 600, 660, 720, 900, 1200, 1500, 1800, 2700, 3600]
        // Avisos de batería baja (%; 0 = desactivado)
        readonly property QtObject lowBattery: QtObject {
            readonly property int warn: 20
            readonly property int critical: 10
            readonly property int suspend: 5
        }
        readonly property int lowBatterySuspendDelay: 10000   // ms entre el aviso y la suspensión
    }

    // ===== Panel de energía (pill de batería) =====
    readonly property QtObject power: QtObject {
        readonly property int stepperWidth: 104
        readonly property int rowHeight: 32
        readonly property int labelWidth: 130
        readonly property int segmentHeight: 40     // selector de perfil de energía
    }

    // ===== Perfiles de energía (valores por defecto; nombres de `powerprofilesctl`) =====
    readonly property QtObject profiles: QtObject {
        readonly property string battery: "power-saver"
        readonly property string ac: "balanced"
    }

    // ===== Historial del portapapeles =====
    readonly property QtObject clipboard: QtObject {
        readonly property int listWidth: 280
        readonly property int rowHeight: 52
        readonly property int thumbSize: 40
        readonly property int gap: 16               // entre la lista y la vista previa
        readonly property int qrSize: 260
        readonly property int qrMaxBytes: 2000      // más que esto, el teléfono ya no lo lee bien
        readonly property int confirmTimeout: 3000  // ms del "¿Ejecutar?" y "¿Borrar todo?"
        readonly property int decodeJobs: 2         // miniaturas que se decodifican a la vez
        readonly property int maxEntries: 300       // filas que se muestran (cliphist guarda más)
        readonly property string cacheDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/stixshell/clipboard"
    }

    // ===== Reproductor multimedia (MPRIS) =====
    readonly property QtObject media: QtObject {
        // Pill plegada: carátula redonda con un anillo de progreso
        readonly property int pillArt: 22
        readonly property int ringWidth: 2
        readonly property int miniClock: 28          // reloj circular mientras la música está expandida
        // Panel expandido
        readonly property int panelWidth: 520
        readonly property int panelHeight: 216
        readonly property int padding: 20
        readonly property int artSize: 150
        readonly property int chipsHeight: 34        // fichas de reproductor (solo con dos o más)
        readonly property int buttonSize: 38
        readonly property real blur: 1.0             // 0..1
        readonly property int blurMax: 64
        readonly property real dim: 0.45             // oscurecido del fondo
        // Saltos (segundos)
        readonly property int seekBack: 5
        readonly property int seekForward: 15
        readonly property real volumeStep: 0.05
        // Tiempos (ms)
        readonly property int pollInterval: 500      // refresco de la posición mientras suena
        readonly property int volumeOsd: 1500        // el anillo muestra el volumen tras mover la rueda
        readonly property int hideAfter: 300000      // sin sonar este tiempo, la pill se oculta
        readonly property int artTimeout: 1000       // carátula que no llega: ícono de la app
        readonly property int trackFade: 200         // fundido al cambiar de canción
    }

    // ===== Centro de control =====
    readonly property QtObject control: QtObject {
        readonly property int tileHeight: 56         // casilla en forma de pastilla
        readonly property int tileIcon: 36           // círculo del ícono dentro de la casilla
        readonly property int tileGlyph: 18          // glifo dentro del círculo
        readonly property int tileSpacing: 8
        readonly property int footerHeight: 44       // fila de abajo: apagar, batería y ajustes
    }

    // ===== Grabador de pantalla (wf-recorder, scripts/screen-record.py) =====
    readonly property QtObject recorder: QtObject {
        readonly property int fps: 60
        readonly property int countdown: 3           // segundos de cuenta regresiva antes de grabar
        readonly property string encoder: "h264_vaapi"      // por la GPU
        readonly property string fallbackEncoder: "libx264" // por la CPU, si VA-API falla
        readonly property string device: "/dev/dri/renderD128"
        readonly property string folderName: "Grabaciones"  // subcarpeta de Vídeos por defecto
        readonly property string filePattern: "'Grabación' yyyy-MM-dd HH-mm-ss"
        readonly property int dot: 8                 // punto rojo del contador
        readonly property int pulse: 900             // ms del latido del punto
        readonly property int checkInterval: 3000    // ms entre revisiones de que wf-recorder sigue vivo
    }

    // ===== Capturador de pantalla (services/screenshot, components/widgets/screenshot) =====
    readonly property QtObject screenshot: QtObject {
        readonly property string folderName: "Capturas"      // subcarpeta de Imágenes por defecto
        readonly property string filePattern: "'Captura' yyyy-MM-dd HH-mm-ss"
        readonly property int closeDelay: 420        // ms tras cerrar la isla antes de congelar (su animación dura anim.pill)
        readonly property int hideDelay: 150         // ms tras la cuenta regresiva (la pill se oculta) antes de congelar
        readonly property var delays: [0, 3, 5]      // segundos del retardo (el botón ⏱ los recorre)
        // Colores de las anotaciones (los del tema) y grosores del trazo; el grosor también fija el texto y los números
        readonly property var colors: ["#ff1744", "#ffb300", "#00e676", "#2979ff", "#d500f9", "#ffffff", "#0a0a0f"]
        readonly property var strokes: [2, 4, 8]
        readonly property var textSizes: [16, 24, 36]
        readonly property var counterSizes: [24, 32, 44]
        readonly property int stickerSize: 96
        readonly property int pixelBlock: 12         // lado de cada bloque al pixelar
        readonly property int blurRadius: 64
        readonly property real highlighterOpacity: 0.4
        readonly property int historyMax: 50
        readonly property int minSize: 8             // área mínima (px)
        readonly property int toolbarHeight: 48
        readonly property int barBottom: 56          // margen de la barra de modos al borde de abajo
        readonly property int barHeight: 52
        readonly property string ocrLang: "spa+eng"  // idiomas del OCR (tesseract-ocr-spa y tesseract-ocr-eng)
        readonly property int ocrUpscaleBelow: 1200  // px de ancho: debajo de eso el OCR prueba también agrandando 2×
        readonly property int ocrCardMin: 360        // ancho de la tarjeta del texto leído
        readonly property int ocrCardMax: 640
    }

    // ===== Colores dinámicos según el wallpaper (matugen, scripts/theme.py, services/theme) =====
    readonly property QtObject theme: QtObject {
        readonly property int fade: 600                // ms del fundido de colores (igual que anim.wallpaper)
        readonly property int debounce: 150            // ms tras cambiar de wallpaper antes de regenerar
        // Qué tan teñido sale el fondo en «Del wallpaper»
        readonly property var tints: [
            { id: "tinted", label: "Sutil" },
            { id: "vivid", label: "Intensa" }
        ]
        // Los dos modos de color
        readonly property var modes: [
            { id: "scheme", label: "Del wallpaper", hint: "Fondo y acento de la imagen, a elegir entre sus combinaciones." },
            { id: "custom", label: "Acento propio", hint: "El acento que elijas; fondos neutros." }
        ]
        // Muestras del acento propio (azul, índigo, violeta, rosa, rojo, naranja, ámbar, verde, turquesa y cian)
        readonly property var swatches: ["#2979ff", "#3d5afe", "#d500f9", "#ff4081", "#ff1744", "#ff6d00", "#ffb300", "#00e676", "#1de9b6", "#00e5ff"]
    }

    // ===== Pantallas (services/display) =====
    readonly property QtObject displays: QtObject {
        readonly property int confirmSeconds: 15     // «¿Mantener esta configuración?» antes de revertir
    }

    // ===== Animaciones (ms) =====
    readonly property QtObject anim: QtObject {
        readonly property int pill: Math.round(280 * root.animScale)
        readonly property int fadeIn: Math.round(200 * root.animScale)
        readonly property int fadeDelay: Math.round(100 * root.animScale)
        readonly property int fadeOut: Math.round(120 * root.animScale)
        readonly property int control: Math.round(150 * root.animScale)
        readonly property int hover: Math.round(120 * root.animScale)             // hover y pulsación
        readonly property int highlight: Math.round(100 * root.animScale)         // movimiento del resaltado del launcher
        readonly property int wallpaper: Math.round(600 * root.animScale)
    }
}
