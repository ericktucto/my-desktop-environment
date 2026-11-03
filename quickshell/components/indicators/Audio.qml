import Quickshell
import QtQuick
import "../base/" as Base
import "../controls/" as C
import "../widgets/audio/" as A
import "../../services/audio/" as S
import "../../" as App

Base.Island {
    id: root

    collapsedWidth: 90
    expandedHeight: panel.implicitHeight + 2 * paddingContainer
    expandedWidth: 360

    radiusExpanded: 32

    preventFocus: true

    readonly property var sink: S.AudioStore.sink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    Row {
        spacing: 8
        C.IconSvg {
            source: "/home/erick/Descargas/svg/volumen-on.svg"
            size: 16
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.muted ? "Mute" : S.AudioStore.percent(root.sink) + "%"
            font.family: "Symbols Nerd Font"   // o el nombre exacto de tu Nerd Font
            font.pixelSize: 12
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Pill cerrada: clic derecho = mute, rueda = volumen.
    // El clic izquierdo no se acepta aquí, así que llega al MouseArea de Island (abre el panel).
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: !root.expanded
        acceptedButtons: Qt.RightButton

        onClicked: S.AudioStore.toggleMute(root.sink)
        onWheel: wheel => {
            S.AudioStore.step(root.sink, wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            wheel.accepted = true;
        }
    }

    body: A.AudioPanel {
        id: panel
        width: parent ? parent.width : 0
    }
}
