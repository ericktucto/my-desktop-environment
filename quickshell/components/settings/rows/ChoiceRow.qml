import QtQuick
import "../../widgets/controlcenter/" as CC

// Una opción entre pocas, como pastillas: `options` = [{ id, label }], `value` = id elegido.
SettingRow {
    id: root

    property var options: []
    property string value: ""
    property string defaultValue: ""

    signal picked(string id)

    changed: defaultValue !== "" && value !== defaultValue
    onResetRequested: picked(defaultValue)

    Row {
        spacing: 6
        Repeater {
            model: root.options
            CC.Chip {
                required property var modelData
                height: 28
                radius: 14
                label: modelData.label
                selected: root.value === modelData.id
                onClicked: root.picked(modelData.id)
            }
        }
    }
}
