import QtQuick
import QtQuick.Controls
import "../../../services/screenshot/" as S
import "../../../" as App

// Barra de herramientas del editor, junto al área: herramientas, color, grosor, lo propio de la herramienta
// (relleno, fondo del texto, pixelar o difuminar), y deshacer y rehacer.
Rectangle {
    id: root

    readonly property var store: S.AnnotationStore
    readonly property var conf: App.Config.screenshot

    implicitWidth: row.implicitWidth + 20
    implicitHeight: conf.toolbarHeight
    radius: height / 2
    color: App.Theme.island
    border.width: 1
    border.color: App.Theme.border

    // Lo que se edita: la anotación seleccionada o, si no hay, la herramienta
    readonly property string ctx: {
        store.version;
        const k = store.kindOf(store.selectedId);
        return k !== "" ? k : store.tool;
    }
    readonly property bool hasStyle: ctx !== "pixel" && ctx !== "sticker" && ctx !== "move"

    readonly property var tools: [
        {
            id: "move",
            glyph: 0xf01c0,
            tip: "Mover y editar (V)"
        },
        {
            id: "arrow",
            glyph: 0xf005c,
            tip: "Flecha (A)"
        },
        {
            id: "rect",
            glyph: 0xf0e5f,
            tip: "Rectángulo (R)"
        },
        {
            id: "ellipse",
            glyph: 0xf0766,
            tip: "Elipse (E)"
        },
        {
            id: "line",
            glyph: 0,
            tip: "Línea (L)"
        },
        {
            id: "pen",
            glyph: 0xf03eb,
            tip: "Lápiz (P)"
        },
        {
            id: "marker",
            glyph: 0,
            tip: "Resaltador (H)"
        },
        {
            id: "text",
            glyph: 0,
            tip: "Texto (T)"
        },
        {
            id: "counter",
            glyph: 0xf03a6,
            tip: "Números (N)"
        },
        {
            id: "pixel",
            glyph: 0,
            tip: "Pixelar o difuminar (B)"
        },
        {
            id: "sticker",
            glyph: 0xf01f6,
            tip: "Stickers (S)"
        }
    ]

    // Un botón redondo de la barra
    component Btn: Rectangle {
        id: btn
        property bool active: false
        property bool enabled2: true
        property string tip: ""
        default property alias content: holder.data
        signal clicked

        width: 34
        height: 34
        radius: 17
        color: active ? App.Theme.primary : (mouse.containsMouse && enabled2 ? App.Theme.surfaceActive : "transparent")
        opacity: enabled2 ? 1 : 0.35

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }

        Item {
            id: holder
            anchors.centerIn: parent
            width: 20
            height: 20
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled2
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
        ToolTip.visible: mouse.containsMouse && tip !== ""
        ToolTip.text: tip
        ToolTip.delay: 600
    }

    component Glyph: Text {
        anchors.centerIn: parent
        color: App.Theme.white
        font.family: App.Config.fonts.icons
        font.pixelSize: 18
    }

    component Sep: Rectangle {
        width: 1
        height: 22
        color: App.Theme.islandEdge
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // ── Herramientas ──
        Repeater {
            model: root.tools
            delegate: Btn {
                id: tb
                required property var modelData
                active: root.store.tool === modelData.id
                tip: modelData.tip
                onClicked: root.store.setTool(modelData.id)

                Glyph {
                    color: tb.active ? App.Theme.onPrimary : App.Theme.white
                    visible: tb.modelData.glyph !== 0
                    text: tb.modelData.glyph !== 0 ? String.fromCodePoint(tb.modelData.glyph) : ""
                }
                // Las que no tienen ícono en la fuente se dibujan
                Rectangle {
                    visible: tb.modelData.id === "line"
                    anchors.centerIn: parent
                    width: 22
                    height: 2.5
                    radius: 1.25
                    rotation: -45
                    color: tb.active ? App.Theme.onPrimary : App.Theme.white
                }
                Rectangle {
                    visible: tb.modelData.id === "marker"
                    anchors.centerIn: parent
                    width: 20
                    height: 9
                    radius: 2
                    rotation: -35
                    color: Qt.rgba(1, 0.92, 0, 0.75)
                }
                Text {
                    visible: tb.modelData.id === "text"
                    anchors.centerIn: parent
                    text: "T"
                    color: tb.active ? App.Theme.onPrimary : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }
                Grid {
                    visible: tb.modelData.id === "pixel"
                    anchors.centerIn: parent
                    columns: 3
                    spacing: 1
                    Repeater {
                        model: 9
                        Rectangle {
                            required property int index
                            width: 6
                            height: 6
                            color: tb.active ? App.Theme.onPrimary : App.Theme.white
                            opacity: index % 2 === 0 ? 1 : 0.35
                        }
                    }
                }
            }
        }

        Sep {
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Color ──
        Row {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.hasStyle ? 1 : 0.35

            Repeater {
                model: root.conf.colors
                delegate: Item {
                    id: sw
                    required property int index
                    required property string modelData
                    width: 24
                    height: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        radius: 9
                        color: sw.modelData
                        border.width: root.store.cfg.color === sw.index ? 2 : 1
                        border.color: root.store.cfg.color === sw.index ? App.Theme.white : App.Theme.grayDark
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.hasStyle
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.store.setColor(sw.index)
                    }
                }
            }
        }

        Sep {
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Grosor ──
        Repeater {
            model: [3, 5, 9]
            delegate: Btn {
                id: sz
                required property int index
                required property int modelData
                enabled2: root.hasStyle
                active: root.store.sizeIndex === index
                tip: ["Fino", "Medio", "Grueso"][index]
                onClicked: root.store.setSize(index)

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: sz.modelData
                    radius: height / 2
                    color: App.Theme.white
                }
            }
        }

        // ── Lo propio de la herramienta ──
        Sep {
            visible: ctxButtons.visible
            anchors.verticalCenter: parent.verticalCenter
        }
        Row {
            id: ctxButtons
            visible: root.ctx === "rect" || root.ctx === "ellipse" || root.ctx === "text" || root.ctx === "pixel"
            spacing: 4

            Btn {
                visible: root.ctx === "rect" || root.ctx === "ellipse"
                active: root.store.cfg.fill
                tip: "Relleno"
                onClicked: root.store.toggleFill()
                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 12
                    radius: 2
                    color: root.store.cfg.fill ? App.Theme.white : "transparent"
                    border.width: 2
                    border.color: App.Theme.white
                }
            }
            Btn {
                visible: root.ctx === "text"
                active: root.store.cfg.textBackground
                tip: "Fondo del texto"
                onClicked: root.store.toggleTextBackground()
                Text {
                    anchors.centerIn: parent
                    text: "Aa"
                    color: root.store.cfg.textBackground ? App.Theme.black : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: 13
                    font.weight: Font.Bold

                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height
                        radius: 3
                        color: root.store.cfg.textBackground ? App.Theme.white : "transparent"
                    }
                }
            }
            Rectangle {
                visible: root.ctx === "pixel"
                width: blurLabel.implicitWidth + 24
                height: 34
                radius: 17
                color: blurMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

                Text {
                    id: blurLabel
                    anchors.centerIn: parent
                    text: root.store.cfg.blur ? "Difuminar" : "Pixelar"
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: blurMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.toggleBlur()
                }
            }
        }

        Sep {
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Deshacer y rehacer ──
        Btn {
            enabled2: root.store.canUndo
            tip: "Deshacer (Ctrl+Z)"
            onClicked: root.store.undo()
            Glyph {
                text: String.fromCodePoint(0xf054d)
            }
        }
        Btn {
            enabled2: root.store.canRedo
            tip: "Rehacer (Ctrl+Shift+Z)"
            onClicked: root.store.redo()
            Glyph {
                text: String.fromCodePoint(0xf044e)
            }
        }
    }
}
