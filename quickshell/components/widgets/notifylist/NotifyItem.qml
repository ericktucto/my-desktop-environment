import QtQuick
import QtQuick.Effects
import Quickshell.Services.Notifications
import "../../controls/" as C
import "../../../services/notify/" as S
import "../../../" as App

// Tarjeta de una notificación. Se usa en el historial y en los popups.
// `modelData` es la key de la entrada en NotificationStore.
Rectangle {
    id: root

    required property string modelData
    property bool popup: false

    readonly property var cfg: App.Config.notifications
    readonly property var entry: S.NotificationStore.entry(modelData)
    readonly property var iconInfo: S.NotificationStore.iconFor(entry)
    readonly property bool critical: entry ? entry.urgency === NotificationUrgency.Critical : false
    readonly property string appName: entry ? entry.appName : ""

    // Estado visual (no se guarda): título y cuerpo completos
    property bool expanded: false
    readonly property bool canExpand: expanded || summaryText.truncated || bodyText.truncated

    // Si la foto no carga se usa el ícono de la app
    property bool photoFailed: false
    readonly property bool showPhoto: iconInfo.kind === "photo" && !photoFailed

    signal activated
    signal closeRequested
    signal rightClicked

    width: parent?.width ?? cfg.popupWidth
    height: content.implicitHeight + 2 * cfg.cardPadding
    radius: cfg.cardRadius

    Behavior on height {
        NumberAnimation {
            duration: App.Config.anim.pill
            easing.type: Easing.OutCubic
        }
    }

    color: popup ? App.Theme.island : App.Theme.surface
    border.width: popup || critical ? 1 : 0
    border.color: critical ? App.Theme.red : App.Theme.islandEdge

    // Clic en la tarjeta (los botones, declarados después, reciben los suyos)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.activated();
        }
    }

    // ── Círculo con foto, ícono de la app o inicial ──
    Item {
        id: avatar
        x: root.cfg.cardPadding
        y: root.cfg.cardPadding
        width: root.cfg.imageSize
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(App.Theme.primary.r, App.Theme.primary.g, App.Theme.primary.b, 0.3)
            visible: !root.showPhoto
        }

        Image {
            id: appImg
            anchors.centerIn: parent
            width: root.cfg.appIconSize
            height: width
            visible: !root.showPhoto && root.iconInfo.app !== "" && status === Image.Ready
            source: root.iconInfo.app
            sourceSize: Qt.size(root.cfg.appIconSize, root.cfg.appIconSize)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: !root.showPhoto && (root.iconInfo.app === "" || appImg.status !== Image.Ready)
            text: (root.appName[0] ?? "?").toUpperCase()
            color: App.Theme.white
            font.pixelSize: App.Config.fontSize.lg
            font.weight: Font.DemiBold
        }

        Image {
            id: photo
            anchors.fill: parent
            visible: root.showPhoto
            source: root.showPhoto ? root.iconInfo.source : ""
            sourceSize: Qt.size(root.cfg.imageSize * 2, root.cfg.imageSize * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            onStatusChanged: if (status === Image.Error)
                root.photoFailed = true

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSource: maskRect
            }
        }

        Rectangle {
            id: maskRect
            visible: false
            layer.enabled: true
            anchors.fill: parent
            radius: width / 2
        }
    }

    Column {
        id: content
        x: root.cfg.cardPadding + root.cfg.imageSize + 12
        y: root.cfg.cardPadding
        width: root.width - x - root.cfg.cardPadding
        spacing: 2

        // Fila superior: app · hora · cerrar
        Item {
            width: parent.width
            height: root.cfg.closeSize

            Text {
                anchors.left: parent.left
                anchors.right: timeText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.appName
                color: App.Theme.gray
                font.pixelSize: App.Config.fontSize.xs
                elide: Text.ElideRight
            }

            Text {
                id: timeText
                anchors.right: expandButton.visible ? expandButton.left : closeButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry ? S.NotificationStore.ago(root.entry.time) : ""
                color: App.Theme.gray
                font.pixelSize: App.Config.fontSize.xs
            }

            // Expandir / plegar (solo si algo quedó cortado)
            Rectangle {
                id: expandButton
                visible: root.canExpand
                anchors.right: closeButton.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.cfg.closeSize
                height: width
                radius: width / 2
                color: expandMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surfaceHover

                Behavior on color {
                    ColorAnimation {
                        duration: App.Config.anim.control
                    }
                }

                C.IconSvg {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("../../../assets/svg/chevron-down.svg")
                    size: 12
                    color: App.Theme.white
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: App.Config.anim.control
                        }
                    }
                }

                MouseArea {
                    id: expandMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = !root.expanded
                }
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.cfg.closeSize
                height: width
                radius: width / 2
                color: closeMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surfaceHover

                Behavior on color {
                    ColorAnimation {
                        duration: App.Config.anim.control
                    }
                }

                C.IconSvg {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("../../../assets/svg/close.svg")
                    size: 12
                    color: App.Theme.white
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Text {
            id: summaryText
            width: parent.width
            text: root.entry ? root.entry.summary : ""
            color: App.Theme.white
            font.pixelSize: App.Config.fontSize.lg
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 100000 : root.cfg.summaryLines
            elide: Text.ElideRight
            visible: text !== ""
        }

        // Cuerpo: plegado en pocas líneas; expandido con alto máximo y scroll
        Item {
            width: parent.width
            height: bodyText.text === "" ? 0 : (root.expanded ? Math.min(bodyText.implicitHeight, root.cfg.expandedMaxHeight) : bodyText.implicitHeight)
            visible: bodyText.text !== ""
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: App.Config.anim.pill
                    easing.type: Easing.OutCubic
                }
            }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: bodyText.implicitHeight
                interactive: root.expanded && contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: bodyText
                    width: parent.width
                    text: root.entry ? S.NotificationStore.formatBody(root.entry.body) : ""
                    textFormat: Text.StyledText
                    color: App.Theme.gray
                    font.pixelSize: App.Config.fontSize.md
                    wrapMode: Text.Wrap
                    maximumLineCount: root.expanded ? 100000 : (root.popup ? root.cfg.popupBodyLines : root.cfg.bodyLines)
                    elide: Text.ElideRight
                }
            }
        }

        // Acciones: solo si la notificación sigue viva en la app
        Flow {
            width: parent.width
            topPadding: 6
            spacing: 6
            visible: actionsRepeater.count > 0

            Repeater {
                id: actionsRepeater
                model: root.entry && root.entry.alive ? root.entry.actions.filter(a => a.identifier !== "default") : []

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: actionText.implicitWidth + 20
                    height: 26
                    radius: height / 2
                    color: actionMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surfaceHover

                    Behavior on color {
                        ColorAnimation {
                            duration: App.Config.anim.control
                        }
                    }

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: App.Theme.white
                        font.pixelSize: App.Config.fontSize.sm
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: S.NotificationStore.invokeAction(root.modelData, actionButton.modelData.identifier)
                    }
                }
            }
        }
    }
}
