import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

Rectangle {
    id: portalFlowRoot

    implicitWidth: 1040
    implicitHeight: 700
    radius: Theme.radiusMd
    color: Theme.bgCard
    border.color: Theme.glassBorder
    border.width: 1
    clip: true

    signal simulateGwlOn3D(var gwlJob)

    // =========================================================================
    // WORKFLOW STATE (Mirrors InvenesisClientPortal -> Company LIMS -> Results)
    // =========================================================================
    property int currentStage: 0 // 0: Catalogue, 1: Compound Table, 2: Cart & Send, 3: Plate & 3D GWL, 4: Lab QC, 5: Results & 4PL
    property string categoryFilter: "All"
    property string catalogSearch: ""
    property string projectCode: "PRJ-2026-042"
    property string quoteNumber: "Q2026-01"

    // Step 1: Validated Screening Assays Catalogue
    property var assayCatalogue: [
        { code: "ASY-101", name: "Motility Phenotypic Screen",  category: "Phenotypic",       format: "96-well",  vol: "50 µL",  dmsoMax: "1.0%" },
        { code: "ASY-102", name: "Cell Viability & Toxicity",   category: "Phenotypic",       format: "96-well",  vol: "40 µL",  dmsoMax: "0.8%" },
        { code: "ASY-204", name: "Ion Channel Patch / MEA",     category: "Electrophysiology",format: "96-well",  vol: "60 µL",  dmsoMax: "0.5%" },
        { code: "ASY-208", name: "Kinase Fluorescence Assay",   category: "Biochemical",      format: "384-well", vol: "20 µL",  dmsoMax: "1.5%" },
        { code: "ASY-301", name: "Receptor Binding HTRF",       category: "Biochemical",      format: "384-well", vol: "20 µL",  dmsoMax: "1.0%" },
        { code: "ASY-305", name: "Surface Contact Assay",       category: "Phenotypic",       format: "96-well",  vol: "50 µL",  dmsoMax: "1.0%" }
    ]

    // Step 2: Active Assay Product Page + Inline Editable Compound Spreadsheet
    property int activeAssayIndex: 0
    property string screeningMode: "secondary" // "primary" or "secondary"
    property string defaultForm: "solution"   // "solution" or "powder"
    property var productTableRows: []
    property string tableStatusBanner: ""
    property string studyRemarks: ""

    // Step 3: Client Study Cart
    property var cartItems: []

    // Step 4 -> 5 -> 6 Lifecycle Flags
    property bool batchSubmitted: false
    property bool plateReady: false
    property bool hitpick3dCompleted: false
    property bool analysisReady: false
    property bool resultsPublished: false
    property int compiledGwlLineCount: 0

    // Step 4, 5 & 6: Company LIMS SBS-96 Plate & Analyzed Readout State
    property var companyQueue: []
    property int selectedQueueIdx: 0
    property var companyPlateWells: [] // 96 items (8 rows x 12 cols)
    property var inspectedPlateWell: null
    property var analyzedResults: []
    property real plateZPrime: 0.79
    property real plateSbRatio: 6.4
    property real plateControlsCv: 3.1

    readonly property var rowLetters: ["A", "B", "C", "D", "E", "F", "G", "H"]
    readonly property var compoundProfiles: [
        { ic50: 0.42, emax: 96.5, hill: 1.35 },
        { ic50: 2.85, emax: 89.0, hill: 1.15 },
        { ic50: 18.4, emax: 54.0, hill: 0.95 },
        { ic50: 0.19, emax: 98.2, hill: 1.50 },
        { ic50: 42.0, emax: 28.0, hill: 0.85 },
        { ic50: 1.15, emax: 93.4, hill: 1.25 }
    ]

    readonly property var selectedAssayObj: (activeAssayIndex >= 0 && activeAssayIndex < assayCatalogue.length)
                                            ? assayCatalogue[activeAssayIndex] : assayCatalogue[0]

    readonly property int totalCartDatapoints: {
        var sum = 0;
        for (var i = 0; i < cartItems.length; ++i) sum += cartItems[i].datapoints;
        return sum;
    }

    readonly property int placedQueueCount: {
        var c = 0;
        for (var i = 0; i < companyQueue.length; ++i) {
            if (companyQueue[i].placedRow >= 0) c++;
        }
        return c;
    }

    readonly property string batchStatusText: {
        if (resultsPublished) return "COMPLETED • CLIENT RESULTS LIVE";
        if (analysisReady)    return "READOUT ANALYZED";
        if (hitpick3dCompleted) return "3D GWL HITPICK DONE";
        if (plateReady)       return "PLATED ON SBS-96";
        if (batchSubmitted)   return "SUBMITTED (" + requestId + ")";
        if (cartItems.length > 0) return "IN CART (" + cartItems.length + ")";
        return "DRAFT";
    }

    property string requestId: "REQ-2026-042"

    readonly property color batchStatusColor: {
        if (resultsPublished) return Theme.statusGreen;
        if (analysisReady || hitpick3dCompleted || plateReady || batchSubmitted) return Theme.paletteAccent;
        if (cartItems.length > 0) return Theme.terracottaGlow;
        return Theme.textMuted;
    }

    readonly property int maxUnlockedStage: {
        if (resultsPublished) return 5;
        if (analysisReady) return 4;
        if (batchSubmitted) return 3;
        if (cartItems.length > 0) return 2;
        return 1; // Assay 0 & starter batch ready immediately so stage 1/2 transition is seamless
    }

    Component.onCompleted: resetWorkflow()

    // =========================================================================
    // WORKFLOW & SPREADSHEET LOGIC
    // =========================================================================
    function makeDefaultRows() {
        return [
            { sampleId: "CPD-901", quantity: "100", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "DMSO", startDose: 30.0, dilutionFold: 3.16, nbDilutions: 6, nbReplicates: 2 },
            { sampleId: "CPD-902", quantity: "100", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "DMSO", startDose: 30.0, dilutionFold: 3.16, nbDilutions: 6, nbReplicates: 2 },
            { sampleId: "CPD-903", quantity: "50",  quantityUnit: "µL", stockConc: "5",  stockUnit: "mM", solvent: "EtOH", startDose: 100.0, dilutionFold: 3.16, nbDilutions: 6, nbReplicates: 2 }
        ];
    }

    function resetWorkflow() {
        currentStage = 0;
        categoryFilter = "All";
        catalogSearch = "";
        projectCode = "PRJ-2026-042";
        quoteNumber = "Q2026-01";
        activeAssayIndex = 0;
        screeningMode = "secondary";
        defaultForm = "solution";
        productTableRows = makeDefaultRows();
        tableStatusBanner = "";
        studyRemarks = "";
        cartItems = [];
        batchSubmitted = false;
        plateReady = false;
        hitpick3dCompleted = false;
        analysisReady = false;
        resultsPublished = false;
        compiledGwlLineCount = 0;
        companyQueue = [];
        selectedQueueIdx = 0;
        companyPlateWells = [];
        inspectedPlateWell = null;
        analyzedResults = [];
    }

    function openAssayProductPage(idx) {
        if (idx >= 0 && idx < assayCatalogue.length) {
            activeAssayIndex = idx;
        }
        if (productTableRows.length === 0) {
            productTableRows = makeDefaultRows();
        }
        tableStatusBanner = "";
        currentStage = 1;
    }

    function isAssayInCart(code) {
        for (var i = 0; i < cartItems.length; ++i) {
            if (cartItems[i].assayCode === code) return true;
        }
        return false;
    }

    function setScreeningMode(newMode) {
        screeningMode = newMode;
        var next = productTableRows.slice();
        for (var i = 0; i < next.length; ++i) {
            var item = Object.assign({}, next[i]);
            if (newMode === "secondary") {
                if (item.nbDilutions <= 1) item.nbDilutions = 6;
                if (item.dilutionFold <= 1.0) item.dilutionFold = 3.16;
            } else {
                item.nbDilutions = 1;
                item.dilutionFold = 1.0;
            }
            next[i] = item;
        }
        productTableRows = next;
    }

    function setDefaultForm(newForm) {
        defaultForm = newForm;
        var next = productTableRows.slice();
        for (var i = 0; i < next.length; ++i) {
            var item = Object.assign({}, next[i]);
            if (newForm === "powder") {
                item.quantityUnit = (item.quantityUnit === "g") ? "g" : "mg";
                if (item.quantity === "100") item.quantity = "10";
                item.stockConc = "";
            } else {
                item.quantityUnit = (item.quantityUnit === "mL") ? "mL" : "µL";
                if (item.quantity === "10") item.quantity = "100";
                if (item.stockConc === "") item.stockConc = "10";
                if (!item.stockUnit) item.stockUnit = "mM";
            }
            next[i] = item;
        }
        productTableRows = next;
    }

    function addBlankTableRow() {
        if (productTableRows.length >= 8) {
            tableStatusBanner = "Max 8 rows per SBS-96 plate demo batch reached.";
            return;
        }
        var next = productTableRows.slice();
        var isPow = (defaultForm === "powder");
        next.push({
            sampleId: "CPD-" + (901 + next.length),
            quantity: isPow ? "10" : "100",
            quantityUnit: isPow ? "mg" : "µL",
            stockConc: isPow ? "" : "10",
            stockUnit: "mM",
            solvent: "DMSO",
            startDose: 30.0,
            dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0,
            nbDilutions: screeningMode === "secondary" ? 6 : 1,
            nbReplicates: 2
        });
        productTableRows = next;
        tableStatusBanner = "";
    }

    function duplicateTableRow(idx) {
        if (idx < 0 || idx >= productTableRows.length || productTableRows.length >= 8) return;
        var src = productTableRows[idx];
        var next = productTableRows.slice();
        var copy = Object.assign({}, src);
        copy.sampleId = src.sampleId ? (src.sampleId + "_COPY") : "CPD-NEW";
        next.splice(idx + 1, 0, copy);
        productTableRows = next;
        tableStatusBanner = "Duplicated row " + (idx + 1);
    }

    function removeTableRow(idx) {
        if (idx < 0 || idx >= productTableRows.length) return;
        var next = productTableRows.slice();
        next.splice(idx, 1);
        productTableRows = next;
        tableStatusBanner = "";
    }

    function updateTableRow(idx, field, val) {
        if (idx < 0 || idx >= productTableRows.length) return;
        var next = productTableRows.slice();
        var item = Object.assign({}, next[idx]);
        item[field] = val;
        next[idx] = item;
        productTableRows = next;
    }

    function cycleTableRowField(idx, field) {
        if (idx < 0 || idx >= productTableRows.length) return;
        var row = productTableRows[idx];
        var options = [];
        if (field === "solvent") options = ["DMSO", "EtOH", "H2O", "None"];
        else if (field === "quantityUnit") options = (defaultForm === "powder") ? ["mg", "g"] : ["µL", "mL"];
        else if (field === "stockUnit") options = ["mM", "µM"];
        else if (field === "dilutionFold") options = [2.0, 3.16, 10.0];
        else if (field === "nbDilutions") options = [4, 6, 8];
        else if (field === "nbReplicates") options = [1, 2, 3];
        if (options.length === 0) return;

        var cur = row[field];
        var nextIdx = 0;
        for (var i = 0; i < options.length; ++i) {
            if (options[i] === cur || (typeof cur === "number" && Math.abs(cur - options[i]) < 0.05)) {
                nextIdx = (i + 1) % options.length;
                break;
            }
        }
        updateTableRow(idx, field, options[nextIdx]);
    }

    function loadDemoTableBatch() {
        productTableRows = [
            { sampleId: "CPD-901", quantity: "100", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "DMSO", startDose: 30.0,  dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0, nbDilutions: screeningMode === "secondary" ? 6 : 1, nbReplicates: 2 },
            { sampleId: "CPD-902", quantity: "100", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "DMSO", startDose: 30.0,  dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0, nbDilutions: screeningMode === "secondary" ? 6 : 1, nbReplicates: 2 },
            { sampleId: "CPD-903", quantity: "50",  quantityUnit: "µL", stockConc: "5",  stockUnit: "mM", solvent: "EtOH", startDose: 100.0, dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0, nbDilutions: screeningMode === "secondary" ? 6 : 1, nbReplicates: 2 },
            { sampleId: "CPD-904", quantity: "100", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "DMSO", startDose: 10.0,  dilutionFold: screeningMode === "secondary" ? 2.0  : 1.0, nbDilutions: screeningMode === "secondary" ? 8 : 1, nbReplicates: 2 },
            { sampleId: "CPD-905", quantity: "120", quantityUnit: "µL", stockConc: "10", stockUnit: "mM", solvent: "H2O",  startDose: 30.0,  dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0, nbDilutions: screeningMode === "secondary" ? 6 : 1, nbReplicates: 3 }
        ];
        tableStatusBanner = "Loaded 5-compound demo batch into spreadsheet.";
    }

    function clearTableRows() {
        productTableRows = [];
        tableStatusBanner = "";
    }

    // Excel / CSV Drop & Validation Overlay Helpers
    function buildSampleExcelRows() {
        return [
            { id: "CPD-901", solvent: "DMSO", stock: "10 mM", vol: "100 µL", form: "Solution" },
            { id: "CPD-902", solvent: "DMSO", stock: "10 mM", vol: "100 µL", form: "Solution" },
            { id: "CPD-902", solvent: "DMSO", stock: "10 mM", vol: "80 µL",  form: "Solution" },
            { id: "CPD-903", solvent: "EtOH", stock: "5 mM",  vol: "50 µL",  form: "Solution" },
            { id: "CPD-905", solvent: "H2O",  stock: "10 mM", vol: "120 µL", form: "Solution" },
            { id: "CPD-906", solvent: "DMSO", stock: "5 mM",  vol: "2.5 mg", form: "Powder" }
        ];
    }

    function parseDelimitedTextRows(text) {
        var lines = String(text || "").split(/\r?\n/);
        var parsed = [];
        var delim = ",";
        if (lines.length > 0 && lines[0].indexOf("\t") !== -1) delim = "\t";
        else if (lines.length > 0 && lines[0].indexOf(";") !== -1) delim = ";";

        var startRow = 0;
        var colMap = { id: 0, solvent: 1, stock: 2, vol: 3, form: 4 };
        if (lines.length > 0) {
            var hdr = lines[0].toLowerCase();
            if (hdr.indexOf("compound") !== -1 || hdr.indexOf("sample") !== -1 || hdr.indexOf("id") !== -1) {
                var hParts = lines[0].split(delim);
                for (var h = 0; h < hParts.length; ++h) {
                    var k = hParts[h].trim().toLowerCase();
                    if (k.indexOf("id") !== -1 || k.indexOf("compound") !== -1 || k.indexOf("sample") !== -1) colMap.id = h;
                    else if (k.indexOf("solv") !== -1 || k.indexOf("vehicle") !== -1) colMap.solvent = h;
                    else if (k.indexOf("stock") !== -1 || k.indexOf("conc") !== -1) colMap.stock = h;
                    else if (k.indexOf("vol") !== -1 || k.indexOf("qty") !== -1) colMap.vol = h;
                    else if (k.indexOf("form") !== -1) colMap.form = h;
                }
                startRow = 1;
            }
        }
        for (var i = startRow; i < lines.length && parsed.length < 8; ++i) {
            var line = lines[i].trim();
            if (line === "") continue;
            var parts = line.split(delim);
            var cid = parts.length > colMap.id ? parts[colMap.id].trim().toUpperCase() : "";
            if (cid === "") continue;
            parsed.push({
                id: cid,
                solvent: parts.length > colMap.solvent && parts[colMap.solvent].trim() !== "" ? parts[colMap.solvent].trim() : "DMSO",
                stock: parts.length > colMap.stock && parts[colMap.stock].trim() !== "" ? parts[colMap.stock].trim() : "10 mM",
                vol: parts.length > colMap.vol && parts[colMap.vol].trim() !== "" ? parts[colMap.vol].trim() : "100 µL",
                form: parts.length > colMap.form && parts[colMap.form].trim() !== "" ? parts[colMap.form].trim() : "Solution"
            });
        }
        return parsed;
    }

    function handleDroppedUrl(rawUrl) {
        var s = String(rawUrl || "");
        var cleanPath = s.split("?")[0];
        var slashIdx = Math.max(cleanPath.lastIndexOf("/"), cleanPath.lastIndexOf("\\"));
        var fileName = slashIdx >= 0 ? cleanPath.substring(slashIdx + 1) : cleanPath;
        if (fileName === "") fileName = "Dropped_Compounds.xlsx";
        var lower = fileName.toLowerCase();

        if (lower.endsWith(".csv") || lower.endsWith(".tsv") || lower.endsWith(".txt")) {
            try {
                var xhr = new XMLHttpRequest();
                xhr.open("GET", s, false);
                xhr.send();
                var textRows = parseDelimitedTextRows(xhr.responseText);
                if (textRows.length > 0) {
                    excelPreviewOverlay.openWithBatch(
                        fileName,
                        textRows,
                        "CSV/TSV PARSER: Read " + textRows.length + " rows directly from file • Duplicate & vehicle checks active"
                    );
                    return;
                }
            } catch (e) {
                // Fall through cleanly to workbook simulation in WASM / sandboxed mode
            }
        }

        excelPreviewOverlay.openWithBatch(
            fileName,
            buildSampleExcelRows(),
            "WORKBOOK SHEET1 INGESTED (" + fileName + ") • ALIAS MAPPING & DUPLICATE CHECK ACTIVE"
        );
    }

    function importConfirmedExcelBatch(importedRows, remarks) {
        var next = [];
        for (var i = 0; i < importedRows.length && next.length < 8; ++i) {
            var r = importedRows[i];
            var volParts = String(r.vol || "100 µL").split(/\s+/);
            var stkParts = String(r.stock || "10 mM").split(/\s+/);
            next.push({
                sampleId: r.id,
                quantity: volParts[0] || "100",
                quantityUnit: volParts[1] || "µL",
                stockConc: defaultForm === "powder" ? "" : (stkParts[0] || "10"),
                stockUnit: stkParts[1] || "mM",
                solvent: r.solvent || "DMSO",
                startDose: 30.0,
                dilutionFold: screeningMode === "secondary" ? 3.16 : 1.0,
                nbDilutions: screeningMode === "secondary" ? 6 : 1,
                nbReplicates: 2
            });
        }
        productTableRows = next;
        if (remarks !== "") studyRemarks = remarks;
        tableStatusBanner = "Imported " + next.length + " row(s) from " + excelPreviewOverlay.fileName;
    }

    function appendParsedTsvRows(rows) {
        var next = productTableRows.slice();
        var added = 0;
        for (var i = 0; i < rows.length && next.length < 8; ++i) {
            next.push(Object.assign({}, rows[i]));
            added++;
        }
        productTableRows = next;
        tableStatusBanner = "Pasted " + added + " Excel row(s) into spreadsheet table.";
    }

    function addCurrentProductToCart(goToCart) {
        var validRows = [];
        var counts = {};
        for (var i = 0; i < productTableRows.length; ++i) {
            var sid = String(productTableRows[i].sampleId || "").trim().toUpperCase();
            if (sid === "") continue;
            counts[sid] = (counts[sid] || 0) + 1;
            validRows.push(Object.assign({}, productTableRows[i], { sampleId: sid }));
        }
        if (validRows.length === 0) return;

        // Disambiguate duplicate Sample IDs exactly like PortalExcelPreviewDialog / PortalSpreadsheetTable
        var seen = {};
        var totalPts = 0;
        var disambiguated = [];
        for (var j = 0; j < validRows.length; ++j) {
            var row = validRows[j];
            var base = row.sampleId;
            if ((counts[base] || 0) > 1) {
                seen[base] = (seen[base] || 0) + 1;
                row.sampleId = base + " (Sample " + seen[base] + ")";
            }
            var dils = screeningMode === "secondary" ? row.nbDilutions : 1;
            totalPts += dils * row.nbReplicates;
            disambiguated.push(row);
        }

        var nextCart = cartItems.slice();
        nextCart.push({
            bundleId: "REQ-" + (nextCart.length + 1),
            assayIndex: activeAssayIndex,
            assayCode: selectedAssayObj.code,
            assayName: selectedAssayObj.name,
            screeningMode: screeningMode,
            defaultForm: defaultForm,
            projectCode: projectCode,
            quoteNumber: quoteNumber,
            rows: disambiguated,
            datapoints: totalPts
        });
        cartItems = nextCart;

        if (goToCart) {
            currentStage = 2;
        } else {
            tableStatusBanner = "Added " + selectedAssayObj.code + " (" + disambiguated.length + " compounds) to Cart.";
            currentStage = 0;
        }
    }

    function editCartBundle(idx) {
        if (idx < 0 || idx >= cartItems.length) return;
        var bundle = cartItems[idx];
        activeAssayIndex = bundle.assayIndex;
        screeningMode = bundle.screeningMode;
        defaultForm = bundle.defaultForm;
        projectCode = bundle.projectCode;
        quoteNumber = bundle.quoteNumber;
        var restored = [];
        for (var i = 0; i < bundle.rows.length; ++i) {
            restored.push(Object.assign({}, bundle.rows[i]));
        }
        productTableRows = restored;
        removeCartItem(idx);
        tableStatusBanner = "Loaded " + bundle.assayCode + " back into spreadsheet for editing.";
        currentStage = 1;
    }

    function removeCartItem(idx) {
        if (idx < 0 || idx >= cartItems.length) return;
        var next = cartItems.slice();
        next.splice(idx, 1);
        cartItems = next;
    }

    function buildSubmissionPayloadJson() {
        var studies = [];
        for (var i = 0; i < cartItems.length; ++i) {
            var b = cartItems[i];
            var cmps = [];
            for (var j = 0; j < b.rows.length; ++j) cmps.push(b.rows[j].sampleId);
            studies.push({
                request: b.bundleId,
                assay_code: b.assayCode,
                mode: b.screeningMode,
                form: b.defaultForm,
                quote_number: b.quoteNumber,
                samples: cmps,
                datapoints: b.datapoints
            });
        }
        return JSON.stringify({
            endpoint: "POST /api/v1/batches/submit",
            project_code: projectCode,
            batch_id: requestId,
            well_coordinate_space: "A1-P24",
            remarks: studyRemarks,
            total_datapoints: totalCartDatapoints,
            requests: studies,
            validation: "DUPLICATE_AND_SOLVENT_RULES_PASSED"
        }, null, 2);
    }

    function submitOrderToCompany() {
        if (cartItems.length === 0) return;

        batchSubmitted = true;

        // Deterministic source tube slots distributed across BOTH yellow Matrix racks (Batch_21)
        var sourceSlots = [
            { rack: 1, rackName: "Matrix_Rack[001]", row: 1, col: 2 },
            { rack: 2, rackName: "Matrix_Rack[002]", row: 3, col: 6 },
            { rack: 1, rackName: "Matrix_Rack[001]", row: 5, col: 9 },
            { rack: 2, rackName: "Matrix_Rack[002]", row: 0, col: 1 },
            { rack: 1, rackName: "Matrix_Rack[001]", row: 2, col: 5 },
            { rack: 2, rackName: "Matrix_Rack[002]", row: 4, col: 10 },
            { rack: 1, rackName: "Matrix_Rack[001]", row: 6, col: 3 },
            { rack: 2, rackName: "Matrix_Rack[002]", row: 2, col: 8 }
        ];

        var queue = [];
        var colorIdx = 0;
        for (var i = 0; i < cartItems.length; ++i) {
            var bundle = cartItems[i];
            for (var j = 0; j < bundle.rows.length && queue.length < 8; ++j) {
                var r = bundle.rows[j];
                var slot = sourceSlots[colorIdx % sourceSlots.length];
                queue.push({
                    id: r.sampleId,
                    solvent: r.solvent,
                    stock: r.stockConc ? (r.stockConc + " " + r.stockUnit) : "Powder",
                    color: Theme.compoundPalette[colorIdx % Theme.compoundPalette.length],
                    assay: bundle.assayCode,
                    screeningMode: bundle.screeningMode,
                    startConc: r.startDose,
                    dilutions: bundle.screeningMode === "secondary" ? r.nbDilutions : 1,
                    replicates: r.nbReplicates,
                    dilutionFold: r.dilutionFold > 1.0 ? r.dilutionFold : 3.16,
                    srcRack: slot.rack,
                    srcRackName: slot.rackName,
                    srcRow: slot.row,
                    srcCol: slot.col,
                    srcWell: formatWell96(slot.row, slot.col),
                    placedRow: -1
                });
                colorIdx++;
            }
        }
        companyQueue = queue;
        selectedQueueIdx = 0;
        initializeEmptyCompanyPlate();
        plateReady = false;
        hitpick3dCompleted = false;
        analysisReady = false;
        resultsPublished = false;
        compiledGwlLineCount = 0;
        currentStage = 3;
    }

    function formatWell96(r, c) {
        return rowLetters[r] + (c < 9 ? "0" : "") + (c + 1);
    }

    function initializeEmptyCompanyPlate() {
        var wells = [];
        for (var r = 0; r < 8; ++r) {
            for (var c = 0; c < 12; ++c) {
                var isNeg = (c === 0);
                var isPos = (c === 11);
                wells.push({
                    row: r,
                    col: c,
                    wellId: formatWell96(r, c),
                    isControl: (isNeg || isPos),
                    controlType: isNeg ? "DMSO" : (isPos ? "STD" : ""),
                    compoundId: "",
                    assay: "",
                    queueIdx: -1,
                    step: -1,
                    concUm: 0.0,
                    volUl: isNeg || isPos ? 30.0 : 0.0,
                    inhibition: isNeg ? 2.4 : (isPos ? 97.8 : 0.0),
                    color: Theme.bgVoid
                });
            }
        }
        companyPlateWells = wells;
        inspectedPlateWell = wells[0];
    }

    function placeQueueCompoundInRow(qIdx, targetRow) {
        if (qIdx < 0 || qIdx >= companyQueue.length) return;
        if (targetRow < 0 || targetRow >= 8) return;

        var wells = companyPlateWells.slice();
        var q = companyQueue.slice();

        for (var i = 0; i < 96; ++i) {
            var w = wells[i];
            if (!w.isControl && (w.queueIdx === qIdx || w.row === targetRow)) {
                wells[i] = {
                    row: w.row, col: w.col, wellId: w.wellId,
                    isControl: false, controlType: "",
                    compoundId: "", assay: "", queueIdx: -1,
                    step: -1, concUm: 0.0, volUl: 0.0, inhibition: 0.0, color: Theme.bgVoid
                };
            }
        }

        for (var k = 0; k < q.length; ++k) {
            var qCopy = Object.assign({}, q[k]);
            if (qCopy.placedRow === targetRow) qCopy.placedRow = -1;
            if (k === qIdx) qCopy.placedRow = targetRow;
            q[k] = qCopy;
        }

        var cmp = q[qIdx];
        var steps = Math.max(1, Math.min(10, cmp.dilutions));
        var fold = cmp.dilutionFold > 1.0 ? cmp.dilutionFold : 3.162;
        for (var s = 0; s < steps; ++s) {
            var col = 1 + s;
            var idx = targetRow * 12 + col;
            var conc = cmp.startConc / Math.pow(fold, s);
            wells[idx] = {
                row: targetRow, col: col, wellId: formatWell96(targetRow, col),
                isControl: false, controlType: "",
                compoundId: cmp.id, assay: cmp.assay, queueIdx: qIdx,
                step: s, concUm: conc, volUl: s === 0 ? 45.0 : 30.0,
                inhibition: 0.0, color: cmp.color
            };
        }

        companyQueue = q;
        companyPlateWells = wells;
        plateReady = placedQueueCount > 0;
        inspectedPlateWell = wells[targetRow * 12 + 1];
        compiledGwlLineCount = plateReady ? buildCompiledGwlJob().gwlLines.length : 0;

        for (var n = 0; n < q.length; ++n) {
            if (q[n].placedRow < 0) {
                selectedQueueIdx = n;
                break;
            }
        }
    }

    function autoPlaceAllOnPlate() {
        initializeEmptyCompanyPlate();
        var q = companyQueue.slice();
        for (var k = 0; k < q.length && k < 8; ++k) {
            var qCopy = Object.assign({}, q[k]);
            qCopy.placedRow = -1;
            q[k] = qCopy;
        }
        companyQueue = q;
        for (var i = 0; i < companyQueue.length && i < 8; ++i) {
            placeQueueCompoundInRow(i, i);
        }
    }

    function buildCompiledGwlJob() {
        var gwlLines = [];
        var steps = [];
        // Verified CAD safe heights (LiHa_Tips -90.8 => Z_tip = 160.9 mm > 113 mm tallest obstacle)
        var SAFE_Z = 251.70;
        var PARK_Z = 207.10;
        var PLATE_HOVER_Z = 121.70;
        var PLATE_DISP_Z = 104.20;
        var MATRIX_ASP_Z = 169.30; // Z_tip = 78.5 mm inside yellow Matrix tube [69.7..94.7]
        var TIP_PICK_Z = 99.20;
        var TROUGH_ASP_Z = 179.95;
        var WASTE_DROP_Z = 168.00;

        var allEightMask = [true, true, true, true, true, true, true, true];
        var noneMask = [false, false, false, false, false, false, false, false];
        var placedMask = [false, false, false, false, false, false, false, false];
        var placedItems = [];
        var maxDilSteps = 1;

        for (var qIdx = 0; qIdx < companyQueue.length; ++qIdx) {
            var cItem = companyQueue[qIdx];
            if (cItem.placedRow >= 0 && cItem.placedRow < 8) {
                placedItems.push(cItem);
                placedMask[cItem.placedRow] = true;
                var cDil = Math.max(1, Math.min(10, cItem.dilutions));
                if (cDil > maxDilSteps) maxDilSteps = cDil;
            }
        }
        placedItems.sort(function(a, b) { return a.placedRow - b.placedRow; });

        var placedCount = placedItems.length;
        var placedRowNames = [];
        for (var pi = 0; pi < placedItems.length; ++pi) {
            placedRowNames.push(rowLetters[placedItems[pi].placedRow]);
        }
        var placedLabel = placedCount + " Tips (Row" + (placedCount === 1 ? " " : "s ") + placedRowNames.join(",") + ")";

        function masksEqual(a, b) {
            for (var mi = 0; mi < 8; ++mi) {
                if (Boolean(a[mi]) !== Boolean(b[mi])) return false;
            }
            return true;
        }

        gwlLines.push("C; Tecan Fluent 1080 HITPICK & SERIAL DILUTION " + requestId + " (" + projectCode + ")");
        gwlLines.push("C; Ph1: All 8 Tips DMSO Prep -> Ph2: Change to " + placedCount + " Tips -> Ph3: Single-Tip Matrix Asp -> Ph4: Parallel Dilution");

        // =====================================================================
        // PHASE 1: Take all 8 tips at once -> Distribute DMSO across plate -> Eject all 8 tips
        // =====================================================================
        var ph1TipIdx = gwlLines.length;
        gwlLines.push("C; Ph1 Mount ALL 8 DiTi tips @ TipRack[001] Col 1 (DMSO & Diluent Prep)");
        steps.push({
            label: "Phase 1: Mount ALL 8 Tips @ TipRack Col 1 [159.7, 404.8]",
            channelLabel: "All 8 Tips (Ch1–8)",
            compoundId: "8x DiTi MOUNT",
            wellId: "TipRack Col 1",
            concText: "DMSO Prep",
            color: Theme.paletteAccent,
            x: 159.73, y: 404.78, transitZ: PARK_Z, dipZ: TIP_PICK_Z, retractZ: SAFE_Z,
            activeMask: allEightMask,
            tipsMaskAfterDip: allEightMask,
            moveMs: 620, dipMs: 280, retractMs: 260,
            gwlLineIdx: ph1TipIdx
        });

        var dmsoAspIdx = gwlLines.length;
        gwlLines.push("A;100ml_Higher;;All8_DMSO;240.0;Aspirate DMSO diluent with Ch1..8");
        steps.push({
            label: "Phase 1: Aspirate DMSO w/ ALL 8 Tips @ 100ml_Higher [123.0, 289.5]",
            channelLabel: "All 8 Tips (Ch1–8)",
            compoundId: "DMSO DILUENT",
            wellId: "100ml_Higher",
            concText: "8 × 240 µL",
            color: Theme.goldAccent,
            x: 123.00, y: 289.50, transitZ: SAFE_Z, dipZ: TROUGH_ASP_Z, retractZ: SAFE_Z,
            activeMask: allEightMask,
            tipsMaskAfterDip: allEightMask,
            moveMs: 500, dipMs: 240, retractMs: 240,
            gwlLineIdx: dmsoAspIdx
        });

        // DMSO goes into Col 1 (DMSO Ctrl), serial dilution Cols 3..(1+maxDilSteps), and Col 12 (Pos STD buffer)
        var dmsoCols = [{ col: 0, tag: "Col 1 DMSO Ctrl", gwl: "D;Daughter[001];;A01-H01;30.0;DMSO Ctrl", clr: Theme.goldAccent }];
        for (var dc = 1; dc < maxDilSteps; ++dc) {
            var plateColIdx = 1 + dc; // dc=1 -> Col 3 (index 2)
            dmsoCols.push({
                col: plateColIdx,
                tag: "Col " + (plateColIdx + 1) + " Diluent",
                gwl: "D;Daughter[001];;Col" + (plateColIdx + 1) + " (A-H);30.0;Serial Diluent",
                clr: Theme.goldAccent
            });
        }
        dmsoCols.push({ col: 11, tag: "Col 12 STD Ctrl", gwl: "D;Daughter[001];;A12-H12;30.0;Pos STD Ctrl", clr: Theme.statusGreen });

        for (var di = 0; di < dmsoCols.length; ++di) {
            var dCol = dmsoCols[di];
            var isFirstD = (di === 0);
            var isLastD = (di === dmsoCols.length - 1);
            var dmsoDispIdx = gwlLines.length;
            gwlLines.push(dCol.gwl);
            steps.push({
                label: "Phase 1: Distribute DMSO w/ All 8 Tips -> " + dCol.tag,
                channelLabel: "All 8 Tips (Ch1–8)",
                compoundId: "DMSO PRE-FILL",
                wellId: dCol.tag,
                concText: "8 × 30 µL",
                color: dCol.clr,
                x: 309.73 + dCol.col * 9.0, y: 212.78,
                transitZ: isFirstD ? SAFE_Z : PLATE_HOVER_Z,
                dipZ: PLATE_DISP_Z,
                retractZ: isLastD ? SAFE_Z : PLATE_HOVER_Z,
                activeMask: allEightMask,
                tipsMaskAfterDip: allEightMask,
                moveMs: isFirstD ? 580 : 170,
                dipMs: 170,
                retractMs: isLastD ? 260 : 100,
                gwlLineIdx: dmsoDispIdx
            });
        }

        var ph1WasteIdx = gwlLines.length;
        gwlLines.push("W; Eject ALL 8 DMSO tips @ Poubelle [109.5, 204.0]");
        steps.push({
            label: "Phase 1 Complete: Eject ALL 8 DMSO Tips @ Poubelle",
            channelLabel: "All 8 Tips (Ch1–8)",
            compoundId: "TIP CHANGE",
            wellId: "Poubelle",
            concText: "8× Eject",
            color: Theme.textMuted,
            x: 109.50, y: 204.00, transitZ: SAFE_Z, dipZ: WASTE_DROP_Z, retractZ: PARK_Z,
            activeMask: allEightMask,
            tipsMaskAfterDip: noneMask,
            moveMs: 560, dipMs: 240, retractMs: 220,
            gwlLineIdx: ph1WasteIdx
        });

        // =====================================================================
        // PHASE 2: Change Tips — Mount ONLY the N tips needed for placed compounds (all at once)
        // =====================================================================
        if (placedCount > 0) {
            var ph2TipIdx = gwlLines.length;
            gwlLines.push("C; Ph2 Change Tips: Mount ONLY " + placedCount + " fresh tips (Rows " + placedRowNames.join(",") + ") @ TipRack[001] Col 2");
            steps.push({
                label: "Phase 2: Change Tips — Mount " + placedLabel + " @ TipRack Col 2",
                channelLabel: placedLabel,
                compoundId: "CHANGE TIPS (" + placedCount + "×)",
                wellId: "TipRack Col 2",
                concText: placedCount + " Fresh Tips",
                color: Theme.paletteAccent,
                x: 168.73, y: 404.78, transitZ: PARK_Z, dipZ: TIP_PICK_Z, retractZ: SAFE_Z,
                activeMask: placedMask,
                tipsMaskAfterDip: placedMask,
                moveMs: 600, dipMs: 280, retractMs: 260,
                gwlLineIdx: ph2TipIdx
            });

            // =================================================================
            // PHASE 3: Aspirate ONE COMPOUND AT A TIME from Yellow Matrices
            // Tip k (= Channel placedRow) dips solo into its Matrix well while others stay parked!
            // worldY(ch) = axisY - ch * 9.0  =>  axisY = srcWellY + ch * 9.0
            // =================================================================
            for (var si = 0; si < placedItems.length; ++si) {
                var cmp = placedItems[si];
                var ch = cmp.placedRow;
                var singleMask = [false, false, false, false, false, false, false, false];
                singleMask[ch] = true;

                var srcX = 605.38 + cmp.srcCol * 9.0;
                var srcBaseY = cmp.srcRack === 1 ? 197.86 : 389.86;
                var srcWellY = srcBaseY - cmp.srcRow * 9.0;
                var gantryY = srcWellY + ch * 9.0;

                var aspIdx = gwlLines.length;
                gwlLines.push("A;" + cmp.srcRackName + ";;" + cmp.srcWell + ";45.0;Ch" + (ch + 1) + " " + cmp.id + " (" + cmp.solvent + ")");
                steps.push({
                    label: "Phase 3: Tip " + (ch + 1) + " Solo Aspirate " + cmp.id + " @ Yellow M" + cmp.srcRack + ":" + cmp.srcWell,
                    channelLabel: "Single Tip Ch" + (ch + 1) + " (Row " + rowLetters[ch] + ")",
                    compoundId: cmp.id + " [Tip " + (ch + 1) + "]",
                    wellId: "M" + cmp.srcRack + ":" + cmp.srcWell,
                    concText: cmp.stock,
                    color: cmp.color,
                    x: srcX, y: gantryY, transitZ: SAFE_Z, dipZ: MATRIX_ASP_Z, retractZ: SAFE_Z,
                    activeMask: singleMask,
                    tipsMaskAfterDip: placedMask,
                    moveMs: si === 0 ? 660 : 500, dipMs: 240, retractMs: 260,
                    gwlLineIdx: aspIdx
                });
            }

            // =================================================================
            // PHASE 4: Distribute ALL compounds into Daughter[001] AT ONCE & Parallel Serial Dilution
            // =================================================================
            var colMasks = [];
            for (var sIdx = 0; sIdx < maxDilSteps; ++sIdx) {
                var cm = [false, false, false, false, false, false, false, false];
                for (var pi2 = 0; pi2 < placedItems.length; ++pi2) {
                    var it = placedItems[pi2];
                    if (Math.max(1, Math.min(10, it.dilutions)) > sIdx) {
                        cm[it.placedRow] = true;
                    }
                }
                colMasks.push(cm);
            }

            for (var colStep = 0; colStep < maxDilSteps; ++colStep) {
                var plateCol = 1 + colStep; // Col 2 (idx 1) is Top Conc; Col 3.. are Serial Dilutions
                var curMask = colMasks[colStep];
                var sameAsPrev = (colStep > 0) && masksEqual(curMask, colMasks[colStep - 1]);
                var sameAsNext = (colStep < maxDilSteps - 1) && masksEqual(curMask, colMasks[colStep + 1]);

                var activeRowLabels = [];
                for (var ri = 0; ri < 8; ++ri) {
                    if (curMask[ri]) activeRowLabels.push(rowLetters[ri]);
                }

                var isTopConc = (colStep === 0);
                var dilLineIdx = gwlLines.length;
                if (isTopConc) {
                    gwlLines.push("D;Daughter[001];;Col2 (Rows " + activeRowLabels.join(",") + ");45.0;Simultaneous Top-Conc Dispense");
                } else {
                    gwlLines.push("T;Daughter[001];;Col" + plateCol + "->Col" + (plateCol + 1) + " (Rows " + activeRowLabels.join(",") + ");15.0;Parallel Serial Dilution");
                }

                steps.push({
                    label: isTopConc
                           ? ("Phase 4: Dispense ALL " + activeRowLabels.length + " Compounds AT ONCE -> Daughter Col 2")
                           : ("Phase 4: Parallel Serial Dilution -> Col " + (plateCol + 1) + " (Rows " + activeRowLabels.join(",") + ")"),
                    channelLabel: activeRowLabels.length + " Tips (Rows " + activeRowLabels.join(",") + ")",
                    compoundId: isTopConc ? "TOP CONC DISPENSE" : ("SERIAL DIL STEP " + colStep),
                    wellId: "Col " + (plateCol + 1) + " (" + activeRowLabels.join(",") + ")",
                    concText: isTopConc ? "All At Once" : ("1:" + placedItems[0].dilutionFold.toFixed(1) + " Mix"),
                    color: isTopConc ? Theme.terracottaGlow : Theme.paletteAccent,
                    x: 309.73 + plateCol * 9.0, y: 212.78,
                    transitZ: sameAsPrev ? PLATE_HOVER_Z : SAFE_Z,
                    dipZ: PLATE_DISP_Z,
                    retractZ: sameAsNext ? PLATE_HOVER_Z : SAFE_Z,
                    activeMask: curMask,
                    tipsMaskAfterDip: placedMask,
                    moveMs: sameAsPrev ? 190 : 620,
                    dipMs: 200,
                    retractMs: sameAsNext ? 120 : 260,
                    gwlLineIdx: dilLineIdx
                });
            }

            // Final Eject of all N serial-dilution tips at Poubelle
            var finalWasteIdx = gwlLines.length;
            gwlLines.push("W; Eject " + placedCount + " compound tips @ Poubelle [109.5, 204.0]");
            steps.push({
                label: "Phase 4 Complete: Eject " + placedLabel + " @ Poubelle",
                channelLabel: placedLabel,
                compoundId: "WASTE",
                wellId: "Poubelle",
                concText: placedCount + "× Tip Eject",
                color: Theme.textMuted,
                x: 109.50, y: 204.00, transitZ: SAFE_Z, dipZ: WASTE_DROP_Z, retractZ: PARK_Z,
                activeMask: placedMask,
                tipsMaskAfterDip: noneMask,
                moveMs: 560, dipMs: 240, retractMs: 220,
                gwlLineIdx: finalWasteIdx
            });
        }

        return {
            requestId: requestId,
            projectCode: projectCode,
            gwlLines: gwlLines,
            steps: steps
        };
    }

    function complete3dHitpickAndAnalyze() {
        hitpick3dCompleted = true;
        if (!analysisReady) {
            runScreeningAndAnalyze();
        } else {
            currentStage = 4;
        }
    }

    function runScreeningAndAnalyze() {
        if (placedQueueCount === 0) return;

        var wells = companyPlateWells.slice();
        var results = [];
        var negVals = [];
        var posVals = [];

        for (var i = 0; i < 96; ++i) {
            var w = Object.assign({}, wells[i]);
            if (w.isControl) {
                var jitter = Math.sin(w.row * 1.9 + w.col * 0.7) * 1.8;
                if (w.controlType === "DMSO") {
                    w.inhibition = Math.max(0.0, 2.5 + jitter);
                    negVals.push(w.inhibition);
                } else {
                    w.inhibition = Math.min(100.0, 97.5 + jitter * 0.7);
                    posVals.push(w.inhibition);
                }
            } else if (w.queueIdx >= 0) {
                var prof = compoundProfiles[w.queueIdx % compoundProfiles.length];
                var inh = 2.0 + (prof.emax - 2.0) / (1.0 + Math.pow(prof.ic50 / Math.max(0.0001, w.concUm), prof.hill));
                var wellJitter = Math.sin(w.row * 3.1 + w.col * 2.3) * 1.9;
                w.inhibition = Math.max(0.0, Math.min(100.0, inh + wellJitter));
            }
            wells[i] = w;
        }

        var meanNeg = 0.0, meanPos = 0.0;
        for (var a = 0; a < negVals.length; ++a) meanNeg += negVals[a];
        for (var b = 0; b < posVals.length; ++b) meanPos += posVals[b];
        meanNeg /= Math.max(1, negVals.length);
        meanPos /= Math.max(1, posVals.length);

        var varNeg = 0.0, varPos = 0.0;
        for (var a2 = 0; a2 < negVals.length; ++a2) varNeg += Math.pow(negVals[a2] - meanNeg, 2);
        for (var b2 = 0; b2 < posVals.length; ++b2) varPos += Math.pow(posVals[b2] - meanPos, 2);
        var sdNeg = Math.sqrt(varNeg / Math.max(1, negVals.length));
        var sdPos = Math.sqrt(varPos / Math.max(1, posVals.length));
        plateZPrime = Math.max(0.0, Math.min(0.96, 1.0 - (3.0 * (sdPos + sdNeg)) / Math.max(1.0, Math.abs(meanPos - meanNeg))));
        plateSbRatio = Math.max(1.5, meanPos / Math.max(1.0, meanNeg + 12.0));
        plateControlsCv = Math.max(1.2, (sdPos / Math.max(1.0, meanPos)) * 100.0);

        for (var qIdx = 0; qIdx < companyQueue.length; ++qIdx) {
            var item = companyQueue[qIdx];
            if (item.placedRow < 0) continue;
            var prof2 = compoundProfiles[qIdx % compoundProfiles.length];

            var rowWells = [];
            var sumY = 0.0;
            for (var wi = 0; wi < 96; ++wi) {
                var pw = wells[wi];
                if (!pw.isControl && pw.queueIdx === qIdx) {
                    rowWells.push({
                        wellId: pw.wellId,
                        concUm: pw.concUm,
                        inhibition: pw.inhibition,
                        spread: Math.max(1.1, 3.6 - (item.replicates || 2) * 0.65)
                    });
                    sumY += pw.inhibition;
                }
            }
            var meanY = sumY / Math.max(1, rowWells.length);
            var ssRes = 0.0, ssTot = 0.0;
            for (var rwi = 0; rwi < rowWells.length; ++rwi) {
                var cUm = rowWells[rwi].concUm;
                var pred = 2.0 + (prof2.emax - 2.0) / (1.0 + Math.pow(prof2.ic50 / Math.max(0.0001, cUm), prof2.hill));
                var obs = rowWells[rwi].inhibition;
                ssRes += Math.pow(obs - pred, 2);
                ssTot += Math.pow(obs - meanY, 2);
            }
            var rSq = ssTot > 1.0 ? Math.max(0.75, Math.min(0.999, 1.0 - (ssRes / ssTot))) : 0.965;
            var pic50Val = -Math.log10(Math.max(1e-6, prof2.ic50 * 1e-6));
            var callTxt = prof2.emax >= 80.0 && prof2.ic50 <= 5.0 ? "HIT"
                        : (prof2.emax >= 50.0 ? "MODERATE" : "INACTIVE");

            results.push({
                id: item.id,
                assay: item.assay,
                rowLabel: rowLetters[item.placedRow],
                color: item.color,
                emax: prof2.emax,
                bottom: 2.0,
                ic50: prof2.ic50,
                pic50: pic50Val,
                hill: prof2.hill,
                rSquared: rSq,
                replicates: item.replicates || 2,
                startConc: item.startConc,
                dilutions: item.dilutions,
                dilutionFold: item.dilutionFold,
                call: callTxt,
                wells: rowWells
            });
        }

        companyPlateWells = wells;
        analyzedResults = results;
        analysisReady = true;
        resultsPublished = false;
        inspectedPlateWell = wells[1];
        currentStage = 4;
    }

    function heatmapColor(inh) {
        var norm = Math.max(0.0, Math.min(1.0, inh / 100.0));
        if (norm < 0.5) {
            return Theme.mix(Theme.bgVoid, Theme.paletteAccent, norm * 2.0);
        }
        return Theme.mix(Theme.paletteAccent, Theme.statusGreen, (norm - 0.5) * 2.0);
    }

    // =========================================================================
    // MAIN UI LAYOUT
    // =========================================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceMd
        spacing: Theme.spaceSm

        // 1. HEADER & STATUS BAR
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "End-to-End Workflow: Client Portal ➔ Company LIMS & Data Delivery"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.letterSpacing: Theme.trackMicro
                    color: Theme.textMuted
                    text: "CLIENT STOREFRONT (CATALOGUE + SPREADSHEET + CART) ➔ LIMS SBS-96 & 3D GWL ➔ 4PL RESULTS"
                }
            }

            Rectangle {
                Layout.preferredWidth: statusPillTxt.implicitWidth + 22
                Layout.preferredHeight: 28
                radius: Theme.radiusPill
                color: Theme.alpha(portalFlowRoot.batchStatusColor, 0.14)
                border.color: portalFlowRoot.batchStatusColor
                border.width: 1

                Text {
                    id: statusPillTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: portalFlowRoot.batchStatusColor
                    text: portalFlowRoot.batchStatusText
                }
            }

            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 28
                radius: Theme.radiusPill
                color: resetFlowMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                border.color: Theme.glassBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "Reset Flow"
                }
                MouseArea {
                    id: resetFlowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: portalFlowRoot.resetWorkflow()
                }
            }
        }

        // 2. 6-STAGE INTERACTIVE STEPPER (STOREFRONT <-> COMPANY LIMS <-> CLIENT RESULTS)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Theme.radiusSm
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    model: [
                        { idx: 0, side: "CLIENT",  label: "1. Assay Catalogue" },
                        { idx: 1, side: "CLIENT",  label: "2. Compound Table" },
                        { idx: 2, side: "CLIENT",  label: "3. Cart & Send" },
                        { idx: 3, side: "COMPANY", label: "4. Plate & 3D GWL" },
                        { idx: 4, side: "COMPANY", label: "5. Lab QC & Publish" },
                        { idx: 5, side: "CLIENT",  label: "6. Results & 4PL" }
                    ]

                    Rectangle {
                        required property var modelData
                        readonly property bool isCurrent: portalFlowRoot.currentStage === modelData.idx
                        readonly property bool isUnlocked: modelData.idx <= portalFlowRoot.maxUnlockedStage
                        readonly property bool isDone: modelData.idx < portalFlowRoot.currentStage || (modelData.idx === 5 && portalFlowRoot.resultsPublished)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 4
                        color: isCurrent ? Theme.paletteAccent : (isDone ? Theme.alpha(Theme.statusGreen, 0.14) : Theme.bgCard)
                        border.color: isCurrent ? Theme.paletteAccent : (isDone ? Theme.statusGreen : Theme.borderCard)
                        border.width: 1
                        opacity: isUnlocked ? 1.0 : 0.45

                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontMono; font.pixelSize: 7; font.weight: Font.Bold
                                color: isCurrent ? Theme.textOnAccent : (modelData.side === "COMPANY" ? Theme.terracottaGlow : Theme.textDim)
                                text: modelData.side
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                color: isCurrent ? Theme.textOnAccent : (isDone ? Theme.statusGreen : Theme.textPrimary)
                                text: modelData.label
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: isUnlocked
                            cursorShape: isUnlocked ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: portalFlowRoot.currentStage = modelData.idx
                        }
                    }
                }
            }
        }

        // 3. ACTIVE STAGE WORKSPACE
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // =================================================================
            // STAGE 1: ASSAYS CATALOGUE STOREFRONT (PortalAssaysCatalogView)
            // =================================================================
            ColumnLayout {
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 0
                spacing: Theme.spaceSm

                // Search Bar + Category Filter Chips + Quick Cart Pill
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: Theme.radiusSm
                        color: Theme.bgVoid
                        border.color: searchInput.activeFocus ? Theme.paletteAccent : Theme.borderCard
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            Text { font.family: Theme.fontIcon; font.pixelSize: 15; color: Theme.textDim; text: "search" }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: searchInput.text === "" && !searchInput.activeFocus
                                    font.family: Theme.fontBody; font.pixelSize: 11; color: Theme.textDim
                                    text: "Search assays by code, title, or category..."
                                }
                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontBody; font.pixelSize: 11; color: Theme.textPrimary
                                    selectByMouse: true
                                    text: portalFlowRoot.catalogSearch
                                    onTextChanged: portalFlowRoot.catalogSearch = text
                                }
                            }
                        }
                    }

                    Repeater {
                        model: ["All", "Phenotypic", "Biochemical", "Electrophysiology"]
                        Rectangle {
                            required property var modelData
                            readonly property bool isCat: portalFlowRoot.categoryFilter === modelData
                            Layout.preferredWidth: catTxt.implicitWidth + 16
                            Layout.preferredHeight: 30
                            radius: Theme.radiusPill
                            color: isCat ? Theme.paletteAccent : Theme.bgSurface
                            border.color: isCat ? Theme.paletteAccent : Theme.borderCard; border.width: 1
                            Text {
                                id: catTxt
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                color: isCat ? Theme.textOnAccent : Theme.textPrimary
                                text: modelData
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: portalFlowRoot.categoryFilter = modelData
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: catCartTxt.implicitWidth + 18
                        Layout.preferredHeight: 30
                        radius: Theme.radiusPill
                        color: portalFlowRoot.cartItems.length > 0 ? Theme.cinnabar : Theme.bgSurface
                        border.color: portalFlowRoot.cartItems.length > 0 ? Theme.terracottaGlow : Theme.borderCard
                        border.width: 1
                        Text {
                            id: catCartTxt
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                            color: portalFlowRoot.cartItems.length > 0 ? Theme.textOnCinnabar : Theme.textMuted
                            text: "Cart (" + portalFlowRoot.cartItems.length + ")"
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: portalFlowRoot.cartItems.length > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: portalFlowRoot.currentStage = 2
                        }
                    }
                }

                // Assay Product Cards Grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: portalFlowRoot.assayCatalogue
                        Rectangle {
                            id: assayCard
                            required property int index
                            required property var modelData
                            readonly property string qLower: portalFlowRoot.catalogSearch.trim().toLowerCase()
                            readonly property bool matchesCat: portalFlowRoot.categoryFilter === "All" || modelData.category === portalFlowRoot.categoryFilter
                            readonly property bool matchesSearch: qLower === ""
                                || modelData.code.toLowerCase().indexOf(qLower) !== -1
                                || modelData.name.toLowerCase().indexOf(qLower) !== -1
                                || modelData.category.toLowerCase().indexOf(qLower) !== -1
                            readonly property bool matches: matchesCat && matchesSearch
                            readonly property bool inCart: portalFlowRoot.isAssayInCart(modelData.code)
                            readonly property bool isCurrentAssay: portalFlowRoot.activeAssayIndex === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusSm
                            color: cardHover.containsMouse ? Theme.alpha(Theme.paletteAccent, 0.14) : Theme.bgSurface
                            border.color: inCart ? Theme.statusGreen : (cardHover.containsMouse || isCurrentAssay ? Theme.paletteAccent : Theme.borderCard)
                            border.width: (cardHover.containsMouse || inCart || isCurrentAssay) ? 1.5 : 1
                            opacity: matches ? 1.0 : 0.25

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: assayCard.matches
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: portalFlowRoot.openAssayProductPage(assayCard.index)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Rectangle {
                                        Layout.preferredWidth: acTxt.implicitWidth + 12
                                        Layout.preferredHeight: 20
                                        radius: 4
                                        color: Theme.alpha(Theme.paletteAccent, 0.16)
                                        Text {
                                            id: acTxt
                                            anchors.centerIn: parent
                                            font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                            color: Theme.paletteAccent; text: assayCard.modelData.code
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        visible: assayCard.inCart
                                        Layout.preferredWidth: inCartBadgeTxt.implicitWidth + 12
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: Theme.statusGreen
                                        Text {
                                            id: inCartBadgeTxt
                                            anchors.centerIn: parent
                                            font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                            color: Theme.textOnGreen; text: "IN CART ✓"
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    font.family: Theme.fontDisplay; font.pixelSize: 18; font.weight: Font.Bold
                                    color: Theme.textPrimary; text: assayCard.modelData.name
                                }

                                Text {
                                    font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.terracottaGlow
                                    text: assayCard.modelData.category.toUpperCase() + "  •  " + assayCard.modelData.format + "  •  " + assayCard.modelData.vol
                                }

                                Item { Layout.fillHeight: true }

                                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textDim; text: "Max DMSO " + assayCard.modelData.dmsoMax }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                        color: cardHover.containsMouse ? Theme.paletteAccent : Theme.textPrimary
                                        text: "Configure Compounds ➔"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // STAGE 2: ASSAY PRODUCT PAGE & INLINE SPREADSHEET (PortalProductPageView)
            // =================================================================
            PortalCompoundSpreadsheet {
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 1
                selectedAssay: portalFlowRoot.selectedAssayObj
                projectCode: portalFlowRoot.projectCode
                quoteNumber: portalFlowRoot.quoteNumber
                screeningMode: portalFlowRoot.screeningMode
                defaultForm: portalFlowRoot.defaultForm
                tableRows: portalFlowRoot.productTableRows
                cartCount: portalFlowRoot.cartItems.length
                statusBanner: portalFlowRoot.tableStatusBanner

                onBackToCatalogue: portalFlowRoot.currentStage = 0
                onOpenCart: portalFlowRoot.currentStage = 2
                onOpenTsvPaste: tsvPasteOverlay.open()
                onOpenExcelDrop: function(rawUrl) { portalFlowRoot.handleDroppedUrl(rawUrl); }
                onOpenSampleExcel: {
                    excelPreviewOverlay.openWithBatch(
                        "Invenesis_Batch_PRJ2026.xlsx",
                        portalFlowRoot.buildSampleExcelRows(),
                        "WORKBOOK SHEET1 PARSED • ALIAS MAPPING & DUPLICATE CHECK ACTIVE"
                    );
                }
                onProjectCodeEdited: function(val) { if (val !== "") portalFlowRoot.projectCode = val; }
                onQuoteNumberEdited: function(val) { portalFlowRoot.quoteNumber = val; }
                onScreeningModeToggled: function(mode) { portalFlowRoot.setScreeningMode(mode); }
                onFormulationToggled: function(form) { portalFlowRoot.setDefaultForm(form); }
                onRowUpdated: function(idx, field, val) { portalFlowRoot.updateTableRow(idx, field, val); }
                onRowFieldCycled: function(idx, field) { portalFlowRoot.cycleTableRowField(idx, field); }
                onAddBlankRowRequested: portalFlowRoot.addBlankTableRow()
                onDuplicateRowRequested: function(idx) { portalFlowRoot.duplicateTableRow(idx); }
                onRemoveRowRequested: function(idx) { portalFlowRoot.removeTableRow(idx); }
                onLoadDemoBatchRequested: portalFlowRoot.loadDemoTableBatch()
                onClearRowsRequested: portalFlowRoot.clearTableRows()
                onAddToCartRequested: function(goToCart) { portalFlowRoot.addCurrentProductToCart(goToCart); }
            }

            // =================================================================
            // STAGE 3: CART REVIEW & TRANSMIT REQUEST TO COMPANY LIMS
            // =================================================================
            RowLayout {
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 2
                spacing: Theme.spaceMd

                // Left: Cart Request Batches & Lab Remarks
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.terracottaGlow; text: "TEST REQUEST CART (" + portalFlowRoot.cartItems.length + " BATCHES)" }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: addMoreTxt.implicitWidth + 16; Layout.preferredHeight: 26; radius: Theme.radiusPill
                                color: Theme.bgCard; border.color: Theme.paletteAccent; border.width: 1
                                Text { id: addMoreTxt; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.paletteAccent; text: "+ Add Another Assay" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: portalFlowRoot.currentStage = 0 }
                            }
                        }

                        // Cart Items List
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1; clip: true

                            Text {
                                anchors.centerIn: parent
                                visible: portalFlowRoot.cartItems.length === 0
                                font.family: Theme.fontBody; font.pixelSize: 12; color: Theme.textDim
                                text: "Cart is empty. Select an assay and add compounds to queue a study."
                            }

                            Flickable {
                                anchors.fill: parent; anchors.margins: 8
                                contentHeight: cartListCol.implicitHeight; clip: true

                                ColumnLayout {
                                    id: cartListCol; width: parent.width; spacing: 8

                                    Repeater {
                                        model: portalFlowRoot.cartItems
                                        Rectangle {
                                            id: cartBundleCard
                                            required property int index
                                            required property var modelData
                                            Layout.fillWidth: true; Layout.preferredHeight: 74; radius: 6
                                            color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1

                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 10; spacing: 10

                                                Rectangle {
                                                    Layout.preferredWidth: 58; Layout.preferredHeight: 24; radius: 4
                                                    color: Theme.alpha(Theme.paletteAccent, 0.16)
                                                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.paletteAccent; text: cartBundleCard.modelData.assayCode }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 2
                                                    Text { font.family: Theme.fontDisplay; font.pixelSize: 15; font.weight: Font.Bold; color: Theme.textPrimary; text: cartBundleCard.modelData.assayName }
                                                    Text {
                                                        font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted
                                                        text: (cartBundleCard.modelData.screeningMode === "secondary" ? "Secondary IC50" : "Primary 1-pt")
                                                              + " • " + cartBundleCard.modelData.rows.length + " compounds • "
                                                              + cartBundleCard.modelData.datapoints + " pts • Proj " + cartBundleCard.modelData.projectCode
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.preferredWidth: 52; Layout.preferredHeight: 26; radius: 4
                                                    color: Theme.bgCard; border.color: Theme.borderCard; border.width: 1
                                                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textPrimary; text: "Edit" }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: portalFlowRoot.editCartBundle(cartBundleCard.index) }
                                                }

                                                Rectangle {
                                                    Layout.preferredWidth: 26; Layout.preferredHeight: 26; radius: 13
                                                    color: Theme.bgCard; border.color: Theme.borderCard; border.width: 1
                                                    Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; text: "✕" }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: portalFlowRoot.removeCartItem(cartBundleCard.index) }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Special Lab Instructions
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: "LAB REMARKS:" }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 4
                                color: Theme.bgVoid; border.color: cartRemarksIn.activeFocus ? Theme.paletteAccent : Theme.borderCard; border.width: 1
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                    visible: cartRemarksIn.text === "" && !cartRemarksIn.activeFocus
                                    font.family: Theme.fontBody; font.pixelSize: 10; color: Theme.textDim
                                    text: "Optional shipping / DMSO / temperature notes for lab team..."
                                }
                                TextInput {
                                    id: cartRemarksIn
                                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontBody; font.pixelSize: 10; color: Theme.textPrimary; selectByMouse: true
                                    text: portalFlowRoot.studyRemarks
                                    onTextChanged: portalFlowRoot.studyRemarks = text
                                }
                            }
                        }

                        // Validation + Transmit Actions
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.statusGreen; text: "✓ Definitive submission check passed • " + portalFlowRoot.totalCartDatapoints + " total datapoints" }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 256; Layout.preferredHeight: 36; radius: Theme.radiusPill
                                color: portalFlowRoot.cartItems.length > 0 ? Theme.cinnabar : Theme.bgCard
                                border.color: portalFlowRoot.cartItems.length > 0 ? Theme.terracottaGlow : Theme.borderCard; border.width: 1
                                Text {
                                    anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                    color: portalFlowRoot.cartItems.length > 0 ? Theme.textOnCinnabar : Theme.textDim
                                    text: "Send Request to Company LIMS ➔"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: portalFlowRoot.cartItems.length > 0
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: portalFlowRoot.submitOrderToCompany()
                                }
                            }
                        }
                    }
                }

                // Right: Live FastAPI Payload Preview
                Rectangle {
                    Layout.preferredWidth: 370; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1; clip: true

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 6
                        Text { font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.paletteAccent; text: "FASTAPI JSON TRANSMISSION PAYLOAD" }
                        Flickable {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: payloadEdit.paintedHeight; clip: true
                            TextEdit {
                                id: payloadEdit
                                width: parent.width; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                                font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textSecondary
                                text: portalFlowRoot.currentStage === 2 ? portalFlowRoot.buildSubmissionPayloadJson() : ""
                            }
                        }
                    }
                }
            }

            // =================================================================
            // STAGE 4: IN-COMPANY PLATE PLACEMENT & 3D GWL EXECUTION (COMPANY LIMS)
            // =================================================================
            RowLayout {
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 3
                spacing: Theme.spaceMd

                // Left: SBS-96 Plate Grid (A01-H12) + Well Inspector
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.terracottaGlow; text: "COMPANY LIMS // SBS-96 PLATE PLACEMENT (A01–H12)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; text: "Click any row to place selected compound" }
                        }

                        // Plate Chassis
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 480
                            Layout.preferredHeight: 320
                            radius: 8; color: Theme.stoneDark; border.color: Theme.glassBorder; border.width: 1.5

                            Row {
                                x: 30; y: 6; spacing: 10
                                Repeater {
                                    model: 12
                                    Item {
                                        required property int index
                                        width: 26; height: 14
                                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: String(index + 1) }
                                    }
                                }
                            }

                            Column {
                                x: 8; y: 24; spacing: 10
                                Repeater {
                                    model: 8
                                    Item {
                                        required property int index
                                        width: 16; height: 26
                                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: portalFlowRoot.rowLetters[index] }
                                    }
                                }
                            }

                            Grid {
                                x: 30; y: 24
                                width: 432; height: 280
                                columns: 12; rows: 8
                                columnSpacing: 10; rowSpacing: 10

                                Repeater {
                                    model: portalFlowRoot.companyPlateWells
                                    Rectangle {
                                        required property var modelData
                                        width: 26; height: 26; radius: 13; antialiasing: true
                                        color: {
                                            if (modelData.isControl) return modelData.controlType === "STD" ? Theme.alpha(Theme.statusGreen, 0.75) : Theme.bgCard;
                                            if (modelData.queueIdx >= 0) {
                                                var base = Qt.color(modelData.color);
                                                var a = Math.max(0.28, 1.0 - (modelData.step / 8.0) * 0.68);
                                                return Qt.rgba(base.r, base.g, base.b, a);
                                            }
                                            return Theme.bgVoid;
                                        }
                                        border.color: modelData.isControl && modelData.controlType === "STD" ? Theme.statusGreen : (modelData.queueIdx >= 0 ? Theme.textPrimary : Theme.borderCard)
                                        border.width: modelData.step === 0 ? 1.5 : 1

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: Theme.fontMono; font.pixelSize: 7; font.weight: Font.Bold
                                            color: modelData.isControl ? (modelData.controlType === "STD" ? Theme.textOnGreen : Theme.textDim)
                                                 : (modelData.queueIdx >= 0 ? Theme.textOn(parent.color) : Theme.textDim)
                                            text: modelData.isControl ? (modelData.controlType === "STD" ? "+" : "D")
                                                : (modelData.queueIdx >= 0 ? String(modelData.step + 1) : "")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: portalFlowRoot.inspectedPlateWell = modelData
                                            onClicked: {
                                                if (!modelData.isControl && portalFlowRoot.selectedQueueIdx >= 0 && portalFlowRoot.selectedQueueIdx < portalFlowRoot.companyQueue.length) {
                                                    portalFlowRoot.placeQueueCompoundInRow(portalFlowRoot.selectedQueueIdx, modelData.row);
                                                } else {
                                                    portalFlowRoot.inspectedPlateWell = modelData;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Well Inspector Bar
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6; color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textPrimary
                                text: {
                                    var w = portalFlowRoot.inspectedPlateWell;
                                    if (!w) return "Hover or click a well to inspect coordinate A01–H12";
                                    if (w.isControl) return "Well " + w.wellId + " • Control (" + w.controlType + ") • " + w.volUl + " µL";
                                    if (w.queueIdx >= 0) return "Well " + w.wellId + " • " + w.compoundId + " • Step " + (w.step + 1) + " (" + w.concUm.toFixed(2) + " µM) • " + w.volUl + " µL • " + w.assay;
                                    return "Well " + w.wellId + " • Empty (click to place selected compound in Row " + portalFlowRoot.rowLetters[w.row] + ")";
                                }
                            }
                        }
                    }
                }

                // Right: Incoming Order Queue & GWL / 3D Robot / Reader Dispatch
                Rectangle {
                    Layout.preferredWidth: 320; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.glassFill; border.color: Theme.glassBorder; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 8

                        Text { font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.paletteAccent; text: "INCOMING QUEUE (" + portalFlowRoot.requestId + ")" }

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1; clip: true
                            Flickable {
                                anchors.fill: parent; anchors.margins: 6
                                contentHeight: qCol.implicitHeight; clip: true
                                ColumnLayout {
                                    id: qCol; width: parent.width; spacing: 5
                                    Repeater {
                                        model: portalFlowRoot.companyQueue
                                        Rectangle {
                                            id: qItemRect
                                            required property int index
                                            required property var modelData
                                            readonly property bool isSel: portalFlowRoot.selectedQueueIdx === index
                                            readonly property bool isPlaced: modelData.placedRow >= 0
                                            Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 4
                                            color: isSel ? Theme.bgSurfaceHover : Theme.bgSurface
                                            border.color: isSel ? Theme.paletteAccent : (isPlaced ? Theme.statusGreen : Theme.borderCard)
                                            border.width: isSel ? 1.5 : 1

                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                                Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: qItemRect.modelData.color }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 1
                                                    Text { Layout.fillWidth: true; elide: Text.ElideRight; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.textPrimary; text: qItemRect.modelData.id + " (" + qItemRect.modelData.assay + ")" }
                                                    Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted; text: "Src M" + qItemRect.modelData.srcRack + ":" + qItemRect.modelData.srcWell + " • " + qItemRect.modelData.dilutions + " pts @ " + qItemRect.modelData.startConc + " µM" }
                                                }
                                                Text {
                                                    font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                                    color: qItemRect.isPlaced ? Theme.statusGreen : Theme.statusWarning
                                                    text: qItemRect.isPlaced ? ("ROW " + portalFlowRoot.rowLetters[qItemRect.modelData.placedRow]) : "PENDING"
                                                }
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: portalFlowRoot.selectedQueueIdx = qItemRect.index }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 32; radius: Theme.radiusPill
                            color: Theme.paletteAccent
                            Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.textOnAccent; text: "Auto-Place All on Plate" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: portalFlowRoot.autoPlaceAllOnPlate() }
                        }

                        Rectangle {
                            visible: portalFlowRoot.plateReady
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 5
                            color: Theme.alpha(Theme.statusGreen, 0.12)
                            border.color: Theme.statusGreen
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: Theme.statusGreen
                                text: "✓ " + portalFlowRoot.compiledGwlLineCount + " GWL cmds compiled for Fluent 1080"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 38; radius: Theme.radiusPill
                            color: portalFlowRoot.plateReady ? Theme.cinnabar : Theme.bgSurface
                            border.color: portalFlowRoot.plateReady ? Theme.terracottaGlow : Theme.borderCard; border.width: 1
                            Text {
                                anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                color: portalFlowRoot.plateReady ? Theme.textOnCinnabar : Theme.textDim
                                text: "Simulate Hitpick on 3D Fluent ➔"
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: portalFlowRoot.plateReady
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: portalFlowRoot.simulateGwlOn3D(portalFlowRoot.buildCompiledGwlJob())
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 30; radius: Theme.radiusPill
                            color: Theme.bgSurface
                            border.color: portalFlowRoot.plateReady ? Theme.borderCardHover : Theme.borderCard; border.width: 1
                            opacity: portalFlowRoot.plateReady ? 1.0 : 0.45
                            Text {
                                anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
                                color: Theme.textPrimary
                                text: "Skip 3D — Run Optical Reader ➔"
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: portalFlowRoot.plateReady
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: portalFlowRoot.runScreeningAndAnalyze()
                            }
                        }
                    }
                }
            }

            // =================================================================
            // STAGE 5: ANALYZE RAW READER DATA & PUBLISH TO CLIENT PORTAL
            // =================================================================
            RowLayout {
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 4
                spacing: Theme.spaceMd

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.statusGreen; text: "OPTICAL READER HEATMAP (% INHIBITION)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.statusGreen; text: "Z'=" + portalFlowRoot.plateZPrime.toFixed(2) + " PASS • S/B=" + portalFlowRoot.plateSbRatio.toFixed(1) + "x • CV=" + portalFlowRoot.plateControlsCv.toFixed(1) + "%" }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 480; Layout.preferredHeight: 320
                            radius: 8; color: Theme.stoneDark; border.color: Theme.glassBorder; border.width: 1.5

                            Row {
                                x: 30; y: 6; spacing: 10
                                Repeater {
                                    model: 12
                                    Item {
                                        required property int index
                                        width: 26; height: 14
                                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: String(index + 1) }
                                    }
                                }
                            }
                            Column {
                                x: 8; y: 24; spacing: 10
                                Repeater {
                                    model: 8
                                    Item {
                                        required property int index
                                        width: 16; height: 26
                                        Text { anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.textDim; text: portalFlowRoot.rowLetters[index] }
                                    }
                                }
                            }

                            Grid {
                                x: 30; y: 24; width: 432; height: 280; columns: 12; rows: 8; columnSpacing: 10; rowSpacing: 10
                                Repeater {
                                    model: portalFlowRoot.companyPlateWells
                                    Rectangle {
                                        required property var modelData
                                        width: 26; height: 26; radius: 13; antialiasing: true
                                        color: (modelData.isControl || modelData.queueIdx >= 0) ? portalFlowRoot.heatmapColor(modelData.inhibition) : Theme.bgVoid
                                        border.color: (modelData.isControl || modelData.queueIdx >= 0) ? Theme.borderCardHover : Theme.borderCard; border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            visible: modelData.isControl || modelData.queueIdx >= 0
                                            font.family: Theme.fontMono; font.pixelSize: 7; font.weight: Font.Bold
                                            color: Theme.textOn(parent.color)
                                            text: String(Math.round(modelData.inhibition))
                                        }
                                        MouseArea {
                                            anchors.fill: parent; hoverEnabled: true
                                            onEntered: portalFlowRoot.inspectedPlateWell = modelData
                                            onClicked: portalFlowRoot.inspectedPlateWell = modelData
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 6; color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textPrimary
                                text: {
                                    var w = portalFlowRoot.inspectedPlateWell;
                                    if (!w) return "Hover a well to inspect measured % inhibition";
                                    if (w.isControl) return "Well " + w.wellId + " (" + w.controlType + ") • Measured Inhibition: " + w.inhibition.toFixed(1) + "%";
                                    if (w.queueIdx >= 0) return "Well " + w.wellId + " • " + w.compoundId + " @ " + w.concUm.toFixed(2) + " µM • Measured Inhibition: " + w.inhibition.toFixed(1) + "%";
                                    return "Well " + w.wellId + " • Empty well";
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 360; Layout.fillHeight: true; radius: Theme.radiusSm
                    color: Theme.glassFill; border.color: Theme.glassBorder; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 8

                        Text { font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.terracottaGlow; text: "ANALYZED COMPOUND EFFICACY TABLE" }

                        Rectangle {
                            visible: portalFlowRoot.hitpick3dCompleted
                            Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 4
                            color: Theme.alpha(Theme.paletteAccent, 0.14)
                            border.color: Theme.paletteAccent; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                color: Theme.paletteAccent
                                text: "✓ 3D GWL HITPICK EXECUTED ON FLUENT 1080"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: Theme.bgVoid; border.color: Theme.borderCard; border.width: 1; clip: true
                            Flickable {
                                anchors.fill: parent; anchors.margins: 6
                                contentHeight: resCol.implicitHeight; clip: true
                                ColumnLayout {
                                    id: resCol; width: parent.width; spacing: 5
                                    Repeater {
                                        model: portalFlowRoot.analyzedResults
                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 4; color: Theme.bgSurface; border.color: Theme.borderCard; border.width: 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                                Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: modelData.color }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 1
                                                    Text { Layout.fillWidth: true; elide: Text.ElideRight; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.textPrimary; text: modelData.id + " • Row " + modelData.rowLabel }
                                                    Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted; text: "Emax " + modelData.emax.toFixed(1) + "% • IC50 " + modelData.ic50.toFixed(2) + " µM" }
                                                }
                                                Rectangle {
                                                    Layout.preferredWidth: 68; Layout.preferredHeight: 20; radius: 10
                                                    color: modelData.call === "HIT" ? Theme.statusGreen : (modelData.call === "MODERATE" ? Theme.statusWarning : Theme.bgCard)
                                                    Text {
                                                        anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                                        color: modelData.call === "INACTIVE" ? Theme.textDim : Theme.textOn(parent.color)
                                                        text: modelData.call
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 38; radius: Theme.radiusPill
                            color: Theme.statusGreen
                            border.color: Theme.statusGreen; border.width: 1
                            Text {
                                anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                                color: Theme.textOnGreen
                                text: "Publish & Open Client Results (4PL) ➔"
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    portalFlowRoot.resultsPublished = true;
                                    portalFlowRoot.currentStage = 5;
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // STAGE 6: CLIENT PORTAL RESULTS BROWSER & 4PL DOSE-RESPONSE CURVES
            // =================================================================
            PortalResultsBrowserStage {
                id: resultsBrowserStage
                anchors.fill: parent
                visible: portalFlowRoot.currentStage === 5
                requestId: portalFlowRoot.requestId
                projectCode: portalFlowRoot.projectCode
                studyRemarks: portalFlowRoot.studyRemarks
                plateZPrime: portalFlowRoot.plateZPrime
                plateSbRatio: portalFlowRoot.plateSbRatio
                plateControlsCv: portalFlowRoot.plateControlsCv
                ran3dSimulator: portalFlowRoot.hitpick3dCompleted
                analyzedResults: portalFlowRoot.analyzedResults
                onBackToLabQc: portalFlowRoot.currentStage = 4
                onRestartWorkflow: portalFlowRoot.resetWorkflow()
            }
        }
    }

    // Modal Overlays
    ExcelImportPreviewOverlay {
        id: excelPreviewOverlay
        onConfirmed: function(importedRows, remarks) {
            portalFlowRoot.importConfirmedExcelBatch(importedRows, remarks);
        }
    }

    PortalTsvPasteOverlay {
        id: tsvPasteOverlay
        screeningMode: portalFlowRoot.screeningMode
        defaultForm: portalFlowRoot.defaultForm
        onRowsConfirmed: function(rows) {
            portalFlowRoot.appendParsedTsvRows(rows);
        }
    }
}
