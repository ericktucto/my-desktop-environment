import QtQuick
import "../../base" as Base
import "../../../" as App
import "../../../services/brightness/" as B
import "../../../services/osd/" as O

Base.Island {
    id: root

    property string current: 'applist'

    expandedHeight: {
        if (current === 'applist')
            return App.Config.panel.launcherHeight;
        if (current === 'wallpapers')
            return App.Config.wallpaperPicker.imgHeight * 2 + App.Config.wallpaperPicker.spacingCell * 2 + 2 * App.Config.pill.padding;
        if (current === 'session')
            return App.Config.session.height;
        if (current === 'control')
            return islandBody.controlHeight + 2 * paddingContainer;
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
        return 400;
    }

    preventFocus: true

    IslandStatus {}

    // Clic derecho en el reloj: centro de control. El izquierdo llega al MouseArea de Island (launcher).
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        parent: root
        anchors.fill: parent
        enabled: !root.expanded
        acceptedButtons: Qt.RightButton
        onClicked: {
            root.current = 'control';
            B.BrightnessStore.refresh();
            root.open();
        }
    }

    // Al abrir la isla, el OSD sobra
    onOpened: O.OsdStore.hide()

    body: IslandBody {
        id: islandBody
        root: root
    }

    onClicked: {
        current = 'applist';
    }
}
