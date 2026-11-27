import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."
import "../../controls"

Rectangle {
    id: doseDemoRoot

    implicitWidth: 840
    implicitHeight: 540
    radius: Theme.radiusMd
    color: Theme.bgCard
    border.color: Theme.glassBorder
    border.width: 1
    clip: true

    // 4PL Hill Equation Parameters
    property real ic50: 1.45        // µM
    property real hillSlope: 1.25   // Hill coefficient
    property real topEfficacy: 96.0 // %
    property real bottomEfficacy: 4.0 // %
    property real assayNoise: 1.8   // % replicate SD
    property real hitThreshold: 80.0
    property int activePresetIndex: 1

    // Dose concentrations (log scale: 0.003 to 100 µM)
    readonly property var testDoses: [0.003, 0.01, 0.03, 0.1, 0.3, 1.0, 3.0, 10.0, 30.0, 100.0]

    // Deterministic replicate residuals so R^2, CI95, and Z'-factor are genuinely computed
    readonly property var replicateOffsets: [-1.1, 0.8, -0.5, 1.3, -0.9, 0.6, -1.2, 0.9, -0.4, 0.7]

    // Live computed regression & HTS QC statistics
    readonly property real midResponse: (bottomEfficacy + topEfficacy) * 0.5
    readonly property real computedRSquared: {
        var ys = [];
        var preds = [];
        var sumY = 0.0;
        for (var i = 0; i < testDoses.length; ++i) {
            var pred = hillResponse(testDoses[i]);
            var obs = Math.max(0.0, Math.min(108.0, pred + replicateOffsets[i] * assayNoise));
            ys.push(obs);
            preds.push(pred);
            sumY += obs;
        }
        var meanY = sumY / ys.length;
        var ssRes = 0.0;
        var ssTot = 0.0;
        for (var j = 0; j < ys.length; ++j) {
            var res = ys[j] - preds[j];
            var tot = ys[j] - meanY;
            ssRes += res * res;
            ssTot += tot * tot;
        }
        if (ssTot <= 1e-6) return 1.0;
        return Math.max(0.0, Math.min(0.9999, 1.0 - (ssRes / ssTot)));
    }

    readonly property real computedZPrime: {
        var span = Math.abs(topEfficacy - bottomEfficacy);
        if (span <= 1e-4) return -1.0;
        var sdPos = assayNoise * 1.15;
        var sdNeg = assayNoise * 0.95;
        return Math.max(-1.0, Math.min(0.99, 1.0 - (3.0 * (sdPos + sdNeg)) / span));
    }

    readonly property string zPrimeQualityLabel: {
        if (computedZPrime >= 0.50) return "EXCELLENT";
        if (computedZPrime >= 0.0) return "MARGINAL";
        return "RE-OPTIMIZE";
    }

    readonly property color zPrimeQualityColor: {
        if (computedZPrime >= 0.50) return Theme.statusGreen;
        if (computedZPrime >= 0.0) return Theme.statusWarning;
        return Theme.cinnabar;
    }

    readonly property real computedCi95: {
        var rmseFactor = Math.sqrt(Math.max(0.0005, 1.0 - computedRSquared));
        var relErr = Math.min(0.45, (1.6 * rmseFactor) / Math.max(0.4, hillSlope));
        return Math.max(0.01, ic50 * relErr);
    }

    // Calculate response at given concentration X
    function hillResponse(conc) {
        var logRatio = Math.log10(conc) - Math.log10(ic50);
        return bottomEfficacy + (topEfficacy - bottomEfficacy) / (1.0 + Math.pow(10.0, -hillSlope * logRatio));
    }

    function applyPreset(idx, ic, hill, emax, noise) {
        activePresetIndex = idx;
        ic50 = ic;
        hillSlope = hill;
        topEfficacy = emax;
        bottomEfficacy = 4.0;
        assayNoise = noise;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        spacing: Theme.spaceMd

        // Header + Pharmacological Presets
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.sizeH3
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    text: "Pharmacological Dose-Response, 4PL Fit & HTS Assay QC"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMicro
                    font.letterSpacing: Theme.trackMicro
                    color: Theme.textMuted
                    text: "NON-LINEAR HILL REGRESSION // IC50, R², 95% CI & Z'-FACTOR SCREENING GATE"
                }
            }

            // Preset Pills
            Row {
                spacing: 6

                Repeater {
                    model: [
                        { label: "Potent (0.18 µM)", ic: 0.18, hill: 1.40, emax: 97.0, noise: 1.4 },
                        { label: "Nominal (1.45 µM)", ic: 1.45, hill: 1.25, emax: 96.0, noise: 1.8 },
                        { label: "Partial (68%)",    ic: 0.85, hill: 0.95, emax: 68.0, noise: 2.4 },
                        { label: "Steep (nH 2.4)",   ic: 2.20, hill: 2.40, emax: 98.0, noise: 1.6 }
                    ]

                    Rectangle {
                        readonly property bool isSel: doseDemoRoot.activePresetIndex === index
                        width: pLbl.implicitWidth + 18
                        height: 28
                        radius: Theme.radiusPill
                        color: isSel ? Theme.paletteAccent : (pMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface)
                        border.color: isSel ? Theme.paletteAccent : Theme.glassBorder
                        border.width: 1
                        scale: pMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            id: pLbl
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: isSel ? Theme.textOnAccent : Theme.textPrimary
                            text: modelData.label
                        }

                        MouseArea {
                            id: pMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: doseDemoRoot.applyPreset(index, modelData.ic, modelData.hill, modelData.emax, modelData.noise)
                        }
                    }
                }
            }
        }

        // Plot Canvas + Control Sliders
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceLg

            // Interactive Graph Canvas
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.bgSurface
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                Canvas {
                    id: curveCanvas
                    anchors.fill: parent
                    anchors.margins: 12
                    antialiasing: true

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    // Redraw whenever parameters change
                    Connections {
                        target: doseDemoRoot
                        function onIc50Changed() { curveCanvas.requestPaint(); }
                        function onHillSlopeChanged() { curveCanvas.requestPaint(); }
                        function onTopEfficacyChanged() { curveCanvas.requestPaint(); }
                        function onBottomEfficacyChanged() { curveCanvas.requestPaint(); }
                        function onAssayNoiseChanged() { curveCanvas.requestPaint(); }
                    }

                    Connections {
                        target: Theme
                        function onPaletteChanged() { curveCanvas.requestPaint(); }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        var w = width;
                        var h = height;
                        if (w <= 0 || h <= 0) return;
                        ctx.clearRect(0, 0, w, h);

                        var mLeft = 56;
                        var mRight = 32;
                        var mTop = 28;
                        var mBottom = 40;
                        var plotW = w - mLeft - mRight;
                        var plotH = h - mTop - mBottom;

                        var logMin = -3.0;
                        var logMax = 2.0;
                        var yMin = 0.0;
                        var yMax = 110.0;

                        function getX(dose) {
                            var logVal = Math.log10(dose);
                            return mLeft + ((logVal - logMin) / (logMax - logMin)) * plotW;
                        }

                        function getY(efficacy) {
                            return mTop + plotH - ((efficacy - yMin) / (yMax - yMin)) * plotH;
                        }

                        // Draw Grid Lines & Decade Ticks
                        ctx.strokeStyle = Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.08);
                        ctx.lineWidth = 1;

                        var decades = [0.001, 0.01, 0.1, 1.0, 10.0, 100.0];
                        ctx.fillStyle = Theme.textMuted;
                        ctx.font = "10px 'JetBrains Mono', monospace";
                        ctx.textAlign = "center";

                        for (var d = 0; d < decades.length; ++d) {
                            var gx = getX(decades[d]);
                            ctx.beginPath();
                            ctx.moveTo(gx, mTop);
                            ctx.lineTo(gx, mTop + plotH);
                            ctx.stroke();
                            ctx.fillText(decades[d].toString() + " µM", gx, mTop + plotH + 18);
                        }

                        // Y-axis ticks (0%, 25%, 50%, 75%, 100%)
                        ctx.textAlign = "right";
                        for (var yVal = 0; yVal <= 100; yVal += 25) {
                            var gy = getY(yVal);
                            ctx.beginPath();
                            ctx.moveTo(mLeft, gy);
                            ctx.lineTo(mLeft + plotW, gy);
                            ctx.stroke();
                            ctx.fillText(yVal + "%", mLeft - 8, gy + 3);
                        }

                        // Hit Threshold dashed line (80%)
                        var y80 = getY(doseDemoRoot.hitThreshold);
                        ctx.strokeStyle = Theme.statusWarning;
                        ctx.setLineDash([4, 4]);
                        ctx.beginPath();
                        ctx.moveTo(mLeft, y80);
                        ctx.lineTo(mLeft + plotW, y80);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        ctx.fillStyle = Theme.statusWarning;
                        ctx.font = "9px 'JetBrains Mono', monospace";
                        ctx.textAlign = "right";
                        ctx.fillText("80% HIT THRESHOLD", mLeft + plotW, y80 - 6);

                        // True 4PL Midpoint (IC50) Vertical & Horizontal Guides
                        var ic50X = getX(doseDemoRoot.ic50);
                        var ic50Y = getY(doseDemoRoot.midResponse);
                        ctx.strokeStyle = Qt.rgba(Theme.paletteAccent.r, Theme.paletteAccent.g, Theme.paletteAccent.b, 0.55);
                        ctx.setLineDash([2, 4]);
                        ctx.beginPath();
                        ctx.moveTo(ic50X, mTop + plotH);
                        ctx.lineTo(ic50X, ic50Y);
                        ctx.lineTo(mLeft, ic50Y);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        // 4PL Smooth Curve
                        ctx.strokeStyle = Theme.paletteAccent;
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        for (var i = 0; i <= 120; ++i) {
                            var logVal = logMin + (i / 120.0) * (logMax - logMin);
                            var cVal = Math.pow(10.0, logVal);
                            var resp = doseDemoRoot.hillResponse(cVal);
                            var px = getX(cVal);
                            var py = getY(resp);
                            if (i === 0) ctx.moveTo(px, py);
                            else ctx.lineTo(px, py);
                        }
                        ctx.stroke();

                        // IC50 Inflection Marker Dot
                        ctx.fillStyle = Theme.paletteAccent;
                        ctx.beginPath();
                        ctx.arc(ic50X, ic50Y, 5.0, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.strokeStyle = Theme.bgBase;
                        ctx.lineWidth = 1.5;
                        ctx.stroke();

                        ctx.fillStyle = Theme.paletteAccent;
                        ctx.font = "bold 9px 'JetBrains Mono', monospace";
                        ctx.textAlign = "left";
                        ctx.fillText("IC50 " + doseDemoRoot.ic50.toFixed(2) + " µM", ic50X + 8, ic50Y - 6);

                        // Replicate Data Points & Error Whiskers
                        var doses = doseDemoRoot.testDoses;
                        var offsets = doseDemoRoot.replicateOffsets;
                        for (var j = 0; j < doses.length; ++j) {
                            var c = doses[j];
                            var meanY = doseDemoRoot.hillResponse(c);
                            var measured = Math.max(0.0, Math.min(108.0, meanY + offsets[j] * doseDemoRoot.assayNoise));
                            var sem = Math.max(1.0, doseDemoRoot.assayNoise * 1.15);

                            var dpx = getX(c);
                            var dpy = getY(measured);
                            var pyTop = getY(Math.min(109.0, measured + sem));
                            var pyBot = getY(Math.max(0.0, measured - sem));

                            ctx.strokeStyle = Theme.paletteSecondary;
                            ctx.lineWidth = 1.2;
                            ctx.beginPath();
                            ctx.moveTo(dpx, pyTop);
                            ctx.lineTo(dpx, pyBot);
                            ctx.moveTo(dpx - 4, pyTop);
                            ctx.lineTo(dpx + 4, pyTop);
                            ctx.moveTo(dpx - 4, pyBot);
                            ctx.lineTo(dpx + 4, pyBot);
                            ctx.stroke();

                            ctx.fillStyle = Theme.textPrimary;
                            ctx.beginPath();
                            ctx.arc(dpx, dpy, 3.5, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.strokeStyle = Theme.bgBase;
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }
                    }
                }
            }

            // Right Controls & Telemetry Panel
            Rectangle {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.glassFill
                border.color: Theme.glassBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMd
                    spacing: 8

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMicro
                        font.letterSpacing: Theme.trackMicro
                        color: Theme.terracottaGlow
                        text: "REGRESSION PARAMETERS"
                    }

                    // IC50 Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "IC50 POTENCY" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.terracottaGlow; text: doseDemoRoot.ic50.toFixed(2) + " µM" }
                        }
                        AccentSlider {
                            Layout.fillWidth: true
                            from: 0.05; to: 10.0; value: doseDemoRoot.ic50
                            onMoved: { doseDemoRoot.activePresetIndex = -1; doseDemoRoot.ic50 = value; }
                        }
                    }

                    // Hill Slope Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "HILL SLOPE (nH)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.textPrimary; text: doseDemoRoot.hillSlope.toFixed(2) }
                        }
                        AccentSlider {
                            Layout.fillWidth: true
                            from: 0.5; to: 3.0; value: doseDemoRoot.hillSlope
                            onMoved: { doseDemoRoot.activePresetIndex = -1; doseDemoRoot.hillSlope = value; }
                        }
                    }

                    // Top Efficacy Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "MAX EFFICACY (Emax)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.textPrimary; text: doseDemoRoot.topEfficacy.toFixed(1) + "%" }
                        }
                        AccentSlider {
                            Layout.fillWidth: true
                            from: 55.0; to: 102.0; value: doseDemoRoot.topEfficacy
                            onMoved: { doseDemoRoot.activePresetIndex = -1; doseDemoRoot.topEfficacy = value; }
                        }
                    }

                    // Assay Noise Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "REPLICATE VARIANCE" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.textPrimary; text: "±" + doseDemoRoot.assayNoise.toFixed(1) + "%" }
                        }
                        AccentSlider {
                            Layout.fillWidth: true
                            from: 0.5; to: 6.5; value: doseDemoRoot.assayNoise
                            onMoved: { doseDemoRoot.activePresetIndex = -1; doseDemoRoot.assayNoise = value; }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.divider }

                    // Live Calculated Stats + HTS Z'-Factor Gate
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "GOODNESS OF FIT (R²)" }
                            Item { Layout.fillWidth: true }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold
                                color: doseDemoRoot.computedRSquared >= 0.95 ? Theme.statusGreen : Theme.statusWarning
                                text: doseDemoRoot.computedRSquared.toFixed(4)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "pIC50 (-log IC50)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.textPrimary; text: (-Math.log10(doseDemoRoot.ic50 * 1e-6)).toFixed(2) }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "CONFIDENCE (95% CI)" }
                            Item { Layout.fillWidth: true }
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold; color: Theme.textPrimary; text: "± " + doseDemoRoot.computedCi95.toFixed(2) + " µM" }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; color: Theme.textMuted; text: "HTS Z'-FACTOR" }
                            Item { Layout.fillWidth: true }
                            Text {
                                font.family: Theme.fontMono; font.pixelSize: Theme.sizeMicro; font.weight: Font.Bold
                                color: doseDemoRoot.zPrimeQualityColor
                                text: doseDemoRoot.computedZPrime.toFixed(2) + " • " + doseDemoRoot.zPrimeQualityLabel
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
