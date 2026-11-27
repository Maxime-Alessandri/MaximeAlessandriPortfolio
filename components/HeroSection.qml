import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."
import "../controls"

Item {
    id: heroSectionRoot

    implicitWidth: 1440
    implicitHeight: 920
    property bool active: true
    property real scrollY: 0

    signal navigateTo(string sectionId)
    signal openContact()
    signal openLogoShowcase()

    readonly property color accentColor: Theme.paletteAccent
    readonly property color bgDark: Theme.bgBase
    readonly property color textCream: Theme.textPrimary
    readonly property color accentBlue: Theme.paletteSecondary
    readonly property color accentBurgundy: Theme.paletteTertiary
    readonly property bool isWide: width >= 1200
    readonly property bool isMedium: width >= 860

    // =========================================================================
    // 01 // BACKGROUND ATMOSPHERE (Deep Canvas + OGL WebGL Plasma Shader)
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        color: heroSectionRoot.bgDark
        Behavior on color {
            ColorAnimation { duration: 450; easing.type: Easing.OutCubic }
        }
    }

    PlasmaBackground {
        id: plasmaBg
        anchors.fill: parent
        color: heroSectionRoot.accentColor
        speed: 0.16
        scale: 1.15
        effectOpacity: 0.50
        mouseInteractive: true
        running: heroSectionRoot.active
        z: 1

        Behavior on color {
            ColorAnimation { duration: 450; easing.type: Easing.OutCubic }
        }
    }

    // Atmospheric Bottom Dissolve: Multi-stop gradient smoothly melting plasma into Theme.bgVoid
    Rectangle {
        id: bottomAtmosphereFade
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 280
        z: 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.45; color: Theme.alpha(Theme.bgVoid, 0.45) }
            GradientStop { position: 0.80; color: Theme.alpha(Theme.bgVoid, 0.90) }
            GradientStop { position: 1.0; color: Theme.bgVoid }
        }
    }

    // =========================================================================
    // 02 // TOP NAVIGATION BAR (Apple Frosted Glass & Specular Light Reflection)
    // =========================================================================
    Rectangle {
        id: topNavBar
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 1400)
        height: 56
        radius: 28
        color: Theme.glassFill
        border.color: Theme.borderCard
        border.width: 1
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 12
            spacing: 12

            // Brand Emblem & Identity (Maxime.Dev)
            Row {
                id: brandRow
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                // Clickable Emblem with Apple Spring Scale (Opens Logo Showcase)
                MouseArea {
                    id: emblemMouse
                    width: 30
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: heroSectionRoot.openLogoShowcase()

                    scale: emblemMouse.pressed ? 0.90 : (emblemMouse.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    BrandEmblem {
                        anchors.fill: parent
                        badgeRadius: 15
                        conceptIndex: Theme.activeLogoConcept
                        badgeColor: heroSectionRoot.accentColor
                        emblemColor: Theme.textOnAccent
                        accentColor: Theme.isDark ? Qt.color("#FFFFFF") : Qt.color("#000000")
                    }
                }

                // Brand Title Text (Navigates to Overview)
                MouseArea {
                    id: brandMouse
                    height: 38
                    width: brandTitleText.implicitWidth
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: heroSectionRoot.navigateTo("overview")

                    scale: brandMouse.pressed ? 0.96 : (brandMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                    Text {
                        id: brandTitleText
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontDisplay
                        font.pixelSize: 19
                        font.weight: Font.Bold
                        font.letterSpacing: -0.3
                        color: heroSectionRoot.textCream
                        text: "MAXIME<font color='" + heroSectionRoot.accentColor + "'>.</font>DEV"
                        textFormat: Text.RichText
                    }
                }

                Rectangle {
                    visible: heroSectionRoot.isWide
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 16
                    color: Theme.divider
                }

                Text {
                    visible: heroSectionRoot.isWide
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                    color: Theme.textDim
                    text: "SCIENTIST // SOFTWARE ARCHITECT"
                }
            }

            Item { Layout.fillWidth: true }

            // Navigation Links with Apple Fluid Pointer Interaction
            Row {
                id: navLinksRow
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                visible: heroSectionRoot.isMedium

                Repeater {
                    model: [
                        { name: "Overview", id: "overview" },
                        { name: "Capabilities", id: "robotics" },
                        { name: "Architecture", id: "lims" },
                        { name: "Workbench", id: "demos" },
                        { name: "Publications", id: "publications" },
                        { name: "Curriculum", id: "cv" }
                    ]

                    Rectangle {
                        width: navLabel.implicitWidth + 16
                        height: 34
                        radius: 17
                        color: navMouse.containsMouse ? Theme.bgSurfaceHover : "transparent"
                        scale: navMouse.pressed ? 0.94 : (navMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        Text {
                            id: navLabel
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1.0
                            font.weight: Font.Medium
                            color: navMouse.containsMouse ? heroSectionRoot.textCream : Theme.textMuted
                            text: modelData.name
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: heroSectionRoot.navigateTo(modelData.id)
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Compact Dark / Light Mode Toggle
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: 18
                color: themeBtnMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                border.color: themeBtnMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard
                border.width: 1
                scale: themeBtnMouse.pressed ? 0.92 : (themeBtnMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcon
                    font.pixelSize: 17
                    color: Theme.textPrimary
                    text: Theme.isDark ? "light_mode" : "dark_mode"
                }

                MouseArea {
                    id: themeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.toggleDarkLight()
                }
            }

            // Contact Pill Action
            CustomButton {
                Layout.alignment: Qt.AlignVCenter
                text: "Contact ↗"
                variant: "primary"
                customHeight: 36
                customRadius: 18
                onClicked: heroSectionRoot.openContact()
            }
        }
    }

    // =========================================================================
    // 03 // LEFT ARCHITECTURAL SPINE (Side Navigation & Socials)
    // =========================================================================
    Item {
        id: leftSpine
        visible: heroSectionRoot.isWide
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.top: topNavBar.bottom
        anchors.bottom: bottomFooterBar.top
        width: 36
        z: 8

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.divider
        }

        // Rotated Monospace Vertical Label
        Text {
            anchors.centerIn: parent
            font.family: Theme.fontMono
            font.pixelSize: 9
            font.letterSpacing: 4.0
            font.capitalization: Font.AllUppercase
            color: Theme.textDim
            text: "WET-LAB SCIENCE // SOFTWARE ARCHITECT"
            transform: Rotation { angle: -90 }
        }

        // Bottom Social Icons Column
        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: ghMouse.containsMouse ? Theme.bgSurfaceHover : "transparent"
                scale: ghMouse.pressed ? 0.90 : (ghMouse.containsMouse ? 1.12 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: ghMouse.containsMouse ? heroSectionRoot.accentColor : Theme.textDim
                    text: "GH"
                }

                MouseArea {
                    id: ghMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://github.com/Maxime-Alessandri")
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: inMouse.containsMouse ? Theme.bgSurfaceHover : "transparent"
                scale: inMouse.pressed ? 0.90 : (inMouse.containsMouse ? 1.12 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: inMouse.containsMouse ? heroSectionRoot.accentColor : Theme.textDim
                    text: "IN"
                }

                MouseArea {
                    id: inMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://www.linkedin.com/in/maxime-alessandri-phd")
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: mailMouse.containsMouse ? Theme.bgSurfaceHover : "transparent"
                scale: mailMouse.pressed ? 0.90 : (mailMouse.containsMouse ? 1.12 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: mailMouse.containsMouse ? heroSectionRoot.accentColor : Theme.textDim
                    text: "@"
                }

                MouseArea {
                    id: mailMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("mailto:alessandrimaxime@gmail.com")
                }
            }
        }
    }

    // =========================================================================
    // 04 // MAIN HERO CONTENT (Grid: Editorial Left + Centerpiece Right)
    // =========================================================================
    Item {
        id: heroContainer
        anchors.top: topNavBar.bottom
        anchors.bottom: bottomFooterBar.top
        anchors.left: heroSectionRoot.isWide ? leftSpine.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: heroSectionRoot.isWide ? 40 : 24
        anchors.rightMargin: 24
        z: 5

        // Apple Fluid Parallax Depth & Ethereal Dissolve on Scroll
        transform: Translate {
            y: -Math.min(heroSectionRoot.scrollY * 0.28, 180)
        }
        opacity: Math.max(0.0, 1.0 - (heroSectionRoot.scrollY / (heroSectionRoot.height * 0.65)))

        // Centered Content Bounds
        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, 1340)
            height: Math.min(parent.height, 740)

            // LEFT COLUMN: Narrative & Value Proposition
            Column {
                id: editorialCol
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: heroSectionRoot.isWide ? parent.width * 0.53 : parent.width
                spacing: 22

                // Eyebrow Status Chip
                Rectangle {
                    height: 32
                    radius: 16
                    width: chipRow.implicitWidth + 24
                    color: Theme.glassFill
                    border.color: Theme.borderSubtle
                    border.width: 1

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 8
                            height: 8
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: pingCircle
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: heroSectionRoot.accentColor
                                opacity: 0.75

                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: heroSectionRoot.active
                                    NumberAnimation { from: 1.0; to: 2.2; duration: 1200; easing.type: Easing.OutQuad }
                                    NumberAnimation { from: 2.2; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                                }
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: heroSectionRoot.active
                                    NumberAnimation { from: 0.8; to: 0.0; duration: 1200 }
                                    NumberAnimation { from: 0.0; to: 0.8; duration: 600 }
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: heroSectionRoot.accentColor
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.4
                            font.capitalization: Font.AllUppercase
                            color: heroSectionRoot.accentColor
                            text: "PhD NEUROSCIENTIST • SCIENTIFIC SOFTWARE ARCHITECT • SWISS CITIZEN"
                        }
                    }
                }

                // Giant Architectural Headline
                Column {
                    spacing: 0
                    width: parent.width

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: Math.max(36, Math.min(editorialCol.width * 0.095, 68))
                        font.weight: Font.Black
                        font.letterSpacing: -1.5
                        lineHeight: 0.95
                        color: heroSectionRoot.textCream
                        text: "BRIDGING WET-LAB"
                    }

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: Math.max(36, Math.min(editorialCol.width * 0.095, 68))
                        font.weight: Font.Black
                        font.letterSpacing: -1.5
                        lineHeight: 0.95
                        color: heroSectionRoot.textCream
                        text: "BIOLOGY & LAB"
                    }

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: Math.max(36, Math.min(editorialCol.width * 0.095, 68))
                        font.weight: Font.Black
                        font.letterSpacing: -1.5
                        lineHeight: 0.95
                        color: Theme.textMuted
                        text: "AUTOMATION."
                    }
                }

                // Authoritative Narrative
                Text {
                    width: Math.min(parent.width - 20, 580)
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontBody
                    font.pixelSize: 16
                    lineHeight: 1.55
                    color: Theme.textSecondary
                    text: "Scientist and PhD Neuroscientist with 6+ years combining wet-lab experimental research with production software engineering. Built custom LIMS, well-level microplate tracking (A1–P24), and Tecan liquid-handling pipelines that replaced manual spreadsheets and reduced operational labor by ~70%."
                }

                // Primary & Secondary Action CTAs
                Row {
                    spacing: 16

                    CustomButton {
                        text: "Launch Live Workbench ➔"
                        iconName: "play_arrow"
                        variant: "primary"
                        customHeight: 46
                        customRadius: 23
                        onClicked: heroSectionRoot.navigateTo("demos")
                    }

                    CustomButton {
                        text: "System Architectures"
                        variant: "secondary"
                        customHeight: 46
                        customRadius: 23
                        onClicked: heroSectionRoot.navigateTo("lims")
                    }
                }

                // Impact Metrics Row
                Row {
                    spacing: 20
                    topPadding: 6

                    Column {
                        Text { font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold; color: heroSectionRoot.textCream; text: "~70%" }
                        Text { font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textDim; text: "Labor Overhead Cut" }
                    }

                    Rectangle { width: 1; height: 30; color: Theme.divider }

                    Column {
                        Text { font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold; color: heroSectionRoot.textCream; text: "A1–P24" }
                        Text { font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textDim; text: "Well-Level LIMS" }
                    }

                    Rectangle { width: 1; height: 30; color: Theme.divider }

                    Column {
                        Text { font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold; color: heroSectionRoot.textCream; text: "3" }
                        Text { font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textDim; text: "Peer-Reviewed Papers" }
                    }
                }
            }

            // RIGHT COLUMN: Visual Centerpiece (Portrait, Animated Rings & Tech Stack)
            Item {
                id: visualCol
                visible: heroSectionRoot.isWide
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width * 0.44, 520)
                height: 580

                // Background Faint Architectural Watermark
                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -10
                    anchors.rightMargin: -10
                    font.family: Theme.fontDisplay
                    font.pixelSize: 72
                    font.weight: Font.Black
                    font.letterSpacing: -2.0
                    color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.05)
                    text: "ARCHITECT"
                    z: 0

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        width: 48
                        height: 2
                        color: heroSectionRoot.accentColor
                        opacity: 0.8
                    }
                }

                // Rotating Concentric Geometric Circles
                Rectangle {
                    id: outerRing
                    anchors.centerIn: parent
                    width: 480
                    height: 480
                    radius: 240
                    color: "transparent"
                    border.color: Qt.rgba(heroSectionRoot.accentColor.r, heroSectionRoot.accentColor.g, heroSectionRoot.accentColor.b, 0.15)
                    border.width: 1
                    z: 1

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        running: heroSectionRoot.active
                        from: 0
                        to: 360
                        duration: 32000
                    }
                }

                Rectangle {
                    id: middleRing
                    anchors.centerIn: parent
                    width: 380
                    height: 380
                    radius: 190
                    color: "transparent"
                    border.color: Qt.rgba(heroSectionRoot.accentColor.r, heroSectionRoot.accentColor.g, heroSectionRoot.accentColor.b, 0.10)
                    border.width: 1
                    z: 1

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        running: heroSectionRoot.active
                        from: 360
                        to: 0
                        duration: 22000
                    }
                }

                Rectangle {
                    id: innerAccentRing
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 60
                    anchors.verticalCenterOffset: -40
                    width: 220
                    height: 220
                    radius: 110
                    color: "transparent"
                    border.color: heroSectionRoot.accentColor
                    border.width: 2
                    opacity: 0.25
                    z: 1
                }

                // Portrait Image Container with Stylized Rounded Clipping
                Rectangle {
                    id: portraitMask
                    anchors.centerIn: parent
                    width: 400
                    height: 480
                    radius: 28
                    color: heroSectionRoot.bgDark
                    clip: true
                    border.color: Theme.borderSubtle
                    border.width: 1
                    z: 2

                    Image {
                        id: portraitImage
                        anchors.fill: parent
                        source: "../assets/images/Maxime-Alessandri-BW.jpeg"
                        sourceSize.width: 500
                        sourceSize.height: 600
                        fillMode: Image.PreserveAspectCrop
                        opacity: Theme.isDark ? 0.85 : 0.94
                    }

                    // Theme-Aware Vignette Radial Gradient Overlay
                    Canvas {
                        id: portraitVignette
                        anchors.fill: parent

                        Connections {
                            target: Theme
                            function onPaletteChanged() { portraitVignette.requestPaint(); }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var bg = Theme.bgBase;
                            var r = Math.round(bg.r * 255);
                            var g = Math.round(bg.g * 255);
                            var b = Math.round(bg.b * 255);
                            var edgeAlpha = Theme.isDark ? 0.82 : 0.35;
                            var midAlpha = Theme.isDark ? 0.20 : 0.08;
                            var grad = ctx.createRadialGradient(width * 0.5, height * 0.5, 60, width * 0.5, height * 0.5, width * 0.72);
                            grad.addColorStop(0.0, "rgba(" + r + "," + g + "," + b + ",0.0)");
                            grad.addColorStop(0.7, "rgba(" + r + "," + g + "," + b + "," + midAlpha + ")");
                            grad.addColorStop(1.0, "rgba(" + r + "," + g + "," + b + "," + edgeAlpha + ")");
                            ctx.fillStyle = grad;
                            ctx.fillRect(0, 0, width, height);
                        }
                    }
                }

                // Floating Glass Card ("CORE STACK" — Clickable jump to Capabilities)
                Rectangle {
                    id: stackCard
                    anchors.bottom: portraitMask.bottom
                    anchors.bottomMargin: -16
                    anchors.left: portraitMask.left
                    anchors.leftMargin: -24
                    width: 268
                    height: 124
                    radius: 18
                    color: Theme.glassFill
                    border.color: stackMouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
                    border.width: 1
                    clip: true
                    z: 5

                    scale: stackMouse.pressed ? 0.97 : (stackMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    MouseArea {
                        id: stackMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: heroSectionRoot.navigateTo("robotics")
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Row {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 16
                                radius: 1.5
                                color: heroSectionRoot.accentColor
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.4
                                font.capitalization: Font.AllUppercase
                                color: heroSectionRoot.textCream
                                text: "CORE STACK ➔"
                            }
                        }

                        // Technology Tags Grid
                        Flow {
                            width: parent.width
                            spacing: 5

                            Repeater {
                                model: ["C++ / Qt 6", "Python / FastAPI", "PostgreSQL", "Tecan / SiLA 2", "GWL / RS-232", "WASM / CI/CD"]

                                Rectangle {
                                    height: 22
                                    width: tagText.implicitWidth + 12
                                    radius: 4
                                    color: Theme.glassFill
                                    border.color: Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: tagText
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textSecondary
                                        text: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 05 // BOTTOM FOOTER & TELEMETRY RAIL (With Apple Scroll Cue Affordance)
    // =========================================================================
    Rectangle {
        id: bottomFooterBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        color: "transparent"
        z: 10
        opacity: Math.max(0.0, 1.0 - (heroSectionRoot.scrollY / 220.0))

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 1400)
            height: 1
            color: Theme.divider
            opacity: 0.5
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: Math.max(32, (parent.width - 1400) / 2)
            anchors.rightMargin: Math.max(32, (parent.width - 1400) / 2)

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 36

                Column {
                    spacing: 2
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                        color: Theme.textDim
                        text: "LOCATION"
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: heroSectionRoot.textCream
                        text: "46.5532° N, 6.6328° E • Le Mont-sur-Lausanne, Switzerland"
                    }
                }

                Column {
                    spacing: 2
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                        color: Theme.textDim
                        text: "EXPERIENCE"
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: heroSectionRoot.textCream
                        text: "6+ YEARS (PhD + CTO)"
                    }
                }
            }

            // Centered Apple Fluid Scroll Cue Pill (Click to Glide to Dossier)
            Rectangle {
                id: scrollCuePill
                anchors.centerIn: parent
                height: 32
                implicitWidth: scrollCueRow.implicitWidth + 24
                radius: 16
                color: scrollCueMouse.containsMouse ? Theme.bgSurfaceHover : Theme.glassFill
                border.color: scrollCueMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard
                border.width: 1
                scale: scrollCueMouse.pressed ? 0.94 : (scrollCueMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Row {
                    id: scrollCueRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackMicro
                        font.capitalization: Font.AllUppercase
                        color: scrollCueMouse.containsMouse ? heroSectionRoot.textCream : Theme.textSecondary
                        text: "EXPLORE DOSSIER"
                    }

                    Text {
                        id: chevronText
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.paletteAccent
                        text: "↓"

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: heroSectionRoot.active
                            NumberAnimation { from: 0; to: 3; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 3; to: 0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                MouseArea {
                    id: scrollCueMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: heroSectionRoot.navigateTo("overview")
                }
            }

            // Interactive Flagship Palette Quick-Selector Swatches
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textDim
                    text: "THEME"
                    visible: heroSectionRoot.width > 980
                }

                Repeater {
                    model: [
                        { id: "applePro",       dot: "#2997FF" },
                        { id: "appleBiolab",    dot: "#00D2FF" },
                        { id: "swissPrecision", dot: "#FF5500" },
                        { id: "medicalPharma",  dot: "#2563EB" },
                        { id: "appleCleanroom", dot: "#F5F5F7" }
                    ]

                    Rectangle {
                        readonly property bool isCurrent: Theme.activePreset === modelData.id
                        anchors.verticalCenter: parent.verticalCenter
                        width: isCurrent ? 14 : 10
                        height: isCurrent ? 14 : 10
                        radius: width / 2
                        color: modelData.dot
                        border.color: isCurrent ? Theme.textPrimary : Theme.borderCardHover
                        border.width: isCurrent ? 2 : 1
                        scale: swatchMouse.pressed ? 0.85 : (swatchMouse.containsMouse ? 1.25 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on width { NumberAnimation { duration: 140 } }
                        Behavior on height { NumberAnimation { duration: 140 } }

                        MouseArea {
                            id: swatchMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setPalette(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
