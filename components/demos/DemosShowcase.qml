import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."
import "."

ColumnLayout {
    id: showcaseRoot

    Layout.fillWidth: true
    spacing: Theme.spaceLg

    property int activeTab: 0
    property bool active: true

    // Section Title & Explanatory Header
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: benchTag.implicitWidth + 20
                radius: 12
                color: Theme.glassFill
                border.color: Theme.paletteAccent
                border.width: 1

                Text {
                    id: benchTag
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: Theme.trackMicro
                    font.capitalization: Font.AllUppercase
                    color: Theme.paletteAccent
                    text: "04 // WORKBENCH"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMicro
                font.letterSpacing: Theme.trackWide
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                color: Theme.textDim
                text: "PRODUCTION-DERIVED ENGINEERING MODULES"
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.sizeH1
            font.weight: Font.Bold
            color: Theme.textPrimary
            text: "Interactive Engineering Workbench"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: Theme.textSecondary
            text: "Interactive sub-systems adapted from production lab automation and LIMS engineering work: drag-and-drop Excel batches into the Client Portal, configure Compound × Assay matrices, execute compiled GWL hitpicks on the 3D Tecan Fluent twin, and inspect 4PL IC50 results."
        }
    }

    // Tab Navigation Bar: Apple Fluid Segmented Control with Gliding Capsule Thumb (5 Production Tabs)
    Rectangle {
        id: segmentedTrack
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: Theme.radiusMd
        color: Theme.bgSurface
        border.color: Theme.borderCard
        border.width: 1
        clip: true

        // Gliding Active Capsule Thumb with Apple Physics
        Rectangle {
            id: activeCapsule
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 3
            x: (showcaseRoot.activeTab * (segmentedTrack.width - 6) / 5) + 3
            width: (segmentedTrack.width - 6) / 5
            radius: Theme.radiusMd - 2
            color: Theme.bgCard
            border.color: Theme.terracottaGlow
            border.width: 1

            Behavior on x {
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 0

            Repeater {
                model: [
                    { id: 0, title: "01 // PORTAL ➔ LAB",  sub: "End-to-End LIMS Flow" },
                    { id: 1, title: "02 // DIGITAL TWIN",   sub: "Tecan Fluent 1080 3D" },
                    { id: 2, title: "03 // HITPICK MAPPER", sub: "96-to-384 Engine" },
                    { id: 3, title: "04 // 4PL & ASSAY QC", sub: "IC50 & Z'-Factor" },
                    { id: 4, title: "05 // GWL / SILA 2",   sub: "Worklist & DB Ingest" }
                ]

                Item {
                    id: tabItem
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    scale: tabMouse.pressed ? 0.95 : (tabMouse.containsMouse && showcaseRoot.activeTab !== modelData.id ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 2

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.sizeMicro
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            color: showcaseRoot.activeTab === modelData.id ? Theme.textPrimary : (tabMouse.containsMouse ? Theme.textSecondary : Theme.textMuted)
                            text: modelData.title
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.family: Theme.fontBody
                            font.pixelSize: 10
                            color: showcaseRoot.activeTab === modelData.id ? Theme.terracottaGlow : Theme.textDim
                            text: modelData.sub
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showcaseRoot.activeTab = modelData.id
                    }
                }
            }
        }
    }

    // Active Demo Stack Container
    StackLayout {
        Layout.fillWidth: true
        currentIndex: showcaseRoot.activeTab
        Layout.preferredHeight: showcaseRoot.activeTab === 0 ? 700 : (showcaseRoot.activeTab === 2 ? 650 : 600)

        ClientPortalWorkflowDemo {
            id: portalDemo
            Layout.fillWidth: true
            Layout.fillHeight: true
            onSimulateGwlOn3D: function(gwlJob) {
                robotDemo.startGwlHitpickJob(gwlJob);
                showcaseRoot.activeTab = 1;
            }
        }

        RoboticArmDemo {
            id: robotDemo
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: showcaseRoot.active && showcaseRoot.activeTab === 1
            onContinueToPortalResults: {
                portalDemo.complete3dHitpickAndAnalyze();
                showcaseRoot.activeTab = 0;
            }
        }

        PlateVisualizerDemo {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        DoseResponseDemo {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        GwlGeneratorDemo {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
