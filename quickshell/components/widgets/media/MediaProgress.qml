import QtQuick
import "../../../" as App

// Barra de progreso (se puede clickear o arrastrar) con los tiempos "1:23" y "−2:10".
// En transmisiones sin duración (radio, directos) muestra "EN VIVO".
Item {
    id: root

    property real position: 0       // segundos
    property real length: 0         // segundos
    property real progress: 0       // 0..1
    property bool live: false
    property bool canSeek: true
    property color accent: App.Theme.primary

    signal seekRequested(real fraction)

    implicitHeight: 34

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const r = s % 60;
        const rr = (r < 10 ? "0" : "") + r;
        return h > 0 ? h + ":" + (m < 10 ? "0" : "") + m + ":" + rr : m + ":" + rr;
    }

    // Mientras se arrastra, la barra sigue al mouse y no a la posición del reproductor
    property bool dragging: false
    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : progress

    // ── En vivo ──
    Row {
        visible: root.live
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: App.Theme.red
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "EN VIVO"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
    }

    // ── Con duración ──
    Item {
        visible: !root.live
        anchors.fill: parent

        Item {
            id: bar
            anchors.top: parent.top
            width: parent.width
            height: 18

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: App.Theme.track

                Rectangle {
                    width: parent.width * root.shownValue
                    height: parent.height
                    radius: 3
                    color: root.accent
                }
            }
            Rectangle {
                visible: root.canSeek && (barMouse.containsMouse || root.dragging)
                x: Math.max(0, Math.min(track.width - width, track.width * root.shownValue - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: App.Theme.white
            }

            MouseArea {
                id: barMouse
                anchors.fill: parent
                enabled: root.canSeek
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                function valueAt(x) {
                    return Math.max(0, Math.min(1, x / width));
                }
                onPressed: mouse => {
                    root.dragging = true;
                    root.dragValue = valueAt(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (root.dragging)
                        root.dragValue = valueAt(mouse.x);
                }
                onReleased: mouse => {
                    root.dragging = false;
                    root.seekRequested(valueAt(mouse.x));
                }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: root.fmt(root.dragging ? root.dragValue * root.length : root.position)
            color: App.Theme.gray
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.xs
        }
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: "−" + root.fmt(root.length - (root.dragging ? root.dragValue * root.length : root.position))
            color: App.Theme.gray
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.xs
        }
    }
}
