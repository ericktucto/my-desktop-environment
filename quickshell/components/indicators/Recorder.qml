import QtQuick
import "../base" as Base
import "../../services/recorder/" as R
import "../../" as App

// Contador de la grabación, a la derecha del reloj: cuenta regresiva, punto rojo que late con el tiempo
// y un ícono por cada audio que se graba. Un clic cancela o detiene y guarda.
Base.Island {
    id: root

    readonly property var store: R.RecorderStore

    visible: store.showPill
    openOnClick: false

    readonly property bool counting: store.phase === "countdown"
    readonly property bool saving: store.phase === "saving"

    // Punto rojo (late mientras graba)
    Rectangle {
        visible: !root.counting
        anchors.verticalCenter: parent.verticalCenter
        width: App.Config.recorder.dot
        height: width
        radius: width / 2
        color: App.Theme.red

        SequentialAnimation on opacity {
            running: root.visible && root.store.phase === "recording"
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.25
                duration: App.Config.recorder.pulse / 2
            }
            NumberAnimation {
                to: 1
                duration: App.Config.recorder.pulse / 2
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.counting ? String(root.store.count) : (root.saving ? "Guardando…" : root.store.elapsedText)
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
        font.letterSpacing: -0.5
    }

    // Qué audio entra en el video
    Text {
        visible: !root.counting && !root.saving && root.store.internal
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xf057e)
        color: App.Theme.gray
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.sm
    }
    Text {
        visible: !root.counting && !root.saving && root.store.mic
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xf036c)
        color: App.Theme.gray
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.sm
    }

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: !root.saving
        cursorShape: Qt.PointingHandCursor
        onClicked: root.store.stopOrCancel()
    }
}
