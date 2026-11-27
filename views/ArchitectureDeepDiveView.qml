import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."

ColumnLayout {
    id: archRoot

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
                Layout.preferredWidth: archTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: archTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "03 // ARCHITECTURE"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "SHIPPED PRODUCTION SYSTEMS"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: "Flagship Architectural Case Studies"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            text: "Production laboratory software, database systems, and robotic automation architectures designed, deployed, and supported alongside bench biologists."
        }
    }

    // Case Study 1: Custom LIMS, WebAssembly Client Portal & Well-Level Tracking (A1-P24)
    Rectangle {
        id: cs1Card
        Layout.fillWidth: true
        implicitHeight: cs1Col.implicitHeight + (Theme.spaceLg * 2)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: cs1Mouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea {
            id: cs1Mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        ColumnLayout {
            id: cs1Col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: Theme.terracottaGlow }
                        Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow; text: "CASE STUDY 01 // CUSTOM LIMS & SAMPLE TRACKING (INVENESIS SÀRL)" }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Custom LIMS, WebAssembly Client Portal & Well-Level Tracking (A1–P24)"
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 124; Layout.preferredHeight: 26; radius: Theme.radiusPill
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.statusGreen; text: "PRODUCTION ACTIVE" }
                }
            }

            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.55
                text: "Partnered directly with laboratory technicians and screening biologists to replace manual spreadsheet handoffs with a centralized production LIMS built from scratch: a web-based client submission portal in Qt/C++ compiled to WebAssembly, a Python FastAPI validation engine, and a PostgreSQL central database modeling microplates down to individual well coordinates (A1–P24), compound volumes, and barcodes. Built automated parsers ingesting raw optical reader files and instrument logs directly into searchable database tables, supported by interactive staff training and user guides."
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ["Qt 6 / WebAssembly", "Python FastAPI", "PostgreSQL (A1–P24)", "Raw Reader Parsing", "Audit Logging", "Staff Training"]
                        Rectangle {
                            width: tagText1.implicitWidth + 16; height: 24; radius: Theme.radiusPill
                            color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                            Text { id: tagText1; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; text: modelData }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: cs1BtnTxt.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: Theme.radiusPill
                    color: cs1BtnMouse.containsMouse ? Theme.cinnabar : Theme.bgSurface
                    border.color: cs1BtnMouse.containsMouse ? Theme.terracottaGlow : Theme.borderCard
                    border.width: 1
                    scale: cs1BtnMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        id: cs1BtnTxt
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                        color: cs1BtnMouse.containsMouse ? Theme.textOnCinnabar : Theme.textPrimary
                        text: "Try Client Portal ➔ Lab Flow ➔"
                    }
                    MouseArea {
                        id: cs1BtnMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: archRoot.navigateToDemo(0)
                    }
                }
            }
        }
    }

    // Case Study 2: Direct Database-to-Robot Liquid Handling & C++ Hardware Daemons
    Rectangle {
        id: cs2Card
        Layout.fillWidth: true
        implicitHeight: cs2Col.implicitHeight + (Theme.spaceLg * 2)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: cs2Mouse.containsMouse ? Theme.statusGreen : Theme.glassBorder
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea {
            id: cs2Mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        ColumnLayout {
            id: cs2Col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: Theme.statusGreen }
                        Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.statusGreen; text: "CASE STUDY 02 // LIQUID HANDLING & HARDWARE DAEMONS (INVENESIS SÀRL)" }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Direct Database-to-Robot Liquid Handling & C++ Hardware Daemons"
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 132; Layout.preferredHeight: 26; radius: Theme.radiusPill
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.terracottaGlow; text: "~70% LABOR CUT" }
                }
            }

            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.55
                text: "Connected the PostgreSQL laboratory database directly to Tecan Fluent (FluentControl) and Freedom EVO liquid handlers via SiLA 2 (gRPC) and dynamic GWL worklists. Automated compound cherry-picking and serial dilutions — turning assay preparation previously split between a senior technician and scientist into a streamlined pipeline run by a junior technician at half-time (~70% labor reduction) while eliminating manual pipetting mistakes. Replaced outdated vendor software libraries with lightweight C++ background daemons (RS-232/TCP, token-based concurrency control) for microplate sealers and carousels."
            }

            // 5-Stage Production Pipeline Block Diagram
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 66; radius: Theme.radiusSm
                color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 6

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; color: Theme.bgCard
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: "POSTGRESQL LIMS" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "A1–P24 Coordinates" }
                        }
                    }

                    Text { font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.textDim; text: "➔" }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; color: Theme.bgCard
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.terracottaGlow; text: "GWL COMPILER" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "Cherry-Pick & Dilutions" }
                        }
                    }

                    Text { font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.textDim; text: "➔" }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; color: Theme.bgCard
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.statusGreen; text: "SILA 2 (gRPC)" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "Fluent & EVO Dispatch" }
                        }
                    }

                    Text { font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.textDim; text: "➔" }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; color: Theme.bgCard
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.goldAccent; text: "C++ DAEMONS" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "RS-232/TCP Sealer & Carousel" }
                        }
                    }

                    Text { font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.textDim; text: "➔" }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; color: Theme.bgCard
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.paletteAccent; text: "READER INGEST" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "Standardized DB Tables" }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: cs2BtnTxt.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: Theme.radiusPill
                    color: cs2BtnMouse.containsMouse ? Theme.cinnabar : Theme.bgSurface
                    border.color: cs2BtnMouse.containsMouse ? Theme.terracottaGlow : Theme.borderCard
                    border.width: 1
                    scale: cs2BtnMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        id: cs2BtnTxt
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                        color: cs2BtnMouse.containsMouse ? Theme.textOnCinnabar : Theme.textPrimary
                        text: "Launch 3D Digital Twin ➔"
                    }
                    MouseArea {
                        id: cs2BtnMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: archRoot.navigateToDemo(1)
                    }
                }
            }
        }
    }

    // Case Study 3: Automated Electrophysiology Pipelines & Departmental Software Adoption (UNIL)
    Rectangle {
        id: cs3Card
        Layout.fillWidth: true
        implicitHeight: cs3Col.implicitHeight + (Theme.spaceLg * 2)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: cs3Mouse.containsMouse ? Theme.cinnabar : Theme.glassBorder
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea {
            id: cs3Mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        ColumnLayout {
            id: cs3Col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: Theme.cinnabar }
                        Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow; text: "CASE STUDY 03 // SIGNAL PROCESSING & LAB ADOPTION (UNIL)" }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontDisplay; font.pixelSize: Theme.sizeH2; font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary; text: "Automated Electrophysiology Pipelines & Departmental Software Adoption"
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 132; Layout.preferredHeight: 26; radius: Theme.radiusPill
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.statusGreen; text: "100% LAB ADOPTION" }
                }
            }

            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.55
                text: "Built automated data analysis pipelines in Python and MATLAB to process multi-terabyte electrophysiological datasets — handling signal filtering, time-frequency Morlet wavelet analysis, and statistical evaluation. Packaged these workflows into user-friendly recording and analysis software that standardized data collection procedures and achieved complete adoption across departmental researchers, alongside co-designing an AstraZeneca-partnered drug testing study using Microelectrode Arrays (MEA) on acute brain slices."
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ["Python & MATLAB", "Multi-TB EEG / MEA", "Wavelet Analysis", "Complete Lab Adoption", "AstraZeneca Study"]
                        Rectangle {
                            width: tagText3.implicitWidth + 16; height: 24; radius: Theme.radiusPill
                            color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                            Text { id: tagText3; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; text: modelData }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: cs3BtnTxt.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: Theme.radiusPill
                    color: cs3BtnMouse.containsMouse ? Theme.cinnabar : Theme.bgSurface
                    border.color: cs3BtnMouse.containsMouse ? Theme.terracottaGlow : Theme.borderCard
                    border.width: 1
                    scale: cs3BtnMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        id: cs3BtnTxt
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                        color: cs3BtnMouse.containsMouse ? Theme.textOnCinnabar : Theme.textPrimary
                        text: "Explore Publications ➔"
                    }
                    MouseArea {
                        id: cs3BtnMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: archRoot.navigateToSection("publications")
                    }
                }
            }
        }
    }
}
