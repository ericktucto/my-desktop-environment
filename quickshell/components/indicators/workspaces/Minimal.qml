import QtQuick
import "../../../services/workspaces/" as S
import "../../../" as App

// Mínimo: solo el activo, «2 / 4». No hay a qué apuntar: el clic abre la vista general.
WsStyle {
    id: root

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    function idAt(x) {
        return -1;
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: S.WorkspaceStore.currentId + " / " + S.WorkspaceStore.count
        color: App.Theme.white
        font.family: App.Config.fonts.mono
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.Medium
    }
}
