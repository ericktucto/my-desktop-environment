import QtQuick
import "../../controls/" as C

// Interruptor: `checked`; `toggled(bool)` al cambiarlo.
SettingRow {
    id: root

    property bool checked: false
    // Valor de fábrica (para el punto de «cambiado»)
    property bool defaultValue: false

    signal toggled(bool checked)

    changed: checked !== defaultValue
    onResetRequested: toggled(defaultValue)

    C.Switch {
        checked: root.checked
        onToggled: c => root.toggled(c)
    }
}
