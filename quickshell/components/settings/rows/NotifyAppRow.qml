import QtQuick
import Quickshell
import Quickshell.Io
import "../../controls/" as C
import "../../widgets/controlcenter/" as CC
import "../../../services/notify/" as N
import "../../../services/sound/" as SND
import "../../../" as App

// Una app que ha notificado: Silenciar, su sonido (‹ nombre ›; vacío = el de las notificaciones), un archivo propio
// y «Probar».
SettingRow {
    id: root

    property string app: ""
    readonly property string sound: SND.SoundStore.appSound(app)
    readonly property bool custom: sound.startsWith("/")
    readonly property bool muted: N.NotificationStore.isMuted(app)
    // "" = el de fábrica, y luego los del tema
    readonly property var names: [""].concat(SND.SoundStore.themeSounds)
    readonly property string defaultSound: SND.SoundStore.soundOf("notify")
    readonly property string soundText: sound === "" ? "Normal" : (custom ? "♪ " + sound.substring(sound.lastIndexOf("/") + 1) : sound)

    label: app
    keywords: "notificaciones silenciar sonido app"
    changed: muted || sound !== ""
    onResetRequested: {
        N.NotificationStore.setMuted(app, false);
        SND.SoundStore.setAppSound(app, "");
    }
    controlWidth: 540

    function move(step) {
        const i = Math.max(0, names.indexOf(sound));
        const next = names[(i + step + names.length) % names.length];
        SND.SoundStore.setAppSound(app, next);
        SND.SoundStore.playFile(next || defaultSound);
    }

    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "") {
                    SND.SoundStore.setAppSound(root.app, p);
                    SND.SoundStore.playFile(p);
                }
            }
        }
    }

    // (de derecha a izquierda)
    CC.SmallButton {
        label: "Probar"
        onClicked: SND.SoundStore.playFile(root.sound || root.defaultSound)
    }
    CC.SmallButton {
        label: "Archivo…"
        onClicked: {
            if (picker.running)
                return;
            const cur = root.custom ? root.sound.substring(0, root.sound.lastIndexOf("/")) : "";
            picker.command = ["python3", Quickshell.shellPath("scripts/pick.py"), "file", cur, "Elegir un sonido", "*.oga", "*.ogg", "*.wav", "*.flac", "*.mp3"];
            picker.running = true;
        }
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
                width: modelData.step === 0 ? 140 : 26
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
                    text: root.soundText
                    color: root.muted ? App.Theme.gray : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Silenciar"
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }
    C.Switch {
        anchors.verticalCenter: parent.verticalCenter
        checked: root.muted
        onToggled: c => N.NotificationStore.setMuted(root.app, c)
    }
}
