pragma Singleton
import Quickshell
import QtQuick

// Configuración de tamaños. Se lee como App.Config.pill.height, etc.
Singleton {
    id: root

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
    }

    // ===== Barra =====
    readonly property QtObject bar: QtObject {
        readonly property int marginLeft: 8
        readonly property int marginRight: 12
        readonly property int spacing: 8             // separación entre pills
        readonly property int gapBelow: 8            // aire debajo de las pills
        readonly property int exclusiveZone: root.pill.top + root.pill.height + gapBelow
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
        readonly property int controlCenterWidth: 380
        readonly property int notificationsWidth: 420
        readonly property int batteryWidth: 420
        readonly property int clipboardWidth: 880
        readonly property int clipboardHeight: 520
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
        readonly property int overviewWidth: count * cardWidth + (count - 1) * cardSpacing + 2 * root.pill.padding
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
        // > 0 = al bloquear se desbloquea solo a los N s (solo para probar sin quedarte fuera)
        readonly property int testAutoUnlock: 0
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

    // ===== Animaciones (ms) =====
    readonly property QtObject anim: QtObject {
        readonly property int pill: 280
        readonly property int fadeIn: 200
        readonly property int fadeDelay: 100
        readonly property int fadeOut: 120
        readonly property int control: 150
        readonly property int hover: 120             // hover y pulsación
        readonly property int highlight: 100         // movimiento del resaltado del launcher
        readonly property int wallpaper: 600
    }
}
