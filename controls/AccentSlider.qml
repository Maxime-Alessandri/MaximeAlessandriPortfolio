import QtQuick
import QtQuick.Controls.Basic
import InvenesisPortfolio
import ".."

Slider {
    id: control

    implicitWidth: 200
    implicitHeight: 24
    activeFocusOnTab: true

    Accessible.role: Accessible.Slider

    background: Item {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - track.height / 2
        width: control.availableWidth
        height: 4

        Rectangle {
            id: track
            anchors.fill: parent
            radius: 2
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 0.5

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Theme.paletteAccent
            }
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: control.pressed ? Theme.cinnabarHover : (control.hovered ? Theme.terracottaGlow : Theme.paletteAccent)
        border.color: control.activeFocus ? Theme.textPrimary : Theme.bgVoid
        border.width: control.activeFocus ? 2 : 1.5

        scale: control.pressed ? 0.92 : (control.hovered ? 1.12 : 1.0)
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
    }
}
