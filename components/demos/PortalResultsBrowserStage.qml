import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import InvenesisPortfolio
import "../.."

ColumnLayout {
    id: resultsStageRoot

    spacing: Theme.spaceSm

    property string requestId: "REQ-2026-042"
    property string projectCode: "PRJ-2026-042"
    property string studyRemarks: ""
    property real plateZPrime: 0.79
    property real plateSbRatio: 6.4
    property real plateControlsCv: 3.1
    property bool ran3dSimulator: false
    property var analyzedResults: []

    property string hitFilter: "ALL"
    property int selectedIdx: 0
    property int hoveredWellIdx: -1

    signal backToLabQc()
    signal restartWorkflow()

    readonly property int totalHitCount: {
        var c = 0;
        for (var i = 0; i < analyzedResults.length; ++i) {
            if (analyzedResults[i].call === "HIT") c++;
        }
        return c;
    }

    readonly property var filteredResults: {
        if (hitFilter === "ALL") return analyzedResults;
        var out = [];
        for (var i = 0; i < analyzedResults.length; ++i) {
            if (analyzedResults[i].call === hitFilter) out.push(analyzedResults[i]);
        }
        return out;
    }

    readonly property var selectedCompound: {
        if (filteredResults.length === 0) return null;
        var idx = Math.max(0, Math.min(selectedIdx, filteredResults.length - 1));
        return filteredResults[idx];
    }

    onSelectedCompoundChanged: {
        hoveredWellIdx = -1;
        curveCanvas.requestPaint();
    }

    onHoveredWellIdxChanged: curveCanvas.requestPaint()

    onVisibleChanged: {
        if (visible) curveCanvas.requestPaint();
    }

    // 1. Top Batch Specifications & Filter Strip (modeled on PortalRequestDetails)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: Theme.radiusSm
        color: Theme.bgSurface
        border.color: Theme.borderCard
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.textPrimary
                text: resultsStageRoot.requestId
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.textDim
                text: "• " + resultsStageRoot.projectCode
            }

            Rectangle {
                Layout.preferredWidth: compBadgeTxt.implicitWidth + 14
                Layout.preferredHeight: 22
                radius: Theme.radiusPill
                color: Theme.statusGreen
                Text {
                    id: compBadgeTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Theme.textOnGreen
                    text: "COMPLETED"
                }
            }

            Rectangle {
                Layout.preferredWidth: zpBadgeTxt.implicitWidth + 14
                Layout.preferredHeight: 22
                radius: Theme.radiusPill
                color: Theme.alpha(Theme.statusGreen, 0.14)
                border.color: Theme.statusGreen
                border.width: 1
                Text {
                    id: zpBadgeTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Theme.statusGreen
                    text: "Z'=" + resultsStageRoot.plateZPrime.toFixed(2) + " PASS"
                }
            }

            Rectangle {
                visible: resultsStageRoot.ran3dSimulator
                Layout.preferredWidth: gwlBadgeTxt.implicitWidth + 14
                Layout.preferredHeight: 22
                radius: Theme.radiusPill
                color: Theme.alpha(Theme.paletteAccent, 0.14)
                border.color: Theme.paletteAccent
                border.width: 1
                Text {
                    id: gwlBadgeTxt
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: Theme.paletteAccent
                    text: "3D GWL VERIFIED"
                }
            }

            Text {
                font.family: Theme.fontMono
                font.pixelSize: 9
                color: Theme.textMuted
                text: resultsStageRoot.totalHitCount + "/" + resultsStageRoot.analyzedResults.length + " Hits"
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4
                Repeater {
                    model: ["ALL", "HIT", "MODERATE", "INACTIVE"]
                    Rectangle {
                        required property var modelData
                        readonly property bool isSel: resultsStageRoot.hitFilter === modelData
                        width: fTxt.implicitWidth + 14
                        height: 24
                        radius: Theme.radiusPill
                        color: isSel ? Theme.paletteAccent : Theme.bgCard
                        border.color: isSel ? Theme.paletteAccent : Theme.borderCard
                        border.width: 1
                        Text {
                            id: fTxt
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: isSel ? Theme.textOnAccent : Theme.textPrimary
                            text: modelData
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                resultsStageRoot.hitFilter = modelData;
                                resultsStageRoot.selectedIdx = 0;
                                resultsStageRoot.hoveredWellIdx = -1;
                                curveCanvas.requestPaint();
                            }
                        }
                    }
                }
            }
        }
    }

    // 2. Main Master-Detail Results Browser
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.spaceMd

        // Left Pane: Screened Compounds List
        Rectangle {
            Layout.preferredWidth: 274
            Layout.fillHeight: true
            radius: Theme.radiusSm
            color: Theme.bgVoid
            border.color: Theme.borderCard
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.terracottaGlow
                        text: "SCREENED COMPOUNDS (" + resultsStageRoot.filteredResults.length + ")"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        color: Theme.textDim
                        text: "SELECT FOR 4PL"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        visible: resultsStageRoot.filteredResults.length === 0
                        width: parent.width - 20
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        color: Theme.textDim
                        text: "No compounds match '" + resultsStageRoot.hitFilter + "' filter."
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: listCol.implicitHeight
                        clip: true

                        ColumnLayout {
                            id: listCol
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: resultsStageRoot.filteredResults

                                Rectangle {
                                    id: cmpRowCard
                                    required property int index
                                    required property var modelData

                                    readonly property bool isSel: resultsStageRoot.selectedIdx === index
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 58
                                    radius: 6
                                    color: isSel ? Theme.alpha(Theme.paletteAccent, 0.14) : Theme.bgSurface
                                    border.color: isSel ? Theme.paletteAccent : Theme.borderCard
                                    border.width: isSel ? 1.5 : 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: 10
                                            Layout.preferredHeight: 10
                                            radius: 5
                                            color: cmpRowCard.modelData.color
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                font.family: Theme.fontMono
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: Theme.textPrimary
                                                text: cmpRowCard.modelData.id
                                            }

                                            Text {
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                color: Theme.textMuted
                                                text: cmpRowCard.modelData.assay + " • Row " + cmpRowCard.modelData.rowLabel + " • " + cmpRowCard.modelData.replicates + "x"
                                            }

                                            Text {
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                color: Theme.paletteAccent
                                                text: "IC50 " + cmpRowCard.modelData.ic50.toFixed(2) + " µM • Emax " + cmpRowCard.modelData.emax.toFixed(0) + "%"
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 62
                                            Layout.preferredHeight: 20
                                            radius: 10
                                            color: cmpRowCard.modelData.call === "HIT"
                                                   ? Theme.statusGreen
                                                   : (cmpRowCard.modelData.call === "MODERATE" ? Theme.statusWarning : Theme.bgCard)

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                                color: cmpRowCard.modelData.call === "INACTIVE" ? Theme.textDim : Theme.textOn(parent.color)
                                                text: cmpRowCard.modelData.call
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            resultsStageRoot.selectedIdx = cmpRowCard.index;
                                            resultsStageRoot.hoveredWellIdx = -1;
                                            curveCanvas.requestPaint();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right Pane: Interactive 4PL Dose-Response Curve + Well Raw Readouts
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusSm
            color: Theme.bgSurface
            border.color: Theme.borderCard
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Compound Header + Quantitative 4PL Metrics Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        radius: 6
                        visible: resultsStageRoot.selectedCompound !== null
                        color: resultsStageRoot.selectedCompound ? resultsStageRoot.selectedCompound.color : Theme.paletteAccent
                    }

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: resultsStageRoot.selectedCompound
                              ? (resultsStageRoot.selectedCompound.id + " (" + resultsStageRoot.selectedCompound.assay + ")")
                              : "No Compound Selected"
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: resultsStageRoot.selectedCompound ? [
                            { k: "IC50",  v: resultsStageRoot.selectedCompound.ic50.toFixed(2) + " µM", c: Theme.paletteAccent },
                            { k: "pIC50", v: resultsStageRoot.selectedCompound.pic50.toFixed(2),        c: Theme.textPrimary },
                            { k: "HILL",  v: resultsStageRoot.selectedCompound.hill.toFixed(2),         c: Theme.textPrimary },
                            { k: "EMAX",  v: resultsStageRoot.selectedCompound.emax.toFixed(1) + "%",   c: Theme.statusGreen },
                            { k: "R²",    v: resultsStageRoot.selectedCompound.rSquared.toFixed(3),     c: Theme.statusGreen }
                        ] : []

                        Rectangle {
                            required property var modelData
                            Layout.preferredWidth: 74
                            Layout.preferredHeight: 34
                            radius: 5
                            color: Theme.bgVoid
                            border.color: Theme.borderCard
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    font.family: Theme.fontMono
                                    font.pixelSize: 7
                                    color: Theme.textDim
                                    text: modelData.k
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: modelData.c
                                    text: modelData.v
                                }
                            }
                        }
                    }
                }

                // 4PL Sigmoid Dose-Response Canvas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: Theme.bgVoid
                    border.color: Theme.borderCard
                    border.width: 1
                    clip: true

                    Canvas {
                        id: curveCanvas
                        anchors.fill: parent
                        anchors.margins: 8
                        antialiasing: true

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        Connections {
                            target: Theme
                            function onPaletteChanged() { curveCanvas.requestPaint(); }
                        }

                        function evalHill(cmp, conc) {
                            var bot = cmp.bottom !== undefined ? cmp.bottom : 2.0;
                            var top = cmp.emax;
                            var ic50 = Math.max(0.0001, cmp.ic50);
                            var hill = cmp.hill || 1.2;
                            return bot + (top - bot) / (1.0 + Math.pow(ic50 / Math.max(0.00001, conc), hill));
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            var w = width;
                            var h = height;
                            if (w <= 10 || h <= 10) return;
                            ctx.clearRect(0, 0, w, h);

                            var cmp = resultsStageRoot.selectedCompound;
                            if (!cmp || !cmp.wells || cmp.wells.length === 0) return;

                            var mLeft = 48;
                            var mRight = 24;
                            var mTop = 20;
                            var mBottom = 34;
                            var plotW = w - mLeft - mRight;
                            var plotH = h - mTop - mBottom;
                            if (plotW <= 10 || plotH <= 10) return;

                            // Derive log10 concentration domain dynamically around the compound's tested range
                            var minC = cmp.wells[0].concUm;
                            var maxC = cmp.wells[0].concUm;
                            for (var k = 1; k < cmp.wells.length; ++k) {
                                minC = Math.min(minC, cmp.wells[k].concUm);
                                maxC = Math.max(maxC, cmp.wells[k].concUm);
                            }
                            var logMin = Math.floor(Math.log10(Math.max(0.0001, minC)) - 0.35);
                            var logMax = Math.ceil(Math.log10(Math.max(0.001, maxC)) + 0.35);
                            if (logMax - logMin < 3) logMin = logMax - 3;

                            var yMin = 0.0;
                            var yMax = 110.0;

                            function toX(conc) {
                                var lc = Math.log10(Math.max(0.00001, conc));
                                return mLeft + ((lc - logMin) / (logMax - logMin)) * plotW;
                            }
                            function toY(pct) {
                                return mTop + plotH - ((pct - yMin) / (yMax - yMin)) * plotH;
                            }

                            // 1. Subtle Grid Lines & Axes Labels
                            ctx.strokeStyle = Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.09);
                            ctx.lineWidth = 1;
                            ctx.fillStyle = Theme.textMuted;
                            ctx.font = "9px 'JetBrains Mono', monospace";

                            // Vertical decade ticks
                            ctx.textAlign = "center";
                            for (var d = logMin; d <= logMax; ++d) {
                                var doseTick = Math.pow(10, d);
                                var gx = mLeft + ((d - logMin) / (logMax - logMin)) * plotW;
                                ctx.beginPath();
                                ctx.moveTo(gx, mTop);
                                ctx.lineTo(gx, mTop + plotH);
                                ctx.stroke();
                                var lbl = doseTick >= 1 ? (doseTick.toFixed(0) + " µM") : (doseTick.toPrecision(1) + " µM");
                                ctx.fillText(lbl, gx, mTop + plotH + 16);
                            }

                            // Horizontal % inhibition ticks
                            ctx.textAlign = "right";
                            var yTicks = [0, 25, 50, 75, 100];
                            for (var t = 0; t < yTicks.length; ++t) {
                                var gy = toY(yTicks[t]);
                                ctx.beginPath();
                                ctx.moveTo(mLeft, gy);
                                ctx.lineTo(mLeft + plotW, gy);
                                ctx.stroke();
                                ctx.fillText(yTicks[t] + "%", mLeft - 6, gy + 3);
                            }

                            // 2. 80% Hit Threshold Line
                            ctx.save();
                            ctx.strokeStyle = Qt.rgba(Theme.statusGreen.r, Theme.statusGreen.g, Theme.statusGreen.b, 0.45);
                            ctx.lineWidth = 1;
                            ctx.setLineDash([4, 4]);
                            var y80 = toY(80.0);
                            ctx.beginPath();
                            ctx.moveTo(mLeft, y80);
                            ctx.lineTo(mLeft + plotW, y80);
                            ctx.stroke();
                            ctx.fillStyle = Theme.statusGreen;
                            ctx.textAlign = "left";
                            ctx.fillText("80% HIT GATE", mLeft + 6, y80 - 4);
                            ctx.restore();

                            // 3. Fitted 4PL Hill Curve + Soft Area Fill
                            var curveCol = Qt.color(cmp.color);
                            var samples = 110;
                            ctx.beginPath();
                            for (var s = 0; s <= samples; ++s) {
                                var lVal = logMin + (s / samples) * (logMax - logMin);
                                var concVal = Math.pow(10, lVal);
                                var respVal = evalHill(cmp, concVal);
                                var px = mLeft + (s / samples) * plotW;
                                var py = toY(respVal);
                                if (s === 0) ctx.moveTo(px, py);
                                else ctx.lineTo(px, py);
                            }
                            ctx.strokeStyle = curveCol;
                            ctx.lineWidth = 2.5;
                            ctx.stroke();

                            // Translucent fill under curve
                            ctx.lineTo(mLeft + plotW, toY(0));
                            ctx.lineTo(mLeft, toY(0));
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(curveCol.r, curveCol.g, curveCol.b, 0.12);
                            ctx.fill();

                            // 4. Midpoint IC50 Crosshairs & Label
                            var midPct = ((cmp.bottom !== undefined ? cmp.bottom : 2.0) + cmp.emax) * 0.5;
                            var icX = toX(cmp.ic50);
                            var icY = toY(midPct);
                            if (icX >= mLeft && icX <= mLeft + plotW) {
                                ctx.save();
                                ctx.strokeStyle = Theme.terracottaGlow;
                                ctx.lineWidth = 1.2;
                                ctx.setLineDash([3, 3]);
                                ctx.beginPath();
                                ctx.moveTo(icX, toY(0));
                                ctx.lineTo(icX, icY);
                                ctx.lineTo(mLeft, icY);
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.arc(icX, icY, 4.5, 0, Math.PI * 2);
                                ctx.fillStyle = Theme.terracottaGlow;
                                ctx.fill();

                                ctx.fillStyle = Theme.terracottaGlow;
                                ctx.font = "bold 9px 'JetBrains Mono', monospace";
                                ctx.textAlign = icX > mLeft + plotW * 0.65 ? "right" : "left";
                                var offsetX = icX > mLeft + plotW * 0.65 ? -8 : 8;
                                ctx.fillText("IC50 " + cmp.ic50.toFixed(2) + " µM", icX + offsetX, icY - 6);
                                ctx.restore();
                            }

                            // 5. Measured Plate Well Points + Error Whiskers
                            for (var i = 0; i < cmp.wells.length; ++i) {
                                var pt = cmp.wells[i];
                                var wx = toX(pt.concUm);
                                var wy = toY(pt.inhibition);
                                var errPx = Math.abs(toY(pt.inhibition - pt.spread) - toY(pt.inhibition + pt.spread)) * 0.5;
                                var isHover = (resultsStageRoot.hoveredWellIdx === i);

                                // Replicate error bar
                                ctx.strokeStyle = Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.45);
                                ctx.lineWidth = 1.2;
                                ctx.beginPath();
                                ctx.moveTo(wx, wy - errPx);
                                ctx.lineTo(wx, wy + errPx);
                                ctx.moveTo(wx - 3, wy - errPx);
                                ctx.lineTo(wx + 3, wy - errPx);
                                ctx.moveTo(wx - 3, wy + errPx);
                                ctx.lineTo(wx + 3, wy + errPx);
                                ctx.stroke();

                                // Well Circle
                                ctx.beginPath();
                                ctx.arc(wx, wy, isHover ? 6.5 : 4.5, 0, Math.PI * 2);
                                ctx.fillStyle = isHover ? Theme.terracottaGlow : curveCol;
                                ctx.fill();
                                ctx.lineWidth = isHover ? 2.0 : 1.2;
                                ctx.strokeStyle = Theme.bgVoid;
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onExited: resultsStageRoot.hoveredWellIdx = -1
                            onPositionChanged: function(mouse) {
                                var cmp = resultsStageRoot.selectedCompound;
                                if (!cmp || !cmp.wells || cmp.wells.length === 0) {
                                    resultsStageRoot.hoveredWellIdx = -1;
                                    return;
                                }
                                var mLeft = 48;
                                var mRight = 24;
                                var plotW = curveCanvas.width - mLeft - mRight;
                                if (plotW <= 10) return;

                                var minC = cmp.wells[0].concUm;
                                var maxC = cmp.wells[0].concUm;
                                for (var k = 1; k < cmp.wells.length; ++k) {
                                    minC = Math.min(minC, cmp.wells[k].concUm);
                                    maxC = Math.max(maxC, cmp.wells[k].concUm);
                                }
                                var logMin = Math.floor(Math.log10(Math.max(0.0001, minC)) - 0.35);
                                var logMax = Math.ceil(Math.log10(Math.max(0.001, maxC)) + 0.35);
                                if (logMax - logMin < 3) logMin = logMax - 3;

                                var bestIdx = -1;
                                var bestDist = 22;
                                for (var i = 0; i < cmp.wells.length; ++i) {
                                    var lc = Math.log10(Math.max(0.00001, cmp.wells[i].concUm));
                                    var px = mLeft + ((lc - logMin) / (logMax - logMin)) * plotW;
                                    var dx = Math.abs(mouse.x - px);
                                    if (dx < bestDist) {
                                        bestDist = dx;
                                        bestIdx = i;
                                    }
                                }
                                resultsStageRoot.hoveredWellIdx = bestIdx;
                            }
                        }
                    }

                    // Hover Well Tooltip Pill
                    Rectangle {
                        visible: resultsStageRoot.hoveredWellIdx >= 0
                                 && resultsStageRoot.selectedCompound !== null
                                 && resultsStageRoot.hoveredWellIdx < resultsStageRoot.selectedCompound.wells.length
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: hoverTipTxt.implicitWidth + 16
                        height: 24
                        radius: Theme.radiusPill
                        color: Theme.tooltipFill
                        border.color: Theme.terracottaGlow
                        border.width: 1

                        Text {
                            id: hoverTipTxt
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            text: {
                                var cmp = resultsStageRoot.selectedCompound;
                                var idx = resultsStageRoot.hoveredWellIdx;
                                if (!cmp || idx < 0 || idx >= cmp.wells.length) return "";
                                var w = cmp.wells[idx];
                                return "Well " + w.wellId + " • " + w.concUm.toFixed(2) + " µM ➔ " + w.inhibition.toFixed(1) + "% inh";
                            }
                        }
                    }
                }

                // Well-by-Well Raw Data Strip
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: Theme.bgVoid
                    border.color: Theme.borderCard
                    border.width: 1
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 5
                        contentWidth: wellPillRow.implicitWidth
                        clip: true

                        Row {
                            id: wellPillRow
                            spacing: 6
                            Repeater {
                                model: resultsStageRoot.selectedCompound ? resultsStageRoot.selectedCompound.wells : []
                                Rectangle {
                                    required property int index
                                    required property var modelData
                                    readonly property bool isHi: resultsStageRoot.hoveredWellIdx === index
                                    width: wPillTxt.implicitWidth + 14
                                    height: 24
                                    radius: 4
                                    color: isHi ? Theme.paletteAccent : Theme.bgSurface
                                    border.color: isHi ? Theme.paletteAccent : Theme.borderCard
                                    border.width: 1
                                    Text {
                                        id: wPillTxt
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        font.weight: isHi ? Font.Bold : Font.Normal
                                        color: isHi ? Theme.textOnAccent : Theme.textSecondary
                                        text: modelData.wellId + ": " + (modelData.concUm >= 1 ? modelData.concUm.toFixed(1) : modelData.concUm.toFixed(2)) + "µM ➔ " + Math.round(modelData.inhibition) + "%"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: resultsStageRoot.hoveredWellIdx = index
                                        onExited: resultsStageRoot.hoveredWellIdx = -1
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom Bar: Remarks note + Back + Restart
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textDim
                        text: resultsStageRoot.studyRemarks !== ""
                              ? ("NOTE: " + resultsStageRoot.studyRemarks)
                              : ("PLATE QC: S/B " + resultsStageRoot.plateSbRatio.toFixed(1) + "x • CTRL CV " + resultsStageRoot.plateControlsCv.toFixed(1) + "% • A01–H12 STORED IN POSTGRESQL")
                    }

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 34
                        radius: Theme.radiusPill
                        color: Theme.bgCard
                        border.color: Theme.borderCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            text: "← Lab QC Heatmap"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: resultsStageRoot.backToLabQc()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 186
                        Layout.preferredHeight: 34
                        radius: Theme.radiusPill
                        color: Theme.cinnabar
                        border.color: Theme.terracottaGlow
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.textOnCinnabar
                            text: "Start New Simulation ↻"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: resultsStageRoot.restartWorkflow()
                        }
                    }
                }
            }
        }
    }
}
