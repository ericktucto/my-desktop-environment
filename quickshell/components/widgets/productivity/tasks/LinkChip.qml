import QtQuick
import "../../../../" as App

// Un link de la tarea: ícono por tipo, la etiqueta corta ("acme/api#412") y, si se sabe, el título.
// Clic abre el link; la × lo quita. `state` (open, merged, closed, draft) llega en la fase 4.
Rectangle {
    id: root

    property var link
    property bool removable: true

    signal removed

    readonly property var glyphs: ({
            "github-pr": 0xf126,
            "github-issue": 0xf06a,
            "gitlab-mr": 0xf126,
            "gitlab-issue": 0xf06a,
            "jira": 0xf0ae,
            "figma": 0xf1fc,
            "gdoc": 0xf15c,
            "url": 0xf0c1
        })
    readonly property var stateColors: ({
            "open": App.Theme.green,
            "merged": App.Theme.purple,
            "closed": App.Theme.red,
            "draft": App.Theme.gray
        })

    implicitWidth: Math.min(row.implicitWidth + 24, 360)
    height: 28
    radius: 14
    color: mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Qt.openUrlExternally(root.link.url)
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: 12
        spacing: 6

        Rectangle {
            visible: root.link.state !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: root.stateColors[root.link.state] ?? App.Theme.gray
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(root.glyphs[root.link.kind] ?? 0xf0c1)
            color: App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            text: root.link.label
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.Medium
        }
        Text {
            visible: root.link.title !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 160)
            text: "· " + root.link.title
            elide: Text.ElideRight
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            id: removeButton
            visible: root.removable
            opacity: mouse.containsMouse ? 1 : 0
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xf00d)
            color: removeMouse.containsMouse ? App.Theme.red : App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.sm
            MouseArea {
                id: removeMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removed()
            }
        }
    }
}
