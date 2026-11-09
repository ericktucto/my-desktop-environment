pragma Singleton
import QtQuick
import Quickshell
import "../../" as App

// Qué muestra el OSD de la isla central contraída: "", "volume", "brightness" o "mic".
Singleton {
    id: store

    property string kind: ""

    function show(k) {
        kind = k;
        hideTimer.restart();
    }

    function hide() {
        kind = "";
        hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: App.Config.osd.timeout
        onTriggered: store.kind = ""
    }
}
