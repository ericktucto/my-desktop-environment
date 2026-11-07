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
        readonly property int iconSize: 16           // ícono de las pills plegadas (Audio, Zoom, Notificaciones)
    }

    // ===== Tamaño de cada pill abierta =====
    readonly property QtObject panel: QtObject {
        readonly property int launcherWidth: 480
        readonly property int launcherHeight: 600
        readonly property int wallpapersWidth: 800
        readonly property int audioWidth: 360
        readonly property int notificationsWidth: 420
        readonly property int workspacesWidth: 360
        readonly property int workspacesHeight: 80
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
    }

    // ===== Workspaces =====
    readonly property QtObject workspaces: QtObject {
        readonly property int count: 4
        readonly property int dotSize: 10
        readonly property int activeWidth: 20
        readonly property int spacing: 10
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
