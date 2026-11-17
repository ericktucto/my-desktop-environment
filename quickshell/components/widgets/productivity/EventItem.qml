import QtQuick
import "../controlcenter/" as CC
import "../../../services/calendar/" as CS
import "../../../" as App

// Un evento de la lista: barra de color, hora, título, lugar y cuenta regresiva. Con un clic se despliega
// (lugar, descripción, calendario y los botones Unirse, Copiar enlace y Abrir en Google).
Rectangle {
    id: root

    readonly property var store: CS.CalendarStore
    property var ev
    readonly property bool special: !!(ev.holiday || ev.observance)
    readonly property bool expanded: !special && store.expandedId === ev.id
    readonly property bool past: store.isPast(ev)
    property bool copied: false

    signal closeRequested

    implicitHeight: col.implicitHeight + 8
    radius: 12
    color: expanded ? App.Theme.surface : (headMouse.containsMouse && !special ? App.Theme.surfaceHover : "transparent")
    opacity: past && !expanded ? 0.5 : 1

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    Column {
        id: col
        x: 10
        y: 4
        width: parent.width - 20
        spacing: 6

        // Fila principal
        Item {
            width: parent.width
            height: 28

            Rectangle {
                id: bar
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 20
                radius: 1.5
                color: root.ev.color
            }
            Text {
                id: when
                anchors.left: bar.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 124
                text: root.ev.holiday ? "Feriado" : root.ev.observance ? "Celebración" : root.store.timeLabel(root.ev)
                elide: Text.ElideRight
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Row {
                id: right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: root.store.countdown(root.ev)
                    color: root.store.isNow(root.ev) ? App.Theme.primary : App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: root.store.isNow(root.ev) ? Font.DemiBold : Font.Normal
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.ev.meet !== ""
                    text: String.fromCodePoint(0xf0567)
                    color: App.Theme.gray
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.icon
                }
            }
            Row {
                anchors.left: when.right
                anchors.leftMargin: 8
                anchors.right: right.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                clip: true
                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width)
                    text: root.ev.title
                    elide: Text.ElideRight
                    color: root.ev.holiday ? App.Theme.red : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.Medium
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.expanded && root.ev.location !== "" && parent.width - titleText.width > 40
                    width: Math.max(0, parent.width - titleText.width - 8)
                    text: root.ev.location
                    elide: Text.ElideRight
                    color: App.Theme.grayDark
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }
            MouseArea {
                id: headMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.special
                cursorShape: Qt.PointingHandCursor
                onClicked: root.store.toggleEvent(root.ev)
            }
        }

        // Detalles
        Column {
            visible: root.expanded
            width: parent.width
            spacing: 6
            leftPadding: 13

            Text {
                visible: root.ev.location !== ""
                width: parent.width - 13
                text: root.ev.location
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                visible: root.ev.description !== ""
                width: parent.width - 13
                text: root.ev.description
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                text: root.ev.calName
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
            Row {
                spacing: 8
                bottomPadding: 4
                CC.SmallButton {
                    visible: root.ev.meet !== ""
                    primary: true
                    label: "Unirse"
                    onClicked: {
                        root.store.openUrl(root.ev.meet);
                        root.closeRequested();
                    }
                }
                CC.SmallButton {
                    visible: root.ev.meet !== ""
                    label: root.copied ? "Copiado" : "Copiar enlace"
                    onClicked: {
                        root.store.copyText(root.ev.meet);
                        root.copied = true;
                        copiedTimer.restart();
                    }
                }
                CC.SmallButton {
                    visible: root.ev.link !== ""
                    label: "Abrir en Google"
                    onClicked: {
                        root.store.openUrl(root.ev.link);
                        root.closeRequested();
                    }
                }
            }
        }
    }

    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: root.copied = false
    }
}
