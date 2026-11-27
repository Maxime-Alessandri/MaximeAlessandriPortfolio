import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."

ColumnLayout {
    id: timelineRoot

    Layout.fillWidth: true
    spacing: Theme.spaceLg

    // Header
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: cvTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: cvTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "06 // CURRICULUM"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "EXPERIENCE, EDUCATION & CREDENTIALS"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: "Curriculum & Professional Trajectory"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            text: "Progression from doctoral neuroscience & cellular biophysics research to technical leadership in custom LIMS, laboratory databases, and automated liquid handling."
        }
    }

    // Timeline Nodes (Matched 1:1 to sent CV)
    Repeater {
        model: [
            {
                period: "FEB 2025 – PRESENT",
                role: "Chief Technology Officer & Lead Software Architect",
                company: "Invenesis Sàrl • St-Blaise, Switzerland",
                highlights: "• Laboratory Workflow Modernization: Partnered directly with laboratory technicians and screening biologists at a drug discovery CRO to map experimental protocols and build software tailored to daily bench routines.\n• Custom LIMS & Sample Tracking: Designed and deployed a production LIMS from scratch — Qt/C++ WebAssembly client portal, FastAPI validation engine, and PostgreSQL database modeling microplates down to individual well coordinates (A1–P24), compound volumes, and barcodes.\n• Liquid Handling Automation (~70% Labor Reduction): Connected PostgreSQL directly to Tecan Fluent and Freedom EVO via SiLA 2 and dynamic GWL worklists; automated cherry-picking and serial dilutions, shifting assay prep from a senior technician + scientist split to a junior technician at half-time while eliminating manual pipetting mistakes.\n• Instrument Data Ingestion & C++ Drivers: Built automated parsers reading raw optical reader files and logs into PostgreSQL; replaced outdated vendor libraries with lightweight C++ background daemons (RS-232/TCP, token-based concurrency) for microplate sealers and carousels.\n• Staff Training & Ongoing Support: Conducted interactive training sessions, wrote practical user guides, and provided daily support ensuring smooth adoption across all ongoing screening studies."
            },
            {
                period: "NOV 2024 – JAN 2025",
                role: "Junior Lead Scientist — High-Throughput Screening (HTS)",
                company: "Lermed • Lausanne, Switzerland",
                highlights: "• Screening Assay Strategy: Led the scientific and technical specification of an automated screening workflow for neurodegenerative disease research, translating disease biology into reproducible high-throughput assay formats.\n• Biomarker Selection: Assessed clinical and experimental literature to define a prioritized set of validated translational biomarkers and quantitative measurement criteria."
            },
            {
                period: "SUMMER 2024",
                role: "Project Manager — Deep-Tech Innovation",
                company: "Microcity (Swiss Innovation Park) • Neuchâtel, Switzerland",
                highlights: "• Multi-Partner Project Coordination: Facilitated collaborative technology projects connecting academic research laboratories, startups, and established regional companies across Western Switzerland, converting laboratory innovations into structured technical plans."
            },
            {
                period: "2020 – 2024",
                role: "PhD Researcher & Neuroscientist (Signal Processing & Software)",
                company: "University of Lausanne (UNIL) • Lausanne, Switzerland",
                highlights: "• Automated Data Processing Tools: Built automated Python and MATLAB pipelines to process multi-terabyte electrophysiological datasets, handling signal filtering, time-frequency wavelet analysis, and statistical evaluation.\n• Laboratory Software Adoption: Developed user-friendly recording and analysis software that standardized data collection procedures, achieving complete adoption across departmental researchers.\n• Collaborative Pharmacological Study (AstraZeneca): Co-designed and executed an industry-partnered drug testing study using Microelectrode Arrays (MEA) on acute brain slices (J Cereb Blood Flow Metab, 2022).\n• Mentorship & Governance: Served as elected PhD representative, supervised 3 Master's thesis candidates (all achieved top academic marks), and published first-author research in iScience (2024)."
            },
            {
                period: "2018 – 2020",
                role: "Master Researcher — Cellular Biophysics & Biosensors",
                company: "University of Lausanne (UNIL) • Lausanne, Switzerland",
                highlights: "• Biosensor Experimental Validation: Performed patch-clamp electrophysiology, quantitative calcium imaging, and cellular assays to study receptor kinetics, contributing to a co-authored paper in Biosensors (2022)."
            },
            {
                period: "2015 – 2018",
                role: "Bachelor of Science (B.Sc.) in Biology",
                company: "University of Neuchâtel • Neuchâtel, Switzerland",
                highlights: "• Comprehensive foundational training in molecular biology, neurobiology, biochemistry, and quantitative scientific methodology."
            }
        ]

        Rectangle {
            id: timelineCard
            Layout.fillWidth: true
            implicitHeight: nodeRow.implicitHeight + (Theme.spaceMd * 2)
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: timeMouse.containsMouse ? (index === 0 ? Theme.terracottaGlow : Theme.glassBorder) : Theme.borderCard
            border.width: 1
            clip: true

            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: timeMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            RowLayout {
                id: nodeRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceMd
                spacing: Theme.spaceLg

                // Left Timeline Dot & Date Badge
                Column {
                    Layout.preferredWidth: 160
                    Layout.alignment: Qt.AlignTop
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: index === 0 ? Theme.terracottaGlow : Theme.cinnabar
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackMicro
                        color: index === 0 ? Theme.terracottaGlow : Theme.textMuted
                        text: modelData.period
                    }
                }

                // Right Content
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.sizeH3
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackHeading
                        color: Theme.textPrimary
                        text: modelData.role
                    }

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        color: Theme.textMuted
                        text: modelData.company
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontBody
                        font.pixelSize: Theme.sizeBodySm
                        lineHeight: 1.5
                        color: Theme.textSecondary
                        text: modelData.highlights
                    }
                }
            }
        }
    }

    // Credentials, Technical Toolkit & Languages Summary Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: credGrid.implicitHeight + (Theme.spaceLg * 2)
        radius: Theme.radiusMd
        color: Theme.bgSurface
        border.color: Theme.borderCard
        border.width: 1

        GridLayout {
            id: credGrid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spaceLg
            columns: timelineRoot.width > 820 ? 3 : 1
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceMd

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 6
                Text {
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro; color: Theme.terracottaGlow
                    text: "EDUCATION"
                }
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Ph.D. in Neuroscience — Univ. of Lausanne (2020–2024)\n• M.Sc. in Medical Biology — Univ. of Lausanne (2018–2020)\n• B.Sc. in Biology — Univ. of Neuchâtel (2015–2018)"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 6
                Text {
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro; color: Theme.statusGreen
                    text: "TECHNICAL TOOLKIT & METHODOLOGIES"
                }
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Python (FastAPI, PySide6, OpenCV) • C++ & Qt 6\n• SQL & Relational Schema Design • Git & CI/CD\n• Data Science with MATLAB • Experimental Design\n• Agile / Scrum / Kanban Delivery"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 6
                Text {
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro; color: Theme.goldAccent
                    text: "LANGUAGES & PROFILE"
                }
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody; font.pixelSize: Theme.sizeBodySm; color: Theme.textSecondary; lineHeight: 1.5
                    text: "• Swiss Citizen • Based in Le Mont-sur-Lausanne\n• French (Native) • English (Fluent C1–C2) • German (Basic)\n• Staff Training, User Guides & MSc Mentorship"
                }
            }
        }
    }
}
