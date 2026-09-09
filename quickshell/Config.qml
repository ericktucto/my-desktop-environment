pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // ===== Wallpapers =====
    readonly property int spacingCell: 12
    readonly property int imgWidth: 200
    readonly property int imgHeight: imgWidth * 9 / 16
    readonly property int borderImg: 4
}
