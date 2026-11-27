import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."
import "../controls"

Item {
    id: logoModalRoot

    visible: false
    anchors.fill: parent
    z: 999

    property bool isOpen: false
    signal closed()

    function open() {
        logoModalRoot.visible = true;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 250
        repeat: false
        onTriggered: {
            logoModalRoot.visible = false;
            logoModalRoot.closed();
        }
    }

    // Backdrop with smooth dimming scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bgVoid.r, Theme.bgVoid.g, Theme.bgVoid.b, 0.82)
        opacity: logoModalRoot.isOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: logoModalRoot.close()
        }
    }

    // Modal Card with Apple Liquid Specular Sheet & Physical Scale Entry
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 780)
        implicitHeight: modalCol.implicitHeight + 48
        height: Math.min(parent.height - 40, implicitHeight)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        opacity: logoModalRoot.isOpen ? 1.0 : 0.0
        scale: logoModalRoot.isOpen ? 1.0 : 0.94

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header Row: Title & Close Button
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 4
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: catTag.implicitWidth + 14
                            radius: 10
                            color: Theme.glassFill
                            border.color: Theme.paletteAccent
                            border.width: 1

                            Text {
                                id: catTag
                                anchors.centerIn: parent
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: Theme.trackMicro
                                font.capitalization: Font.AllUppercase
                                color: Theme.paletteAccent
                                text: "BRAND IDENTITY // VECTOR EMBLEMS"
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.sizeH2
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary
                        text: "Signature Navigation Emblem Showcase"
                    }

                    Text {
                        font.family: Theme.fontBody
                        font.pixelSize: 13
                        color: Theme.textSecondary
                        text: "Six custom-engineered geometric marks designed for the portfolio navigation bar. Click any concept to activate."
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: closeMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1
                    scale: closeMouse.pressed ? 0.92 : (closeMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: Theme.textPrimary
                        text: "close"
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: logoModalRoot.close()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Scrollable List of the 6 Logo Concepts
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: Theme.logoConcepts

                        Rectangle {
                            id: conceptCard
                            Layout.fillWidth: true
                            implicitHeight: cardRow.implicitHeight + 24
                            radius: Theme.radiusSm
                            color: isCurrent ? Theme.bgSurfaceHover : (cardMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface)
                            border.color: isCurrent ? Theme.paletteAccent : (cardMouse.containsMouse ? Theme.borderCardHover : Theme.borderCard)
                            border.width: isCurrent ? 1.5 : 1

                            readonly property bool isCurrent: Theme.activeLogoConcept === index

                            scale: cardMouse.pressed ? 0.99 : (cardMouse.containsMouse ? 1.01 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.setLogo(index)
                            }

                            RowLayout {
                                id: cardRow
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 16

                                // Left Large Emblem Display
                                Rectangle {
                                    Layout.preferredWidth: 54
                                    Layout.preferredHeight: 54
                                    radius: 27
                                    color: conceptCard.isCurrent ? Theme.paletteAccent : Theme.glassFill
                                    border.color: conceptCard.isCurrent ? Theme.paletteAccent : Theme.borderSubtle
                                    border.width: 1

                                    BrandEmblem {
                                        anchors.centerIn: parent
                                        width: 36
                                        height: 36
                                        conceptIndex: index
                                        showBackgroundBadge: false
                                        emblemColor: conceptCard.isCurrent ? Theme.textOnAccent : Theme.textPrimary
                                        accentColor: conceptCard.isCurrent ? Theme.textOnAccent : Theme.paletteAccent
                                    }
                                }

                                // Middle Narrative
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            font.family: Theme.fontDisplay
                                            font.pixelSize: 16
                                            font.weight: Font.Bold
                                            font.letterSpacing: Theme.trackHeading
                                            color: Theme.textPrimary
                                            text: modelData.name
                                        }

                                        Rectangle {
                                            visible: conceptCard.isCurrent
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: activeText.implicitWidth + 12
                                            radius: 9
                                            color: Theme.paletteAccent

                                            Text {
                                                id: activeText
                                                anchors.centerIn: parent
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.6
                                                color: Theme.textOnAccent
                                                text: "ACTIVE EMBLEM"
                                            }
                                        }
                                    }

                                    Text {
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: Theme.trackMicro
                                        font.capitalization: Font.AllUppercase
                                        color: Theme.paletteAccent
                                        text: modelData.tagline
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        font.family: Theme.fontBody
                                        font.pixelSize: 12
                                        lineHeight: 1.45
                                        color: Theme.textSecondary
                                        text: modelData.description
                                    }
                                }

                                // Right Selection Indicator
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: conceptCard.isCurrent ? Theme.paletteAccent : "transparent"
                                    border.color: conceptCard.isCurrent ? Theme.paletteAccent : Theme.borderCard
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: conceptCard.isCurrent ? Theme.textOnAccent : Theme.textDim
                                        text: conceptCard.isCurrent ? "✓" : "○"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Footer Bar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textDim
                    text: "SHORTCUTS: Press 'L' to cycle logo concepts • 'P' / 'O' to cycle color palettes"
                }

                Item { Layout.fillWidth: true }

                CustomButton {
                    text: "Done ✓"
                    variant: "primary"
                    customHeight: 34
                    customRadius: 17
                    onClicked: logoModalRoot.close()
                }
            }
        }
    }
}
