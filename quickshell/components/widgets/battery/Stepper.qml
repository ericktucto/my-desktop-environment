import QtQuick
import "../../../" as App

// Valor con botones − y +.
Item {
    id: root

    property string text
    property bool active: true      // false = atenuado (la fuente que no rige ahora)

    signal decrement
    signal increment

    width: App.Config.power.stepperWidth
    height: App.Config.power.rowHeight

    component RoundButton: Rectangle {
        id: btn

        property string label
        signal clicked

        width: 24
        height: 24
        radius: 12
        anchors.verticalCenter: parent.verticalCenter
        color: App.Theme.surface

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }

        Text {
            anchors.centerIn: parent
            text: btn.label
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: btn.color = containsMouse ? App.Theme.surfaceActive : App.Theme.surface
            onClicked: btn.clicked()
        }
    }

    RoundButton {
        id: minus
        anchors.left: parent.left
        label: "−"
        onClicked: root.decrement()
    }

    Text {
        anchors.left: minus.right
        anchors.right: plus.left
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: root.active ? App.Theme.white : App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.Medium
    }

    RoundButton {
        id: plus
        anchors.right: parent.right
        label: "+"
        onClicked: root.increment()
    }
}
