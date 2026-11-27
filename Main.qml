import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import InvenesisPortfolio
import "components"
import "components/demos"
import "views"

ApplicationWindow {
    id: appWindow

    width: 1440
    height: 900
    minimumWidth: 480
    minimumHeight: 600
    visible: true
    title: "Dr. Maxime Alessandri, PhD — Scientist & Scientific Software Architect"
    color: Theme.bgVoid

    readonly property bool modalOrInputActive: contactModal.isOpen || logoShowcaseModal.isOpen ||
        (appWindow.activeFocusItem !== null &&
         (appWindow.activeFocusItem.toString().indexOf("TextEdit") !== -1 ||
          appWindow.activeFocusItem.toString().indexOf("TextInput") !== -1))

    readonly property string activeSectionId: {
        var y = flickable.contentY + 140;
        if (y >= targetY(sectionTimeline)) return "cv";
        if (y >= targetY(sectionPublications)) return "publications";
        if (y >= targetY(sectionDemos)) return "demos";
        if (y >= targetY(sectionArch)) return "lims";
        if (y >= targetY(sectionCompetencies)) return "robotics";
        return "overview";
    }

    readonly property bool demosActive: {
        var top = targetY(sectionDemos);
        return flickable.contentY + flickable.height > top - 160 &&
               flickable.contentY < top + sectionDemos.height + 160;
    }

    // Section Scroll Targets with Exact MapToItem Offset
    function targetY(item) {
        if (!item) return 0;
        var pt = item.mapToItem(contentCol, 0, 0);
        return Math.max(0, pt.y - 68);
    }

    function scrollToSection(sectionId) {
        if (sectionId === "overview") flickable.contentY = targetY(sectionOverview);
        else if (sectionId === "robotics") flickable.contentY = targetY(sectionCompetencies);
        else if (sectionId === "lims") flickable.contentY = targetY(sectionArch);
        else if (sectionId === "demos") flickable.contentY = targetY(sectionDemos);
        else if (sectionId === "publications") flickable.contentY = targetY(sectionPublications);
        else if (sectionId === "cv") flickable.contentY = targetY(sectionTimeline);
        else flickable.contentY = 0;
    }

    function navigateToDemo(tabIndex) {
        sectionDemos.activeTab = tabIndex;
        scrollToSection("demos");
    }

    // Scroll Viewport with Apple Fluid Rubber-Banding Physics
    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.DragAndOvershootBounds
        flickDeceleration: 1500
        maximumFlickVelocity: 4000
        clip: true

        Behavior on contentY {
            enabled: !flickable.moving && !flickable.dragging
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 0

            // 00 // HERO SECTION (Interactive Cinematic Showcase)
            HeroSection {
                id: heroSection
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(860, appWindow.height)
                active: flickable.contentY < height
                scrollY: flickable.contentY

                onNavigateTo: function(id) { appWindow.scrollToSection(id); }
                onOpenContact: contactModal.open()
                onOpenLogoShowcase: logoShowcaseModal.open()
            }

            // MAIN EDITORIAL CONTENT CONTAINER (Max Width 1280px Centered)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: innerCol.implicitHeight + (Theme.space3Xl * 2) + 32

                ColumnLayout {
                    id: innerCol
                    anchors.top: parent.top
                    anchors.topMargin: Theme.space3Xl + 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 48, 1280)
                    spacing: Theme.space3Xl

                    // 01 // EXECUTIVE SUMMARY & METRICS
                    ExecutiveSummaryView {
                        id: sectionOverview
                        Layout.fillWidth: true
                        onOpenContact: contactModal.open()
                        onNavigateToSection: function(id) { appWindow.scrollToSection(id); }
                        onNavigateToDemo: function(tabIdx) { appWindow.navigateToDemo(tabIdx); }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // 02 // 4-PILLAR COMPETENCY MATRIX
                    CompetenciesView {
                        id: sectionCompetencies
                        Layout.fillWidth: true
                        onNavigateToSection: function(id) { appWindow.scrollToSection(id); }
                        onNavigateToDemo: function(tabIdx) { appWindow.navigateToDemo(tabIdx); }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // 03 // ARCHITECTURAL CASE STUDIES
                    ArchitectureDeepDiveView {
                        id: sectionArch
                        Layout.fillWidth: true
                        onNavigateToSection: function(id) { appWindow.scrollToSection(id); }
                        onNavigateToDemo: function(tabIdx) { appWindow.navigateToDemo(tabIdx); }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // 04 // INTERACTIVE ENGINEERING WORKBENCH (4 PRODUCTION DEMOS)
                    DemosShowcase {
                        id: sectionDemos
                        Layout.fillWidth: true
                        active: appWindow.demosActive
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // 05 // SCIENTIFIC PUBLICATIONS
                    PublicationsView {
                        id: sectionPublications
                        Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // 06 // CURRICULUM & CAREER TIMELINE
                    CareerTimelineView {
                        id: sectionTimeline
                        Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // FOOTER
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        radius: Theme.radiusMd
                        color: Theme.bgCard
                        border.color: Theme.borderCard
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spaceLg
                            spacing: Theme.spaceMd

                            Column {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: Theme.textPrimary
                                    text: "DR. MAXIME ALESSANDRI, PhD"
                                }
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.sizeMicro
                                    color: Theme.textMuted
                                    text: "Scientist & Scientific Software Architect • Built with C++ / Qt 6 QML & WebAssembly • Press P / O for 20 Palettes"
                                }
                            }

                            Row {
                                spacing: 10
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    width: 118; height: 34; radius: Theme.radiusPill
                                    color: footerCvMouse.pressed ? Theme.bgSurfaceHover : Theme.bgSurface
                                    border.color: footerCvMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard; border.width: 1
                                    scale: footerCvMouse.pressed ? 0.95 : (footerCvMouse.containsMouse ? 1.03 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                        color: Theme.textPrimary
                                        text: "Download CV"
                                    }
                                    MouseArea {
                                        id: footerCvMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally(AppConfig.cvUrl())
                                    }
                                }

                                Rectangle {
                                    width: 140; height: 34; radius: Theme.radiusPill
                                    color: touchMouse.pressed ? Theme.cinnabarHover : Theme.cinnabar
                                    border.color: Theme.terracottaGlow; border.width: 1
                                    scale: touchMouse.pressed ? 0.95 : (touchMouse.containsMouse ? 1.03 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                        color: Theme.textOnCinnabar
                                        text: "Get in Touch ↗"
                                    }
                                    MouseArea {
                                        id: touchMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: contactModal.open()
                                    }
                                }

                                Rectangle {
                                    width: 120; height: 34; radius: Theme.radiusPill
                                    color: topMouse.pressed ? Theme.bgSurfaceHover : Theme.bgSurface
                                    border.color: Theme.borderCard; border.width: 1
                                    scale: topMouse.pressed ? 0.95 : (topMouse.containsMouse ? 1.03 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                        color: Theme.textPrimary
                                        text: "Back to Top ↑"
                                    }
                                    MouseArea {
                                        id: topMouse
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: flickable.contentY = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Floating Dynamic Island / Sticky Top Bar (Apple Materialization: scale + opacity + specular rim)
    Rectangle {
        id: floatingBar
        anchors.top: parent.top; anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 48, 1140)
        height: 48
        radius: Theme.radiusPill
        color: Theme.glassFill
        border.color: Theme.glassBorder
        border.width: 1
        clip: true
        visible: opacity > 0.01

        property real progress: Math.min(1.0, Math.max(0.0, (flickable.contentY - 450) / 200.0))
        opacity: progress
        scale: 0.94 + (0.06 * progress)
        z: 100

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 12
            spacing: Theme.spaceSm

            // Brand Emblem & Identity (Click to open Logo Showcase)
            MouseArea {
                Layout.preferredHeight: 32
                Layout.preferredWidth: floatBrandRow.implicitWidth
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: logoShowcaseModal.open()

                Row {
                    id: floatBrandRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    BrandEmblem {
                        width: 24
                        height: 24
                        badgeRadius: 12
                        conceptIndex: Theme.activeLogoConcept
                        badgeColor: Theme.paletteAccent
                        emblemColor: Theme.textOnAccent
                        accentColor: Theme.isDark ? Qt.color("#FFFFFF") : Qt.color("#000000")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontDisplay
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary
                        text: "MAXIME ALESSANDRI, PhD"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4
                visible: floatingBar.width > 740

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
                        readonly property bool isActiveSection: appWindow.activeSectionId === modelData.id
                        width: navLabelF.implicitWidth + 18
                        height: 32
                        radius: Theme.radiusPill
                        color: isActiveSection ? Theme.alpha(Theme.paletteAccent, 0.16) : (navMouseF.containsMouse ? Theme.bgSurfaceHover : "transparent")
                        border.color: isActiveSection ? Theme.paletteAccent : "transparent"
                        border.width: isActiveSection ? 1 : 0
                        scale: navMouseF.pressed ? 0.94 : (navMouseF.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        Text {
                            id: navLabelF
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.sizeMicro
                            font.letterSpacing: Theme.trackMicro
                            font.capitalization: Font.AllUppercase
                            font.weight: isActiveSection ? Font.Bold : Font.DemiBold
                            color: isActiveSection ? Theme.paletteAccent : Theme.textPrimary
                            text: modelData.name
                        }

                        MouseArea {
                            id: navMouseF
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appWindow.scrollToSection(modelData.id)
                        }
                    }
                }
            }

            // Dark / Light Theme Toggle Pill
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: themeToggleFMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                border.color: themeToggleFMouse.containsMouse ? Theme.paletteAccent : Theme.borderCard
                border.width: 1
                scale: themeToggleFMouse.pressed ? 0.92 : (themeToggleFMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcon
                    font.pixelSize: 16
                    color: Theme.textPrimary
                    text: Theme.isDark ? "light_mode" : "dark_mode"
                }

                MouseArea {
                    id: themeToggleFMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.toggleDarkLight()
                }
            }

            Rectangle {
                Layout.preferredWidth: 108
                Layout.preferredHeight: 32
                radius: Theme.radiusPill
                color: contactFMouse.pressed ? Theme.cinnabarHover : Theme.cinnabar
                scale: contactFMouse.pressed ? 0.95 : (contactFMouse.containsMouse ? 1.03 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                    color: Theme.textOnCinnabar
                    text: "Contact ↗"
                }
                MouseArea {
                    id: contactFMouse
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: contactModal.open()
                }
            }
        }
    }

    // Direct Executive Contact Modal
    ContactModal {
        id: contactModal
    }

    // Signature Brand Emblem Showcase Modal
    LogoShowcaseModal {
        id: logoShowcaseModal
    }

    // Automatically show toast whenever palette preset or logo changes
    Connections {
        target: Theme
        function onActivePresetChanged() {
            paletteToast.showToastMessage(paletteToast.getPaletteLabel());
        }
        function onActiveLogoConceptChanged() {
            var concept = Theme.logoConcepts[Theme.activeLogoConcept];
            paletteToast.showToastMessage("LOGO: " + concept.name.toUpperCase() + " • L to cycle");
        }
    }

    // Keyboard Hotkey 'P': Next Palette | 'O': Previous Palette (disabled in modals/text inputs)
    Shortcut {
        sequence: "P"
        enabled: !appWindow.modalOrInputActive
        onActivated: Theme.nextPreset()
    }

    Shortcut {
        sequence: "O"
        enabled: !appWindow.modalOrInputActive
        onActivated: Theme.prevPreset()
    }

    Shortcut {
        sequence: "Shift+P"
        enabled: !appWindow.modalOrInputActive
        onActivated: Theme.prevPreset()
    }

    // Keyboard Hotkey 'L': Next Logo Concept
    Shortcut {
        sequence: "L"
        enabled: !appWindow.modalOrInputActive
        onActivated: Theme.nextLogo()
    }

    // Escape closes active modal
    Shortcut {
        sequence: "Escape"
        enabled: contactModal.isOpen || logoShowcaseModal.isOpen
        onActivated: {
            if (contactModal.isOpen) contactModal.close();
            if (logoShowcaseModal.isOpen) logoShowcaseModal.close();
        }
    }

    // Live Palette / Logo Switcher Toast Indicator
    Rectangle {
        id: paletteToast
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 24
        z: 9999
        width: toastRow.implicitWidth + 28
        height: 40
        radius: Theme.radiusPill
        color: Theme.glassFill
        border.color: Theme.paletteAccent
        border.width: 1.5
        opacity: 0.0

        property string currentMessage: ""

        function getPaletteLabel() {
            var keys = Object.keys(Theme.presets);
            var idx = keys.indexOf(Theme.activePreset) + 1;
            var mode = Theme.isDark ? "DARK" : "LIGHT";
            return "[" + idx + "/" + keys.length + "] " + Theme.activePreset.toUpperCase() + " (" + mode + ") • P / O to cycle";
        }

        function showToastMessage(msg) {
            currentMessage = msg;
            toastAnim.restart();
        }

        SequentialAnimation {
            id: toastAnim
            NumberAnimation { target: paletteToast; property: "opacity"; to: 1.0; duration: 150 }
            PauseAnimation { duration: 2800 }
            NumberAnimation { target: paletteToast; property: "opacity"; to: 0.0; duration: 400 }
        }

        Row {
            id: toastRow
            anchors.centerIn: parent
            spacing: 10
            Rectangle {
                width: 10; height: 10; radius: 5
                color: Theme.paletteAccent
                border.color: Theme.textPrimary
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.textPrimary
                text: paletteToast.currentMessage !== "" ? paletteToast.currentMessage : paletteToast.getPaletteLabel()
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
