import QtQuick
import "../rows/" as R
import "../../widgets/window/" as WW
import "../../widgets/controlcenter/" as CC
import "../../../services/keybinds/" as K
import "../../../" as App

// Atajos de teclado de Hyprland (los de hypr/keybinds): la lista por grupos con su combinación. Se pueden quitar
// y restablecer; los cambios se aplican en vivo y se guardan.
Page {
    id: page

    readonly property var store: K.KeybindStore

    pageId: "shortcuts"
    pageName: "Atajos"
    subtitle: store.binds.length + " atajos de teclado."

    Repeater {
        model: page.store.groups
        Column {
            id: grp
            required property var modelData
            width: page.width - 16
            spacing: 8

            R.Section {
                text: grp.modelData.name
            }
            Repeater {
                model: grp.modelData.binds
                R.SettingRow {
                    id: row
                    required property var modelData
                    searchId: "bind-" + modelData.id
                    label: modelData.description || modelData.id
                    hint: modelData.bind === null ? "Sin atajo" : ""
                    keywords: modelData.id + " " + (modelData.bind ?? "") + " tecla combinacion"
                    changed: page.store.isChanged(modelData)
                    onResetRequested: page.store.reset(modelData.id)

                    CC.SmallButton {
                        visible: row.modelData.bind !== null
                        label: "Quitar"
                        onClicked: page.store.setBind(row.modelData.id, "")
                    }
                    CC.SmallButton {
                        visible: page.store.isChanged(row.modelData)
                        label: "Restablecer"
                        onClicked: page.store.reset(row.modelData.id)
                    }
                    WW.KeyCaps {
                        anchors.verticalCenter: parent.verticalCenter
                        keys: (row.modelData.bind ?? "").replace(/ \+ /g, "+")
                    }
                }
            }
        }
    }
}
