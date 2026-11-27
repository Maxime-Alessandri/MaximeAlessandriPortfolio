import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

ColumnLayout {
    id: sheetRoot

    spacing: 8

    property var selectedAssay: null
    property string projectCode: "PRJ-2026-042"
    property string quoteNumber: "Q2026-01"
    property string screeningMode: "secondary" // "primary" or "secondary"
    property string defaultForm: "solution"   // "solution" or "powder"
    property var tableRows: []
    property int cartCount: 0
    property string statusBanner: ""

    signal backToCatalogue()
    signal openCart()
    signal openTsvPaste()
    signal openExcelDrop(string rawUrl)
    signal openSampleExcel()
    signal projectCodeEdited(string val)
    signal quoteNumberEdited(string val)
    signal screeningModeToggled(string mode)
    signal formulationToggled(string form)
    signal rowUpdated(int idx, string field, var val)
    signal rowFieldCycled(int idx, string field)
    signal addBlankRowRequested()
    signal duplicateRowRequested(int idx)
    signal removeRowRequested(int idx)
    signal loadDemoBatchRequested()
    signal clearRowsRequested()
    signal addToCartRequested(bool goToCart)

    readonly property var duplicateAnalysis: {
        var counts = {};
        for (var i = 0; i < tableRows.length; ++i) {
            var sid = String(tableRows[i].sampleId || "").trim().toUpperCase();
            if (sid !== "") counts[sid] = (counts[sid] || 0) + 1;
        }
        var dupCount = 0;
        for (var j = 0; j < tableRows.length; ++j) {
            var s2 = String(tableRows[j].sampleId || "").trim().toUpperCase();
            if (s2 !== "" && counts[s2] > 1) dupCount++;
        }
        return { counts: counts, dupRowCount: dupCount };
    }

    readonly property int estimatedDatapoints: {
        var sum = 0;
        for (var i = 0; i < tableRows.length; ++i) {
            var r = tableRows[i];
            if (String(r.sampleId || "").trim() === "") continue;
            var dils = (screeningMode === "secondary") ? (r.nbDilutions || 6) : 1;
            var reps = r.nbReplicates || 2;
            sum += dils * reps;
        }
        return sum;
    }

    readonly property int estimatedPlates: Math.max(1, Math.ceil(tableRows.length / 8))

    // =========================================================================
    // 1. PRODUCT SPEC HEADER + INLINE ORDER CONTEXT (modeled on PortalProductPageView)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: Theme.radiusSm
        color: Theme.bgSurface
        border.color: Theme.borderCard
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                Layout.preferredWidth: backCatTxt.implicitWidth + 16
                Layout.preferredHeight: 28
                radius: Theme.radiusPill
                color: backCatMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgCard
                border.color: Theme.borderCard
                border.width: 1
                Text {
                    id: backCatTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "← Catalogue"
                }
                MouseArea {
                    id: backCatMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sheetRoot.backToCatalogue()
                }
            }

            Rectangle {
                Layout.preferredWidth: assayCodeTxt.implicitWidth + 14
                Layout.preferredHeight: 24
                radius: 4
                color: Theme.paletteAccent
                Text {
                    id: assayCodeTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.textOnAccent
                    text: sheetRoot.selectedAssay ? sheetRoot.selectedAssay.code : "ASY-101"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.family: Theme.fontDisplay
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: sheetRoot.selectedAssay ? sheetRoot.selectedAssay.name : "Screening Assay"
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                    text: sheetRoot.selectedAssay
                          ? (sheetRoot.selectedAssay.format + " • " + sheetRoot.selectedAssay.vol + " • Max DMSO " + sheetRoot.selectedAssay.dmsoMax)
                          : "96-well • 50 µL"
                }
            }

            // Inline Project Code Input
            Row {
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Theme.textDim
                    text: "PROJ:"
                }
                Rectangle {
                    width: 96
                    height: 26
                    radius: 4
                    color: Theme.bgVoid
                    border.color: projEdit.activeFocus ? Theme.paletteAccent : Theme.borderCard
                    border.width: 1
                    TextInput {
                        id: projEdit
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        selectByMouse: true
                        text: sheetRoot.projectCode
                        onEditingFinished: sheetRoot.projectCodeEdited(text.trim().toUpperCase())
                    }
                }
            }

            // Inline Quote N° Input
            Row {
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Theme.textDim
                    text: "QUOTE:"
                }
                Rectangle {
                    width: 82
                    height: 26
                    radius: 4
                    color: Theme.bgVoid
                    border.color: quoteEdit.activeFocus ? Theme.paletteAccent : Theme.borderCard
                    border.width: 1
                    TextInput {
                        id: quoteEdit
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textSecondary
                        selectByMouse: true
                        text: sheetRoot.quoteNumber
                        onEditingFinished: sheetRoot.quoteNumberEdited(text.trim())
                    }
                }
            }

            // Cart Quick Button
            Rectangle {
                Layout.preferredWidth: cartQuickTxt.implicitWidth + 18
                Layout.preferredHeight: 28
                radius: Theme.radiusPill
                color: Theme.alpha(Theme.paletteAccent, 0.14)
                border.color: Theme.paletteAccent
                border.width: 1
                Text {
                    id: cartQuickTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.paletteAccent
                    text: "Cart (" + sheetRoot.cartCount + ")"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sheetRoot.openCart()
                }
            }
        }
    }

    // =========================================================================
    // 2. PROTOCOL MODE, FORMULATION TOGGLE & EXCEL/ROW ACTION BAR
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 8

        // Primary vs Secondary Mode Segmented Switch
        Row {
            spacing: 0
            Repeater {
                model: [
                    { id: "primary",   label: "Primary (1-pt)" },
                    { id: "secondary", label: "Secondary (IC50)" }
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool isSel: sheetRoot.screeningMode === modelData.id
                    width: modeLbl.implicitWidth + 16
                    height: 28
                    radius: 4
                    color: isSel ? Theme.paletteAccent : Theme.bgSurface
                    border.color: isSel ? Theme.paletteAccent : Theme.borderCard
                    border.width: 1
                    Text {
                        id: modeLbl
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: isSel ? Theme.textOnAccent : Theme.textSecondary
                        text: modelData.label
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sheetRoot.screeningModeToggled(modelData.id)
                    }
                }
            }
        }

        // Solution vs Powder Formulation Switch
        Row {
            spacing: 0
            Repeater {
                model: [
                    { id: "solution", label: "Solution" },
                    { id: "powder",   label: "Powder" }
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool isSel: sheetRoot.defaultForm === modelData.id
                    width: formLbl.implicitWidth + 14
                    height: 28
                    radius: 4
                    color: isSel ? Theme.alpha(Theme.terracottaGlow, 0.20) : Theme.bgSurface
                    border.color: isSel ? Theme.terracottaGlow : Theme.borderCard
                    border.width: 1
                    Text {
                        id: formLbl
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: isSel ? Theme.terracottaGlow : Theme.textSecondary
                        text: modelData.label
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sheetRoot.formulationToggled(modelData.id)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Draggable Virtual Excel Sheet Chip (drag onto table below OR click)
        Item {
            Layout.preferredWidth: 132
            Layout.preferredHeight: 28
            z: xlsxChipMouse.drag.active ? 40 : 2

            Rectangle {
                id: virtualXlsxChip
                width: parent.width
                height: parent.height
                x: 0
                y: 0
                radius: 4
                color: xlsxChipMouse.drag.active ? Theme.alpha(Theme.statusGreen, 0.25)
                     : (xlsxChipMouse.containsMouse ? Theme.bgSurfaceHover : Theme.alpha(Theme.statusGreen, 0.12))
                border.color: Theme.statusGreen
                border.width: xlsxChipMouse.drag.active ? 1.5 : 1

                Drag.active: xlsxChipMouse.drag.active
                Drag.hotSpot.x: width * 0.5
                Drag.hotSpot.y: height * 0.5

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                        color: Theme.statusGreen
                        text: "table_chart"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: Theme.statusGreen
                        text: "Drop Batch.xlsx"
                    }
                }

                MouseArea {
                    id: xlsxChipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: virtualXlsxChip
                    drag.minimumX: -620
                    drag.maximumX: 220
                    drag.minimumY: -40
                    drag.maximumY: 260
                    property real startX: 0
                    property real startY: 0
                    onPressed: {
                        startX = virtualXlsxChip.x;
                        startY = virtualXlsxChip.y;
                    }
                    onReleased: {
                        var dist = Math.abs(virtualXlsxChip.x - startX) + Math.abs(virtualXlsxChip.y - startY);
                        var dropped = (virtualXlsxChip.Drag.drop() !== Qt.IgnoreAction);
                        virtualXlsxChip.x = 0;
                        virtualXlsxChip.y = 0;
                        if (!dropped && dist < 8) {
                            sheetRoot.openSampleExcel();
                        }
                    }
                }
            }
        }

        // Paste from Excel Button
        Rectangle {
            Layout.preferredWidth: pasteBtnTxt.implicitWidth + 20
            Layout.preferredHeight: 28
            radius: 4
            color: Theme.paletteAccent
            Row {
                id: pasteBtnRow
                anchors.centerIn: parent
                spacing: 4
                Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontIcon; font.pixelSize: 13; color: Theme.textOnAccent; text: "content_paste" }
                Text { id: pasteBtnTxt; anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textOnAccent; text: "Paste Excel" }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sheetRoot.openTsvPaste()
            }
        }

        // + Add Row Button
        Rectangle {
            Layout.preferredWidth: addBtnTxt.implicitWidth + 16
            Layout.preferredHeight: 28
            radius: 4
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1
            Text { id: addBtnTxt; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: "+ Add Row" }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sheetRoot.addBlankRowRequested()
            }
        }

        // Demo Batch Button
        Rectangle {
            Layout.preferredWidth: demoBatchTxt.implicitWidth + 14
            Layout.preferredHeight: 28
            radius: 4
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1
            Text { id: demoBatchTxt; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary; text: "Demo Batch" }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sheetRoot.loadDemoBatchRequested()
            }
        }

        // Clear Table Button
        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 28
            radius: 4
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1
            opacity: sheetRoot.tableRows.length > 0 ? 1.0 : 0.45
            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; text: "Clear" }
            MouseArea {
                anchors.fill: parent
                enabled: sheetRoot.tableRows.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: sheetRoot.clearRowsRequested()
            }
        }
    }

    // =========================================================================
    // 3. LIVE DUPLICATE WARNING BANNER (Matching PortalSpreadsheetTable)
    // =========================================================================
    Rectangle {
        visible: sheetRoot.duplicateAnalysis.dupRowCount > 0
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 4
        color: Theme.alpha(Theme.statusWarning, 0.16)
        border.color: Theme.statusWarning
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6
            Text { font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.terracottaGlow; text: "warning" }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Theme.textPrimary
                text: "DUPLICATE SAMPLE IDs DETECTED (" + sheetRoot.duplicateAnalysis.dupRowCount + " rows) — auto-disambiguated as (Sample 1), (Sample 2) on Cart / LIMS submission."
            }
        }
    }

    // =========================================================================
    // 4. INLINE EDITABLE SPREADSHEET TABLE + FULL-TABLE EXCEL DROP OVERLAY
    // =========================================================================
    Rectangle {
        id: tableContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radiusSm
        color: Theme.bgVoid
        border.color: tableDropArea.containsDrag ? Theme.statusGreen : Theme.borderCard
        border.width: tableDropArea.containsDrag ? 2 : 1
        clip: true

        DropArea {
            id: tableDropArea
            anchors.fill: parent
            z: 5
            onEntered: function(drag) {
                if (drag.hasUrls || drag.source === virtualXlsxChip) {
                    drag.acceptProposedAction();
                }
            }
            onDropped: function(drop) {
                if (drop.hasUrls && drop.urls.length > 0) {
                    sheetRoot.openExcelDrop(String(drop.urls[0]));
                    drop.acceptProposedAction();
                } else if (drop.source === virtualXlsxChip) {
                    sheetRoot.openSampleExcel();
                    drop.acceptProposedAction();
                }
            }
        }

        // Translucent Excel Drag-Over Visual Overlay
        Rectangle {
            visible: tableDropArea.containsDrag
            anchors.fill: parent
            z: 25
            color: Theme.alpha(Theme.paletteAccent, 0.18)
            border.color: Theme.paletteAccent
            border.width: 2
            radius: Theme.radiusSm

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontIcon
                    font.pixelSize: 34
                    color: Theme.paletteAccent
                    text: "upload_file"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontDisplay
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "Drop Excel File (.xlsx / .csv) Here to Fill Table"
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Sticky Header Row
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: Theme.bgSurface

                Row {
                    id: hdrRow
                    anchors.fill: parent
                    spacing: 0
                    readonly property bool showStock: sheetRoot.defaultForm === "solution"
                    readonly property bool showSec: sheetRoot.screeningMode === "secondary"

                    Item { width: 32; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "#" } }
                    Item { width: hdrRow.width - 32 - 96 - (hdrRow.showStock ? 98 : 0) - 72 - 96 - (hdrRow.showSec ? 132 : 0) - 56 - 68; height: parent.height
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.paletteAccent; text: "SAMPLE ID *" }
                    }
                    Item { width: 96; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "QUANTITY" } }
                    Item { width: 98; height: parent.height; visible: hdrRow.showStock; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "STOCK CONC" } }
                    Item { width: 72; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "SOLVENT" } }
                    Item { width: 96; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.terracottaGlow; text: hdrRow.showSec ? "START DOSE" : "TEST DOSE" } }
                    Item { width: 66; height: parent.height; visible: hdrRow.showSec; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "FOLD" } }
                    Item { width: 66; height: parent.height; visible: hdrRow.showSec; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "DIL PTS" } }
                    Item { width: 56; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "REPS" } }
                    Item { width: 68; height: parent.height; Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textDim; text: "ACTIONS" } }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

            // Empty State vs Inline Spreadsheet Rows
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    visible: sheetRoot.tableRows.length === 0
                    spacing: 6
                    width: parent.width - 48
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.fontIcon
                        font.pixelSize: 28
                        color: Theme.textDim
                        text: "table_rows"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.fontDisplay
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "No Compounds in Table Yet"
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        color: Theme.textDim
                        text: "Drag an Excel (.xlsx / .csv) file onto this table, drag 'Drop Batch.xlsx', click 'Paste Excel' to paste cells from clipboard, or click '+ Add Row' / 'Demo Batch'."
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 4
                    contentHeight: rowsStack.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: rowsStack
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: sheetRoot.tableRows

                            Rectangle {
                                id: spRow
                                required property int index
                                required property var modelData

                                readonly property string upperSid: String(modelData.sampleId || "").trim().toUpperCase()
                                readonly property bool isDup: upperSid !== "" && (sheetRoot.duplicateAnalysis.counts[upperSid] || 0) > 1
                                readonly property bool showStock: sheetRoot.defaultForm === "solution"
                                readonly property bool showSec: sheetRoot.screeningMode === "secondary"

                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 4
                                color: isDup ? Theme.alpha(Theme.statusWarning, 0.10)
                                     : (index % 2 === 0 ? Theme.bgSurface : Theme.bgCard)
                                border.color: isDup ? Theme.statusWarning : Theme.borderCard
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    spacing: 0

                                    // 1. Row Index
                                    Item {
                                        width: 32; height: parent.height
                                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: String(spRow.index + 1) }
                                    }

                                    // 2. Editable Sample ID
                                    Item {
                                        width: parent.width - 32 - 96 - (spRow.showStock ? 98 : 0) - 72 - 96 - (spRow.showSec ? 132 : 0) - 56 - 68
                                        height: parent.height

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 6

                                            Rectangle {
                                                Layout.preferredWidth: 8
                                                Layout.preferredHeight: 8
                                                radius: 4
                                                color: Theme.compoundPalette[spRow.index % Theme.compoundPalette.length]
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 24
                                                radius: 3
                                                color: Theme.bgVoid
                                                border.color: sidInput.activeFocus ? Theme.paletteAccent : (spRow.isDup ? Theme.statusWarning : Theme.borderSubtle)
                                                border.width: 1

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left; anchors.leftMargin: 6
                                                    visible: sidInput.text === "" && !sidInput.activeFocus
                                                    font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim
                                                    text: "CPD-..."
                                                }
                                                TextInput {
                                                    id: sidInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 6; anchors.rightMargin: 6
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    color: spRow.isDup ? Theme.terracottaGlow : Theme.textPrimary
                                                    selectByMouse: true
                                                    text: spRow.modelData.sampleId || ""
                                                    onEditingFinished: sheetRoot.rowUpdated(spRow.index, "sampleId", text.trim().toUpperCase())
                                                }
                                            }
                                        }
                                    }

                                    // 3. Editable Quantity + Unit Chip
                                    Item {
                                        width: 96; height: parent.height
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Rectangle {
                                                width: 48; height: 24; radius: 3
                                                color: Theme.bgVoid
                                                border.color: qtyIn.activeFocus ? Theme.paletteAccent : Theme.borderSubtle; border.width: 1
                                                TextInput {
                                                    id: qtyIn
                                                    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                                    verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                                                    font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; selectByMouse: true
                                                    text: String(spRow.modelData.quantity || "")
                                                    onEditingFinished: sheetRoot.rowUpdated(spRow.index, "quantity", text.trim())
                                                }
                                            }
                                            Rectangle {
                                                width: 34; height: 24; radius: 3
                                                color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textSecondary; text: spRow.modelData.quantityUnit }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "quantityUnit") }
                                            }
                                        }
                                    }

                                    // 4. Stock Conc + Unit Chip (Solution mode)
                                    Item {
                                        width: 98; height: parent.height
                                        visible: spRow.showStock
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Rectangle {
                                                width: 48; height: 24; radius: 3
                                                color: Theme.bgVoid
                                                border.color: stkIn.activeFocus ? Theme.paletteAccent : Theme.borderSubtle; border.width: 1
                                                TextInput {
                                                    id: stkIn
                                                    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                                    verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                                                    font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; selectByMouse: true
                                                    text: String(spRow.modelData.stockConc || "")
                                                    onEditingFinished: sheetRoot.rowUpdated(spRow.index, "stockConc", text.trim())
                                                }
                                            }
                                            Rectangle {
                                                width: 34; height: 24; radius: 3
                                                color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                                Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.textSecondary; text: spRow.modelData.stockUnit }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "stockUnit") }
                                            }
                                        }
                                    }

                                    // 5. Solvent Chip (Click to cycle)
                                    Item {
                                        width: 72; height: parent.height
                                        Rectangle {
                                            anchors.centerIn: parent; width: 60; height: 24; radius: 3
                                            color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.paletteAccent; text: spRow.modelData.solvent }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "solvent") }
                                        }
                                    }

                                    // 6. Editable Start / Test Dose (µM)
                                    Item {
                                        width: 96; height: parent.height
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Rectangle {
                                                width: 52; height: 24; radius: 3
                                                color: Theme.bgVoid
                                                border.color: doseIn.activeFocus ? Theme.paletteAccent : Theme.borderSubtle; border.width: 1
                                                TextInput {
                                                    id: doseIn
                                                    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                                    verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                                                    font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.terracottaGlow; selectByMouse: true
                                                    text: String(spRow.modelData.startDose)
                                                    onEditingFinished: {
                                                        var num = parseFloat(text);
                                                        if (!isNaN(num) && num > 0) sheetRoot.rowUpdated(spRow.index, "startDose", num);
                                                    }
                                                }
                                            }
                                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "µM" }
                                        }
                                    }

                                    // 7. Dilution Fold (Secondary mode)
                                    Item {
                                        width: 66; height: parent.height
                                        visible: spRow.showSec
                                        Rectangle {
                                            anchors.centerIn: parent; width: 54; height: 24; radius: 3
                                            color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary; text: spRow.modelData.dilutionFold + "x" }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "dilutionFold") }
                                        }
                                    }

                                    // 8. Dilution Points (Secondary mode)
                                    Item {
                                        width: 66; height: parent.height
                                        visible: spRow.showSec
                                        Rectangle {
                                            anchors.centerIn: parent; width: 54; height: 24; radius: 3
                                            color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: spRow.modelData.nbDilutions + "-pt" }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "nbDilutions") }
                                        }
                                    }

                                    // 9. Replicates
                                    Item {
                                        width: 56; height: parent.height
                                        Rectangle {
                                            anchors.centerIn: parent; width: 44; height: 24; radius: 3
                                            color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                                            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textPrimary; text: spRow.modelData.nbReplicates + "x" }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sheetRoot.rowFieldCycled(spRow.index, "nbReplicates") }
                                        }
                                    }

                                    // 10. Row Actions: Duplicate + Delete
                                    Item {
                                        width: 68; height: parent.height
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Rectangle {
                                                width: 24; height: 24; radius: 4
                                                color: dupMouse.containsMouse ? Theme.alpha(Theme.paletteAccent, 0.20) : Theme.bgVoid
                                                border.color: Theme.borderCard; border.width: 1
                                                Text { anchors.centerIn: parent; font.family: Theme.fontIcon; font.pixelSize: 13; color: Theme.textSecondary; text: "content_copy" }
                                                MouseArea {
                                                    id: dupMouse
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: sheetRoot.duplicateRowRequested(spRow.index)
                                                }
                                            }
                                            Rectangle {
                                                width: 24; height: 24; radius: 4
                                                color: delMouse.containsMouse ? Theme.alpha(Theme.cinnabar, 0.22) : Theme.bgVoid
                                                border.color: delMouse.containsMouse ? Theme.cinnabar : Theme.borderCard; border.width: 1
                                                Text { anchors.centerIn: parent; font.family: Theme.fontIcon; font.pixelSize: 13; color: delMouse.containsMouse ? Theme.cinnabar : Theme.textMuted; text: "delete_outline" }
                                                MouseArea {
                                                    id: delMouse
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: sheetRoot.removeRowRequested(spRow.index)
                                                }
                                            }
                                        }
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
    // 5. FOOTER METRICS & ADD TO CART BAR (Matching PortalProductPageView)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: Theme.radiusSm
        color: Theme.bgSurface
        border.color: Theme.borderCard
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Theme.textPrimary
                text: sheetRoot.tableRows.length + " sample(s)  •  " + sheetRoot.estimatedDatapoints + " pts  •  " + sheetRoot.estimatedPlates + " plate (96w)"
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.family: Theme.fontMono
                font.pixelSize: 9
                color: sheetRoot.statusBanner !== "" ? Theme.statusGreen : Theme.textDim
                text: sheetRoot.statusBanner !== "" ? ("✓ " + sheetRoot.statusBanner) : "Click any unit/dose cell to edit inline"
            }

            Rectangle {
                readonly property bool canAdd: sheetRoot.estimatedDatapoints > 0
                Layout.preferredWidth: 196
                Layout.preferredHeight: 32
                radius: Theme.radiusPill
                color: Theme.bgCard
                border.color: canAdd ? Theme.paletteAccent : Theme.borderCard
                border.width: 1
                opacity: canAdd ? 1.0 : 0.45
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: parent.canAdd ? Theme.paletteAccent : Theme.textDim
                    text: "+ Add to Cart & Browse More"
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: parent.canAdd
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: sheetRoot.addToCartRequested(false)
                }
            }

            Rectangle {
                readonly property bool canAdd: sheetRoot.estimatedDatapoints > 0
                Layout.preferredWidth: 212
                Layout.preferredHeight: 32
                radius: Theme.radiusPill
                color: canAdd ? Theme.cinnabar : Theme.bgSurface
                border.color: canAdd ? Theme.terracottaGlow : Theme.borderCard
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: parent.canAdd ? Theme.textOnCinnabar : Theme.textDim
                    text: "Add to Cart & Review Order ➔"
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: parent.canAdd
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: sheetRoot.addToCartRequested(true)
                }
            }
        }
    }
}
