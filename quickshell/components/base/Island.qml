import QtQuick
import Quickshell
import Quickshell.Wayland
import '../../' as Root

Rectangle {
    id: p

    property bool expanded: false
    property int collapsedWidth: 140
    property int collapsedHeight: 28
    property int expandedWidth: 320
    property int expandedHeight: 180
    property int radiusExpanded: 0
    property bool preventFocus: false

    default property alias content: contentContainer.data
    property alias body: pillContainer.data
    readonly property bool hasBody: pillContainer.children.length > 0

    signal opened()
    signal closed()

    onExpandedChanged: expanded ? opened() : closed()

    function open()  { expanded = true }
    function close() { expanded = false }

    y: 6
    width: expanded ? expandedWidth : collapsedWidth
    height: expanded ? expandedHeight : collapsedHeight
    radius: expanded ? radiusExpanded || 16 : height / 2
    color: Root.Theme.island
    clip: true

    Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    Row {
        id: contentContainer
        anchors.centerIn: parent
        opacity: p.expanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Item {
        id: pillContainer
        anchors.fill: parent
        anchors.margins: 16
        opacity: p.expanded ? 1 : 0
        visible: opacity > 0
        focus: true

        onVisibleChanged: {
            if (visible && !preventFocus) {
                forceActiveFocus()
            }
        }

        Keys.onPressed: function(event) {
            if (event.key == Qt.Key_Escape) p.expanded = false
            event.accepted = true
        }

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: p.expanded ? 100 : 0 }
                NumberAnimation { duration: 200 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // disabled si no hay body — la pill no hace nada si no tiene contenido
        // disabled cuando esta expandido
        enabled: p.hasBody && !p.expanded

        onClicked: p.expanded = true
    }
}

