import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."
import "../controls"

ColumnLayout {
    id: summaryRoot

    Layout.fillWidth: true
    spacing: Theme.spaceXl

    signal openContact()
    signal navigateToSection(string sectionId)
    signal navigateToDemo(int tabIndex)

    // =========================================================================
    // 01 // CHAPTER PRELUDE & SECTION HEADER
    // =========================================================================
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: chaptTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: chaptTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "01 // DOSSIER"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "SCIENTIST & SCIENTIFIC SOFTWARE ARCHITECT"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1 + 2
            font.weight: Font.Bold
            font.letterSpacing: Theme.trackDisplay
            color: Theme.textPrimary
            text: "Dual Fluency: Wet-Lab Experimental Science & Production Software"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            lineHeight: 1.55
            color: Theme.textSecondary
            text: "6+ years combining doctoral neuroscience and microplate assay expertise with custom LIMS architecture, automated liquid handling, and hands-on laboratory staff mentorship."
        }
    }

    // =========================================================================
    // 02 // DOSSIER DETAILS CARD (Single-Column Swiss Credentials & Outcomes)
    // =========================================================================
    Rectangle {
        id: dossierCard
        Layout.fillWidth: true
        Layout.preferredHeight: dossierInnerCol.implicitHeight + (Theme.spaceLg * 2)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: Theme.glassBorder
        border.width: 1

        ColumnLayout {
            id: dossierInnerCol
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceLg

            // Swiss Credentials Header Row
            Flow {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Rectangle {
                    height: 28
                    width: credRow.implicitWidth + 20
                    radius: 14
                    color: Theme.glassFill
                    border.color: Theme.paletteAccent
                    border.width: 1

                    Row {
                        id: credRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontIcon
                            font.pixelSize: 13
                            color: Theme.paletteAccent
                            text: "verified"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Theme.textPrimary
                            text: "SWISS CITIZEN • WET-LAB & SOFTWARE"
                        }
                    }
                }

                Text {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                    color: Theme.textMuted
                    text: "MAXIME ALESSANDRI, PhD  •  LE MONT-SUR-LAUSANNE, CH  •  PhD NEUROSCIENCE (UNIL)"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.divider
            }

            // Narrative Heading
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: Theme.trackWide
                    font.capitalization: Font.AllUppercase
                    font.weight: Font.Bold
                    color: Theme.terracottaGlow
                    text: "CORE PHILOSOPHY & OPERATIONAL IMPACT"
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.sizeH2
                    font.weight: Font.Bold
                    lineHeight: 1.2
                    color: Theme.textPrimary
                    text: "From Manual Spreadsheets to Centralized, Automated Lab Workflows"
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.family: Theme.fontBody
                font.pixelSize: Theme.sizeBody
                lineHeight: 1.6
                color: Theme.textSecondary
                text: "As Chief Technology Officer at a drug discovery screening CRO, I worked directly alongside bench biologists and technicians to modernize daily experimental operations. I designed and deployed an end-to-end custom LIMS (Qt/WebAssembly client portal, FastAPI validation engine, PostgreSQL tracking microplates down to A1–P24), connected it to Tecan Fluent and Freedom EVO liquid handlers via SiLA 2 and dynamic worklists (~70% labor overhead reduction), automated raw optical reader ingestion into searchable database tables, and trained laboratory staff to ensure smooth adoption across ongoing studies."
            }

            // Four Clickable Core Outcome Proof Tiles (100% CV-verified metrics)
            GridLayout {
                Layout.fillWidth: true
                columns: summaryRoot.width > 600 ? 4 : 2
                rowSpacing: Theme.spaceMd
                columnSpacing: Theme.spaceMd

                Repeater {
                    model: [
                        { val: "~70%",   label: "LABOR OVERHEAD CUT",   targetType: "section", targetVal: "lims" },
                        { val: "100%",   label: "LAB TOOL ADOPTION",    targetType: "section", targetVal: "cv" },
                        { val: "A1–P24", label: "WELL-LEVEL TRACKING",  targetType: "demo",    targetVal: 0 },
                        { val: "3",      label: "PEER-REVIEWED PAPERS", targetType: "section", targetVal: "publications" }
                    ]

                    Rectangle {
                        id: tileRect
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        radius: Theme.radiusSm
                        color: tileMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                        border.color: tileMouse.containsMouse ? Theme.terracottaGlow : Theme.borderCard
                        border.width: 1
                        clip: true

                        scale: tileMouse.pressed ? 0.96 : (tileMouse.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontDisplay
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                font.letterSpacing: Theme.trackHeading
                                color: Theme.terracottaGlow
                                text: tileRect.modelData.val
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.letterSpacing: Theme.trackMicro
                                color: Theme.textMuted
                                text: tileRect.modelData.label
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (tileRect.modelData.targetType === "demo") {
                                    summaryRoot.navigateToDemo(tileRect.modelData.targetVal);
                                } else {
                                    summaryRoot.navigateToSection(tileRect.modelData.targetVal);
                                }
                            }
                        }
                    }
                }
            }

            // CTAs
            Row {
                spacing: Theme.spaceMd

                CustomButton {
                    text: "Contact & References ↗"
                    variant: "primary"
                    onClicked: summaryRoot.openContact()
                }

                CustomButton {
                    text: "Download Full CV (.docx)"
                    iconName: "download"
                    variant: "secondary"
                    onClicked: Qt.openUrlExternally(AppConfig.cvUrl())
                }
            }
        }
    }
}
