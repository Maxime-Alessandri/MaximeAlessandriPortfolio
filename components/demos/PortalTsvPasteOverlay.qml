import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

Rectangle {
    id: pasteOverlayRoot

    anchors.fill: parent
    z: 55
    visible: isOpen
    color: Theme.alpha(Theme.bgVoid, 0.82)

    property bool isOpen: false
    property string screeningMode: "secondary"
    property string defaultForm: "solution"
    property var parsedRows: []

    signal rowsConfirmed(var rows)
    signal cancelled()

    function open() {
        rawPasteEdit.text = "";
        parsedRows = [];
        isOpen = true;
        rawPasteEdit.forceActiveFocus();
    }

    function insertSampleExcelTsv() {
        rawPasteEdit.text =
            "Sample ID\tSolvent\tStock\tQty\tStart Dose\tDil Fold\tDilutions\tReplicates\n" +
            "CPD-910\tDMSO\t10 mM\t100 uL\t30 uM\t3.16\t6\t2\n" +
            "CPD-911\tDMSO\t10 mM\t100 uL\t30 uM\t3.16\t6\t2\n" +
            "CPD-912\tEtOH\t5 mM\t50 uL\t100 uM\t3.16\t8\t2\n" +
            "CPD-913\tDMSO\t10 mM\t120 uL\t10 uM\t2.0\t6\t3";
    }

    function parseRawText(raw) {
        var trimmed = String(raw || "").trim();
        if (trimmed === "") {
            parsedRows = [];
            return;
        }
        var lines = trimmed.split(/\r?\n/);
        var validLines = [];
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].trim() !== "") validLines.push(lines[i]);
        }
        if (validLines.length === 0) {
            parsedRows = [];
            return;
        }

        var delim = "\t";
        if (validLines[0].indexOf("\t") === -1) {
            if (validLines[0].indexOf(";") !== -1) delim = ";";
            else if (validLines[0].indexOf(",") !== -1) delim = ",";
        }

        var hdrTokens = validLines[0].split(delim);
        var hdrScore = 0;
        var map = {};
        for (var c = 0; c < hdrTokens.length; ++c) {
            var norm = hdrTokens[c].trim().toLowerCase().replace(/[^a-z0-9]/g, "");
            if (norm.indexOf("sample") !== -1 || norm.indexOf("compound") !== -1 || norm === "id") { map.id = c; hdrScore++; }
            else if (norm.indexOf("solv") !== -1 || norm.indexOf("vehicle") !== -1) { map.solvent = c; hdrScore++; }
            else if (norm.indexOf("stock") !== -1) { map.stock = c; hdrScore++; }
            else if (norm.indexOf("qty") !== -1 || norm.indexOf("vol") !== -1 || norm.indexOf("mass") !== -1) { map.qty = c; hdrScore++; }
            else if (norm.indexOf("dose") !== -1 || norm.indexOf("start") !== -1) { map.dose = c; hdrScore++; }
            else if (norm.indexOf("fold") !== -1 || norm.indexOf("step") !== -1) { map.fold = c; hdrScore++; }
            else if (norm.indexOf("dil") !== -1) { map.dils = c; hdrScore++; }
            else if (norm.indexOf("rep") !== -1) { map.reps = c; hdrScore++; }
        }

        var hasHeader = hdrScore >= 2;
        var startIdx = hasHeader ? 1 : 0;
        var isPowder = (defaultForm === "powder");
        var out = [];

        for (var r = startIdx; r < validLines.length && out.length < 8; ++r) {
            var cells = validLines[r].split(delim);
            function pick(key, posIdx) {
                var idx = hasHeader ? (map[key] !== undefined ? map[key] : -1) : posIdx;
                return (idx >= 0 && idx < cells.length) ? cells[idx].trim() : "";
            }
            var sid = pick("id", 0).toUpperCase();
            if (sid === "") continue;

            var solv = pick("solvent", 1) || "DMSO";
            var stockRaw = pick("stock", 2);
            var stockVal = isPowder ? "" : (stockRaw.replace(/[^0-9.]/g, "") || "10");
            var stockUnit = stockRaw.toLowerCase().indexOf("um") !== -1 || stockRaw.toLowerCase().indexOf("µm") !== -1 ? "µM" : "mM";

            var qtyRaw = pick("qty", 3);
            var qtyVal = qtyRaw.replace(/[^0-9.]/g, "") || (isPowder ? "5" : "100");
            var qtyUnit = isPowder ? (qtyRaw.toLowerCase().indexOf("g") !== -1 && qtyRaw.toLowerCase().indexOf("mg") === -1 ? "g" : "mg")
                                   : (qtyRaw.toLowerCase().indexOf("ml") !== -1 ? "mL" : "µL");

            var doseRaw = pick("dose", 4);
            var startDose = parseFloat(doseRaw.replace(/[^0-9.]/g, ""));
            if (isNaN(startDose) || startDose <= 0) startDose = 30.0;

            var foldRaw = pick("fold", 5);
            var dilFold = parseFloat(foldRaw.replace(/[^0-9.]/g, ""));
            if (isNaN(dilFold) || dilFold <= 1.0) dilFold = (screeningMode === "secondary" ? 3.16 : 1.0);

            var dilsRaw = pick("dils", 6);
            var nbDilutions = parseInt(dilsRaw.replace(/[^0-9]/g, ""), 10);
            if (isNaN(nbDilutions) || nbDilutions <= 0) nbDilutions = (screeningMode === "secondary" ? 6 : 1);

            var repsRaw = pick("reps", 7);
            var nbReplicates = parseInt(repsRaw.replace(/[^0-9]/g, ""), 10);
            if (isNaN(nbReplicates) || nbReplicates <= 0) nbReplicates = 2;

            out.push({
                sampleId: sid,
                solvent: solv,
                stockConc: stockVal,
                stockUnit: stockUnit,
                quantity: qtyVal,
                quantityUnit: qtyUnit,
                startDose: startDose,
                dilutionFold: dilFold,
                nbDilutions: nbDilutions,
                nbReplicates: nbReplicates
            });
        }
        parsedRows = out;
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: function(mouse) { mouse.accepted = true; }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 720)
        height: Math.min(parent.height - 32, 470)
        radius: Theme.radiusMd
        color: Theme.bgCard
        border.color: Theme.paletteAccent
        border.width: 2

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true; }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 7
                    color: Theme.alpha(Theme.paletteAccent, 0.16)
                    border.color: Theme.paletteAccent
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: Theme.paletteAccent
                        text: "content_paste"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "Paste Cells Directly from Excel (TSV / CSV)"
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                        text: "Copy compound rows in Excel (Ctrl+C) and paste here (Ctrl+V), or insert sample rows to test."
                    }
                }

                Rectangle {
                    Layout.preferredWidth: sampleTsvTxt.implicitWidth + 16
                    Layout.preferredHeight: 26
                    radius: Theme.radiusPill
                    color: sampleTsvMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.paletteAccent
                    border.width: 1
                    Text {
                        id: sampleTsvTxt
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: Theme.paletteAccent
                        text: "Insert Sample Excel Rows"
                    }
                    MouseArea {
                        id: sampleTsvMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pasteOverlayRoot.insertSampleExcelTsv()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.textPrimary; text: "✕" }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pasteOverlayRoot.isOpen = false;
                            pasteOverlayRoot.cancelled();
                        }
                    }
                }
            }

            // Paste Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: Theme.radiusSm
                color: Theme.bgVoid
                border.color: rawPasteEdit.activeFocus ? Theme.paletteAccent : Theme.borderCard
                border.width: 1
                clip: true

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 10
                    visible: rawPasteEdit.text.length === 0
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textDim
                    text: "Paste tab-separated Excel columns here...\nExample: Sample ID | Solvent | Stock | Qty | Start Dose | Dil Fold | Dilutions | Replicates"
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentWidth: parent.width - 16
                    contentHeight: Math.max(height, rawPasteEdit.paintedHeight)
                    clip: true

                    TextEdit {
                        id: rawPasteEdit
                        width: parent.width
                        height: Math.max(parent.height, paintedHeight)
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textPrimary
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        onTextChanged: pasteOverlayRoot.parseRawText(text)
                    }
                }
            }

            // Live Parsed Preview Table
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgVoid
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        color: Theme.bgSurface
                        Row {
                            anchors.fill: parent
                            spacing: 0
                            Item { width: parent.width * 0.24; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "SAMPLE ID" } }
                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "SOLVENT" } }
                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "STOCK" } }
                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "QTY" } }
                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "START µM" } }
                            Item { width: parent.width * 0.20; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "DIL × REP" } }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent
                            visible: pasteOverlayRoot.parsedRows.length === 0
                            font.family: Theme.fontBody
                            font.pixelSize: 11
                            color: Theme.textDim
                            text: "Parsed rows will appear here automatically."
                        }

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 4
                            contentHeight: previewRowsCol.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: previewRowsCol
                                width: parent.width
                                spacing: 3

                                Repeater {
                                    model: pasteOverlayRoot.parsedRows
                                    Rectangle {
                                        id: pRow
                                        required property int index
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26
                                        radius: 3
                                        color: pRow.index % 2 === 0 ? Theme.bgSurface : Theme.bgCard
                                        Row {
                                            anchors.fill: parent
                                            spacing: 0
                                            Item { width: parent.width * 0.24; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: pRow.modelData.sampleId } }
                                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.paletteAccent; text: pRow.modelData.solvent } }
                                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary; text: pRow.modelData.stockConc ? (pRow.modelData.stockConc + " " + pRow.modelData.stockUnit) : "-" } }
                                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; text: pRow.modelData.quantity + " " + pRow.modelData.quantityUnit } }
                                            Item { width: parent.width * 0.14; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; text: pRow.modelData.startDose + " µM" } }
                                            Item { width: parent.width * 0.20; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.terracottaGlow; text: pRow.modelData.nbDilutions + "pt (" + pRow.modelData.dilutionFold + "x) × " + pRow.modelData.nbReplicates } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: pasteOverlayRoot.parsedRows.length > 0 ? Theme.statusGreen : Theme.textMuted
                    text: pasteOverlayRoot.parsedRows.length + " valid row(s) detected (max 8 plated per SBS-96 batch)"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 34
                    radius: Theme.radiusPill
                    color: Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.textPrimary; text: "Cancel" }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pasteOverlayRoot.isOpen = false;
                            pasteOverlayRoot.cancelled();
                        }
                    }
                }

                Rectangle {
                    readonly property bool canImport: pasteOverlayRoot.parsedRows.length > 0
                    Layout.preferredWidth: 224
                    Layout.preferredHeight: 34
                    radius: Theme.radiusPill
                    color: canImport ? Theme.statusGreen : Theme.bgSurface
                    border.color: canImport ? Theme.statusGreen : Theme.borderCard
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: parent.canImport ? Theme.textOnGreen : Theme.textDim
                        text: "Import " + pasteOverlayRoot.parsedRows.length + " Row(s) into Table ✓"
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canImport
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            var outRows = pasteOverlayRoot.parsedRows.slice();
                            pasteOverlayRoot.isOpen = false;
                            pasteOverlayRoot.rowsConfirmed(outRows);
                        }
                    }
                }
            }
        }
    }
}
