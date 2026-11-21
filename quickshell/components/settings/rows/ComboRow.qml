import QtQuick
import "../../widgets/wallpapers/" as W

// Las combinaciones de fondo y acento del wallpaper puesto, como mini pills (las mismas del selector de wallpapers).
// `combos` = [{ id, name, preview }], `value` = id elegido, `tint` = tinted | vivid.
SettingRow {
    id: root

    property var combos: []
    property string value: ""
    property string tint: "vivid"
    property string defaultValue: ""

    signal picked(string id)

    stacked: true
    changed: defaultValue !== "" && value !== defaultValue
    onResetRequested: picked(defaultValue)

    Flow {
        width: parent.width
        spacing: 10
        Repeater {
            model: root.combos
            W.ComboCard {
                required property var modelData
                width: 124
                combo: modelData
                tint: root.tint
                selected: root.value === modelData.id
                onClicked: root.picked(modelData.id)
            }
        }
    }
}
