import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

Rectangle {
    id: demoRoot

    implicitWidth: 1040
    implicitHeight: 640
    radius: Theme.radiusMd
    color: Theme.bgCard
    border.color: Theme.glassBorder
    border.width: 1
    clip: true

    // =========================================================================
    // STATE PROPERTIES & MODELS
    // =========================================================================

    property int hitCount: 8            // Number of hits (4 to 16)
    property int dilutionSteps: 8       // Number of serial dilution points (4, 6, 8, 10)
    property real dilutionFactor: 3.162 // Half-log (sqrt(10) ~ 3.162), or 2.0, 5.0, 10.0
    property string replicateMode: "q1" // "q1", "duplicate" (Q1+Q2), "quad" (Q1-Q4)

    // Interactive Drag & Drop state
    property bool isDragging: false
    property int draggingHitIndex: -1
    property point dragCurrentPos: Qt.point(0, 0)
    property int dragHoverDaughterRow: -1
    property int dragHoverDaughterCol: -1
    property int selectedMotherHitIndex: -1
    property int hoveredHitIndex: -1

    // Inspected Well Telemetry
    property var inspectedWell: null

    // Plate Coordinate Constants
    readonly property var rowLetters96: ["A","B","C","D","E","F","G","H"]
    readonly property var rowLetters384: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"]

    // Dynamic Microplate Compound Palette (derived dynamically from Theme)
    readonly property var compoundPalette: Theme.compoundPalette

    readonly property var compoundNames: [
        "CPD-8102 (Kinase Inh)",
        "CPD-4419 (GPCR Antag)",
        "CPD-2305 (Ion Channel)",
        "CPD-9120 (Allosteric)",
        "CPD-1147 (Protease Inh)",
        "CPD-7083 (Epigenetic)",
        "CPD-5521 (Nuclear Rec)",
        "CPD-3364 (Phosphatase)",
        "CPD-6729 (Macrocycle)",
        "CPD-1892 (PROTAC Degrader)",
        "CPD-4281 (Covalent Lig)",
        "CPD-8904 (Peptidomimetic)",
        "CPD-7715 (Enzyme Mod)",
        "CPD-2943 (Receptor Ant)",
        "CPD-6018 (Channel Blocker)",
        "CPD-3570 (Signal Trans)"
    ]

    // Active Hits List
    property var motherHits: []

    // 96-well grid representations: array of 96 elements (r * 12 + c)
    property var motherPlateWells: []
    property var daughterPlateWells: []

    // 384-well grid representation: array of 384 elements (r * 24 + c)
    property var testPlateWells: []

    // Number of occupied wells in daughter plate
    property int daughterFilledCount: 0
    property int testFilledCount: 0

    // =========================================================================
    // SAFE GETTERS (PREVENT UNDEFINED TYPEERRORS)
    // =========================================================================

    function getHitColor(hIdx) {
        if (hIdx >= 0 && hIdx < motherHits.length && motherHits[hIdx] && motherHits[hIdx].color) {
            return motherHits[hIdx].color;
        }
        var safeIdx = Math.abs(hIdx);
        return compoundPalette[safeIdx % compoundPalette.length] || Theme.paletteAccent;
    }

    function getHitId(hIdx) {
        if (hIdx >= 0 && hIdx < motherHits.length && motherHits[hIdx] && motherHits[hIdx].id) {
            return motherHits[hIdx].id;
        }
        return "";
    }

    function getHitName(hIdx) {
        if (hIdx >= 0 && hIdx < motherHits.length && motherHits[hIdx] && motherHits[hIdx].name) {
            return motherHits[hIdx].name;
        }
        return "";
    }

    // =========================================================================
    // SCROLL INTERACTION LOCK (PREVENT CONFLICT WITH PARENT FLICKABLE)
    // =========================================================================

    function setPageScrollEnabled(enabled) {
        var p = demoRoot.parent;
        while (p) {
            if (p.interactive !== undefined && p.contentY !== undefined) {
                p.interactive = enabled;
                break;
            }
            p = p.parent;
        }
    }

    Component.onDestruction: {
        setPageScrollEnabled(true);
    }

    // =========================================================================
    // INITIALIZATION & BUSINESS LOGIC
    // =========================================================================

    Component.onCompleted: {
        initializePlates();
    }

    function initializePlates() {
        randomizeMotherHits();
        autoFillDaughter();
    }

    function formatWellId(r, c) {
        return rowLetters96[r] + (c < 9 ? "0" : "") + (c + 1);
    }

    function formatWellId384(r, c) {
        return rowLetters384[r] + (c < 9 ? "0" : "") + (c + 1);
    }

    // Randomize mother plate with hitCount hits scattered randomly
    function randomizeMotherHits() {
        var newHits = [];
        var newMotherWells = [];
        for (var i = 0; i < 96; ++i) {
            newMotherWells.push(null);
        }

        // Generate distinct random positions
        var chosenPositions = [];
        while (chosenPositions.length < hitCount) {
            var randPos = Math.floor(Math.random() * 96);
            if (chosenPositions.indexOf(randPos) === -1) {
                chosenPositions.push(randPos);
            }
        }

        for (var k = 0; k < hitCount; ++k) {
            var pos = chosenPositions[k];
            var r = Math.floor(pos / 12);
            var c = pos % 12;
            var hitObj = {
                hitIndex: k,
                id: "CPD-" + (k + 1 < 10 ? "0" : "") + (k + 1),
                name: compoundNames[k % compoundNames.length],
                color: compoundPalette[k % compoundPalette.length],
                motherRow: r,
                motherCol: c,
                motherWell: formatWellId(r, c),
                stockConc: 10000.0, // 10 mM stock
                isPlaced: false,
                daughterRow: -1,
                daughterCol: -1
            };
            newHits.push(hitObj);
            newMotherWells[pos] = hitObj;
        }

        motherHits = newHits;
        motherPlateWells = newMotherWells;

        if (newHits.length > 0) {
            inspectHit(newHits[0]);
        }
    }

    // Auto-fill Daughter plate with serial dilution chains
    function autoFillDaughter() {
        var newDaughterWells = [];
        for (var i = 0; i < 96; ++i) {
            var r = Math.floor(i / 12);
            var c = i % 12;
            var isControl = (c === 0 || c === 11);
            newDaughterWells.push({
                row: r,
                col: c,
                wellId: formatWellId(r, c),
                hitIndex: -1,
                isControl: isControl,
                controlType: isControl ? "DMSO" : "",
                step: -1,
                conc: 0.0,
                volume: isControl ? 15.0 : 0.0
            });
        }

        var updatedHits = [];
        for (var h = 0; h < motherHits.length; ++h) {
            var hit = motherHits[h];
            var targetRow = h % 8;
            var targetCol = 1; // start after DMSO control column

            if (h >= 8) {
                targetRow = (h - 8) % 8;
                targetCol = 1 + Math.min(6, dilutionSteps);
            }

            for (var s = 0; s < dilutionSteps; ++s) {
                var col = targetCol + s;
                if (col >= 11) break; // Keep column 11 for DMSO
                var idx = targetRow * 12 + col;
                var conc = calculateDaughterConc(s);
                newDaughterWells[idx] = {
                    row: targetRow,
                    col: col,
                    wellId: formatWellId(targetRow, col),
                    hitIndex: h,
                    isControl: false,
                    controlType: "",
                    step: s,
                    isSeed: (s === 0),
                    conc: conc,
                    volume: (s === 0 ? 45.0 : 30.0)
                };
            }

            hit.isPlaced = true;
            hit.daughterRow = targetRow;
            hit.daughterCol = targetCol;
            updatedHits.push(hit);
        }

        motherHits = updatedHits;
        daughterPlateWells = newDaughterWells;
        rebuildTestPlate();
    }

    // Clear Daughter plate layout for manual drag & drop
    function clearDaughterLayout() {
        var newDaughterWells = [];
        for (var i = 0; i < 96; ++i) {
            var r = Math.floor(i / 12);
            var c = i % 12;
            var isControl = (c === 0 || c === 11);
            newDaughterWells.push({
                row: r,
                col: c,
                wellId: formatWellId(r, c),
                hitIndex: -1,
                isControl: isControl,
                controlType: isControl ? "DMSO" : "",
                step: -1,
                conc: 0.0,
                volume: isControl ? 15.0 : 0.0
            });
        }

        var updatedHits = [];
        for (var h = 0; h < motherHits.length; ++h) {
            var hit = motherHits[h];
            hit.isPlaced = false;
            hit.daughterRow = -1;
            hit.daughterCol = -1;
            updatedHits.push(hit);
        }

        motherHits = updatedHits;
        daughterPlateWells = newDaughterWells;
        rebuildTestPlate();
    }

    // Place a compound starting at Daughter (startRow, startCol) with serial dilution
    function placeHitInDaughter(hitIdx, startRow, startCol) {
        if (hitIdx < 0 || hitIdx >= motherHits.length) return;
        if (startRow < 0 || startRow >= 8 || startCol < 0 || startCol >= 12) return;

        var wells = daughterPlateWells.slice();

        // Remove any prior placement of this hit
        for (var w = 0; w < 96; ++w) {
            if (wells[w] && wells[w].hitIndex === hitIdx) {
                var isCtrl = (wells[w].col === 0 || wells[w].col === 11);
                wells[w] = {
                    row: wells[w].row,
                    col: wells[w].col,
                    wellId: formatWellId(wells[w].row, wells[w].col),
                    hitIndex: -1,
                    isControl: isCtrl,
                    controlType: isCtrl ? "DMSO" : "",
                    step: -1,
                    conc: 0.0,
                    volume: isCtrl ? 15.0 : 0.0
                };
            }
        }

        // Place serial dilution chain across row
        for (var s = 0; s < dilutionSteps; ++s) {
            var c = startCol + s;
            var r = startRow;
            if (c >= 12) {
                c = c % 12;
                r = Math.min(7, r + 1);
            }
            var idx = r * 12 + c;
            var conc = calculateDaughterConc(s);
            wells[idx] = {
                row: r,
                col: c,
                wellId: formatWellId(r, c),
                hitIndex: hitIdx,
                isControl: false,
                controlType: "",
                step: s,
                isSeed: (s === 0),
                conc: conc,
                volume: (s === 0 ? 45.0 : 30.0)
            };
        }

        motherHits[hitIdx].isPlaced = true;
        motherHits[hitIdx].daughterRow = startRow;
        motherHits[hitIdx].daughterCol = startCol;

        daughterPlateWells = wells;
        rebuildTestPlate();
        inspectDaughterWell(wells[startRow * 12 + startCol]);
    }

    // Rebuild 384-Well Test Plate based on Daughter plate mapping
    function rebuildTestPlate() {
        var newTestWells = [];
        var filledCount = 0;
        var daughterFilled = 0;

        // Initialize 384 empty wells (16 rows x 24 cols)
        for (var idx384 = 0; idx384 < 384; ++idx384) {
            var tr = Math.floor(idx384 / 24);
            var tc = idx384 % 24;

            var isNegControl = (tc === 0 || tc === 23);
            var isPosControl = (tc === 1 || tc === 22);
            var ctrlType = isNegControl ? "DMSO" : (isPosControl ? "STANDARD" : "");

            newTestWells.push({
                row: tr,
                col: tc,
                wellId: formatWellId384(tr, tc),
                hitIndex: -1,
                isControl: (isNegControl || isPosControl),
                controlType: ctrlType,
                quadrant: "",
                step: -1,
                conc: isNegControl ? 0.0 : (isPosControl ? 10.0 : 0.0),
                inhibition: isNegControl ? 2.5 : (isPosControl ? 99.4 : 0.0),
                sourceWellId: "",
                volume: 20.0
            });
        }

        for (var dw = 0; dw < daughterPlateWells.length; ++dw) {
            if (daughterPlateWells[dw] && daughterPlateWells[dw].hitIndex >= 0) {
                daughterFilled++;
            }
        }
        daughterFilledCount = daughterFilled;

        // Quadrant 96-to-384 projection (Q1: 2r, 2c)
        for (var r = 0; r < 8; ++r) {
            for (var c = 0; c < 12; ++c) {
                var dItem = daughterPlateWells[r * 12 + c];
                if (!dItem || dItem.hitIndex < 0 || dItem.hitIndex >= motherHits.length) continue;

                var hIdx = dItem.hitIndex;
                var step = dItem.step;
                var testConc = calculateTestConc(step);
                var inh = calculateInhibition(testConc);

                // Assign to Quadrant 1
                var tr1 = 2 * r;
                var tc1 = 2 * c;
                var idx1 = tr1 * 24 + tc1;
                newTestWells[idx1] = {
                    row: tr1,
                    col: tc1,
                    wellId: formatWellId384(tr1, tc1),
                    hitIndex: hIdx,
                    isControl: false,
                    controlType: "",
                    quadrant: "Q1",
                    step: step,
                    conc: testConc,
                    inhibition: inh,
                    sourceWellId: dItem.wellId,
                    volume: 20.0
                };
                filledCount++;

                // If duplicate mode (Q1 + Q2)
                if (replicateMode === "duplicate" || replicateMode === "quad") {
                    var tr2 = 2 * r;
                    var tc2 = 2 * c + 1;
                    var idx2 = tr2 * 24 + tc2;
                    newTestWells[idx2] = {
                        row: tr2,
                        col: tc2,
                        wellId: formatWellId384(tr2, tc2),
                        hitIndex: hIdx,
                        isControl: false,
                        controlType: "",
                        quadrant: "Q2",
                        step: step,
                        conc: testConc,
                        inhibition: Math.max(0.0, Math.min(100.0, inh + (Math.random() - 0.5) * 3.0)),
                        sourceWellId: dItem.wellId,
                        volume: 20.0
                    };
                    filledCount++;
                }

                // If 4x quadrant mode (Q1 + Q2 + Q3 + Q4)
                if (replicateMode === "quad") {
                    var tr3 = 2 * r + 1;
                    var tc3 = 2 * c;
                    var idx3 = tr3 * 24 + tc3;
                    newTestWells[idx3] = {
                        row: tr3,
                        col: tc3,
                        wellId: formatWellId384(tr3, tc3),
                        hitIndex: hIdx,
                        isControl: false,
                        controlType: "",
                        quadrant: "Q3",
                        step: step,
                        conc: testConc,
                        inhibition: Math.max(0.0, Math.min(100.0, inh + (Math.random() - 0.5) * 3.0)),
                        sourceWellId: dItem.wellId,
                        volume: 20.0
                    };
                    filledCount++;

                    var tr4 = 2 * r + 1;
                    var tc4 = 2 * c + 1;
                    var idx4 = tr4 * 24 + tc4;
                    newTestWells[idx4] = {
                        row: tr4,
                        col: tc4,
                        wellId: formatWellId384(tr4, tc4),
                        hitIndex: hIdx,
                        isControl: false,
                        controlType: "",
                        quadrant: "Q4",
                        step: step,
                        conc: testConc,
                        inhibition: Math.max(0.0, Math.min(100.0, inh + (Math.random() - 0.5) * 3.0)),
                        sourceWellId: dItem.wellId,
                        volume: 20.0
                    };
                    filledCount++;
                }
            }
        }

        testPlateWells = newTestWells;
        testFilledCount = filledCount;
    }

    // Concentration calculations
    function calculateDaughterConc(step) {
        var top = 100.0;
        return top / Math.pow(dilutionFactor, Math.max(0, step));
    }

    function calculateTestConc(step) {
        var top = 10.0;
        return top / Math.pow(dilutionFactor, Math.max(0, step));
    }

    function formatConc(cVal) {
        if (cVal === undefined || isNaN(cVal)) return "--";
        if (cVal >= 1.0) {
            return cVal.toFixed(2) + " µM";
        } else if (cVal >= 0.01) {
            return cVal.toFixed(3) + " µM";
        } else {
            return (cVal * 1000.0).toFixed(1) + " nM";
        }
    }

    // Hill Equation for 4PL sigmoid inhibition
    function calculateInhibition(conc) {
        var ec50 = 1.25;
        var hill = 1.15;
        var bottom = 2.0;
        var top = 98.5;
        var inh = bottom + (top - bottom) / (1.0 + Math.pow(ec50 / Math.max(0.0001, conc), hill));
        return Math.max(0.0, Math.min(100.0, inh));
    }

    // Telemetry inspectors
    function inspectHit(hit) {
        if (!hit) return;
        inspectedWell = {
            plate: "Mother",
            wellId: hit.motherWell,
            row: hit.motherRow,
            col: hit.motherCol,
            hitIndex: hit.hitIndex,
            compound: hit,
            conc: 10000.0,
            step: 0,
            volume: 100.0,
            isControl: false
        };
    }

    function inspectDaughterWell(dWell) {
        if (!dWell) return;
        var hit = (dWell.hitIndex >= 0 && dWell.hitIndex < motherHits.length) ? motherHits[dWell.hitIndex] : null;
        inspectedWell = {
            plate: "Daughter",
            wellId: dWell.wellId,
            row: dWell.row,
            col: dWell.col,
            hitIndex: dWell.hitIndex,
            compound: hit,
            conc: dWell.conc,
            step: dWell.step,
            volume: dWell.volume,
            isControl: dWell.isControl,
            controlType: dWell.controlType
        };
    }

    function inspectTestWell(tWell) {
        if (!tWell) return;
        var hit = (tWell.hitIndex >= 0 && tWell.hitIndex < motherHits.length) ? motherHits[tWell.hitIndex] : null;
        inspectedWell = {
            plate: "Test 384",
            wellId: tWell.wellId,
            row: tWell.row,
            col: tWell.col,
            hitIndex: tWell.hitIndex,
            compound: hit,
            conc: tWell.conc,
            step: tWell.step,
            volume: tWell.volume,
            quadrant: tWell.quadrant,
            inhibition: tWell.inhibition,
            sourceWellId: tWell.sourceWellId,
            isControl: tWell.isControl,
            controlType: tWell.controlType
        };
    }

    // Precise daughter drop hit testing mapped directly to grid
    function checkDaughterDropTarget(rootX, rootY) {
        var pt = demoRoot.mapToItem(daughterGrid, rootX, rootY);
        if (pt.x >= 0 && pt.x <= daughterGrid.width && pt.y >= 0 && pt.y <= daughterGrid.height) {
            var cellW = daughterGrid.width / 12.0;
            var cellH = daughterGrid.height / 8.0;
            var col = Math.floor(pt.x / cellW);
            var row = Math.floor(pt.y / cellH);
            if (row >= 0 && row < 8 && col >= 0 && col < 12) {
                dragHoverDaughterRow = row;
                dragHoverDaughterCol = col;
                return;
            }
        }
        dragHoverDaughterRow = -1;
        dragHoverDaughterCol = -1;
    }

    // =========================================================================
    // VISUAL LAYOUT
    // =========================================================================

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceMd
        spacing: Theme.spaceSm

        // ---------------------------------------------------------------------
        // TOP HEADER: TITLE & REPLICATE MODE SWITCHER
        // ---------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            ColumnLayout {
                spacing: 2
                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "Automated Hitpick & Dilution Engine"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: Theme.trackMicro
                    color: Theme.textMuted
                    text: "ANSI/SLAS STANDARD SBS RECTANGULAR PLATES (LANDSCAPE 1.5:1) // 96-TO-384 QUADRANTS"
                }
            }

            Item { Layout.fillWidth: true }

            // Replicate Projection Mode Switcher
            Row {
                spacing: 4

                Rectangle {
                    width: 74; height: 28; radius: Theme.radiusPill
                    color: demoRoot.replicateMode === "q1" ? Theme.terracotta : Theme.bgSurface
                    border.color: Theme.glassBorder; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 10
                        font.capitalization: Font.AllUppercase; font.weight: Font.Bold
                        color: demoRoot.replicateMode === "q1" ? Theme.textOnAccent : Theme.textMuted
                        text: "Q1 Single"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { demoRoot.replicateMode = "q1"; demoRoot.rebuildTestPlate(); }
                    }
                }

                Rectangle {
                    width: 86; height: 28; radius: Theme.radiusPill
                    color: demoRoot.replicateMode === "duplicate" ? Theme.terracotta : Theme.bgSurface
                    border.color: Theme.glassBorder; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 10
                        font.capitalization: Font.AllUppercase; font.weight: Font.Bold
                        color: demoRoot.replicateMode === "duplicate" ? Theme.textOnAccent : Theme.textMuted
                        text: "2x Replicate"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { demoRoot.replicateMode = "duplicate"; demoRoot.rebuildTestPlate(); }
                    }
                }

                Rectangle {
                    width: 86; height: 28; radius: Theme.radiusPill
                    color: demoRoot.replicateMode === "quad" ? Theme.terracotta : Theme.bgSurface
                    border.color: Theme.glassBorder; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono; font.pixelSize: 10
                        font.capitalization: Font.AllUppercase; font.weight: Font.Bold
                        color: demoRoot.replicateMode === "quad" ? Theme.textOnAccent : Theme.textMuted
                        text: "4x Quad"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { demoRoot.replicateMode = "quad"; demoRoot.rebuildTestPlate(); }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // TOOLBAR: HIT COUNT, RANDOMIZE, DILUTIONS, AUTO-FILL, CLEAR
        // ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: Theme.radiusSm
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Hit Count Selector
                RowLayout {
                    spacing: 6
                    Text {
                        font.family: Theme.fontMono; font.pixelSize: 10
                        color: Theme.textMuted; text: "HITS:"
                    }

                    Rectangle {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 4; color: Theme.bgCard
                        border.color: Theme.glassBorder; border.width: 1
                        Text { anchors.centerIn: parent; text: "-"; font.bold: true; color: Theme.textPrimary }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (demoRoot.hitCount > 4) {
                                    demoRoot.hitCount -= 2;
                                    demoRoot.randomizeMotherHits();
                                    demoRoot.autoFillDaughter();
                                }
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontMono; font.pixelSize: 11
                        font.weight: Font.Bold; color: Theme.terracottaGlow
                        text: demoRoot.hitCount.toString()
                    }

                    Rectangle {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 4; color: Theme.bgCard
                        border.color: Theme.glassBorder; border.width: 1
                        Text { anchors.centerIn: parent; text: "+"; font.bold: true; color: Theme.textPrimary }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (demoRoot.hitCount < 16) {
                                    demoRoot.hitCount += 2;
                                    demoRoot.randomizeMotherHits();
                                    demoRoot.autoFillDaughter();
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.divider }

                // Randomize Mother Hits Button
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: randomizeRow.implicitWidth + 20
                    radius: Theme.radiusSm
                    color: randArea.containsMouse ? Theme.bgSurfaceHover : Theme.bgCard
                    border.color: randArea.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
                    border.width: 1

                    Row {
                        id: randomizeRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontIcon; font.pixelSize: 13; text: "shuffle"; color: Theme.textPrimary }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.DemiBold; color: Theme.textPrimary
                            text: "Randomize Wells"
                        }
                    }

                    MouseArea {
                        id: randArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            demoRoot.randomizeMotherHits();
                            demoRoot.autoFillDaughter();
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.divider }

                // Dilution Steps Selector
                RowLayout {
                    spacing: 4
                    Text {
                        font.family: Theme.fontMono; font.pixelSize: 10
                        color: Theme.textMuted; text: "DILUTIONS:"
                    }

                    Repeater {
                        model: [4, 6, 8, 10]
                        Rectangle {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 22; radius: 4
                            color: demoRoot.dilutionSteps === modelData ? Theme.terracotta : Theme.bgCard
                            border.color: Theme.glassBorder; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 10
                                font.weight: Font.Bold
                                color: demoRoot.dilutionSteps === modelData ? Theme.textOnAccent : Theme.textDim
                                text: modelData.toString()
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    demoRoot.dilutionSteps = modelData;
                                    demoRoot.autoFillDaughter();
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.divider }

                // Dilution Factor Selector
                RowLayout {
                    spacing: 4
                    Text {
                        font.family: Theme.fontMono; font.pixelSize: 10
                        color: Theme.textMuted; text: "FACTOR:"
                    }

                    Repeater {
                        model: [
                            { label: "2x", val: 2.0 },
                            { label: "3.16x", val: 3.162 },
                            { label: "10x", val: 10.0 }
                        ]
                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 40
                            radius: 4
                            color: Math.abs(demoRoot.dilutionFactor - modelData.val) < 0.05 ? Theme.terracotta : Theme.bgCard
                            border.color: Theme.glassBorder; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontMono; font.pixelSize: 9
                                font.weight: Font.Bold
                                color: Math.abs(demoRoot.dilutionFactor - modelData.val) < 0.05 ? Theme.textOnAccent : Theme.textDim
                                text: modelData.label
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    demoRoot.dilutionFactor = modelData.val;
                                    demoRoot.autoFillDaughter();
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Auto-Fill Daughter Button
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: 96
                    radius: Theme.radiusSm
                    color: autoFillArea.containsMouse ? Theme.cinnabarHover : Theme.cinnabar
                    border.color: Theme.terracottaGlow; border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontIcon; font.pixelSize: 13; text: "bolt"; color: Theme.textOnCinnabar }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.Bold; color: Theme.textOnCinnabar
                            text: "Auto-Fill"
                        }
                    }

                    MouseArea {
                        id: autoFillArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: demoRoot.autoFillDaughter()
                    }
                }

                // Clear Daughter Layout Button
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: 80
                    radius: Theme.radiusSm
                    color: clearArea.containsMouse ? Theme.bgSurfaceHover : Theme.bgCard
                    border.color: Theme.glassBorder; border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontIcon; font.pixelSize: 12; text: "close"; color: Theme.textMuted }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.DemiBold; color: Theme.textMuted
                            text: "Clear"
                        }
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: demoRoot.clearDaughterLayout()
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // MAIN WORKBENCH: 3 RECTANGULAR LANDSCAPE SBS PLATES (1.5:1 RATIO)
        // ---------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // =================================================================
            // PLATE 1: MOTHER PLATE (96-WELL SBS LANDSCAPE)
            // =================================================================
            Rectangle {
                Layout.preferredWidth: 295
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgSurface
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Plate Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.Bold; font.letterSpacing: Theme.trackMicro
                            color: Theme.terracottaGlow; text: "01 // MOTHER PLATE"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 8
                            color: Theme.textDim; text: "SBS 96 (LANDSCAPE)"
                        }
                    }

                    Text {
                        font.family: Theme.fontBody; font.pixelSize: 10
                        color: Theme.textMuted
                        text: "Drag hit or click to pick. 10 mM stock."
                    }

                    Item { Layout.fillHeight: true }

                    // ANSI/SLAS SBS Landscape Microplate Chassis (1.5:1 Ratio)
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 276
                        height: 184 // Exactly 276 / 184 = 1.5 : 1 landscape ratio
                        radius: 6
                        color: Theme.stoneDark
                        border.color: Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.4)
                        border.width: 1.5

                        // Chamfered A1 Index notch indicator
                        Rectangle {
                            x: 2; y: 2; width: 8; height: 8; radius: 2
                            color: Qt.rgba(Theme.terracotta.r, Theme.terracotta.g, Theme.terracotta.b, 0.3)
                        }

                        // Column headers 1..12
                        Row {
                            x: 20; y: 4
                            spacing: (276 - 24 - (12 * 15)) / 11.0
                            Repeater {
                                model: 12
                                Item {
                                    width: 15; height: 12
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 8
                                        color: Theme.textDim; text: (index + 1).toString()
                                    }
                                }
                            }
                        }

                        // Row headers A..H
                        Column {
                            x: 4; y: 18
                            spacing: (184 - 24 - (8 * 15)) / 7.0
                            Repeater {
                                model: 8
                                Item {
                                    width: 14; height: 15
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 8
                                        color: Theme.textDim; text: demoRoot.rowLetters96[index]
                                    }
                                }
                            }
                        }

                        // Well Matrix Grid (12 cols x 8 rows, pitch ~19.5px, 1.5:1 landscape)
                        Grid {
                            id: motherGrid
                            x: 20; y: 18
                            width: 276 - 24
                            height: 184 - 24
                            columns: 12; rows: 8
                            rowSpacing: (height - (8 * 15)) / 7.0
                            columnSpacing: (width - (12 * 15)) / 11.0

                            Repeater {
                                model: 96
                                Rectangle {
                                    id: motherWellItem
                                    width: 15; height: 15
                                    radius: 7.5
                                    antialiasing: true

                                    readonly property int r: Math.floor(index / 12)
                                    readonly property int c: index % 12
                                    readonly property var hitItem: (demoRoot.motherPlateWells && demoRoot.motherPlateWells.length > index) ? demoRoot.motherPlateWells[index] : null
                                    readonly property bool hasHit: hitItem !== null
                                    readonly property bool isSelectedHit: hasHit && demoRoot.selectedMotherHitIndex === hitItem.hitIndex
                                    readonly property bool isHoveredHit: hasHit && demoRoot.hoveredHitIndex === hitItem.hitIndex

                                    color: {
                                        if (hasHit) {
                                            return demoRoot.getHitColor(hitItem.hitIndex);
                                        }
                                        return Qt.rgba(Theme.bgVoid.r, Theme.bgVoid.g, Theme.bgVoid.b, 0.7);
                                    }

                                    border.color: {
                                        if (isSelectedHit) return Theme.textPrimary;
                                        if (isHoveredHit) return Theme.terracottaGlow;
                                        if (hasHit) return Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.45);
                                        return Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.25);
                                    }
                                    border.width: (isSelectedHit || isHoveredHit) ? 2 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        visible: motherWellItem.hasHit
                                        font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                        color: Theme.textOn(motherWellItem.color)
                                        text: motherWellItem.hasHit ? (motherWellItem.hitItem.hitIndex + 1).toString() : ""
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        preventStealing: true // PREVENTS PARENT FLICKABLE FROM STEALING DRAG!
                                        cursorShape: motherWellItem.hasHit ? Qt.PointingHandCursor : Qt.ArrowCursor

                                        onEntered: {
                                            if (motherWellItem.hasHit) {
                                                demoRoot.hoveredHitIndex = motherWellItem.hitItem.hitIndex;
                                                demoRoot.inspectHit(motherWellItem.hitItem);
                                            }
                                        }

                                        onExited: {
                                            if (motherWellItem.hasHit && demoRoot.hoveredHitIndex === motherWellItem.hitItem.hitIndex) {
                                                demoRoot.hoveredHitIndex = -1;
                                            }
                                        }

                                        onPressed: (mouse) => {
                                            if (motherWellItem.hasHit) {
                                                demoRoot.setPageScrollEnabled(false); // Lock scrolling
                                                demoRoot.draggingHitIndex = motherWellItem.hitItem.hitIndex;
                                                demoRoot.isDragging = true;
                                                var pt = mapToItem(demoRoot, mouse.x, mouse.y);
                                                demoRoot.dragCurrentPos = pt;
                                                demoRoot.checkDaughterDropTarget(pt.x, pt.y);
                                            }
                                        }

                                        onPositionChanged: (mouse) => {
                                            if (demoRoot.isDragging) {
                                                var pt = mapToItem(demoRoot, mouse.x, mouse.y);
                                                demoRoot.dragCurrentPos = pt;
                                                demoRoot.checkDaughterDropTarget(pt.x, pt.y);
                                            }
                                        }

                                        onReleased: (mouse) => {
                                            demoRoot.setPageScrollEnabled(true); // Unlock scrolling
                                            if (demoRoot.isDragging) {
                                                if (demoRoot.dragHoverDaughterRow >= 0 && demoRoot.dragHoverDaughterCol >= 0) {
                                                    demoRoot.placeHitInDaughter(demoRoot.draggingHitIndex, demoRoot.dragHoverDaughterRow, demoRoot.dragHoverDaughterCol);
                                                } else {
                                                    if (motherWellItem.hasHit) {
                                                        demoRoot.selectedMotherHitIndex = (demoRoot.selectedMotherHitIndex === motherWellItem.hitItem.hitIndex) ? -1 : motherWellItem.hitItem.hitIndex;
                                                    }
                                                }
                                            }
                                            demoRoot.isDragging = false;
                                            demoRoot.draggingHitIndex = -1;
                                            demoRoot.dragHoverDaughterRow = -1;
                                            demoRoot.dragHoverDaughterCol = -1;
                                        }

                                        onCanceled: {
                                            demoRoot.setPageScrollEnabled(true);
                                            demoRoot.isDragging = false;
                                            demoRoot.draggingHitIndex = -1;
                                            demoRoot.dragHoverDaughterRow = -1;
                                            demoRoot.dragHoverDaughterCol = -1;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Lower Skirt Barcode Tag
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim
                        text: "BARCODE: LIB-96-0104 // ANSI-SLAS 1-2004"
                    }
                }
            }

            // Transfer Arrow 1
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text { font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.terracottaGlow; text: "➔" }
                Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "PICK" }
            }

            // =================================================================
            // PLATE 2: DAUGHTER PLATE (96-WELL SBS LANDSCAPE)
            // =================================================================
            Rectangle {
                Layout.preferredWidth: 295
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgSurface
                border.color: (demoRoot.dragHoverDaughterRow >= 0) ? Theme.terracottaGlow : Theme.borderCard
                border.width: (demoRoot.dragHoverDaughterRow >= 0) ? 1.5 : 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Plate Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.Bold; font.letterSpacing: Theme.trackMicro
                            color: Theme.terracottaGlow; text: "02 // DAUGHTER PLATE"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 8
                            color: Theme.textDim; text: demoRoot.daughterFilledCount + "/96 FILLED"
                        }
                    }

                    Text {
                        font.family: Theme.fontBody; font.pixelSize: 10
                        color: Theme.textMuted
                        text: "Drop hit or click empty well to cascade dilution."
                    }

                    Item { Layout.fillHeight: true }

                    // ANSI/SLAS SBS Landscape Microplate Chassis (1.5:1 Ratio)
                    Rectangle {
                        id: daughterChassis
                        Layout.alignment: Qt.AlignHCenter
                        width: 276
                        height: 184 // Exactly 276 / 184 = 1.5 : 1 landscape ratio
                        radius: 6
                        color: Theme.stoneDark
                        border.color: (demoRoot.dragHoverDaughterRow >= 0) ? Theme.terracottaGlow : Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.4)
                        border.width: (demoRoot.dragHoverDaughterRow >= 0) ? 2 : 1.5

                        // Chamfered A1 Index notch indicator
                        Rectangle {
                            x: 2; y: 2; width: 8; height: 8; radius: 2
                            color: Qt.rgba(Theme.terracotta.r, Theme.terracotta.g, Theme.terracotta.b, 0.3)
                        }

                        // Column headers 1..12
                        Row {
                            x: 20; y: 4
                            spacing: (276 - 24 - (12 * 15)) / 11.0
                            Repeater {
                                model: 12
                                Item {
                                    width: 15; height: 12
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 8
                                        color: Theme.textDim; text: (index + 1).toString()
                                    }
                                }
                            }
                        }

                        // Row headers A..H
                        Column {
                            x: 4; y: 18
                            spacing: (184 - 24 - (8 * 15)) / 7.0
                            Repeater {
                                model: 8
                                Item {
                                    width: 14; height: 15
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 8
                                        color: Theme.textDim; text: demoRoot.rowLetters96[index]
                                    }
                                }
                            }
                        }

                        // Well Matrix Grid (12 cols x 8 rows, pitch ~19.5px, 1.5:1 landscape)
                        Grid {
                            id: daughterGrid
                            x: 20; y: 18
                            width: 276 - 24
                            height: 184 - 24
                            columns: 12; rows: 8
                            rowSpacing: (height - (8 * 15)) / 7.0
                            columnSpacing: (width - (12 * 15)) / 11.0

                            Repeater {
                                model: 96
                                Rectangle {
                                    id: daughterWellItem
                                    width: 15; height: 15
                                    radius: 7.5
                                    antialiasing: true

                                    readonly property int r: Math.floor(index / 12)
                                    readonly property int c: index % 12
                                    readonly property var wellData: (demoRoot.daughterPlateWells && demoRoot.daughterPlateWells.length > index) ? demoRoot.daughterPlateWells[index] : null
                                    readonly property bool hasCmp: wellData !== null && wellData.hitIndex >= 0 && wellData.hitIndex < demoRoot.motherHits.length
                                    readonly property bool isCtrl: wellData !== null && wellData.isControl
                                    readonly property bool isHoveredHit: hasCmp && demoRoot.hoveredHitIndex === wellData.hitIndex
                                    readonly property bool isDropTargetPreview: demoRoot.isDragging &&
                                                                                demoRoot.dragHoverDaughterRow === r &&
                                                                                c >= demoRoot.dragHoverDaughterCol &&
                                                                                c < demoRoot.dragHoverDaughterCol + demoRoot.dilutionSteps &&
                                                                                c < 12

                                    color: {
                                        if (isDropTargetPreview && demoRoot.draggingHitIndex >= 0) {
                                            var prevColor = demoRoot.getHitColor(demoRoot.draggingHitIndex);
                                            var stepIdx = c - demoRoot.dragHoverDaughterCol;
                                            var opacityVal = Math.max(0.25, 1.0 - (stepIdx / Math.max(1, demoRoot.dilutionSteps)) * 0.7);
                                            return Qt.rgba(Qt.color(prevColor).r, Qt.color(prevColor).g, Qt.color(prevColor).b, opacityVal);
                                        }

                                        if (hasCmp) {
                                            var baseColor = demoRoot.getHitColor(wellData.hitIndex);
                                            var alpha = Math.max(0.22, 1.0 - (wellData.step / Math.max(1, demoRoot.dilutionSteps)) * 0.75);
                                            return Qt.rgba(Qt.color(baseColor).r, Qt.color(baseColor).g, Qt.color(baseColor).b, alpha);
                                        }

                                        if (isCtrl) {
                                            return Qt.rgba(Theme.stoneDark.r, Theme.stoneDark.g, Theme.stoneDark.b, 0.8);
                                        }

                                        return Qt.rgba(Theme.bgVoid.r, Theme.bgVoid.g, Theme.bgVoid.b, 0.7);
                                    }

                                    border.color: {
                                        if (isDropTargetPreview) return Theme.terracottaGlow;
                                        if (isHoveredHit) return Theme.terracottaGlow;
                                        if (hasCmp && wellData.isSeed) return Theme.textPrimary;
                                        if (hasCmp) return Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.35);
                                        if (isCtrl) return Qt.rgba(Theme.textDim.r, Theme.textDim.g, Theme.textDim.b, 0.4);
                                        return Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.25);
                                    }
                                    border.width: (isDropTargetPreview || isHoveredHit || (hasCmp && wellData.isSeed)) ? 1.5 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 7; font.weight: Font.Bold
                                        color: isCtrl ? Theme.textDim : Theme.textOn(daughterWellItem.color)
                                        text: {
                                            if (daughterWellItem.isCtrl) return "D";
                                            if (daughterWellItem.hasCmp) {
                                                return daughterWellItem.wellData.isSeed ? "S" : (daughterWellItem.wellData.step + 1).toString();
                                            }
                                            return "";
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: (daughterWellItem.hasCmp || demoRoot.selectedMotherHitIndex >= 0) ? Qt.PointingHandCursor : Qt.ArrowCursor

                                        onEntered: {
                                            if (daughterWellItem.hasCmp) {
                                                demoRoot.hoveredHitIndex = daughterWellItem.wellData.hitIndex;
                                                demoRoot.inspectDaughterWell(daughterWellItem.wellData);
                                            } else if (daughterWellItem.isCtrl) {
                                                demoRoot.inspectDaughterWell(daughterWellItem.wellData);
                                            }
                                        }

                                        onExited: {
                                            if (daughterWellItem.hasCmp && demoRoot.hoveredHitIndex === daughterWellItem.wellData.hitIndex) {
                                                demoRoot.hoveredHitIndex = -1;
                                            }
                                        }

                                        onClicked: {
                                            if (demoRoot.selectedMotherHitIndex >= 0) {
                                                demoRoot.placeHitInDaughter(demoRoot.selectedMotherHitIndex, daughterWellItem.r, daughterWellItem.c);
                                                demoRoot.selectedMotherHitIndex = -1;
                                            } else if (daughterWellItem.hasCmp) {
                                                demoRoot.inspectDaughterWell(daughterWellItem.wellData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Lower Skirt Barcode Tag
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim
                        text: "BARCODE: DGHT-96-0201 // SERIAL DILUTION"
                    }
                }
            }

            // Transfer Arrow 2
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text { font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.terracottaGlow; text: "➔" }
                Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "4:1" }
            }

            // =================================================================
            // PLATE 3: TEST PLATE (384-WELL SBS LANDSCAPE)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgSurface
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Plate Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 10
                            font.weight: Font.Bold; font.letterSpacing: Theme.trackMicro
                            color: Theme.terracottaGlow; text: "03 // TEST ASSAY PLATE"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 8
                            color: Theme.textDim; text: "SBS 384 (" + demoRoot.testFilledCount + "/384 ACTIVE)"
                        }
                    }

                    Text {
                        font.family: Theme.fontBody; font.pixelSize: 10
                        color: Theme.textMuted
                        text: "Live 4:1 quadrant interleaving with automated dose-response scaling."
                    }

                    Item { Layout.fillHeight: true }

                    // ANSI/SLAS SBS Landscape 384 Microplate Chassis (1.5:1 Ratio)
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 324
                        height: 216 // Exactly 324 / 216 = 1.5 : 1 landscape ratio
                        radius: 6
                        color: Theme.stoneDark
                        border.color: Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.4)
                        border.width: 1.5

                        // Chamfered A1 Index notch indicator
                        Rectangle {
                            x: 2; y: 2; width: 8; height: 8; radius: 2
                            color: Qt.rgba(Theme.terracotta.r, Theme.terracotta.g, Theme.terracotta.b, 0.3)
                        }

                        // Column headers 1..24
                        Row {
                            x: 18; y: 4
                            spacing: (324 - 22 - (24 * 8)) / 23.0
                            Repeater {
                                model: 24
                                Item {
                                    width: 8; height: 10
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 7
                                        color: (index % 2 === 0) ? Theme.textDim : Theme.textMuted
                                        text: (index + 1).toString()
                                    }
                                }
                            }
                        }

                        // Row headers A..P
                        Column {
                            x: 4; y: 16
                            spacing: (216 - 20 - (16 * 8)) / 15.0
                            Repeater {
                                model: 16
                                Item {
                                    width: 12; height: 8
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono; font.pixelSize: 7
                                        color: Theme.textDim; text: demoRoot.rowLetters384[index]
                                    }
                                }
                            }
                        }

                        // 384 Matrix Grid (24 cols x 16 rows, pitch ~12.5px, 1.5:1 landscape)
                        Grid {
                            id: testGrid
                            x: 18; y: 16
                            width: 324 - 22
                            height: 216 - 20
                            columns: 24; rows: 16
                            rowSpacing: (height - (16 * 8)) / 15.0
                            columnSpacing: (width - (24 * 8)) / 23.0

                            Repeater {
                                model: 384
                                Rectangle {
                                    id: testWellItem
                                    width: 8; height: 8
                                    radius: 4
                                    antialiasing: true

                                    readonly property int r: Math.floor(index / 24)
                                    readonly property int c: index % 24
                                    readonly property var wellData: (demoRoot.testPlateWells && demoRoot.testPlateWells.length > index) ? demoRoot.testPlateWells[index] : null
                                    readonly property bool hasCmp: wellData !== null && wellData.hitIndex >= 0 && wellData.hitIndex < demoRoot.motherHits.length
                                    readonly property bool isCtrl: wellData !== null && wellData.isControl
                                    readonly property bool isHoveredHit: hasCmp && demoRoot.hoveredHitIndex === wellData.hitIndex

                                    color: {
                                        if (hasCmp) {
                                            var baseColor = demoRoot.getHitColor(wellData.hitIndex);
                                            var alpha = Math.max(0.20, 1.0 - (wellData.step / Math.max(1, demoRoot.dilutionSteps)) * 0.78);
                                            return Qt.rgba(Qt.color(baseColor).r, Qt.color(baseColor).g, Qt.color(baseColor).b, alpha);
                                        }

                                        if (isCtrl) {
                                            if (wellData.controlType === "STANDARD") return Qt.rgba(Theme.statusGreen.r, Theme.statusGreen.g, Theme.statusGreen.b, 0.7);
                                            return Qt.rgba(Theme.stoneDark.r, Theme.stoneDark.g, Theme.stoneDark.b, 0.85);
                                        }

                                        return Qt.rgba(Theme.bgVoid.r, Theme.bgVoid.g, Theme.bgVoid.b, 0.6);
                                    }

                                    border.color: {
                                        if (isHoveredHit) return Theme.textPrimary;
                                        if (hasCmp) return Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.3);
                                        if (isCtrl && wellData.controlType === "STANDARD") return Theme.statusGreen;
                                        return Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g, Theme.glassBorder.b, 0.2);
                                    }
                                    border.width: isHoveredHit ? 1.5 : 0.8

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: {
                                            if (testWellItem.hasCmp) {
                                                demoRoot.hoveredHitIndex = testWellItem.wellData.hitIndex;
                                                demoRoot.inspectTestWell(testWellItem.wellData);
                                            } else if (testWellItem.isCtrl) {
                                                demoRoot.inspectTestWell(testWellItem.wellData);
                                            }
                                        }

                                        onExited: {
                                            if (testWellItem.hasCmp && demoRoot.hoveredHitIndex === testWellItem.wellData.hitIndex) {
                                                demoRoot.hoveredHitIndex = -1;
                                            }
                                        }

                                        onClicked: {
                                            demoRoot.inspectTestWell(testWellItem.wellData);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Lower Skirt Barcode Tag
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim
                        text: "BARCODE: ASSAY-384-0501 // 4:1 QUADRANTS"
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // BOTTOM TELEMETRY & TRANSFER INSPECTOR PANEL
        // ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            radius: Theme.radiusSm
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 14

                // Left: Inspected Well Identification Card
                RowLayout {
                    spacing: 8
                    Rectangle {
                        id: inspectedSwatch
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20
                        color: {
                            if (demoRoot.inspectedWell && demoRoot.inspectedWell.compound && demoRoot.inspectedWell.compound.color) {
                                return demoRoot.inspectedWell.compound.color;
                            }
                            return Theme.bgCard;
                        }
                        border.color: Theme.glassBorder; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono; font.pixelSize: 10; font.weight: Font.Bold
                            color: (demoRoot.inspectedWell && demoRoot.inspectedWell.compound) ? Theme.textOn(inspectedSwatch.color) : Theme.textPrimary
                            text: {
                                if (demoRoot.inspectedWell && demoRoot.inspectedWell.compound) {
                                    return (demoRoot.inspectedWell.hitIndex + 1).toString();
                                }
                                return "--";
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 6
                            Text {
                                font.family: Theme.fontDisplay; font.pixelSize: 16; font.weight: Font.Bold
                                color: Theme.textPrimary
                                text: demoRoot.inspectedWell ? (demoRoot.inspectedWell.plate + ": " + demoRoot.inspectedWell.wellId) : "Hover or Select a Well"
                            }

                            Rectangle {
                                visible: demoRoot.inspectedWell !== null && demoRoot.inspectedWell.compound !== null
                                Layout.preferredWidth: 62; Layout.preferredHeight: 16; radius: Theme.radiusPill
                                color: Theme.cinnabar
                                border.color: Theme.terracottaGlow; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono; font.pixelSize: 8; font.weight: Font.Bold
                                    color: Theme.textOnCinnabar; text: "ACTIVE HIT"
                                }
                            }
                        }

                        Text {
                            font.family: Theme.fontMono; font.pixelSize: 9
                            color: Theme.terracottaGlow
                            text: {
                                if (demoRoot.inspectedWell && demoRoot.inspectedWell.compound) {
                                    return demoRoot.inspectedWell.compound.name + " // " + demoRoot.inspectedWell.compound.id;
                                }
                                if (demoRoot.inspectedWell && demoRoot.inspectedWell.isControl) {
                                    return "ASSAY CONTROL // " + demoRoot.inspectedWell.controlType;
                                }
                                return "Select any well to inspect dose-response telemetry";
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.divider }

                // Center: Quantitative Telemetry (Concentration, Dilution Step, Volume)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        ColumnLayout {
                            spacing: 1
                            Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "CALCULATED CONCENTRATION" }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold
                                color: Theme.textPrimary
                                text: demoRoot.inspectedWell ? demoRoot.formatConc(demoRoot.inspectedWell.conc) : "--"
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "SERIAL DILUTION STEP" }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold
                                color: Theme.textPrimary
                                text: {
                                    if (demoRoot.inspectedWell && demoRoot.inspectedWell.step >= 0) {
                                        return "Step " + (demoRoot.inspectedWell.step + 1) + " of " + demoRoot.dilutionSteps;
                                    }
                                    return "Source Stock (10 mM)";
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "ASSAY INHIBITION (4PL)" }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold
                                color: Theme.terracottaGlow
                                text: {
                                    if (demoRoot.inspectedWell && demoRoot.inspectedWell.plate === "Test 384") {
                                        return demoRoot.inspectedWell.inhibition.toFixed(1) + "%";
                                    }
                                    if (demoRoot.inspectedWell && demoRoot.inspectedWell.conc > 0) {
                                        return demoRoot.calculateInhibition(demoRoot.inspectedWell.conc).toFixed(1) + "%";
                                    }
                                    return "--";
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Text { font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textDim; text: "PIPETTE VOLUME" }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold
                                color: Theme.textPrimary
                                text: demoRoot.inspectedWell && demoRoot.inspectedWell.volume ? (demoRoot.inspectedWell.volume + " µL") : "--"
                            }
                        }
                    }

                    // Trajectory Line
                    Text {
                        font.family: Theme.fontMono; font.pixelSize: 9
                        color: Theme.textMuted
                        text: {
                            if (demoRoot.inspectedWell && demoRoot.inspectedWell.compound) {
                                var mWell = demoRoot.inspectedWell.compound.motherWell;
                                var dRow = demoRoot.inspectedWell.compound.daughterRow >= 0 ? demoRoot.formatWellId(demoRoot.inspectedWell.compound.daughterRow, demoRoot.inspectedWell.compound.daughterCol) : "Unassigned";
                                return "TRANSFER PATH: Mother [" + mWell + "] ➔ Daughter [" + dRow + "] ➔ Test 384 [Q1 Interleaved: R=2r, C=2c]";
                            }
                            return "Awaiting well selection...";
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // FLOATING DRAG GHOST (ACTIVE DURING DRAG & DROP)
    // =========================================================================
    Rectangle {
        id: dragGhost
        visible: demoRoot.isDragging && demoRoot.draggingHitIndex >= 0
        x: demoRoot.dragCurrentPos.x - width / 2
        y: demoRoot.dragCurrentPos.y - height / 2
        z: 9999
        width: 34
        height: 34
        radius: 17
        color: demoRoot.getHitColor(demoRoot.draggingHitIndex)
        border.color: Theme.textPrimary
        border.width: 2
        opacity: 0.92

        Text {
            anchors.centerIn: parent
            font.family: Theme.fontMono; font.pixelSize: 9; font.weight: Font.Bold
            color: Theme.textOn(dragGhost.color)
            text: demoRoot.getHitId(demoRoot.draggingHitIndex)
        }
    }
}
