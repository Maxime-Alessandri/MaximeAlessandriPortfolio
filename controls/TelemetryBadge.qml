import QtQuick
import InvenesisPortfolio
import ".."

Rectangle {
    id: badgeRoot

    property string label: ""
    property string value: ""
    property color dotColor: Theme.terracottaGlow
    property bool pulseDot: true

    implicitHeight: 28
    implicitWidth: badgeRow.implicitWidth + 24
    radius: Theme.radiusPill
    color: Theme.glassFill
    border.color: Theme.glassBorder
    border.width: 1

    Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: badgeRoot.dotColor

            SequentialAnimation on opacity {
                running: badgeRoot.pulseDot && badgeRoot.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMicro
            font.letterSpacing: Theme.trackMicro
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            color: Theme.textMuted
            text: badgeRoot.label
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMicro
            font.letterSpacing: Theme.trackMicro
            font.capitalization: Font.AllUppercase
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: badgeRoot.value
        }
    }
}
