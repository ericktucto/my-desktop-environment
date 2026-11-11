import QtQuick
import "../../controls/" as C
import "../../indicators/" as I
import "../../widgets/media/" as M
import "../../../services/audio/" as A
import "../../../services/brightness/" as B
import "../../../services/osd/" as O
import "../../../" as App

// Contenido de la isla central contraída: la hora, o el OSD (volumen, brillo, micrófono)
// unos segundos tras usar las teclas multimedia.
Item {
    id: root

    readonly property var cfg: App.Config.osd
    readonly property string kind: O.OsdStore.kind
    readonly property bool showOsd: kind !== ""
    // Círculo con el reloj analógico mini (la música está expandida)
    property bool circle: false

    readonly property var sink: A.AudioStore.sink
    readonly property var source: A.AudioStore.source
    readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    // Nivel de la barra (0..1), con la misma escala del slider
    readonly property real level: {
        if (kind === "brightness")
            return B.BrightnessStore.value;
        const max = A.AudioStore.maxFor(sink);
        return sink && sink.audio && max > 0 ? Math.max(0, Math.min(1, sink.audio.volume / max)) : 0;
    }
    readonly property bool muted: kind === "volume" && sinkMuted

    readonly property string iconName: {
        if (kind === "brightness")
            return "brightness";
        if (kind === "mic")
            return A.AudioStore.micIcon(source);
        return A.AudioStore.volumeIcon(sink);
    }
    readonly property string label: {
        if (kind === "mic")
            return micMuted ? "Micrófono silenciado" : "Micrófono activo";
        if (kind === "brightness")
            return B.BrightnessStore.percent() + "%";
        return sinkMuted ? "Mute" : A.AudioStore.percent(sink) + "%";
    }

    // La pill sigue el ancho del elemento visible
    implicitWidth: showOsd ? osd.implicitWidth : (circle ? mini.width : clock.implicitWidth)
    implicitHeight: Math.max(clock.implicitHeight, osd.implicitHeight)

    I.ClockText {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.showOsd || root.circle ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.showOsd || root.circle ? App.Config.anim.fadeOut : App.Config.anim.fadeIn
            }
        }
    }

    M.MiniClock {
        id: mini
        anchors.centerIn: parent
        opacity: root.circle ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.circle ? App.Config.anim.fadeIn : App.Config.anim.fadeOut
            }
        }
    }

    Row {
        id: osd
        anchors.centerIn: parent
        spacing: 8
        opacity: root.showOsd ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.showOsd ? App.Config.anim.fadeIn : App.Config.anim.fadeOut
            }
        }

        C.IconSvg {
            anchors.verticalCenter: parent.verticalCenter
            size: root.cfg.iconSize
            source: Qt.resolvedUrl("../../../assets/svg/" + root.iconName + ".svg")
            color: App.Theme.white
        }

        // Barra de nivel (no en el micrófono)
        Rectangle {
            visible: root.kind !== "mic"
            anchors.verticalCenter: parent.verticalCenter
            width: root.cfg.barWidth
            height: root.cfg.barHeight
            radius: height / 2
            color: App.Theme.track

            Rectangle {
                width: parent.width * root.level
                height: parent.height
                radius: height / 2
                color: root.muted ? App.Theme.gray : App.Theme.primary

                Behavior on width {
                    NumberAnimation {
                        duration: App.Config.anim.highlight
                    }
                }
            }
        }

        // Porcentaje: ancho fijo para que la pill no tiemble
        Text {
            visible: root.kind !== "mic"
            anchors.verticalCenter: parent.verticalCenter
            width: root.cfg.percentWidth
            horizontalAlignment: Text.AlignRight
            text: root.label
            color: root.muted ? App.Theme.gray : App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.Medium
        }

        // Micrófono: solo texto
        Text {
            visible: root.kind === "mic"
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.micMuted ? App.Theme.gray : App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.Medium
        }
    }
}
