import QtQuick
import "../../../services/audio/" as A
import "../../../services/notify/" as N
import "../../../services/brightness/" as B
import "../../../" as App

// Centro de control: interruptores rápidos, brillo, salida y micrófono.
Column {
    id: root

    spacing: 14

    // ── Interruptores ──
    Row {
        spacing: 8

        QuickToggle {
            icon: Qt.resolvedUrl("../../../assets/svg/" + (N.NotificationStore.dnd ? "notification-off" : "notification-on") + ".svg")
            text: "No molestar"
            checked: N.NotificationStore.dnd
            onClicked: N.NotificationStore.setDnd(!N.NotificationStore.dnd)
        }
    }

    BrightnessSection {
        width: parent.width
        visible: B.BrightnessStore.available
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    AudioSection {
        width: parent.width
        title: "SALIDA"
        isSink: true
        node: A.AudioStore.sink
        devices: A.AudioStore.sinks
        onSelect: d => A.AudioStore.setDefaultSink(d)
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    AudioSection {
        width: parent.width
        title: "MICRÓFONO"
        isSink: false
        node: A.AudioStore.source
        devices: A.AudioStore.sources
        onSelect: d => A.AudioStore.setDefaultSource(d)
    }
}
