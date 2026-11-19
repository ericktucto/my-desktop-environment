import QtQuick
import "../../services/notify/" as N
import "../../" as App

// Tarjeta de una app en la pantalla de bloqueo: ícono, "App · título (· N)", la hora, una línea del cuerpo y ×
// (marca como leídas las de esa app; siguen en el historial del panel). Solo se mira: no abre nada.
Rectangle {
    id: root

    required property var group

    readonly property var cfg: App.Config.lock
    readonly property var entry: group.latest
    readonly property var iconInfo: N.NotificationStore.iconFor(entry)
    readonly property string body: N.NotificationStore.formatBody(entry.body).replace(/<br>/g, " ").replace(/<[^>]*>/g, "")
    property bool photoFailed: false
    readonly property bool showPhoto: iconInfo.kind === "photo" && !photoFailed

    width: cfg.notifyWidth
    height: content.implicitHeight + 24
    radius: 18
    color: App.Theme.island
    border.width: 1
    border.color: group.critical ? App.Theme.red : App.Theme.border

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 10

        Item {
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                visible: source !== ""
                source: root.showPhoto ? root.iconInfo.source : root.iconInfo.app
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(64, 64)
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Error && root.showPhoto)
                        root.photoFailed = true;
                }
            }
        }

        Column {
            width: parent.width - 32 - 26 - 2 * parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Row {
                width: parent.width
                spacing: 6
                Text {
                    width: parent.width - ago.implicitWidth - parent.spacing
                    elide: Text.ElideRight
                    text: (root.entry.appName !== "" ? root.entry.appName : "Notificación") + (root.entry.summary !== "" ? " · " + root.entry.summary : "") + (root.group.count > 1 ? " · " + root.group.count : "")
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.DemiBold
                }
                Text {
                    id: ago
                    text: N.NotificationStore.ago(root.entry.time)
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }
            Text {
                visible: root.body !== ""
                width: parent.width
                elide: Text.ElideRight
                text: root.body
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        Rectangle {
            width: 26
            height: 26
            radius: 13
            anchors.verticalCenter: parent.verticalCenter
            color: closeMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
            Text {
                anchors.centerIn: parent
                text: "×"
                color: App.Theme.gray
                font.pixelSize: 18
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: N.NotificationStore.markRead(root.group.keys)
            }
        }
    }
}
