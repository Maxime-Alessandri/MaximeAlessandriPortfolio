import QtQuick
import InvenesisPortfolio

Item {
    id: emblemRoot

    implicitWidth: 28
    implicitHeight: 28

    property int conceptIndex: Theme.activeLogoConcept
    property color badgeColor: Theme.paletteAccent
    property color emblemColor: Theme.textOnAccent
    property color accentColor: Theme.isDark ? Qt.color("#FFFFFF") : Qt.color("#000000")
    property bool showBackgroundBadge: true
    property real badgeRadius: width / 2.0

    function drawRoundedRect(c, x, y, rw, rh, r) {
        c.beginPath();
        c.moveTo(x + r, y);
        c.lineTo(x + rw - r, y);
        c.arcTo(x + rw, y, x + rw, y + r, r);
        c.lineTo(x + rw, y + rh - r);
        c.arcTo(x + rw, y + rh, x + rw - r, y + rh, r);
        c.lineTo(x + r, y + rh);
        c.arcTo(x, y + rh, x, y + rh - r, r);
        c.lineTo(x, y + r);
        c.arcTo(x, y, x + r, y, r);
        c.closePath();
    }

    // Background circular or rounded squircle chassis
    Rectangle {
        id: bgBadge
        anchors.fill: parent
        radius: emblemRoot.badgeRadius
        color: emblemRoot.badgeColor
        visible: emblemRoot.showBackgroundBadge

        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // High-precision vector canvas
    Canvas {
        id: vectorCanvas
        anchors.fill: parent
        anchors.margins: emblemRoot.showBackgroundBadge ? Math.max(1, Math.round(emblemRoot.width * 0.05)) : 0
        renderStrategy: Canvas.Immediate
        antialiasing: true
        smooth: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.imageSmoothingEnabled = true;

            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            // Normalized against 28x28 design canvas
            var s = Math.min(w, h) / 28.0;
            var ox = (w - 28.0 * s) / 2.0;
            var oy = (h - 28.0 * s) / 2.0;

            ctx.save();
            ctx.translate(ox, oy);
            ctx.scale(s, s);

            var colMain = emblemRoot.emblemColor.toString();
            var colAcc = emblemRoot.accentColor.toString();

            if (emblemRoot.conceptIndex === 0) {
                // =============================================================
                // CONCEPT 0: PURE NEURAL ACTION POTENTIAL (Hodgkin-Huxley)
                // =============================================================

                // 1. Resting Membrane Potential Datum Gridline (-70 mV baseline)
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 1.0;
                ctx.globalAlpha = 0.28;
                ctx.beginPath();
                ctx.moveTo(3.5, 17.0);
                ctx.lineTo(24.5, 17.0);
                ctx.stroke();

                // 2. Continuous Intracellular Action Potential Waveform
                ctx.globalAlpha = 1.0;
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 2.4;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                ctx.beginPath();
                // Resting baseline lead-in
                ctx.moveTo(3.5, 17.0);
                ctx.lineTo(7.5, 17.0);
                // Threshold inflection & soaring depolarization upstroke
                ctx.bezierCurveTo(9.8, 17.0, 11.6, 11.0, 13.0, 4.8);
                // Graceful rounded peak (+40 mV overshoot)
                ctx.bezierCurveTo(13.6, 3.6, 14.4, 3.6, 15.0, 4.8);
                // Rapid repolarization plunge
                ctx.bezierCurveTo(16.0, 11.0, 17.0, 22.8, 18.6, 22.8);
                // After-hyperpolarization undershoot trough (-85 mV) & recovery
                ctx.bezierCurveTo(20.0, 22.8, 21.4, 17.0, 24.5, 17.0);
                ctx.stroke();

                // 3. Peak Activation Apex Gem (+40 mV Overshoot)
                ctx.fillStyle = colAcc;
                ctx.beginPath();
                ctx.arc(14.0, 4.2, 1.6, 0, 2 * Math.PI);
                ctx.fill();

            } else if (emblemRoot.conceptIndex === 1) {
                // =============================================================
                // CONCEPT 1: ELECTROPHYSIOLOGY 'M' (Swiss Monogram + AP Core)
                // =============================================================
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 2.4;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                // Continuous glyph: Left Pillar -> Depolarization Spike -> Right Pillar
                ctx.beginPath();
                // Left vertical stem (from base to top)
                ctx.moveTo(5.5, 22.0);
                ctx.lineTo(5.5, 7.0);
                // Descend smoothly to resting threshold
                ctx.bezierCurveTo(5.5, 12.5, 7.8, 16.5, 9.8, 16.5);
                // Depolarization upstroke
                ctx.bezierCurveTo(11.8, 16.5, 12.8, 9.5, 13.6, 4.6);
                // Rounded peak
                ctx.bezierCurveTo(14.0, 3.8, 14.6, 3.8, 15.0, 4.6);
                // Repolarization plunge into hyperpolarization
                ctx.bezierCurveTo(15.8, 9.5, 16.8, 21.0, 18.4, 21.0);
                // Recovery ascending to right stem top
                ctx.bezierCurveTo(20.0, 21.0, 22.5, 12.5, 22.5, 7.0);
                // Right vertical stem (down to base)
                ctx.lineTo(22.5, 22.0);
                ctx.stroke();

                // Glowing Action Potential Apex Gem
                ctx.fillStyle = colAcc;
                ctx.beginPath();
                ctx.arc(14.3, 4.2, 1.5, 0, 2 * Math.PI);
                ctx.fill();

            } else if (emblemRoot.conceptIndex === 2) {
                // =============================================================
                // CONCEPT 2: SWISS DECK CALIPERS (Precision Cross & Well)
                // =============================================================
                ctx.fillStyle = colMain;
                ctx.strokeStyle = colMain;

                // 1. Monolithic Swiss Cross Arms
                var armThickness = 5.6;
                var halfThick = armThickness / 2.0;
                var crossRadius = 1.8;

                // Horizontal cross bar
                drawRoundedRect(ctx, 4.5, 14.0 - halfThick, 19.0, armThickness, crossRadius);
                ctx.fill();

                // Vertical cross bar
                drawRoundedRect(ctx, 14.0 - halfThick, 4.5, armThickness, 19.0, crossRadius);
                ctx.fill();

                // 2. Central Micro-Well Droplet Aperture (Alpha Cutout)
                ctx.save();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(14.0, 14.0, 3.2, 0, 2 * Math.PI);
                ctx.fill();
                ctx.restore();

                // 3. Floating Central Micro-Droplet Sphere
                ctx.fillStyle = colAcc;
                ctx.beginPath();
                ctx.arc(14.0, 14.0, 1.6, 0, 2 * Math.PI);
                ctx.fill();

                // 4. Precision Cartesian Caliper Corner Notches (Optical Ticks)
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 1.2;
                ctx.lineCap = "square";
                ctx.globalAlpha = 0.45;

                var cr = 2.4;
                // Top-Left
                ctx.beginPath(); ctx.moveTo(5.5, 5.5 + cr); ctx.lineTo(5.5, 5.5); ctx.lineTo(5.5 + cr, 5.5); ctx.stroke();
                // Top-Right
                ctx.beginPath(); ctx.moveTo(22.5 - cr, 5.5); ctx.lineTo(22.5, 5.5); ctx.lineTo(22.5, 5.5 + cr); ctx.stroke();
                // Bottom-Left
                ctx.beginPath(); ctx.moveTo(5.5, 22.5 - cr); ctx.lineTo(5.5, 22.5); ctx.lineTo(5.5 + cr, 22.5); ctx.stroke();
                // Bottom-Right
                ctx.beginPath(); ctx.moveTo(22.5 - cr, 22.5); ctx.lineTo(22.5, 22.5); ctx.lineTo(22.5, 22.5 - cr); ctx.stroke();
                ctx.globalAlpha = 1.0;

            } else if (emblemRoot.conceptIndex === 3) {
                // =============================================================
                // CONCEPT 3: TRI-KINEMATIC NEXUS (3-Arm Robotics Orbital)
                // =============================================================
                var cx = 14.0;
                var cy = 14.0;
                var rOrbit = 8.6;

                ctx.strokeStyle = colMain;
                ctx.lineWidth = 2.4;
                ctx.lineCap = "round";

                // Three dynamic sweeping kinetic blades (120 deg apart)
                for (var i = 0; i < 3; i++) {
                    var angle0 = i * (2.0 * Math.PI / 3.0) - Math.PI / 6.0;
                    var angle1 = angle0 + 1.25;

                    ctx.beginPath();
                    ctx.arc(cx, cy, rOrbit, angle0, angle1, false);
                    ctx.stroke();

                    // Leading precision kinetic node on outer tip
                    var tipX = cx + rOrbit * Math.cos(angle1);
                    var tipY = cy + rOrbit * Math.sin(angle1);
                    ctx.fillStyle = colAcc;
                    ctx.beginPath();
                    ctx.arc(tipX, tipY, 1.4, 0, 2 * Math.PI);
                    ctx.fill();
                }

                // Central Robot Kinematic Hub
                ctx.fillStyle = colMain;
                ctx.beginPath();
                ctx.arc(cx, cy, 2.6, 0, 2 * Math.PI);
                ctx.fill();

                // Core aperture inside hub (Alpha Cutout)
                ctx.save();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(cx, cy, 1.1, 0, 2 * Math.PI);
                ctx.fill();
                ctx.restore();

            } else if (emblemRoot.conceptIndex === 4) {
                // =============================================================
                // CONCEPT 4: SBS MICROPLATE MATRIX (Assay Grid & Hit Well)
                // =============================================================
                // 1. ANSI/SLAS SBS Plate Boundary with authentic A1 Chamfer Notch
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 1.4;
                ctx.lineJoin = "round";

                ctx.beginPath();
                // Top edge (starts after A1 chamfer)
                ctx.moveTo(8.5, 4.5);
                ctx.lineTo(21.0, 4.5);
                // Top-right rounded corner
                ctx.arcTo(23.5, 4.5, 23.5, 7.0, 2.5);
                // Right edge
                ctx.lineTo(23.5, 21.0);
                // Bottom-right rounded corner
                ctx.arcTo(23.5, 23.5, 21.0, 23.5, 2.5);
                // Bottom edge
                ctx.lineTo(7.0, 23.5);
                // Bottom-left rounded corner
                ctx.arcTo(4.5, 23.5, 4.5, 21.0, 2.5);
                // Left edge
                ctx.lineTo(4.5, 8.5);
                // A1 Chamfer: 45-degree angle cutting across top-left corner
                ctx.lineTo(8.5, 4.5);
                ctx.closePath();
                ctx.stroke();

                // 2. 3x3 Micro-Well Matrix
                var gridCoords = [9.0, 14.0, 19.0];

                for (var r = 0; r < 3; r++) {
                    for (var col = 0; col < 3; col++) {
                        var wx = gridCoords[col];
                        var wy = gridCoords[r];

                        if (r === 1 && col === 1) {
                            // CENTER HIT WELL: Active biological hit compound
                            ctx.strokeStyle = colAcc;
                            ctx.lineWidth = 1.0;
                            ctx.globalAlpha = 0.45;
                            ctx.beginPath();
                            ctx.arc(wx, wy, 3.6, 0, 2 * Math.PI);
                            ctx.stroke();
                            ctx.globalAlpha = 1.0;

                            // Solid radiant hit disc
                            ctx.fillStyle = colAcc;
                            ctx.beginPath();
                            ctx.arc(wx, wy, 2.2, 0, 2 * Math.PI);
                            ctx.fill();
                        } else {
                            // Standard assay screening wells
                            ctx.strokeStyle = colMain;
                            ctx.lineWidth = 1.1;
                            ctx.beginPath();
                            ctx.arc(wx, wy, 1.8, 0, 2 * Math.PI);
                            ctx.stroke();
                        }
                    }
                }

            } else if (emblemRoot.conceptIndex === 5) {
                // =============================================================
                // CONCEPT 5: TRANSLATIONAL MENISCUS & CODE (Biology ➔ Software)
                // =============================================================
                ctx.strokeStyle = colMain;
                ctx.lineWidth = 2.3;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                // Left biological fluid meniscus droplet
                ctx.beginPath();
                ctx.moveTo(10.5, 4.8);
                // Smooth bulb curve down
                ctx.bezierCurveTo(4.8, 9.8, 4.2, 17.0, 7.8, 20.8);
                ctx.bezierCurveTo(11.4, 24.2, 14.5, 20.0, 13.0, 16.2);
                ctx.stroke();

                // Right software terminal execution bracket `>`
                ctx.beginPath();
                ctx.moveTo(15.2, 7.8);
                ctx.lineTo(21.8, 13.5);
                ctx.lineTo(15.2, 19.2);
                ctx.stroke();

                // Active prompt cursor `_`
                ctx.strokeStyle = colAcc;
                ctx.lineWidth = 2.0;
                ctx.beginPath();
                ctx.moveTo(18.5, 22.5);
                ctx.lineTo(23.5, 22.5);
                ctx.stroke();
            }

            ctx.restore();
        }
    }

    // Force repaint when properties change
    onConceptIndexChanged: vectorCanvas.requestPaint()
    onBadgeColorChanged: vectorCanvas.requestPaint()
    onEmblemColorChanged: vectorCanvas.requestPaint()
    onAccentColorChanged: vectorCanvas.requestPaint()
    onShowBackgroundBadgeChanged: vectorCanvas.requestPaint()
    onWidthChanged: vectorCanvas.requestPaint()
    onHeightChanged: vectorCanvas.requestPaint()
}
