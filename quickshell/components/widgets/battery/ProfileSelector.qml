import QtQuick
import "../../../services/power/" as P
import "../../../" as App

// Control segmentado con los perfiles de energía (Ahorro | Equilibrado | Rendimiento).
// Trabaja con los nombres de powerprofilesctl (`power-saver`, `balanced`, `performance`).
Rectangle {
    id: root

    property string current: ""
    property bool active: true          // false = un poco más tenue (la fuente que no rige ahora); sigue siendo clickeable

    signal picked(string key)

    readonly property var items: P.ProfileStore.choices

    height: App.Config.power.segmentHeight
    radius: height / 2
    color: App.Theme.surface
    opacity: active ? 1 : 0.6

    Row {
        anchors.fill: parent

        Repeater {
            model: root.items

            Item {
                id: cell

                required property var modelData
                readonly property bool selected: modelData.key === root.current

                width: root.width / root.items.length
                height: root.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: height / 2
                    // El perfil elegido va teñido con su color; el resto solo reacciona al hover
                    color: cell.selected ? Qt.alpha(cell.modelData.color, 0.25) : (mouse.containsMouse ? App.Theme.surfaceHover : "transparent")

                    Behavior on color {
                        ColorAnimation {
                            duration: App.Config.anim.control
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(cell.modelData.glyph)
                        color: cell.selected ? cell.modelData.color : App.Theme.gray
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.icon
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: cell.modelData.label
                        color: cell.selected ? App.Theme.white : App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.md
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(cell.modelData.key)
                }
            }
        }
    }
}
