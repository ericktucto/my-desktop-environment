import QtQuick
import "../controlcenter/" as CC
import "../../../services/calendar/" as CS
import "../../../" as App

// Cabecera del calendario: ‹ título › (el título abre el selector de mes), Hoy, ↻, ⋮ y las vistas.
Item {
    id: root

    readonly property var store: CS.CalendarStore

    property bool menuOpen: false

    height: App.Config.calendar.headerHeight

    // Ancho que le queda al título (el resto de la fila izquierda es fijo)
    readonly property real titleRoom: width - views.width - 8 - (28 * 4 + todayButton.width + 6 * 5)

    Row {
        id: left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        CalButton {
            glyph: 0xf0141
            onClicked: root.store.shift(-1)
        }

        Rectangle {
            width: Math.min(titleText.implicitWidth + 12, Math.max(80, root.titleRoom))
            height: 28
            radius: 14
            anchors.verticalCenter: parent.verticalCenter
            color: root.store.pickerOpen ? App.Theme.surfaceActive : (titleMouse.containsMouse ? App.Theme.surface : "transparent")

            Text {
                id: titleText
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.store.title
                elide: Text.ElideRight
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: titleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.store.pickerOpen = !root.store.pickerOpen
            }
        }

        CalButton {
            glyph: 0xf0142
            onClicked: root.store.shift(1)
        }

        Rectangle {
            id: todayButton
            width: todayText.implicitWidth + 24
            height: 28
            radius: 14
            anchors.verticalCenter: parent.verticalCenter
            color: todayMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

            Text {
                id: todayText
                anchors.centerIn: parent
                text: "Hoy"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: todayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.store.goToday()
            }
        }

        CalButton {
            glyph: 0xf0450
            spinning: root.store.loading
            onClicked: {
                root.menuOpen = false;
                root.store.refresh(true);
            }
        }

        CalButton {
            glyph: 0xf01d9
            active: root.menuOpen
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    // Mes · Semana · 3 días · Día
    Row {
        id: views
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: [
                {
                    id: "month",
                    label: "Mes"
                },
                {
                    id: "week",
                    label: "Semana"
                },
                {
                    id: "days3",
                    label: "3 días"
                },
                {
                    id: "day",
                    label: "Día"
                }
            ]
            CC.Chip {
                required property var modelData
                height: 28
                radius: 14
                label: modelData.label
                selected: root.store.view === modelData.id
                onClicked: root.store.setView(modelData.id)
            }
        }
    }

    // Menú ⋮
    Rectangle {
        id: menu
        visible: root.menuOpen
        z: 20
        x: left.width - 28 - 150
        y: parent.height + 6
        width: 220
        height: menuColumn.implicitHeight + 16
        radius: 16
        color: App.Theme.island
        border.color: App.Theme.islandEdge
        border.width: 1

        Column {
            id: menuColumn
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 2

            Text {
                visible: root.store.connected && root.store.email !== ""
                width: parent.width
                leftPadding: 8
                topPadding: 4
                bottomPadding: 6
                text: root.store.email
                elide: Text.ElideRight
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }

            Repeater {
                model: {
                    const items = [];
                    if (!root.store.connected && root.store.hasClient)
                        items.push({
                            id: "login",
                            label: "Conectar con Google"
                        });
                    if (root.store.connected)
                        items.push({
                            id: "logout",
                            label: "Desconectar de Google"
                        });
                    items.push({
                        id: "web",
                        label: "Abrir Google Calendar"
                    });
                    return items;
                }
                Rectangle {
                    required property var modelData
                    width: menuColumn.width
                    height: 32
                    radius: 10
                    color: itemMouse.containsMouse ? App.Theme.surfaceActive : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: parent.modelData.label
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.menuOpen = false;
                            if (parent.modelData.id === "login")
                                root.store.login();
                            else if (parent.modelData.id === "logout")
                                root.store.logout();
                            else
                                root.store.openUrl("https://calendar.google.com/calendar/r/" + (root.store.view === "month" ? "month" : root.store.view === "week" ? "week" : root.store.view === "days3" ? "customday" : "day") + "/" + root.store.selected.getFullYear() + "/" + (root.store.selected.getMonth() + 1) + "/" + root.store.selected.getDate());
                        }
                    }
                }
            }
        }
    }
}
