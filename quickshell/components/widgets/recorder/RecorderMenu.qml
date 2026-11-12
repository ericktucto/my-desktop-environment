import QtQuick
import QtQuick.Controls
import Quickshell
import "../controlcenter/" as CC
import "../../../services/recorder/" as R
import "../../../services/audio/" as A
import "../../../" as App

// Menú de grabación (Super+G): qué grabar, qué audio, dónde guardar, y Grabar (también con Enter).
FocusScope {
    id: root

    implicitHeight: col.implicitHeight

    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            R.RecorderStore.begin();
            event.accepted = true;
        }
    }

    function glyph(code) {
        return String.fromCodePoint(code);
    }

    component Section: Text {
        color: App.Theme.gray
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    Column {
        id: col
        width: parent.width
        spacing: 14

        // ── Qué grabar ──
        Section {
            text: "QUÉ GRABAR"
        }
        Grid {
            id: targets
            width: parent.width
            columns: 2
            spacing: App.Config.control.tileSpacing
            readonly property real tileWidth: (width - spacing) / 2

            Repeater {
                model: Quickshell.screens
                delegate: CC.ControlTile {
                    required property var modelData
                    width: targets.tileWidth
                    glyph: root.glyph(0xf0379)
                    title: modelData.name
                    subtitle: modelData.width + " × " + modelData.height
                    checked: R.RecorderStore.target === modelData.name
                    onClicked: R.RecorderStore.setTarget(modelData.name)
                }
            }
            CC.ControlTile {
                width: targets.tileWidth
                glyph: root.glyph(0xf019e)
                title: "Región"
                subtitle: R.RecorderStore.region ? R.RecorderStore.regionText : "Elegir con ›"
                checked: R.RecorderStore.target === "region"
                detail: true
                onClicked: R.RecorderStore.setTarget("region")
                // La flecha abre el selector para marcar el área en la pantalla
                onDetailClicked: R.RecorderStore.pickRegion("menu")
            }
        }

        // ── Audio ──
        Section {
            text: "AUDIO"
        }
        Grid {
            id: audio
            width: parent.width
            columns: 2
            spacing: App.Config.control.tileSpacing
            readonly property real tileWidth: (width - spacing) / 2

            CC.ControlTile {
                width: audio.tileWidth
                glyph: root.glyph(0xf057e)
                title: "Sonido interno"
                subtitle: A.AudioStore.label(A.AudioStore.sink) || "Sin salida"
                checked: R.RecorderStore.internal
                onClicked: R.RecorderStore.setInternal(!R.RecorderStore.internal)
            }
            CC.ControlTile {
                width: audio.tileWidth
                glyph: root.glyph(0xf036c)
                title: "Micrófono"
                subtitle: A.AudioStore.label(A.AudioStore.source) || "Sin micrófono"
                checked: R.RecorderStore.mic
                onClicked: R.RecorderStore.setMic(!R.RecorderStore.mic)
            }
        }

        // ── Carpeta ──
        Section {
            text: "GUARDAR EN"
        }
        Rectangle {
            width: parent.width
            height: App.Config.control.footerHeight
            radius: height / 2
            color: App.Theme.surface

            // Nombre de la carpeta (la ruta completa, de tooltip)
            Item {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: change.left
                anchors.rightMargin: 8
                height: parent.height

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 10

                    Text {
                        id: folderIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyph(0xf024b)
                        color: App.Theme.gray
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.iconLg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - folderIcon.width - parent.spacing
                        text: R.RecorderStore.folderName
                        elide: Text.ElideRight
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.md
                        font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    id: folderHover
                    anchors.fill: parent
                    hoverEnabled: true
                    ToolTip.visible: containsMouse
                    ToolTip.delay: 400
                    ToolTip.text: R.RecorderStore.folder
                }
            }

            Rectangle {
                id: change
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: changeText.implicitWidth + 28
                height: parent.height - 12
                radius: height / 2
                color: changeMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surfaceHover

                Text {
                    id: changeText
                    anchors.centerIn: parent
                    text: "Cambiar"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: changeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: R.RecorderStore.pickFolder()
                }
            }
        }

        // ── Grabar ──
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180
            height: App.Config.control.footerHeight
            radius: height / 2
            color: recMouse.containsMouse ? Qt.lighter(App.Theme.red, 1.12) : App.Theme.red

            Behavior on color {
                ColorAnimation {
                    duration: App.Config.anim.control
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: width
                    radius: width / 2
                    color: App.Theme.white
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Grabar"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg
                    font.weight: Font.Bold
                }
            }
            MouseArea {
                id: recMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: R.RecorderStore.begin()
            }
        }
    }
}
