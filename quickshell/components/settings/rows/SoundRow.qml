import QtQuick
import "../../controls/" as C
import "../../widgets/controlcenter/" as CC
import "../../../services/sound/" as SND
import "../../../" as App

// Un evento con sonido: interruptor, el sonido (‹ nombre ›) y «Probar».
SettingRow {
    id: root

    // { id, label, sound, on } de SoundStore.events
    property var event: ({})
    readonly property var store: SND.SoundStore
    readonly property string sound: store.soundOf(event.id)
    readonly property var names: store.themeSounds

    searchId: "sound-" + event.id
    label: event.label
    keywords: "sonido audio aviso " + (event.group ?? "")
    changed: store.isOn(event.id) !== event.on || sound !== event.sound
    onResetRequested: store.resetEvent(event.id)
    controlWidth: 430

    function move(step) {
        const i = names.indexOf(sound);
        store.setSound(event.id, names[(Math.max(0, i) + step + names.length) % names.length]);
        store.playFile(sound);
    }

    // (de derecha a izquierda)
    CC.SmallButton {
        label: "Probar"
        onClicked: root.store.playFile(root.sound)
    }
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: [
                {
                    glyph: "‹",
                    step: -1
                },
                {
                    glyph: "",
                    step: 0
                },
                {
                    glyph: "›",
                    step: 1
                }
            ]
            Item {
                required property var modelData
                width: modelData.step === 0 ? 170 : 26
                height: 26
                Rectangle {
                    visible: parent.modelData.step !== 0
                    anchors.fill: parent
                    radius: 13
                    color: m.containsMouse ? App.Theme.surfaceActive : App.Theme.surface
                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.modelData.glyph
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.lg
                    }
                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.move(parent.parent.modelData.step)
                    }
                }
                Text {
                    visible: parent.modelData.step === 0
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.sound
                    color: root.store.isOn(root.event.id) ? App.Theme.white : App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }
    }
    C.Switch {
        anchors.verticalCenter: parent.verticalCenter
        checked: root.store.isOn(root.event.id)
        onToggled: c => root.store.setOn(root.event.id, c)
    }
}
