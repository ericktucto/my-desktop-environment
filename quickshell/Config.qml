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
    }

    // ===== Tamaño de cada pill abierta =====
    readonly property QtObject panel: QtObject {
        readonly property int launcherWidth: 480
        readonly property int launcherHeight: 600
        readonly property int wallpapersWidth: 800
        readonly property int audioWidth: 360
        readonly property int notificationsWidth: 340
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

    // ===== Radios pequeños (tarjetas, resaltados) =====
    readonly property QtObject radius: QtObject {
        readonly property int sm: 6
        readonly property int md: 8
    }

    // ===== Animaciones (ms) =====
    readonly property QtObject anim: QtObject {
        readonly property int pill: 280
        readonly property int fadeIn: 200
        readonly property int fadeDelay: 100
        readonly property int fadeOut: 120
        readonly property int control: 150
        readonly property int wallpaper: 600
    }
}
