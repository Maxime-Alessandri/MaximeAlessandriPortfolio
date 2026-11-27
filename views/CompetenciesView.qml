import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."

ColumnLayout {
    id: compRoot

    Layout.fillWidth: true
    spacing: Theme.spaceLg

    signal navigateToDemo(int tabIndex)
    signal navigateToSection(string sectionId)

    // Header
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: capTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: capTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "02 // CAPABILITIES"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "CORE EXPERTISE & TECHNICAL TOOLKIT"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: "Core Competencies & Technical Architecture"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            text: "Multidisciplinary domain expertise bridging custom laboratory informatics, robotic liquid handling, full-stack scientific software, and wet-lab assay science."
        }
    }

    // 4 Competency Pillars Grid (Aligned 1:1 with sent CV toolkit)
    GridLayout {
        id: compGrid
        Layout.fillWidth: true
        columns: compRoot.width > 768 ? 2 : 1
        rowSpacing: Theme.spaceLg
        columnSpacing: Theme.spaceLg

        readonly property real unifiedCardHeight: Math.max(
            300,
            p1Col.implicitHeight,
            p2Col.implicitHeight,
            p3Col.implicitHeight,
            p4Col.implicitHeight
        ) + (Theme.spaceLg * 2)

        // Pillar 1: Laboratory Informatics & Data Systems
        Rectangle {
            id: p1Card
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: compGrid.unifiedCardHeight
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: p1Mouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
            border.width: 1
            clip: true

            scale: p1Mouse.pressed ? 0.99 : (p1Mouse.containsMouse ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: p1Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: compRoot.navigateToDemo(0)
            }

            ColumnLayout {
                id: p1Col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceSm

                RowLayout {
                    Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.terracottaGlow }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Laboratory Informatics & Data Systems"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow
                    text: "CUSTOM LIMS • A1–P24 TRACKING • POSTGRESQL • RAW READER PARSING • AUDIT LOGS"
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Custom LIMS design, production deployment & daily operational support.\n• Sample identity, compound volumes & microplate tracking down to well coordinates (A1–P24).\n• Relational PostgreSQL schema architecture, data standardization & audit logging.\n• Automated extraction & parsing of raw optical reader files and instrument logs directly into PostgreSQL."
                }

                Item { Layout.fillHeight: true }

                Text {
                    font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                    color: p1Mouse.containsMouse ? Theme.terracottaGlow : Theme.textMuted
                    text: "Try End-to-End Portal ➔ Lab Demo ➔"
                }
            }
        }

        // Pillar 2: Liquid Handling & Hardware Automation
        Rectangle {
            id: p2Card
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: compGrid.unifiedCardHeight
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: p2Mouse.containsMouse ? Theme.statusGreen : Theme.glassBorder
            border.width: 1
            clip: true

            scale: p2Mouse.pressed ? 0.99 : (p2Mouse.containsMouse ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: p2Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: compRoot.navigateToDemo(1)
            }

            ColumnLayout {
                id: p2Col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceSm

                RowLayout {
                    Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.statusGreen }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Liquid Handling & Hardware Automation"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.statusGreen
                    text: "TECAN FLUENT / EVO • SILA 2 (gRPC) • GWL • RS-232 / TCP • C++ DAEMONS"
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Direct database-to-robot integration on Tecan Fluent (FluentControl) & Freedom EVO.\n• SiLA 2 (gRPC) & dynamic GWL worklists automating compound cherry-picking & serial dilutions.\n• Lightweight C++ background daemons & RS-232/TCP drivers replacing outdated vendor libraries.\n• Multi-instrument scheduling, token-based concurrency control & automated error handling (sealers, carousels)."
                }

                Item { Layout.fillHeight: true }

                Text {
                    font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                    color: p2Mouse.containsMouse ? Theme.statusGreen : Theme.textMuted
                    text: "Inspect 3D Digital Twin ➔"
                }
            }
        }

        // Pillar 3: Software Engineering & Technical Leadership
        Rectangle {
            id: p3Card
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: compGrid.unifiedCardHeight
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: p3Mouse.containsMouse ? Theme.goldAccent : Theme.glassBorder
            border.width: 1
            clip: true

            scale: p3Mouse.pressed ? 0.99 : (p3Mouse.containsMouse ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: p3Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: compRoot.navigateToSection("lims")
            }

            ColumnLayout {
                id: p3Col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceSm

                RowLayout {
                    Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.goldAccent }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Software Engineering & Staff Enablement"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.goldAccent
                    text: "PYTHON / FASTAPI • C++ / QT 6 / WASM • CI/CD • AI-ASSISTED DEV • TRAINING"
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Python (FastAPI, PySide6, NumPy, SciPy) & C++ (Qt 6, WebAssembly) full-stack development.\n• REST APIs, Linux server administration, automated Git & CI/CD deployment pipelines.\n• Machine learning integration & modern AI-assisted software development workflows.\n• Interactive laboratory staff training, practical user guides & cross-functional alignment with biologists."
                }

                Item { Layout.fillHeight: true }

                Text {
                    font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                    color: p3Mouse.containsMouse ? Theme.goldAccent : Theme.textMuted
                    text: "View Production Case Studies ➔"
                }
            }
        }

        // Pillar 4: Assay Workflows & Experimental Science
        Rectangle {
            id: p4Card
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: compGrid.unifiedCardHeight
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: p4Mouse.containsMouse ? Theme.cinnabar : Theme.glassBorder
            border.width: 1
            clip: true

            scale: p4Mouse.pressed ? 0.99 : (p4Mouse.containsMouse ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: p4Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: compRoot.navigateToSection("publications")
            }

            ColumnLayout {
                id: p4Col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceSm

                RowLayout {
                    Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.cinnabar }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Assay Workflows & Experimental Science"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow
                    text: "PhD NEUROSCIENCE • HTS • SERIAL DILUTIONS • ELECTROPHYSIOLOGY • BIO-IMAGING"
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• HTS protocols, compound logistics, serial dilution math, dead-volume rules & concentration curves.\n• Electrophysiology (patch-clamp, Microelectrode Arrays, high-density EEG) & research microscopy.\n• Preclinical optical assays, in vitro disease models & AstraZeneca-partnered drug screening study.\n• 3 peer-reviewed publications & supervision of 3 Master's thesis students (all top academic marks)."
                }

                Item { Layout.fillHeight: true }

                Text {
                    font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                    color: p4Mouse.containsMouse ? Theme.terracottaGlow : Theme.textMuted
                    text: "Read Peer-Reviewed Publications ➔"
                }
            }
        }
    }
}
