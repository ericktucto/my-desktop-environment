import QtQuick
import "../../base" as Base
import "../../../" as App
import "../../../services/osd/" as O
import "../../../services/panels/" as P
import "../../../services/actions/" as AC
import "../../../services/settings/" as ST

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
            return App.Config.wallpaperPicker.imgHeight * 2 + App.Config.wallpaperPicker.spacingCell * 2 + App.Config.wallpaperPicker.themeRow + App.Config.wallpaperPicker.tintRow + 2 * App.Config.pill.padding;
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
        if (current === 'quickadd')
            return islandBody.quickAddHeight + 2 * paddingContainer;
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
        if (current === 'quickadd')
            return App.Config.tasks.quickWidth;
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

    // Clic en el reloj, según Preferencias → Barra e isla (por defecto: izquierdo Productividad, derecho el centro
    // de control). Esas dos abren su panel aquí mismo; el resto llama a ActionRunner.
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    function runClick(id) {
        if (id === 'control') {
            root.current = 'control';
            islandBody.refreshControl();
            root.open();
        } else if (id === 'productivity') {
            root.current = 'productivity';
            islandBody.openProductivity();
            root.open();
        } else {
            AC.ActionRunner.run(id);
        }
    }

    MouseArea {
        id: clockMouse
        parent: root
        anchors.fill: parent
        enabled: !root.expanded && !root.compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        property real wheelAcc: 0
        onClicked: mouse => {
            const c = ST.SettingsStore.island;
            root.runClick(mouse.button === Qt.RightButton ? c.right : (mouse.button === Qt.MiddleButton ? c.middle : c.left));
        }
        // La rueda (el touchpad acumula): con Shift, la otra acción
        onWheel: wheel => {
            const dy = wheel.angleDelta.y;
            const id = (wheel.modifiers & Qt.ShiftModifier) ? ST.SettingsStore.island.shiftWheel : ST.SettingsStore.island.wheel;
            // Con Shift muchos sistemas mandan el giro por el eje X
            const d = dy !== 0 ? dy : wheel.angleDelta.x;
            if (d === 0 || id === "none")
                return;
            if (wheelAcc * d < 0)
                wheelAcc = 0;
            wheelAcc += d;
            while (Math.abs(wheelAcc) >= App.Config.workspaces.wheelStep) {
                AC.ActionRunner.wheel(id, wheelAcc > 0 ? 1 : -1);
                wheelAcc -= (wheelAcc > 0 ? 1 : -1) * App.Config.workspaces.wheelStep;
            }
            wheel.accepted = true;
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
