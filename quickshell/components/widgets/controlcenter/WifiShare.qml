import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Tarjeta para compartir el Wi-Fi: el QR, el nombre, la contraseña (oculta; el ojo la muestra) y [Copiar contraseña].
Rectangle {
    id: root

    readonly property var share: NS.NetworkStore.share
    property bool showPassword: false

    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: App.Theme.surfaceActive
    border.width: 1
    border.color: App.Theme.primary

    onShareChanged: showPassword = false

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 196
            height: 196
            radius: 10
            color: "white"
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: root.share ? "file://" + root.share.png + "?" + NS.NetworkStore.shareSerial : ""
                cache: false
                smooth: false
                fillMode: Image.PreserveAspectFit
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.share ? root.share.ssid : ""
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Row {
            visible: root.share && root.share.psk !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Clave " + (root.showPassword ? (root.share ? root.share.psk : "") : "••••••••")
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(App.Config.network.glyphEye)
                color: root.showPassword ? App.Theme.primary : App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPassword = !root.showPassword
                }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            SmallButton {
                visible: root.share && root.share.psk !== ""
                label: "Copiar contraseña"
                onClicked: NS.NetworkStore.copyPassword()
            }
            SmallButton {
                label: "Cerrar"
                onClicked: NS.NetworkStore.closeShare()
            }
        }
    }
}
