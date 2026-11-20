import QtQuick
import "../../widgets/battery/" as BW

// Valor con − y +: `text` es lo que se ve; `decrement` e `increment` los emite el control.
SettingRow {
    id: root

    property string text: ""

    signal decrement
    signal increment

    BW.Stepper {
        text: root.text
        onDecrement: root.decrement()
        onIncrement: root.increment()
    }
}
