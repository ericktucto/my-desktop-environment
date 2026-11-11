import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "../../controls/" as C
import "../../../services/media/" as M
import "../../../" as App

// Panel del reproductor (isla expandida): fondo con la carátula difuminada, título, artista, progreso,
// botones y la carátula a la derecha.
Item {
    id: root

    readonly property var cfg: App.Config.media
    readonly property var store: M.MediaStore
    readonly property var player: store.player

    // Radio de la isla: el fondo se recorta con esas esquinas
    property real islandRadius: App.Config.pill.radiusExpanded

    // Color de acento: el más vivo de la paleta de la carátula (o el azul del tema)
    readonly property color accent: {
        const cols = quant.colors;
        if (!cols || cols.length === 0)
            return App.Theme.primary;
        let best = cols[0];
        let bestScore = -1;
        for (const c of cols) {
            const score = c.hsvSaturation * (0.4 + c.hsvValue);
            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }
        return best.hsvSaturation < 0.15 ? App.Theme.primary : Qt.hsva(best.hsvHue, Math.min(1, best.hsvSaturation + 0.1), Math.max(0.75, best.hsvValue), 1);
    }

    ColorQuantizer {
        id: quant
        source: root.store.shownArt
        depth: 2
        rescaleSize: 64
    }

    // El teclado funciona con el panel abierto
    focus: true
    onVisibleChanged: if (visible)
        forceActiveFocus()

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Space:
            store.togglePlaying();
            break;
        case Qt.Key_Left:
            store.seekBy(-cfg.seekBack);
            break;
        case Qt.Key_Right:
            store.seekBy(cfg.seekForward);
            break;
        case Qt.Key_Up:
            store.changeVolume(cfg.volumeStep);
            break;
        case Qt.Key_Down:
            store.changeVolume(-cfg.volumeStep);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // ── Fondo: la carátula difuminada y oscurecida, a todo el ancho de la isla ──
    Item {
        id: bg
        anchors.fill: parent
        anchors.margins: -root.cfg.padding

        Item {
            id: bgMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                radius: root.islandRadius
                color: "black"
            }
        }

        Item {
            id: bgContent
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: bgMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.darker(root.accent, 3)
                    }
                    GradientStop {
                        position: 1
                        color: App.Theme.island
                    }
                }
            }
            Image {
                id: bgImage
                anchors.fill: parent
                source: root.store.shownArt
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(256, 256)
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: root.cfg.blur
                    blurMax: root.cfg.blurMax
                    brightness: -root.cfg.dim
                    saturation: 0.2
                }
            }
        }
    }

    // ── Carátula (a la derecha). Clic: trae la ventana del reproductor ──
    MediaArt {
        id: cover
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.cfg.artSize
        height: width
        radius: 14

        MouseArea {
            anchors.fill: parent
            cursorShape: root.player && root.player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.store.raise()
        }
    }

    // ── Columna izquierda ──
    Column {
        id: left
        anchors.left: parent.left
        anchors.right: cover.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        PlayerChips {
            visible: root.store.players.length > 1
        }

        // Cambio de canción: fundido corto
        Column {
            id: titles
            width: parent.width
            spacing: 2
            readonly property string shownTitle: root.player ? root.player.trackTitle : ""
            readonly property string shownArtist: root.player ? root.player.trackArtist : ""

            Text {
                id: titleText
                width: parent.width
                text: titles.shownTitle
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1

                MouseArea {
                    id: titleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    // El título completo, si no cabe
                    ToolTip.visible: containsMouse && titleText.truncated
                    ToolTip.delay: 500
                    ToolTip.text: titles.shownTitle
                }
            }
            Text {
                width: parent.width
                text: titles.shownArtist
                visible: text !== ""
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Fundido corto al cambiar de canción
            NumberAnimation {
                id: titleFade
                target: titles
                property: "opacity"
                from: 0
                to: 1
                duration: root.cfg.trackFade
            }
            onShownTitleChanged: titleFade.restart()
        }

        MediaProgress {
            width: parent.width
            position: root.store.position
            length: root.store.length
            progress: root.store.progress
            live: root.store.isLive
            canSeek: root.player ? (root.player.canSeek && root.player.positionSupported && !root.store.isLive) : false
            accent: root.accent
            onSeekRequested: fraction => root.store.seekTo(fraction)
        }

        // Anterior · −5 · play/pausa · +15 · siguiente
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            MediaButton {
                icon: "media-previous"
                active: root.player ? root.player.canGoPrevious : false
                onClicked: root.store.previous()
            }
            MediaButton {
                icon: "media-back-5"
                iconSize: 24
                active: root.player ? root.player.canSeek : false
                onClicked: root.store.seekBy(-root.cfg.seekBack)
            }
            MediaButton {
                icon: root.store.playing ? "media-pause" : "media-play"
                highlighted: true
                accent: root.accent
                active: root.player ? root.player.canTogglePlaying : false
                onClicked: root.store.togglePlaying()
            }
            MediaButton {
                icon: "media-forward-15"
                iconSize: 24
                active: root.player ? root.player.canSeek : false
                onClicked: root.store.seekBy(root.cfg.seekForward)
            }
            MediaButton {
                icon: "media-next"
                active: root.player ? root.player.canGoNext : false
                onClicked: root.store.next()
            }
        }

        // Aleatorio · repetir · volumen del reproductor
        Item {
            width: parent.width
            height: 28

            Row {
                id: toggles
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                MediaButton {
                    width: 28
                    iconSize: 16
                    icon: "media-shuffle"
                    visible: root.player ? root.player.shuffleSupported : false
                    highlighted: root.player ? root.player.shuffle : false
                    accent: Qt.alpha(root.accent, 0.5)
                    onClicked: root.store.toggleShuffle()
                }
                MediaButton {
                    width: 28
                    iconSize: 16
                    icon: root.player && root.player.loopState === 2 ? "media-repeat-one" : "media-repeat"
                    visible: root.player ? root.player.loopSupported : false
                    highlighted: root.player ? root.player.loopState !== 0 : false
                    accent: Qt.alpha(root.accent, 0.5)
                    onClicked: root.store.cycleLoop()
                }
            }

            Row {
                anchors.left: toggles.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                visible: root.store.canVolume

                C.IconSvg {
                    id: volIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("../../../assets/svg/media-volume.svg")
                    size: 16
                    color: App.Theme.gray
                }
                C.Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - volIcon.width - parent.spacing
                    value: root.store.volume
                    onMoved: v => root.store.setVolume(v)
                }
            }
        }
    }
}
