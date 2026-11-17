import QtQuick
import "../../base" as Base
import "../../../" as App
import "../../../services/osd/" as O
import "../../../services/panels/" as P

Base.Island {
    id: root

    property string current: 'applist'

    // La música está expandida al centro: el reloj pasa a ser un círculo con un reloj analógico mini
    property bool compact: false
    readonly property bool circle: compact && O.OsdStore.kind === ""
    collapsedPaddingX: circle ? 0 : App.Config.pill.paddingX

    expandedHeight: {
        if (current === 'applist')
            return App.Config.panel.launcherHeight;
        if (current === 'wallpapers')
            return App.Config.wallpaperPicker.imgHeight * 2 + App.Config.wallpaperPicker.spacingCell * 2 + App.Config.wallpaperPicker.themeRow + 2 * App.Config.pill.padding;
        if (current === 'session')
            return App.Config.session.height;
        if (current === 'control')
            return islandBody.controlHeight + 2 * paddingContainer;
        if (current === 'clipboard')
            return App.Config.panel.clipboardHeight;
        if (current === 'recorder')
            return islandBody.recorderHeight + 2 * paddingContainer;
        if (current === 'productivity')
            return islandBody.productivityHeight + 2 * paddingContainer;
        return 300;
    }
    expandedWidth: {
        if (current === 'applist')
            return App.Config.panel.launcherWidth;
        if (current === 'wallpapers')
            return App.Config.panel.wallpapersWidth;
        if (current === 'session')
            return App.Config.session.width;
        if (current === 'control')
            return App.Config.panel.controlCenterWidth;
        if (current === 'clipboard')
            return App.Config.panel.clipboardWidth;
        if (current === 'recorder')
            return App.Config.panel.recorderWidth;
        if (current === 'productivity')
            return islandBody.productivityWidth;
        return 400;
    }

    preventFocus: true
    escapeBack: function () {
        return islandBody.escapeBack();
    }
    // El launcher se abre solo con Super+R; el clic izquierdo abre Productividad (calendario) y el derecho
    // el centro de control
    openOnClick: false

    IslandStatus {
        circle: root.circle
        // Con el mouse encima, el reloj dice la fecha (y el próximo evento)
        showDate: clockMouse.containsMouse
    }

    // Clic izquierdo en el reloj: Productividad. Clic derecho: centro de control.
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        id: clockMouse
        parent: root
        anchors.fill: parent
        enabled: !root.expanded && !root.compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.current = 'control';
                islandBody.refreshControl();
            } else {
                root.current = 'productivity';
                islandBody.openProductivity();
            }
            root.open();
        }
    }

    // Con la música expandida, un clic en el círculo del reloj la pliega y todo vuelve a su lugar
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: root.circle
        cursorShape: Qt.PointingHandCursor
        onClicked: P.PanelStore.closeAll()
    }

    // Al abrir la isla, el OSD sobra
    onOpened: O.OsdStore.hide()

    body: IslandBody {
        id: islandBody
        root: root
    }
}
