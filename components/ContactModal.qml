import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."

Item {
    id: modalRoot

    visible: false
    anchors.fill: parent
    z: 999

    property bool isOpen: false
    signal closed()

    function open() {
        modalRoot.visible = true;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 220
        repeat: false
        onTriggered: {
            modalRoot.visible = false;
            modalRoot.closed();
        }
    }

    // Backdrop with smooth dimming scrim (Apple depth hierarchy)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bgVoid.r, Theme.bgVoid.g, Theme.bgVoid.b, 0.82)
        opacity: modalRoot.isOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: modalRoot.close()
        }
    }

    // Modal Card with Apple Liquid Specular Sheet & Physical Scale Entry
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 660)
        implicitHeight: modalCol.implicitHeight + (Theme.spaceLg * 2)
        height: Math.min(parent.height - 48, implicitHeight)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        opacity: modalRoot.isOpen ? 1.0 : 0.0
        scale: modalRoot.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            // Absorb clicks inside card so backdrop dismiss does not fire
        }

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            // Top Row: Title + Close Button
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.sizeH2
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "Direct Executive Consultation"
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        font.letterSpacing: Theme.trackMicro
                        color: Theme.terracottaGlow
                        text: "MAXIME ALESSANDRI, PhD // SCIENTIST & SCIENTIFIC SOFTWARE ARCHITECT"
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: closeMouse.containsMouse ? Theme.bgSurface : "transparent"
                    scale: closeMouse.pressed ? 0.90 : (closeMouse.containsMouse ? 1.10 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: Theme.textPrimary
                        text: "close"
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modalRoot.close()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Contact Channels
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Email
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: Theme.bgSurface
                        Text { anchors.centerIn: parent; font.family: Theme.fontIcon; font.pixelSize: 16; color: Theme.terracottaGlow; text: "mail" }
                    }
                    Column {
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "PRIMARY EMAIL" }
                        Text { font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; font.weight: Font.DemiBold; color: Theme.textPrimary; text: "alessandrimaxime@gmail.com" }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: 96; Layout.preferredHeight: 28; radius: Theme.radiusPill
                        color: sendEmailMouse.pressed ? Theme.cinnabarHover : Theme.cinnabar
                        scale: sendEmailMouse.pressed ? 0.94 : (sendEmailMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textOnCinnabar; text: "Send Email" }
                        MouseArea {
                            id: sendEmailMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("mailto:alessandrimaxime@gmail.com")
                        }
                    }
                }

                // Phone
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: Theme.bgSurface
                        Text { anchors.centerIn: parent; font.family: Theme.fontIcon; font.pixelSize: 16; color: Theme.statusGreen; text: "call" }
                    }
                    Column {
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "MOBILE & WHATSAPP" }
                        Text { font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; font.weight: Font.DemiBold; color: Theme.textPrimary; text: "+41 78 735 63 88" }
                    }
                    Item { Layout.fillWidth: true }
                    Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; text: "Switzerland (CET)" }
                }

                // Location
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: Theme.bgSurface
                        Text { anchors.centerIn: parent; font.family: Theme.fontIcon; font.pixelSize: 16; color: Theme.goldAccent; text: "location_on" }
                    }
                    Column {
                        Layout.fillWidth: true
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "LOCATION & CITIZENSHIP" }
                        Text { font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; font.weight: Font.DemiBold; color: Theme.textPrimary; text: "Le Mont-sur-Lausanne, Vaud, Switzerland • Swiss Citizen" }
                    }
                }

                // Profiles: LinkedIn & GitHub Quick Chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 34; radius: Theme.radiusPill
                        color: liModalMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                        border.color: liModalMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard; border.width: 1
                        scale: liModalMouse.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                            color: Theme.textPrimary
                            text: "LinkedIn Profile ↗"
                        }
                        MouseArea {
                            id: liModalMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://www.linkedin.com/in/maxime-alessandri-phd")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 34; radius: Theme.radiusPill
                        color: ghModalMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                        border.color: ghModalMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard; border.width: 1
                        scale: ghModalMouse.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                            color: Theme.textPrimary
                            text: "GitHub Repositories ↗"
                        }
                        MouseArea {
                            id: ghModalMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://github.com/Maxime-Alessandri")
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Academic & Professional References (University of Lausanne)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    font.family: Theme.fontMono; font.pixelSize: 9; font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow
                    text: "SCIENTIFIC & ACADEMIC REFERENCES (UNIL)"
                }
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: 12; color: Theme.textSecondary; lineHeight: 1.45
                    text: "• Prof. Jean-Yves Chatton (University of Lausanne) — Jean-Yves.Chatton@unil.ch\n• Prof. Anita Lüthi (University of Lausanne) — anita.luthi@unil.ch"
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 40; radius: Theme.radiusPill
                    color: cvMouse.pressed ? Theme.cinnabarHover : Theme.cinnabar
                    border.color: Theme.terracottaGlow; border.width: 1
                    scale: cvMouse.pressed ? 0.97 : (cvMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold; font.capitalization: Font.AllUppercase
                        color: Theme.textOnCinnabar; text: "Download Full CV (.docx) ↗"
                    }
                    MouseArea {
                        id: cvMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(AppConfig.cvUrl())
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 100; Layout.preferredHeight: 40; radius: Theme.radiusPill
                    color: dismissMouse.pressed ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.borderCard; border.width: 1
                    scale: dismissMouse.pressed ? 0.96 : (dismissMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.textPrimary; text: "Dismiss"
                    }
                    MouseArea {
                        id: dismissMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: modalRoot.close()
                    }
                }
            }
        }
    }
}
