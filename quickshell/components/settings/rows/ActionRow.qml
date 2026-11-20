import QtQuick
import "../../widgets/controlcenter/" as CC

// Un botón (Abrir, Probar, Restablecer…): `actionLabel`; `triggered` al pulsarlo.
SettingRow {
    id: root

    property string actionLabel: ""
    property bool primary: false

    signal triggered

    CC.SmallButton {
        label: root.actionLabel
        primary: root.primary
        enabled: root.enabled
        opacity: enabled ? 1 : 0.4
        onClicked: root.triggered()
    }
}
