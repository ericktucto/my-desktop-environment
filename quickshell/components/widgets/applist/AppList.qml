import QtQuick
import './../../controls/' as Controls
import '../../../' as App

Item {
    id: root

    // Modelo de apps (inyectado)
    property var apps: []
    property var allAppsCache: []
    property var filteredApps: []

    // Se emite al lanzar una app
    signal appLaunched(var app)

    // ══ State interno ══
    onAppsChanged: {
        if (apps.length > allAppsCache.length)
            allAppsCache = apps;

        filteredApps = apps;
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.giveFocus();
            listView.currentIndex = 0;
            filteredApps = allAppsCache.length ? allAppsCache : apps;
        }
    }

    Column {
        id: column
        anchors.fill: parent
        spacing: 10

        Controls.TextField {
            id: searchInput
            placeholder: "Buscar aplicaciones..."

            // CRÍTICO: Return y Enter son distintos en QML
            onPressedKey: function (key) {
                if (key == Qt.Key_Enter) {
                    launchSelected();
                }
                if (key == Qt.Key_Down) {
                    listView.incrementCurrentIndex();
                }
                if (key == Qt.Key_Up) {
                    listView.decrementCurrentIndex();
                }
            }
            onTextChanged: filterApps()
        }

        ListView {
            id: listView
            width: parent.width
            height: column.height - searchInput.height - column.spacing
            clip: true
            model: root.filteredApps

            currentIndex: -1

            // Sincronizar currentIndex con teclado
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()

            highlight: Rectangle {
                color: App.Theme.surfaceHigh
                radius: App.Config.radius.md
            }
            highlightMoveDuration: App.Config.anim.highlight
            highlightResizeDuration: 0

            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1500

            delegate: RowApp {
                width: listView.width
                name: modelData.name || modelData.desktopId || ""
                description: modelData.comment || modelData.genericName || ""
                iconSource: modelData.icon || ""

                onClicked: launchFromIndex(index)
            }

            populate: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: App.Config.anim.hover
                }
            }
        }
    }

    function launchSelected() {
        const idx = Math.max(0, Math.min(listView.currentIndex, filteredApps.length - 1));
        if (idx >= 0 && filteredApps.length > 0)
            root.appLaunched(filteredApps[idx]);
    }

    function launchFromIndex(index) {
        if (index >= 0 && index < filteredApps.length)
            root.appLaunched(filteredApps[index]);
    }

    function filterApps() {
        const q = searchInput.text.toLowerCase().trim();
        if (!q) {
            filteredApps = allAppsCache.length ? allAppsCache : apps;
        } else {
            filteredApps = apps.filter(a => (a.name || "").toLowerCase().includes(q));
        }
        listView.currentIndex = filteredApps.length > 0 ? 0 : -1;
    }
}
