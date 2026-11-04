import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../" as Root

Rectangle {
    id: p

    property bool expanded: false
    property int collapsedWidth: Math.ceil(contentContainer.implicitWidth) + 2 * Root.Config.pill.paddingX
    property int collapsedHeight: Root.Config.pill.height
    property int expandedWidth: 320
    property int expandedHeight: 180
    property int radiusExpanded: Root.Config.pill.radiusExpanded
    property bool preventFocus: false
    property int paddingContainer: Root.Config.pill.padding

    default property alias content: contentContainer.data
    property alias body: pillContainer.data
    readonly property bool hasBody: pillContainer.children.length > 0

    signal clicked
    signal opened
    signal closed

    onExpandedChanged: expanded ? opened() : closed()

    function open() {
        expanded = true;
    }
    function close() {
        expanded = false;
    }

    y: Root.Config.pill.top
    width: expanded ? expandedWidth : collapsedWidth
    height: expanded ? expandedHeight : collapsedHeight
    radius: expanded ? radiusExpanded : height / 2
    color: Root.Theme.island
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Root.Config.anim.pill
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Root.Config.anim.pill
            easing.type: Easing.OutCubic
        }
    }
    Behavior on radius {
        NumberAnimation {
            duration: Root.Config.anim.pill
            easing.type: Easing.OutCubic
        }
    }

    // Absorbe los clics sobre la pill expandida (zonas sin control propio) para que no
    // lleguen al "clic fuera" de la ventana y la cierren. Va al fondo: los controles
    // del cuerpo, declarados después, siguen recibiendo sus clics.
    MouseArea {
        anchors.fill: parent
        enabled: p.expanded
        acceptedButtons: Qt.AllButtons
    }

    Row {
        id: contentContainer
        anchors.centerIn: parent
        spacing: Root.Config.pill.contentSpacing
        opacity: p.expanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Root.Config.anim.fadeOut
            }
        }
    }

    Item {
        id: pillContainer
        anchors.fill: parent
        anchors.margins: paddingContainer
        opacity: p.expanded ? 1 : 0
        visible: opacity > 0
        focus: true

        onVisibleChanged: {
            if (visible && !preventFocus) {
                forceActiveFocus();
            }
        }

        Keys.onPressed: function (event) {
            if (event.key == Qt.Key_Escape)
                p.expanded = false;
            event.accepted = true;
        }

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: p.expanded ? Root.Config.anim.fadeDelay : 0
                }
                NumberAnimation {
                    duration: Root.Config.anim.fadeIn
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // disabled si no hay body — la pill no hace nada si no tiene contenido
        // disabled cuando esta expandido
        enabled: p.hasBody && !p.expanded

        onClicked: {
            p.clicked();
            p.expanded = true;
        }
    }
}
