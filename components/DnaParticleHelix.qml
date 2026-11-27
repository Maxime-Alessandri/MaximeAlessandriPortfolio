import QtQuick
import InvenesisPortfolio
import ".."

Item {
    id: helixRoot

    property int particleCount: 750
    property real helixRadius: Math.min(width * 0.22, 190.0)
    property real helixPitch: 0.012
    property real rotationSpeed: 0.008
    property real plumeDispersion: 0.85
    property real repelRadius: 180.0
    property real repelForce: 24.0
    property bool activeSimulation: true

    // Live Telemetry Bindings
    readonly property int liveParticleCount: particleCount
    readonly property bool liveRepulsionActive: mouseTracker.containsMouse
    readonly property real liveThermalIndex: 37.0 + Math.sin(simTime * 0.5) * 0.12
    property real currentFps: 60.0

    property real simTime: 0.0

    Canvas {
        id: particleCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded
        antialiasing: true

        // Particle system storage
        property var particles: []
        property var colorLUT: []
        property bool initialized: false

        // Mouse tracking in canvas local space
        property real mx: -9999
        property real my: -9999
        property bool mouseActive: false

        // Frame timing
        property real lastFrameTime: 0
        property int frameCounter: 0
        property real fpsTimer: 0

        onAvailableChanged: {
            if (available && !initialized) {
                initColorLUT();
                initParticles();
                initialized = true;
            }
        }

        Component.onCompleted: {
            if (available && !initialized) {
                initColorLUT();
                initParticles();
                initialized = true;
            }
        }

        // =====================================================================
        // PRE-COMPILED COLOR LOOKUP TABLE (Dynamic Palette Engine)
        // Pre-computed color strings with quantized alpha steps to eliminate
        // dynamic string allocations on every frame for silky 60 FPS in WASM
        // =====================================================================
        function initColorLUT() {
            var hColors = Theme.helixColors;
            var baseTones = [];
            for (var i = 0; i < hColors.length; ++i) {
                var c = hColors[i];
                baseTones.push({
                    r: Math.round(c.r * 255),
                    g: Math.round(c.g * 255),
                    b: Math.round(c.b * 255)
                });
            }

            // 10 alpha steps from 0.1 to 1.0
            var lut = [];
            for (var b = 0; b < baseTones.length; ++b) {
                var tone = baseTones[b];
                var alphaSteps = [];
                for (var a = 0; a <= 10; ++a) {
                    var alphaVal = (a / 10.0).toFixed(2);
                    alphaSteps.push("rgba(" + tone.r + "," + tone.g + "," + tone.b + "," + alphaVal + ")");
                }
                lut.push(alphaSteps);
            }
            colorLUT = lut;
        }

        // =====================================================================
        // PARTICLE SYSTEM INITIALIZATION
        // Dual-Strand 3D Helix + Horizontal Base Rungs + Curl Ink Plumes
        // =====================================================================
        function initParticles() {
            var pts = [];
            var count = helixRoot.particleCount;
            var h = particleCanvas.height > 0 ? particleCanvas.height : 800;

            for (var i = 0; i < count; ++i) {
                var roll = Math.random();
                var strandType = 0; // 0=StrandA, 1=StrandB, 2=Rung, 3=InkPlume
                var yPos = (Math.random() - 0.5) * h * 1.25;
                var u = 0;

                if (roll < 0.28) {
                    strandType = 0; // Strand A
                } else if (roll < 0.56) {
                    strandType = 1; // Strand B
                } else if (roll < 0.76) {
                    strandType = 2; // Rung
                    u = Math.random(); // Position along rung chord [0, 1]
                } else {
                    strandType = 3; // Ink Plume shedding into curl noise
                }

                var p = {
                    type: strandType,
                    y: yPos,
                    u: u,
                    phase: Math.random() * Math.PI * 2,
                    plumeAge: Math.random(),
                    curlOffsetX: (Math.random() - 0.5) * 10,
                    curlOffsetY: (Math.random() - 0.5) * 10,
                    curlOffsetZ: (Math.random() - 0.5) * 10,

                    // Current 3D position
                    x: 0,
                    z: 0,
                    // Velocity for spring-damped physics
                    vx: 0,
                    vy: 0,
                    vz: 0,
                    // Target orbit position
                    tx: 0,
                    ty: 0,
                    tz: 0,

                    radius: strandType === 3 ? (1.2 + Math.random() * 2.0) : (1.6 + Math.random() * 2.6),
                    colorIdx: strandType === 3 ? (Math.random() > 0.6 ? 0 : 1) : (Math.random() > 0.75 ? 3 : (Math.random() > 0.4 ? 1 : 2)),
                    alpha: 0.4 + Math.random() * 0.6
                };

                computeOrbitTarget(p, 0);
                p.x = p.tx;
                p.y = p.ty;
                p.z = p.tz;

                pts.push(p);
            }
            particles = pts;
        }

        // Compute 3D target coordinates on helical orbit
        function computeOrbitTarget(p, t) {
            var baseRadius = helixRoot.helixRadius;
            var pitch = helixRoot.helixPitch;
            var rot = t * helixRoot.rotationSpeed;
            var theta = p.y * pitch + rot + p.phase * 0.05;

            var r1x = Math.cos(theta) * baseRadius;
            var r1z = Math.sin(theta) * baseRadius;
            var r2x = Math.cos(theta + Math.PI) * baseRadius;
            var r2z = Math.sin(theta + Math.PI) * baseRadius;

            if (p.type === 0) {
                p.tx = r1x + (Math.random() - 0.5) * 6.0;
                p.ty = p.y;
                p.tz = r1z + (Math.random() - 0.5) * 6.0;
            } else if (p.type === 1) {
                p.tx = r2x + (Math.random() - 0.5) * 6.0;
                p.ty = p.y;
                p.tz = r2z + (Math.random() - 0.5) * 6.0;
            } else if (p.type === 2) {
                p.tx = (1.0 - p.u) * r1x + p.u * r2x;
                p.ty = p.y;
                p.tz = (1.0 - p.u) * r1z + p.u * r2z;
            } else {
                // Ink Plumes: Shed outward into 3D curl-noise flow field
                var parentTheta = theta;
                var sourceX = Math.cos(parentTheta) * baseRadius;
                var sourceZ = Math.sin(parentTheta) * baseRadius;

                var scale = 0.006;
                var flowTime = t * 0.4;
                var nx = Math.sin(p.y * scale + flowTime) * Math.cos(p.z * scale);
                var ny = Math.cos(p.x * scale + flowTime) * Math.sin(p.y * scale);
                var nz = Math.sin(p.z * scale + flowTime) * Math.cos(p.x * scale);

                var progress = p.plumeAge;
                var plumeSpread = 160.0 * progress * helixRoot.plumeDispersion;

                p.tx = sourceX + nx * plumeSpread + p.curlOffsetX;
                p.ty = p.y + ny * plumeSpread * 0.4 + p.curlOffsetY;
                p.tz = sourceZ + nz * plumeSpread + p.curlOffsetZ;
            }
        }

        // =====================================================================
        // PHYSICS INTEGRATION & RENDER LOOP
        // =====================================================================
        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            ctx.clearRect(0, 0, w, h);

            var cx = w * 0.58;
            var cy = h * 0.50;
            var fov = 680.0;

            var pts = particles;
            var count = pts.length;
            var t = helixRoot.simTime;
            var repelR = helixRoot.repelRadius;
            var repelF = helixRoot.repelForce;
            var hasMouse = mouseActive && mx > -500;
            var lut = colorLUT;

            ctx.globalCompositeOperation = "lighter";

            var kSpring = 0.085;
            var kDamping = 0.88;

            for (var i = 0; i < count; ++i) {
                var p = pts[i];

                if (p.type === 3) {
                    p.plumeAge += 0.012;
                    if (p.plumeAge >= 1.0) {
                        p.plumeAge = 0.0;
                        p.y = (Math.random() - 0.5) * h * 1.25;
                    }
                }

                computeOrbitTarget(p, t);

                var fx = (p.tx - p.x) * kSpring;
                var fy = (p.ty - p.y) * kSpring;
                var fz = (p.tz - p.z) * kSpring;

                var zDepth = p.z + 500.0;
                var scale = zDepth > 10.0 ? (fov / zDepth) : 1.0;
                var screenX = cx + p.x * scale;
                var screenY = cy + p.y * scale;

                if (hasMouse) {
                    var dx = screenX - mx;
                    var dy = screenY - my;
                    var distSq = dx * dx + dy * dy;
                    var dist = Math.sqrt(distSq);

                    if (dist < repelR && dist > 0.01) {
                        var normDist = dist / repelR;
                        var pushMag = (1.0 - normDist) * (1.0 - normDist) * repelF;
                        var nx = dx / dist;
                        var ny = dy / dist;

                        fx += nx * pushMag * 14.0;
                        fy += ny * pushMag * 14.0;
                        fz += (Math.random() - 0.5) * pushMag * 8.0;
                    }
                }

                p.vx = (p.vx + fx) * kDamping;
                p.vy = (p.vy + fy) * kDamping;
                p.vz = (p.vz + fz) * kDamping;

                p.x += p.vx;
                p.y += p.vy;
                p.z += p.vz;

                zDepth = p.z + 500.0;
                scale = zDepth > 10.0 ? (fov / zDepth) : 1.0;
                screenX = cx + p.x * scale;
                screenY = cy + p.y * scale;

                var depthAlpha = Math.max(0.12, Math.min(1.0, (p.z + 200.0) / 400.0));
                var finalRadius = Math.max(0.7, p.radius * scale);

                if (p.type === 3) {
                    var plumeFade = Math.sin(p.plumeAge * Math.PI);
                    depthAlpha *= plumeFade * 0.75;
                }

                var alpha = p.alpha * depthAlpha;
                var alphaBucket = Math.max(0, Math.min(10, Math.round(alpha * 10)));
                var cIdx = p.colorIdx;

                ctx.beginPath();
                ctx.arc(screenX, screenY, finalRadius, 0, Math.PI * 2);
                var fallbackTone = Theme.paletteAccent;
                ctx.fillStyle = (lut[cIdx] && lut[cIdx][alphaBucket]) ? lut[cIdx][alphaBucket] : Qt.rgba(fallbackTone.r, fallbackTone.g, fallbackTone.b, 0.8);
                ctx.fill();

                if (scale > 1.15 && p.type !== 3) {
                    ctx.beginPath();
                    ctx.arc(screenX, screenY, finalRadius * 0.4, 0, Math.PI * 2);
                    var innerTone = Theme.textPrimary;
                    ctx.fillStyle = Qt.rgba(innerTone.r, innerTone.g, innerTone.b, 0.7);
                    ctx.fill();
                }
            }
        }

        Connections {
            target: Theme
            function onPaletteChanged() {
                particleCanvas.initColorLUT();
                particleCanvas.requestPaint();
            }
        }
    }

    Timer {
        id: animTimer
        interval: 16
        running: helixRoot.activeSimulation && helixRoot.visible
        repeat: true
        onTriggered: {
            helixRoot.simTime += 0.018;
            particleCanvas.requestPaint();

            particleCanvas.frameCounter++;
            var now = Date.now();
            if (particleCanvas.lastFrameTime === 0) particleCanvas.lastFrameTime = now;
            var elapsed = now - particleCanvas.lastFrameTime;
            if (elapsed >= 1000) {
                helixRoot.currentFps = (particleCanvas.frameCounter * 1000.0) / elapsed;
                particleCanvas.frameCounter = 0;
                particleCanvas.lastFrameTime = now;
            }
        }
    }

    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onPositionChanged: function(mouse) {
            particleCanvas.mx = mouse.x;
            particleCanvas.my = mouse.y;
            particleCanvas.mouseActive = true;
        }

        onExited: {
            particleCanvas.mx = -9999;
            particleCanvas.my = -9999;
            particleCanvas.mouseActive = false;
        }
    }
}
