import QtQuick
import QtQuick.Shapes
import "../base" as Base
import "../widgets/media/" as MW
import "../../services/media/" as M
import "../../" as App

// Pill de música junto al reloj: solo la carátula redonda con un anillo de progreso. Al hacer clic pasa
// al centro y se expande con el reproductor (el reloj se hace un círculo y se corre a la derecha).
Base.Island {
    id: root

    readonly property var cfg: App.Config.media
    readonly property var store: M.MediaStore

    // Círculo: el contenido manda el ancho
    collapsedPaddingX: 0
    expandedWidth: cfg.panelWidth
    expandedHeight: cfg.panelHeight + (store.players.length > 1 ? cfg.chipsHeight : 0)
    paddingContainer: cfg.padding
    // El panel toma el foco por su cuenta (teclado)
    preventFocus: true

    // Solo se ve si hay un reproductor con una pista (o está abierta)
    visible: store.visible || expanded

    // Sin reproductor, el panel no tiene nada que mostrar
    Connections {
        target: root.store
        function onVisibleChanged() {
            if (!root.store.visible)
                root.close();
        }
        function onTogglePanel() {
            if (root.expanded)
                root.close();
            else if (root.store.visible)
                root.open();
        }
    }

    // ── Plegada: carátula con el anillo ──
    Item {
        id: pill
        width: root.collapsedHeight
        height: width

        MW.MediaArt {
            anchors.centerIn: parent
            width: root.cfg.pillArt
            height: width
            round: true
            dimmed: !root.store.playing
        }

        // El anillo muestra el progreso; con la rueda, el volumen un momento
        Shape {
            id: ring
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            readonly property real value: root.store.showVolume ? root.store.volume : (root.store.isLive ? 1 : root.store.progress)
            readonly property real r: (width - root.cfg.ringWidth) / 2

            ShapePath {
                strokeWidth: root.cfg.ringWidth
                strokeColor: App.Theme.track
                fillColor: "transparent"
                PathAngleArc {
                    centerX: pill.width / 2
                    centerY: pill.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: 0
                    sweepAngle: 360
                }
            }
            ShapePath {
                strokeWidth: root.cfg.ringWidth
                strokeColor: root.store.showVolume ? App.Theme.white : (root.store.playing ? App.Theme.primary : App.Theme.grayDark)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: pill.width / 2
                    centerY: pill.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: -90
                    sweepAngle: 360 * Math.max(0.001, ring.value)
                }
            }
        }

        // Rueda sobre la carátula: volumen del reproductor (los clics pasan a la isla)
        MouseArea {
            anchors.fill: parent
            enabled: !root.expanded
            acceptedButtons: Qt.NoButton
            property real acc: 0
            onWheel: wheel => {
                acc += wheel.angleDelta.y;
                while (Math.abs(acc) >= App.Config.workspaces.wheelStep) {
                    root.store.volumeWheel(acc > 0 ? root.cfg.volumeStep : -root.cfg.volumeStep);
                    acc -= acc > 0 ? App.Config.workspaces.wheelStep : -App.Config.workspaces.wheelStep;
                }
            }
        }
    }
    body: MW.MediaPanel {
        anchors.fill: parent
        islandRadius: root.radiusExpanded
    }
}
