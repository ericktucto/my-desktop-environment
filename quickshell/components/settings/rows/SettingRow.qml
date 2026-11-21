import QtQuick
import "../../../services/settings/" as ST
import "../../../" as App

// Fila base de una página de Preferencias: nombre y ayuda a la izquierda y el control a la derecha.
//   changed    el valor se aparta del de fábrica: sale un punto del acento (un clic lo restablece)
//   searchId   nombre para el buscador (si falta, no se registra); `keywords` = palabras extra que la encuentran
// Los controles hijos van a la derecha.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string searchId: ""
    property string keywords: ""
    property bool changed: false
    // Ancho de la zona del control (0 = lo que mida)
    property real controlWidth: 0
    // Alto mínimo de la fila
    property real minHeight: 52
    // El control va debajo del nombre y a todo el ancho (para lo que no cabe a la derecha)
    property bool stacked: false

    default property alias control: ctl.data

    signal resetRequested

    // La página donde está (la registra el buscador)
    readonly property var page: {
        let p = parent;
        while (p && !p.isSettingsPage)
            p = p.parent;
        return p;
    }
    readonly property bool flashing: searchId !== "" && ST.SettingsUi.highlight === searchId && page !== null && ST.SettingsUi.page === page.pageId

    width: parent ? parent.width : 0
    implicitHeight: stacked ? texts.implicitHeight + ctl.childrenRect.height + 32 : Math.max(minHeight, texts.implicitHeight + 16)

    Component.onCompleted: {
        if (searchId !== "" && page)
            ST.SettingsUi.register({
                page: page.pageId,
                pageName: page.pageName,
                id: searchId,
                label: label,
                hint: hint,
                keywords: keywords
            });
    }
    Component.onDestruction: {
        if (searchId !== "" && page)
            ST.SettingsUi.unregister(page.pageId, searchId);
    }
    // Al llegar desde el buscador, la página baja hasta la fila
    onFlashingChanged: {
        if (flashing)
            page.reveal(root);
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.flashing ? App.Theme.surfaceActive : App.Theme.surface
        border.width: root.flashing ? 1 : 0
        border.color: App.Theme.primary
        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }
    }

    // El punto de «cambiado»
    Rectangle {
        visible: root.changed
        x: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: App.Theme.primary
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.resetRequested()
        }
    }

    Column {
        id: texts
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: root.stacked ? parent.right : ctl.left
        anchors.rightMargin: root.stacked ? 18 : 12
        anchors.top: root.stacked ? parent.top : undefined
        anchors.topMargin: 12
        anchors.verticalCenter: root.stacked ? undefined : parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.Medium
        }
        Text {
            visible: root.hint !== ""
            width: parent.width
            text: root.hint
            wrapMode: Text.WordWrap
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
    }

    Row {
        id: ctl
        anchors.right: root.stacked ? undefined : parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: root.stacked ? undefined : parent.verticalCenter
        anchors.left: root.stacked ? parent.left : undefined
        anchors.leftMargin: 18
        anchors.top: root.stacked ? texts.bottom : undefined
        anchors.topMargin: 10
        width: root.stacked ? parent.width - 36 : (root.controlWidth > 0 ? root.controlWidth : implicitWidth)
        spacing: 8
        layoutDirection: root.stacked ? Qt.LeftToRight : Qt.RightToLeft
    }
}
