import QtQuick
import Quickshell
import "../../../services/clipboard/" as S
import "../../../" as App

// Lista del historial. El modelo son los ids (strings), así que al refrescar solo cambian las filas
// que cambian y la selección se queda en su sitio (al borrar una, pasa a la siguiente).
ListView {
    id: list

    // ids de los elementos a mostrar
    property var ids: []

    signal copyRequested(var entry)

    clip: true
    currentIndex: 0
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1500

    model: ScriptModel {
        values: list.ids
    }

    highlight: Rectangle {
        color: App.Theme.surfaceHigh
        radius: App.Config.radius.md
    }
    highlightMoveDuration: App.Config.anim.highlight
    highlightResizeDuration: 0

    delegate: ClipRow {
        required property var modelData
        required property int index

        width: ListView.view.width
        entry: S.ClipboardStore.byId[modelData] || null
        onClicked: list.currentIndex = index
        onDoubleClicked: {
            list.currentIndex = index;
            if (entry)
                list.copyRequested(entry);
        }
    }
}
