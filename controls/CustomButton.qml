import QtQuick
import QtQuick.Controls
import InvenesisPortfolio
import ".."

Item {
    id: control

    property string text: ""
    property string iconName: ""
    property string variant: "primary" // "primary", "secondary", "ghost", "accent"
    property real customHeight: 44.0
    property real customRadius: Theme.radiusPill
    property bool active: false

    signal clicked()

    implicitWidth: Math.max(120, btnRow.implicitWidth + (Theme.spaceLg * 2))
    implicitHeight: customHeight

    // Apple Fluid Tactile Spring Feedback: Compress instantly on pointer down, gently expand on hover
    scale: !control.enabled ? 1.0 : (mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.02 : 1.0))
    Behavior on scale {
        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: control.customRadius
        antialiasing: true

        // Background color resolution based on variant and hover/press
        color: {
            if (!control.enabled) return Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.4)
            if (control.variant === "primary") {
                if (mouseArea.pressed) return Theme.cinnabarHover
                if (mouseArea.containsMouse || control.active) return Theme.terracotta
                return Theme.cinnabar
            } else if (control.variant === "accent") {
                if (mouseArea.pressed) return Theme.cinnabarHover
                if (mouseArea.containsMouse || control.active) return Theme.terracottaGlow
                return Theme.terracotta
            } else if (control.variant === "secondary") {
                if (mouseArea.pressed) return Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.95)
                if (mouseArea.containsMouse || control.active) return Qt.rgba(Theme.bgSurfaceHover.r, Theme.bgSurfaceHover.g, Theme.bgSurfaceHover.b, 0.85)
                return Theme.glassFill
            } else { // "ghost"
                if (mouseArea.pressed) return Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.12)
                if (mouseArea.containsMouse || control.active) return Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.06)
                return "transparent"
            }
        }

        border.color: {
            if (!control.enabled) return "transparent"
            if (control.variant === "primary") return mouseArea.containsMouse ? Theme.terracottaGlow : Theme.terracotta
            if (control.variant === "secondary") return mouseArea.containsMouse ? Theme.borderActive : Theme.borderCard
            if (control.variant === "ghost") return mouseArea.containsMouse ? Theme.borderSubtle : "transparent"
            return Theme.terracottaGlow
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: Theme.spaceSm

            Text {
                id: iconText
                visible: control.iconName !== ""
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontIcon
                font.pixelSize: 18
                text: control.iconName
                color: (control.variant === "primary" || control.variant === "accent") ? Theme.textOn(bgRect.color) : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
            }

            Text {
                id: labelText
                anchors.verticalCenter: parent.verticalCenter
                font.family: control.variant === "ghost" ? Theme.fontMono : Theme.fontBody
                font.pixelSize: control.variant === "ghost" ? Theme.sizeTelemetry : Theme.sizeBodySm
                font.weight: Font.Medium
                font.capitalization: control.variant === "ghost" ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: control.variant === "ghost" ? Theme.trackMicro : 0.0
                text: control.text
                color: {
                    if (!control.enabled) return Theme.textDim
                    if (control.variant === "primary" || control.variant === "accent") return Theme.textOn(bgRect.color)
                    return mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: control.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
