import QtQuick
import Quickshell
import "pages/" as PG
import "../../services/settings/" as ST
import "../../" as App

// Ventana de Preferencias del sistema: a la izquierda el buscador y las páginas; a la derecha la página
// elegida (o los resultados de la búsqueda). Se abre con Super+, , por IPC (stixshell@settings) y desde el
// botón de ajustes del centro de control. Esc limpia la búsqueda y, sin búsqueda, cierra la ventana.
FloatingWindow {
    id: win

    readonly property var ui: ST.SettingsUi

    // Las páginas, en el orden de la barra lateral (glyph = carácter de la fuente de íconos)
    readonly property var pages: [
        {
            id: "appearance",
            name: "Apariencia",
            glyph: 0xf1fc,
            source: "pages/AppearancePage.qml"
        },
        {
            id: "nightlight",
            name: "Luz nocturna",
            glyph: 0xf186,
            source: "pages/NightLightPage.qml"
        },
        {
            id: "energy",
            name: "Energía",
            glyph: 0xf240,
            source: "pages/EnergyPage.qml"
        },
        {
            id: "about",
            name: "Acerca de",
            glyph: 0xf05a,
            source: "pages/AboutPage.qml"
        }
    ]

    title: "Preferencias del sistema"
    visible: ui.open
    color: App.Theme.island
    implicitWidth: 1000
    implicitHeight: 680
    minimumSize: Qt.size(760, 480)

    // Cerrar con la X o con el compositor
    onVisibleChanged: {
        if (!visible && ui.open)
            ui.open = false;
        if (visible)
            Qt.callLater(() => search.forceActiveFocus());
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (win.ui.query !== "")
                    win.ui.query = "";
                else
                    win.ui.open = false;
                event.accepted = true;
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                search.forceActiveFocus();
                event.accepted = true;
            }
        }

        // ── Barra lateral ──
        Rectangle {
            id: side
            width: 230
            height: parent.height
            color: Qt.rgba(1, 1, 1, 0.03)

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: App.Theme.islandEdge
            }

            // Buscador
            Rectangle {
                id: searchBox
                x: 14
                y: 14
                width: parent.width - 28
                height: 34
                radius: 17
                color: App.Theme.surface
                border.width: 1
                border.color: search.activeFocus ? App.Theme.primary : "transparent"

                Text {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xf002)
                    color: App.Theme.gray
                    font.family: App.Config.fonts.icons
                    font.pixelSize: App.Config.fontSize.sm
                }
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 34
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    text: win.ui.query
                    color: App.Theme.white
                    selectionColor: App.Theme.primary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    clip: true
                    onTextEdited: win.ui.query = text
                    onAccepted: {
                        const r = win.ui.results[0];
                        if (r)
                            win.ui.goTo(r.page, r.id);
                    }
                    Keys.onEscapePressed: event => event.accepted = false
                }
                Text {
                    visible: search.text === ""
                    anchors.fill: parent
                    anchors.leftMargin: 34
                    verticalAlignment: Text.AlignVCenter
                    text: "Buscar ajustes"
                    color: App.Theme.placeholder
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
            }

            // Páginas
            Column {
                x: 10
                y: 62
                width: parent.width - 20
                spacing: 2
                Repeater {
                    model: win.pages
                    Rectangle {
                        id: entry
                        required property var modelData
                        readonly property bool current: win.ui.query === "" && win.ui.page === modelData.id
                        width: parent.width
                        height: 36
                        radius: 10
                        color: current ? App.Theme.surfaceActive : (entryMouse.containsMouse ? App.Theme.surface : "transparent")

                        Text {
                            x: 12
                            width: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(entry.modelData.glyph)
                            color: entry.current ? App.Theme.primary : App.Theme.gray
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.icon - 2
                        }
                        Text {
                            x: 42
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData.name
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.md
                            font.weight: entry.current ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.ui.query = "";
                                win.ui.page = entry.modelData.id;
                            }
                        }
                    }
                }
            }
        }

        // ── Contenido ──
        Item {
            id: content
            x: side.width + 28
            y: 20
            width: parent.width - x - 20
            height: parent.height - 40

            // Las páginas se crean todas (así el buscador conoce sus filas) y se ve la elegida
            Repeater {
                model: win.pages
                Loader {
                    required property var modelData
                    anchors.fill: parent
                    source: modelData.source
                    visible: win.ui.query === "" && win.ui.page === modelData.id
                }
            }

            // Resultados de la búsqueda
            Flickable {
                anchors.fill: parent
                visible: win.ui.query !== ""
                contentHeight: resultsCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: resultsCol
                    width: parent.width - 16
                    spacing: 6

                    Text {
                        text: win.ui.results.length > 0 ? "Resultados" : "Sin resultados para «" + win.ui.query + "»"
                        color: win.ui.results.length > 0 ? App.Theme.white : App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: win.ui.results.length > 0 ? 22 : App.Config.fontSize.md
                        font.weight: Font.DemiBold
                        bottomPadding: 6
                    }
                    Repeater {
                        model: win.ui.results
                        Rectangle {
                            id: res
                            required property var modelData
                            width: resultsCol.width
                            height: 50
                            radius: 12
                            color: resMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

                            Column {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: res.modelData.label
                                    color: App.Theme.white
                                    font.family: App.Config.fonts.text
                                    font.pixelSize: App.Config.fontSize.md
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: res.modelData.pageName
                                    color: App.Theme.gray
                                    font.family: App.Config.fonts.text
                                    font.pixelSize: App.Config.fontSize.xs
                                }
                            }
                            MouseArea {
                                id: resMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.ui.goTo(res.modelData.page, res.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
