pragma Singleton
import QtQuick
import Quickshell

// Selector de región de la pantalla (components/widgets/region/RegionSelector.qml), compartido por quien
// necesite marcar un área: el grabador y la importación de VPN por QR. Cada uno se identifica con un `owner`
// y recibe `accepted`/`canceled` solo si es el suyo.
Singleton {
    id: store

    property bool picking: false
    property string owner: ""
    // Región con la que se abre el selector ({ screen, x, y, w, h } en coordenadas globales) o null
    property var initial: null

    // Coordenadas globales del escritorio
    signal accepted(string owner, string screen, real x, real y, real w, real h)
    signal canceled(string owner)

    function pick(who, previous) {
        if (picking)
            return false;
        owner = who;
        initial = previous ?? null;
        picking = true;
        return true;
    }

    function accept(screen, x, y, w, h) {
        if (!picking)
            return;
        picking = false;
        accepted(owner, screen, x, y, w, h);
    }

    function cancel() {
        if (!picking)
            return;
        picking = false;
        canceled(owner);
    }
}
