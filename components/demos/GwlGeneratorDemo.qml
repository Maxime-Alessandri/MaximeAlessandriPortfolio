import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."
import "../../controls"

Rectangle {
    id: gwlDemoRoot

    implicitWidth: 840
    implicitHeight: 520
    radius: Theme.radiusMd
    color: Theme.bgCard
    border.color: Theme.glassBorder
    border.width: 1
    clip: true

    property string protocol: "Serial Dilution (1:3)"
    property real transferVolume: 50.0
    property string liquidClass: "Water_Free_Dispense_Air"
    property string outputFormat: "GWL" // "GWL", "SiLA2", or "DB"
    property bool copiedFeedback: false

    // Generate dynamic script lines
    function generateGwlLines() {
        var lines = [];
        var vol = transferVolume.toFixed(1);
        var lClass = liquidClass;

        lines.push("; ================================================================");
        lines.push("; INVENESIS TECAN FLUENT 1080 DYNAMIC GWL PIPETTING WORKLIST");
        lines.push("; Protocol: " + protocol + " | Liquid Class: " + lClass);
        lines.push("; Generated: " + new Date().toISOString() + " | Architect: Maxime Alessandri, PhD");
        lines.push("; ================================================================");
        lines.push("");

        if (protocol === "Serial Dilution (1:3)") {
            var rows = ["A","B","C","D","E","F","G","H"];
            for (var r = 0; r < rows.length; ++r) {
                var row = rows[r];
                lines.push("; --- Serial Dilution Row " + row + " (1:3 Gradient) ---");
                for (var col = 1; col < 12; ++col) {
                    var srcCol = (col < 10 ? "0" : "") + col;
                    var dstCol = (col + 1 < 10 ? "0" : "") + (col + 1);
                    var srcWell = row + srcCol;
                    var dstWell = row + dstCol;
                    lines.push("A;SourcePlate_96;;;" + srcWell + ";" + vol + ";" + lClass + ";;");
                    lines.push("D;DestPlate_96;;;" + dstWell + ";" + vol + ";" + lClass + ";;");
                    lines.push("W; ;;;; ;;;");
                }
                lines.push("");
            }
        } else if (protocol === "Cherry-Pick Hit Transfer") {
            lines.push("; --- High-Content Hit Cherry-Picking (Efficacy > 80%) ---");
            var hits = ["B04", "C07", "D02", "E09", "F03", "G11"];
            for (var h = 0; h < hits.length; ++h) {
                var hitWell = hits[h];
                var targetWell = "A" + (h + 1 < 10 ? "0" : "") + (h + 1);
                lines.push("A;PrimaryScreen_Plate01;;;" + hitWell + ";" + vol + ";" + lClass + ";;");
                lines.push("D;SecondaryValidation_Plate01;;;" + targetWell + ";" + vol + ";" + lClass + ";;");
                lines.push("W; ;;;; ;;;");
            }
        } else {
            lines.push("; --- 96 to 384-Well Quadrant Replication ---");
            lines.push("A;Master_96_Plate01;;;A01;" + vol + ";" + lClass + ";;");
            lines.push("D;Target_384_Quadrant1;;;A01;" + (vol / 4.0).toFixed(1) + ";" + lClass + ";;");
            lines.push("D;Target_384_Quadrant2;;;A02;" + (vol / 4.0).toFixed(1) + ";" + lClass + ";;");
            lines.push("D;Target_384_Quadrant3;;;B01;" + (vol / 4.0).toFixed(1) + ";" + lClass + ";;");
            lines.push("D;Target_384_Quadrant4;;;B02;" + (vol / 4.0).toFixed(1) + ";" + lClass + ";;");
            lines.push("W; ;;;; ;;;");
        }
        return lines.join("\n");
    }

    function generateSila2Payload() {
        return JSON.stringify({
            "sila2_command": "org.silastandard.instruments/LiquidHandlingController/v1/ExecutePipettingWorklist",
            "metadata": {
                "instrument": "Tecan_Fluent_1080",
                "orchestrator": "Invenesis_LIMS_Scheduler",
                "timestamp": new Date().toISOString()
            },
            "parameters": {
                "ProtocolName": protocol,
                "TransferVolume_uL": Math.round(transferVolume * 10) / 10,
                "LiquidClass": liquidClass,
                "SourceLabwareId": "BC_PLATE_96_0042",
                "DestinationLabwareId": "BC_PLATE_384_0089",
                "TipType": "FCA_200uL_Filter_Tips",
                "WashStation": "Active_Wash_Unit_Nest12"
            },
            "status": "COMMAND_STAGED_READY_FOR_DISPATCH"
        }, null, 2);
    }

    function generateDbIngestRecord() {
        var vol = Math.round(transferVolume * 10) / 10;
        return JSON.stringify({
            "table": "tracked_test_batches",
            "batch_id": 42,
            "robot_request_id": "REQ-2026-0042",
            "well_coordinate_space": "A1-P24",
            "protocol": protocol,
            "liquid_handling": {
                "instrument": "Tecan_Fluent_1080",
                "liquid_class": liquidClass,
                "transfer_volume_uL": vol,
                "source_barcode": "BC_PLATE_96_0042",
                "dest_barcode": "BC_PLATE_384_0089"
            },
            "raw_reader_ingest": {
                "parser": "FastAPI_Reader_Parser_v2",
                "target_tables": ["batch_raw_plates", "compound_efficacies"],
                "sample_well": "A01",
                "z_prime_qc": 0.78,
                "audit_status": "RECORD_INTEGRITY_VERIFIED"
            }
        }, null, 2);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        spacing: Theme.spaceMd

        // Header
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.sizeH3
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    text: "Dynamic Tecan GWL, SiLA 2 & Database Ingestion Compiler"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMicro
                    font.letterSpacing: Theme.trackMicro
                    color: Theme.textMuted
                    text: "DYNAMIC WORKLIST COMPILER // SILA 2 GRPC PAYLOAD // POSTGRESQL STANDARDIZED RECORD"
                }
            }

            // Copy Action Button
            Rectangle {
                Layout.preferredWidth: 144
                Layout.preferredHeight: 32
                radius: Theme.radiusPill
                color: gwlDemoRoot.copiedFeedback ? Theme.statusGreen : Theme.cinnabar
                border.color: gwlDemoRoot.copiedFeedback ? Theme.statusGreen : Theme.terracottaGlow; border.width: 1
                scale: copyMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro
                    font.capitalization: Font.AllUppercase; font.weight: Font.Bold
                    color: gwlDemoRoot.copiedFeedback ? Theme.textOnGreen : Theme.textOnCinnabar
                    text: gwlDemoRoot.copiedFeedback ? "Copied! ✓" : "Copy Payload"
                }
                MouseArea {
                    id: copyMouse
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        codeText.selectAll();
                        codeText.copy();
                        codeText.deselect();
                        gwlDemoRoot.copiedFeedback = true;
                        copyTimer.start();
                    }
                }
            }

            Timer {
                id: copyTimer
                interval: 1600
                onTriggered: gwlDemoRoot.copiedFeedback = false
            }
        }

        // Main Editor Area + Protocol Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceLg

            // Script Output Viewport
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgVoid
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                Flickable {
                    id: flick
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: codeText.paintedWidth
                    contentHeight: codeText.paintedHeight
                    clip: true

                    TextEdit {
                        id: codeText
                        width: Math.max(flick.width, paintedWidth)
                        readOnly: true
                        selectByMouse: true
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.letterSpacing: 0.6
                        color: Theme.textPrimary
                        text: {
                            if (gwlDemoRoot.outputFormat === "GWL") return gwlDemoRoot.generateGwlLines();
                            if (gwlDemoRoot.outputFormat === "SiLA2") return gwlDemoRoot.generateSila2Payload();
                            return gwlDemoRoot.generateDbIngestRecord();
                        }
                    }
                }
            }

            // Right Protocol Parameter Selector
            Rectangle {
                Layout.preferredWidth: 276
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.glassFill
                border.color: Theme.glassBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMd
                    spacing: Theme.spaceSm

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        font.letterSpacing: Theme.trackMicro
                        color: Theme.terracottaGlow
                        text: "PIPELINE OUTPUT FORMAT"
                    }

                    // 3-Way Format Switcher (GWL / SiLA 2 / DB Record)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "GWL",   label: "GWL" },
                                { id: "SiLA2", label: "SiLA 2" },
                                { id: "DB",    label: "DB RECORD" }
                            ]

                            Rectangle {
                                readonly property bool isSel: gwlDemoRoot.outputFormat === modelData.id
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: Theme.radiusPill
                                color: isSel ? Theme.terracotta : Theme.bgCard
                                border.color: isSel ? Theme.terracottaGlow : Theme.borderCard
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                    color: isSel ? Theme.textOnAccent : Theme.textPrimary
                                    text: modelData.label
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: gwlDemoRoot.outputFormat = modelData.id
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // Protocol Selection
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "ACTIVE ASSAY PROTOCOL" }

                        Repeater {
                            model: [
                                { id: "Serial Dilution (1:3)",      label: "Serial Dilution (1:3)" },
                                { id: "Cherry-Pick Hit Transfer",   label: "Hit Cherry-Picking" },
                                { id: "Quadrant Replication",       label: "96 to 384 Replication" }
                            ]

                            Rectangle {
                                readonly property bool isProto: gwlDemoRoot.protocol === modelData.id
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 4
                                color: isProto ? Theme.paletteAccent : Theme.bgCard
                                border.color: isProto ? Theme.paletteAccent : Theme.borderCard
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                    color: isProto ? Theme.textOnAccent : Theme.textPrimary
                                    text: modelData.label
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: gwlDemoRoot.protocol = modelData.id
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // Transfer Volume Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "ASPIRATION VOLUME" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.terracottaGlow; text: gwlDemoRoot.transferVolume.toFixed(0) + " µL" }
                        }
                        AccentSlider {
                            Layout.fillWidth: true
                            from: 5.0; to: 200.0; value: gwlDemoRoot.transferVolume
                            onMoved: gwlDemoRoot.transferVolume = value
                        }
                    }

                    // Liquid Class Selection
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "FLUENTCONTROL LIQUID CLASS" }
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: gwlDemoRoot.liquidClass }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
