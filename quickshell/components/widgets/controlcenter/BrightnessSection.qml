import QtQuick
import "../../controls/" as C
import "../../../services/brightness/" as S
import "../../../" as App

// Brillo de la pantalla: título + porcentaje y un slider.
Column {
    id: root

    spacing: 8

    Item {
        width: parent.width
        height: 18

        Text {
            text: "BRILLO"
            color: App.Theme.gray
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: S.BrightnessStore.percent() + "%"
            color: App.Theme.white
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
    }

    Row {
        width: parent.width
        spacing: 12

        C.IconSvg {
            id: icon
            size: 18
            anchors.verticalCenter: parent.verticalCenter
            source: Qt.resolvedUrl("../../../assets/svg/brightness.svg")
            color: App.Theme.white
        }

        C.Slider {
            width: parent.width - icon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            to: 1
            value: S.BrightnessStore.value
            onMoved: v => S.BrightnessStore.set(v)
        }
    }
}
