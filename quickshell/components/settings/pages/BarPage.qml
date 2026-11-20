import QtQuick
import "../rows/" as R
import "../../../services/actions/" as AC
import "../../../services/settings/" as ST
import "../../../" as App

// Barra e isla: qué hace cada clic y la rueda sobre el reloj (la isla central). Se aplican al instante.
Page {
    id: page

    readonly property var isl: ST.SettingsStore.island
    readonly property var clicks: AC.ActionRunner.clickActions
    readonly property var wheels: AC.ActionRunner.wheelActions

    pageId: "bar"
    pageName: "Barra e isla"
    subtitle: "Qué hace cada clic y la rueda sobre el reloj, en el centro de la barra."

    R.Section {
        text: "Isla central (el reloj)"
    }
    R.CycleRow {
        searchId: "islandLeft"
        label: "Clic izquierdo"
        keywords: "reloj isla central click boton"
        options: page.clicks
        value: page.isl.left
        defaultValue: "productivity"
        onPicked: id => page.isl.left = id
    }
    R.CycleRow {
        searchId: "islandRight"
        label: "Clic derecho"
        keywords: "reloj isla central click boton"
        options: page.clicks
        value: page.isl.right
        defaultValue: "control"
        onPicked: id => page.isl.right = id
    }
    R.CycleRow {
        searchId: "islandMiddle"
        label: "Clic central"
        keywords: "reloj isla central click rueda boton"
        options: page.clicks
        value: page.isl.middle
        defaultValue: "none"
        onPicked: id => page.isl.middle = id
    }
    R.CycleRow {
        searchId: "islandWheel"
        label: "Rueda"
        hint: "Girar la rueda con el mouse encima del reloj."
        keywords: "scroll volumen brillo"
        options: page.wheels
        value: page.isl.wheel
        defaultValue: "volume"
        onPicked: id => page.isl.wheel = id
    }
    R.CycleRow {
        searchId: "islandShiftWheel"
        label: "Shift + rueda"
        keywords: "scroll volumen brillo"
        options: page.wheels
        value: page.isl.shiftWheel
        defaultValue: "brightness"
        onPicked: id => page.isl.shiftWheel = id
    }
    R.ActionRow {
        searchId: "resetIsland"
        label: "Restablecer la isla central"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: ST.SettingsStore.resetSection("island")
    }
}
