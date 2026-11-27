import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import ".."

ColumnLayout {
    id: pubRoot

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
                Layout.preferredWidth: pubTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: pubTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "05 // PUBLICATIONS"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "PEER-REVIEWED TRANSLATIONAL RESEARCH"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: "Peer-Reviewed Scientific Publications"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            text: "Translational research combining biosensor engineering, high-density electrophysiology, automated biosignal pipelines, and pharmacology published in leading international journals."
        }
    }

    // Publications List
    Repeater {
        model: [
            {
                journal: "iScience (Cell Press, 2024)",
                badge: "FIRST AUTHOR // LEAD RESEARCHER",
                title: "The lactate receptor HCAR1: A key modulator of epileptic seizure activity",
                authors: "Alessandri M, Briquet M, Rocher AB, Chatton JY et al.",
                doi: "10.1016/j.isci.2024.109679",
                url: "https://doi.org/10.1016/j.isci.2024.109679",
                tags: ["In Vivo Electrophysiology", "Automated Python/MATLAB Pipeline", "HCAR1 Pharmacology"],
                summary: "Demonstrated that activation of the hydroxycarboxylic acid receptor 1 (HCAR1) substantially suppresses epileptic seizure propagation. Pioneered a novel high-density rodent EEG surgical implantation protocol and automated multi-terabyte wavelet time-frequency decomposition pipeline in Python/MATLAB."
            },
            {
                journal: "Journal of Cerebral Blood Flow & Metabolism (Sage, 2022)",
                badge: "INDUSTRY PHARMA COLLABORATION // ASTRAZENECA",
                title: "Activation of lactate receptor HCAR1 down-modulates neuronal activity in rodent and human brain tissue",
                authors: "Briquet M, Rocher AB, Alessandri M et al.",
                doi: "10.1177/0271678X221080324",
                url: "https://doi.org/10.1177/0271678X221080324",
                tags: ["AstraZeneca Collaboration", "Ex Vivo MEA Screening", "Human & Rodent Tissue"],
                summary: "Collaborative ex vivo pharmacological screening study with AstraZeneca utilizing high-throughput Microelectrode Array (MEA) electrophysiology on acute rodent and human cortical brain slices to characterize cellular signaling cascades."
            },
            {
                journal: "Biosensors (MDPI, 2022)",
                badge: "BIOSENSOR & ASSAY ENGINEERING",
                title: "Evaluation of HCAR1 as a Building Block for Genetically Encoded Extracellular Lactate Biosensors",
                authors: "Wellbourne-Wood J, Briquet M, Alessandri M et al.",
                doi: "10.3390/bios12030143",
                url: "https://doi.org/10.3390/bios12030143",
                tags: ["Biophysical Biosensors", "Patch-Clamp & Ca2+ Imaging", "Assay Validation"],
                summary: "Engineered and validated genetically encoded extracellular biosensors for real-time quantitative monitoring of extracellular lactate fluxes using patch-clamp electrophysiology and two-photon calcium imaging."
            }
        ]

        Rectangle {
            id: pubCard
            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + (Theme.spaceLg * 2)
            radius: Theme.radiusMd
            color: Theme.bgCard
            border.color: cardHoverArea.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
            border.width: 1
            clip: true

            scale: cardHoverArea.pressed ? 0.99 : (cardHoverArea.containsMouse ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            MouseArea {
                id: cardHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(modelData.url)
            }

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        font.letterSpacing: Theme.trackMicro
                        color: Theme.terracottaGlow
                        text: modelData.journal.toUpperCase()
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: badgeTxt.implicitWidth + 16
                        Layout.preferredHeight: 22
                        radius: Theme.radiusPill
                        color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                        Text {
                            id: badgeTxt
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                            color: Theme.statusGreen
                            text: modelData.badge
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.sizeH2
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackHeading
                    color: Theme.textPrimary
                    text: modelData.title
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMicro
                    color: Theme.textMuted
                    text: modelData.authors + " • DOI: " + modelData.doi
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    font.family: Theme.fontBody
                    font.pixelSize: Theme.sizeBodySm
                    lineHeight: 1.55
                    color: Theme.textSecondary
                    text: modelData.summary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: modelData.tags
                            Rectangle {
                                width: pTagTxt.implicitWidth + 14; height: 22; radius: Theme.radiusPill
                                color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                                Text {
                                    id: pTagTxt
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted
                                    text: modelData
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 30
                        radius: Theme.radiusPill
                        color: doiMouse.pressed ? Theme.cinnabarHover : (doiMouse.containsMouse ? Theme.cinnabar : Theme.bgSurface)
                        border.color: Theme.glassBorder; border.width: 1
                        scale: doiMouse.pressed ? 0.94 : (doiMouse.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro
                            font.capitalization: Font.AllUppercase; font.weight: Font.Bold
                            color: doiMouse.containsMouse ? Theme.textOnCinnabar : Theme.textPrimary
                            text: "Open Paper ↗"
                        }

                        MouseArea {
                            id: doiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }
        }
    }
}
