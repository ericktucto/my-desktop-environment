import QtQuick
import Quickshell
import Quickshell.Io
import "../../widgets/controlcenter/" as CC
import "../../../" as App

// Una ruta (carpeta o archivo) con el botón «Elegir…» que abre el diálogo de GTK (scripts/pick.py).
// `value` vacío = el valor de fábrica (`defaultText` se muestra en gris).
SettingRow {
    id: root

    property string value: ""
    property string defaultText: ""
    // "folder" o "file"
    property string kind: "folder"
    property var patterns: []
    property string dialogTitle: ""

    signal picked(string path)

    changed: value !== ""
    onResetRequested: picked("")
    controlWidth: 320

    CC.SmallButton {
        label: "Elegir…"
        onClicked: {
            if (picker.running)
                return;
            picker.command = ["python3", Quickshell.shellPath("scripts/pick.py"), root.kind, root.value !== "" ? root.value : root.defaultText, root.dialogTitle].concat(root.patterns);
            picker.running = true;
        }
    }
    Text {
        width: 220
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
        text: root.value !== "" ? root.value : root.defaultText
        color: root.value !== "" ? App.Theme.white : App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    root.picked(p);
            }
        }
    }
}
