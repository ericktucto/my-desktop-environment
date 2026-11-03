import Quickshell
import QtQuick
import "../base/" as Base
import "../controls/" as C
import "../../" as App

Base.Island {
    id: root

    property string current: 'applist'

    collapsedWidth: 90
    expandedHeight: 600
    expandedWidth: 400

    radiusExpanded: 32

    preventFocus: true

    Row {
        spacing: 8
        C.IconSvg {
            source: "/home/erick/Descargas/svg/volumen-on.svg"
            size: 16
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: '80%'
            font.family: "Symbols Nerd Font"   // o el nombre exacto de tu Nerd Font
            font.pixelSize: 12
            color: App.Theme.white
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    body: Rectangle {
        Item {
            anchors.fill: parent
            Text {
                text: 'Cuerpo'
            }
        }
    }
}
