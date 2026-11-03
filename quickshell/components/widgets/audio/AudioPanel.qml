import QtQuick
import "../../../services/audio/" as S
import "../../../" as App

Column {
    id: root

    spacing: 14

    AudioSection {
        width: parent.width
        title: "SALIDA"
        isSink: true
        node: S.AudioStore.sink
        devices: S.AudioStore.sinks
        onSelect: d => S.AudioStore.setDefaultSink(d)
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
        node: S.AudioStore.source
        devices: S.AudioStore.sources
        onSelect: d => S.AudioStore.setDefaultSource(d)
    }
}
