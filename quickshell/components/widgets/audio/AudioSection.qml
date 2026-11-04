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
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "Mute" : S.AudioStore.percent(root.node) + "%"
            color: root.muted ? App.Theme.orange : App.Theme.white
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
    }

    // ── Ícono (mute) + slider ──
    Row {
        width: parent.width
        spacing: 12

        C.IconSvg {
            id: muteIcon
            size: 18
            anchors.verticalCenter: parent.verticalCenter
            source: Qt.resolvedUrl("../../../assets/svg/" + (root.isSink ? S.AudioStore.volumeIcon(root.node) : S.AudioStore.micIcon(root.node)) + ".svg")
            color: root.muted ? App.Theme.orange : App.Theme.white

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: S.AudioStore.toggleMute(root.node)
            }
        }

        C.Slider {
            width: parent.width - muteIcon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            to: S.AudioStore.maxFor(root.node)
            value: root.node && root.node.audio ? root.node.audio.volume : 0
            enabled: root.node !== null
            onMoved: v => S.AudioStore.setVolume(root.node, v)
        }
    }

    // ── Switch 150% ──
    Row {
        spacing: 16
        height: 24

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            C.Switch {
                anchors.verticalCenter: parent.verticalCenter
                checked: root.boost
                onToggled: on => S.AudioStore.setAllowOver(root.isSink, on)
            }
            Text {
                text: "Permitir 150%"
                color: root.boost ? App.Theme.white : App.Theme.gray
                font.pixelSize: App.Config.fontSize.sm
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: S.AudioStore.setAllowOver(root.isSink, !root.boost)
                }
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
                font.pixelSize: App.Config.fontSize.sm
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
