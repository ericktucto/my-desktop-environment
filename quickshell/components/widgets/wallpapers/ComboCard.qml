import QtQuick
import "../../../" as App

// Una combinación de fondo y acento del wallpaper, como una mini pill con los colores que tendrá la shell
// (los calcula scripts/theme.py: `combo.preview[tint]` = { island, border, text, primary }).
Item {
    id: root

    property var combo: null
    // tinted (Sutil) | vivid (Intensa)
    property string tint: "vivid"
    property bool selected: false

    signal clicked

    readonly property var pv: combo ? combo.preview[tint] : null

    implicitWidth: 120
    implicitHeight: 62

    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        radius: height / 2
        color: root.pv ? root.pv.island : "transparent"
        border.width: root.selected ? 2 : 1
        border.color: root.pv ? (root.selected ? root.pv.primary : root.pv.border) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: 5
                color: root.pv ? root.pv.primary : "transparent"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "12:30"
                color: root.pv ? root.pv.text : App.Theme.white
                font.family: App.Config.fonts.mono
                font.pixelSize: App.Config.fontSize.sm
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 4
                radius: 2
                color: root.pv ? root.pv.primary : "transparent"
            }
        }
    }

    Text {
        anchors.top: pill.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        text: root.combo ? root.combo.name : ""
        elide: Text.ElideRight
        color: root.selected ? App.Theme.white : App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: root.selected ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
