import QtQuick
import "../controlcenter/" as CC
import "../../../" as App

// Selector de color completo: cuadro de saturación y brillo, barra de tono, la muestra y el hex.
// Mientras se arrastra solo cambia la vista previa; el color se aplica al soltar (`picked`), así no corre
// un proceso por cada píxel. «Listo» vuelve a los wallpapers.
Item {
    id: root

    // Color de partida ("#rrggbb")
    property string value: "#2979ff"

    signal picked(string hex)
    signal done

    // Tono, saturación y brillo de lo que se ve (0..1)
    property real h: 0
    property real s: 1
    property real v: 1
    readonly property color current: Qt.hsva(h, s, v, 1)
    readonly property string hex: current.toString().substring(0, 7)

    function load(hex) {
        const c = Qt.color(hex);
        // Un gris no tiene tono: se conserva el que había
        if (c.hsvSaturation > 0.001)
            h = c.hsvHue;
        s = c.hsvSaturation;
        v = c.hsvValue;
    }
    onValueChanged: {
        // Un cambio de afuera (gotero, muestra); si es el mismo color que se está viendo, no se mueve nada
        if (value.toLowerCase() !== hex.toLowerCase())
            load(value);
    }
    Component.onCompleted: load(value)

    // ── Cuadro: saturación (→) y brillo (↓) ──
    Rectangle {
        id: box
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 360
        radius: 10
        clip: true
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: Qt.hsva(root.h, 1, 1, 1)
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#00000000"
                }
                GradientStop {
                    position: 1
                    color: "#ff000000"
                }
            }
        }

        // Dónde está el color
        Rectangle {
            x: root.s * box.width - width / 2
            y: (1 - root.v) * box.height - height / 2
            width: 18
            height: 18
            radius: 9
            color: "transparent"
            border.width: 2
            border.color: root.v > 0.6 && root.s < 0.5 ? "#000000" : "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            function at(m) {
                root.s = Math.max(0, Math.min(1, m.x / width));
                root.v = 1 - Math.max(0, Math.min(1, m.y / height));
            }
            onPressed: m => at(m)
            onPositionChanged: m => at(m)
            onReleased: root.picked(root.hex)
        }
    }

    // ── Barra de tono ──
    Rectangle {
        id: hue
        anchors.left: box.right
        anchors.leftMargin: 14
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 26
        radius: 10
        clip: true
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#ff0000"
            }
            GradientStop {
                position: 0.17
                color: "#ffff00"
            }
            GradientStop {
                position: 0.33
                color: "#00ff00"
            }
            GradientStop {
                position: 0.5
                color: "#00ffff"
            }
            GradientStop {
                position: 0.67
                color: "#0000ff"
            }
            GradientStop {
                position: 0.83
                color: "#ff00ff"
            }
            GradientStop {
                position: 1.0
                color: "#ff0000"
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.h * hue.height - height / 2
            width: hue.width + 4
            height: 8
            radius: 4
            color: Qt.hsva(root.h, 1, 1, 1)
            border.width: 2
            border.color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function at(m) {
                root.h = Math.max(0, Math.min(0.999, m.y / height));
            }
            onPressed: m => at(m)
            onPositionChanged: m => at(m)
            onReleased: root.picked(root.hex)
        }
    }

    // ── La muestra, el hex y Listo ──
    Column {
        anchors.left: hue.right
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        Rectangle {
            width: parent.width
            height: 64
            radius: 12
            color: root.current
            border.width: 1
            border.color: App.Theme.islandEdge
        }
        Text {
            text: root.hex
            color: App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.lg
            font.weight: Font.Medium
        }
        Text {
            width: parent.width
            text: "Arrastra y suelta para aplicar el acento. Solo cambia el acento: la barra queda como el sistema."
            color: App.Theme.subtext
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
            wrapMode: Text.WordWrap
        }
        CC.Chip {
            label: "Listo"
            selected: true
            onClicked: root.done()
        }
    }
}
