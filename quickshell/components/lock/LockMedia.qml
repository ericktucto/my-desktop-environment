import QtQuick
import "../widgets/media/" as MW
import "../../services/media/" as M
import "../../services/settings/" as ST
import "../../" as App

// Tarjeta de música de la pantalla de bloqueo: carátula, título y artista, y ⏮ ⏯ ⏭. Solo con una canción.
Rectangle {
    id: root

    readonly property var store: M.MediaStore
    readonly property var player: store.player

    visible: store.visible && ST.SettingsStore.lock.media
    width: row.implicitWidth + 24
    height: App.Config.lock.mediaArt + 20
    radius: 18
    color: App.Theme.island
    border.width: 1
    border.color: App.Theme.border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12

        MW.MediaArt {
            width: App.Config.lock.mediaArt
            height: width
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                width: Math.min(implicitWidth, 200)
                elide: Text.ElideRight
                text: root.player ? root.player.trackTitle : ""
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.DemiBold
            }
            Text {
                width: Math.min(implicitWidth, 200)
                elide: Text.ElideRight
                text: root.player ? root.player.trackArtist : ""
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            MW.MediaButton {
                icon: "media-previous"
                active: root.player ? root.player.canGoPrevious : false
                onClicked: root.store.previous()
            }
            MW.MediaButton {
                icon: root.store.playing ? "media-pause" : "media-play"
                highlighted: true
                active: root.player ? root.player.canTogglePlaying : false
                onClicked: root.store.togglePlaying()
            }
            MW.MediaButton {
                icon: "media-next"
                active: root.player ? root.player.canGoNext : false
                onClicked: root.store.next()
            }
        }
    }
}
