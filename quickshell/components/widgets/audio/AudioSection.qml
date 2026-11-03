import QtQuick
import "../../controls/" as C
import "../../../services/audio/" as S
import "../../../" as App

Column {
    id: root

    property string title: ""
    property var node: null        // dispositivo activo (sink o source)
    property var devices: []       // dispositivos elegibles
    property bool isSink: true

    signal select(var device)

    readonly property bool muted: node && node.audio ? node.audio.muted : false
    readonly property bool boost: isSink ? S.AudioStore.allowOverSink : S.AudioStore.allowOverSource

    spacing: 8

    // ── Encabezado: título + porcentaje ──
    Item {
        width: parent.width
        height: 18

        Text {
            text: root.title
            color: App.Theme.gray
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "Mute" : S.AudioStore.percent(root.node) + "%"
            color: root.muted ? App.Theme.orange : App.Theme.white
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    // ── Slider ──
    C.Slider {
        width: parent.width
        to: S.AudioStore.maxFor(root.node)
        value: root.node && root.node.audio ? root.node.audio.volume : 0
        enabled: root.node !== null
        onMoved: v => S.AudioStore.setVolume(root.node, v)
    }

    // ── Acciones en texto ──
    Row {
        spacing: 16

        Text {
            text: root.muted ? "Activar" : "Silenciar"
            color: App.Theme.primary
            font.pixelSize: 12
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: S.AudioStore.toggleMute(root.node)
            }
        }

        Text {
            text: (root.boost ? "[x]" : "[ ]") + " Permitir 150%"
            color: root.boost ? App.Theme.primary : App.Theme.gray
            font.pixelSize: 12
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: S.AudioStore.setAllowOver(root.isSink, !root.boost)
            }
        }
    }

    // ── Lista de dispositivos ──
    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.devices

            delegate: Text {
                required property var modelData
                readonly property bool active: modelData === root.node

                width: parent.width
                text: (active ? "● " : "   ") + S.AudioStore.label(modelData)
                elide: Text.ElideRight
                color: active ? App.Theme.primary : App.Theme.gray
                font.pixelSize: 12
                font.weight: active ? Font.Bold : Font.Normal
                topPadding: 3
                bottomPadding: 3

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.select(modelData)
                }
            }
        }
    }
}
