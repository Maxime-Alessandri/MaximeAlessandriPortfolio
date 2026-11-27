pragma Singleton
import QtQuick

QtObject {
    id: theme

    // =========================================================================
    // 20 CURATED AGENCY PALETTES (12 DARK MODE + 8 LIGHT MODE)
    // Structure: [c0, c1, c2, c3, c4]
    // Slot 0: Deep/Secondary Accent
    // Slot 1: Primary Signature Accent (Plasma, CTAs, Focus)
    // Slot 2: Typography / Foreground Ink (Cream/White in Dark, Obsidian/Ink in Light)
    // Slot 3: Base Canvas / Background Void (Deep Void in Dark, Off-White in Light)
    // Slot 4: Secondary Tech Accent / Telemetry / Highlights
    // =========================================================================

    readonly property var presets: ({
        // --- 12 DARK MODE PALETTES (Flagship Apple Pro + Swiss Engineering) ---
        "applePro":         ["#1D1D1F", "#2997FF", "#F5F5F7", "#000000", "#86868B"], // 01. Apple Space Black & Cupertino Electric Blue (WWDC Flagship)
        "appleBiolab":      ["#0B132B", "#00D2FF", "#F0F6FC", "#06080D", "#58A6FF"], // 02. Apple Biotech Neuro-Cyan & Cleanroom Midnight
        "appleTitanium":    ["#242426", "#0071E3", "#F5F5F7", "#0C0D0E", "#98989D"], // 03. Natural Titanium & Deep Space Slate
        "swissPrecision":   ["#3D1E03", "#FF5500", "#F2F4F7", "#0A0B0E", "#717D8A"], // 04. Leica / Teenage Engineering Tungsten & Titanium
        "bioluminescence":  ["#0B1B3D", "#00D2FF", "#EEF7FB", "#04080F", "#5BC0BE"], // 05. Confocal 2-Photon Neuro-Cyan & Deep Void
        "genevaHorology":   ["#0F2E23", "#2DD4BF", "#F5F5F0", "#08120E", "#C2A676"], // 06. Alpine Spruce, Mint Emerald & Brass Horology
        "stealthIris":      ["#1E1B4B", "#6366F1", "#F8FAFC", "#070709", "#38BDF8"], // 07. Linear Studio Hyper-Violet & Pure White
        "emeraldCleanroom": ["#062A1B", "#10B981", "#ECFDF5", "#06130D", "#34D399"], // 08. High-Precision Life Sciences Green & Spruce
        "carbonMonochrome": ["#22252A", "#E2E8F0", "#FFFFFF", "#0B0C0E", "#94A3B8"], // 09. Architectural Titanium Monolith Grayscale
        "deepOceanAbyss":   ["#002840", "#00A8E8", "#E6F4F8", "#00101D", "#007EA7"], // 10. Oceanic Trench Midnight Cobalt & Azure
        "amethystQuantum":  ["#2C0D42", "#A855F7", "#F5EEFD", "#09040E", "#C084FC"], // 11. Quantum Computing Amethyst & Deep Violet
        "kineticCopper":    ["#4A1E17", "#FF5A36", "#F3F1EC", "#0E0F12", "#5C6B73"], // 12. Basalt Charcoal, Radiant Polished Copper & Steel

        // --- 8 LIGHT MODE PALETTES ---
        "appleCleanroom":   ["#E5E5EA", "#0071E3", "#1D1D1F", "#F5F5F7", "#86868B"], // 13. Apple Pure Cleanroom Light Mode (Studio Display)
        "swissCleanroom":   ["#94A3B8", "#FF5500", "#0F172A", "#F8FAFC", "#3B82F6"], // 14. High-Contrast Sterile Cleanroom White & Amber
        "nordicFrost":      ["#CBD5E1", "#0284C7", "#0F172A", "#F1F5F9", "#0EA5E9"], // 15. Arctic Glacial Frost Blue & Dark Slate Ink
        "editorialWashi":   ["#C2A676", "#C1492E", "#1C1917", "#FDFBF7", "#8C7A6B"], // 16. Warm Japanese Washi Paper, Terracotta & Sumi Ink
        "medicalPharma":    ["#93C5FD", "#2563EB", "#0B192C", "#F0F6FF", "#06B6D4"], // 17. Clinical High-Throughput Pharma Blue & Snow Base
        "sageBotanical":    ["#A7D7C5", "#059669", "#0F281E", "#F4F9F6", "#10B981"], // 18. Organic Biotech Botanical Sage & Deep Forest Ink
        "minimalBauhaus":   ["#D4D4D8", "#E11D48", "#18181B", "#FAFAFA", "#2563EB"], // 19. Swiss Bauhaus Stark White, Crimson & Black Ink
        "pureMonolith":     ["#CBD5E1", "#1E293B", "#020617", "#FFFFFF", "#64748B"]  // 20. Pure Museum Gallery Monolith (White & Black)
    })

    // Active preset name — default to Apple Pro:
    property string activePreset: "applePro"

    // Active palette array
    property var palette: presets[activePreset] || presets["applePro"]

    function setPalette(presetOrArray) {
        if (typeof presetOrArray === "string" && presets[presetOrArray]) {
            activePreset = presetOrArray;
            palette = presets[presetOrArray].slice();
        } else if (Array.isArray(presetOrArray) && presetOrArray.length >= 5) {
            activePreset = "custom";
            palette = presetOrArray.slice();
        }
    }

    function nextPreset() {
        var keys = Object.keys(presets);
        var idx = keys.indexOf(activePreset);
        var nextIdx = (idx + 1) % keys.length;
        setPalette(keys[nextIdx]);
    }

    function prevPreset() {
        var keys = Object.keys(presets);
        var idx = keys.indexOf(activePreset);
        var prevIdx = (idx - 1 + keys.length) % keys.length;
        setPalette(keys[prevIdx]);
    }

    function toggleDarkLight() {
        setPalette(isDark ? "appleCleanroom" : "applePro");
    }

    // =========================================================================
    // BRAND EMBLEM LOGO PRESETS & CONCEPTS
    // =========================================================================
    property int activeLogoConcept: 0

    readonly property var logoConcepts: [
        {
            id: "pureActionPotential",
            name: "Neural Action Potential",
            tagline: "Hodgkin-Huxley Waveform",
            description: "Pure intracellular action potential spike (+40mV overshoot, repolarization plunge, and -85mV after-hyperpolarization undershoot) grounded by an authentic resting membrane potential (-70mV) datum line. Pure biophysical elegance honoring PhD neurobiology.",
            icon: "⚡"
        },
        {
            id: "synapticM",
            name: "Electrophysiology 'M'",
            tagline: "Architectural Swiss Monogram",
            description: "A precision Swiss 'M' monogram where the central valley forms a continuous, soaring action potential depolarization wave. Modern architectural typography seamlessly fused with neural signaling—without pipette tips, just pure geometric form.",
            icon: "Ⓜ"
        },
        {
            id: "swissCross",
            name: "Swiss Deck Calipers",
            tagline: "Cartesian Deck Precision",
            description: "Monolithic Swiss cross sculpted with Cartesian coordinate caliper notches and a central micro-well aperture. Homage to Swiss biotechnology engineering and liquid handling deck standards.",
            icon: "+"
        },
        {
            id: "triKinematic",
            name: "Tri-Kinematic Nexus",
            tagline: "3-Arm Robotics Orbital",
            description: "Three sweeping aerodynamic blades converging in 120° rotational symmetry, symbolizing the synchronized multi-threaded arms of the Tecan Fluent: LiHa pipetting, RoMa robotic gripper, and MCA96 head.",
            icon: "⚙"
        },
        {
            id: "microplate",
            name: "SBS Microplate Matrix",
            tagline: "High-Throughput Assay & Hit",
            description: "An authentic SBS microplate silhouette with an ANSI/SLAS A1 registration chamfer, containing a 3x3 well matrix and a radiant cherry-picked hit compound.",
            icon: "▦"
        },
        {
            id: "translational",
            name: "Translational Meniscus",
            tagline: "Wet-Lab Droplet ➔ Code `>_`",
            description: "An organic biological fluid meniscus droplet seamlessly transitioning into a compiled software terminal bracket (`>_`). Represents the career core of automating wet biology into deterministic code.",
            icon: "⇄"
        }
    ]

    function nextLogo() {
        activeLogoConcept = (activeLogoConcept + 1) % logoConcepts.length;
    }

    function setLogo(index) {
        if (index >= 0 && index < logoConcepts.length) {
            activeLogoConcept = index;
        }
    }

    // Helper Color Transformations
    function parse(c) {
        return Qt.color(c);
    }

    function alpha(c, a) {
        var col = Qt.color(c);
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    function lighten(c, factor) {
        var col = Qt.color(c);
        return Qt.rgba(col.r + (1.0 - col.r) * factor,
                       col.g + (1.0 - col.g) * factor,
                       col.b + (1.0 - col.b) * factor,
                       col.a);
    }

    function darken(c, factor) {
        var col = Qt.color(c);
        return Qt.rgba(col.r * (1.0 - factor),
                       col.g * (1.0 - factor),
                       col.b * (1.0 - factor),
                       col.a);
    }

    function mix(c1, c2, weight) {
        var col1 = Qt.color(c1);
        var col2 = Qt.color(c2);
        var w = Math.max(0.0, Math.min(1.0, weight));
        return Qt.rgba(col1.r * (1.0 - w) + col2.r * w,
                       col1.g * (1.0 - w) + col2.g * w,
                       col1.b * (1.0 - w) + col2.b * w,
                       col1.a * (1.0 - w) + col2.a * w);
    }

    function luminance(c) {
        var col = Qt.color(c);
        return 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
    }

    function textOn(bgColor) {
        var col = Qt.color(bgColor);
        var lum = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
        var crWhite = (1.0 + 0.05) / (lum + 0.05);
        var crDark = (lum + 0.05) / (0.008 + 0.05);
        return crDark > crWhite ? Qt.color("#0A0B0E") : Qt.color("#FFFFFF");
    }

    // Normalized Base Palette Colors
    readonly property color c0: Qt.color(palette[0] || "#1D1D1F")
    readonly property color c1: Qt.color(palette[1] || "#2997FF")
    readonly property color c2: Qt.color(palette[2] || "#F5F5F7")
    readonly property color c3: Qt.color(palette[3] || "#000000")
    readonly property color c4: Qt.color(palette[4] || "#86868B")

    // Automatic Light / Dark Mode Detection based on background canvas luminance
    readonly property bool isDark: luminance(c3) < 0.5

    // Semantic Palette Roles
    readonly property color paletteTertiary:  c0
    readonly property color paletteAccent:    c1
    readonly property color paletteLight:     isDark ? c2 : c3
    readonly property color paletteBase:      c3
    readonly property color paletteSecondary: c4

    // Foundation surfaces (Dynamically branches between Dark Mode & Light Mode)
    readonly property color bgVoid:         isDark ? darken(c3, 0.35) : lighten(c3, 0.15)
    readonly property color bgBase:         c3
    readonly property color stoneDark:      isDark ? darken(c3, 0.16) : darken(c3, 0.05)
    readonly property color bgSurface:      isDark ? mix(c3, c4, 0.15) : Qt.rgba(1.0, 1.0, 1.0, 0.95)
    readonly property color bgSurfaceHover: isDark ? mix(c3, c4, 0.25) : darken(c3, 0.07)
    readonly property color bgCard:         isDark ? darken(c3, 0.22) : Qt.rgba(1.0, 1.0, 1.0, 0.88)

    // Core Warm / Vibrant Accents
    readonly property color cedar:          isDark ? darken(c0, 0.40) : mix(c0, c3, 0.30)
    readonly property color tea:            isDark ? darken(c0, 0.25) : mix(c0, c3, 0.15)
    readonly property color cinnabar:       c1
    readonly property color cinnabarHover:  isDark ? lighten(c1, 0.15) : darken(c1, 0.12)
    readonly property color terracotta:     isDark ? lighten(c1, 0.10) : darken(c1, 0.08)
    readonly property color terracottaGlow: isDark ? lighten(c1, 0.25) : darken(c1, 0.20)
    readonly property color goldAccent:     isDark ? (luminance(c4) > 0.35 ? c4 : lighten(c4, 0.35))
                                                   : (luminance(c4) < 0.35 ? c4 : darken(c4, 0.25))

    // Text & Content Hierarchy (Calibrated for WCAG AAA contrast in both modes)
    readonly property color textPrimary:    c2
    readonly property color textSecondary:  isDark ? darken(c2, 0.12) : lighten(c2, 0.06)
    readonly property color textMuted:      isDark ? darken(c2, 0.28) : lighten(c2, 0.12)
    readonly property color textDim:        isDark ? darken(c2, 0.42) : lighten(c2, 0.20)

    // Contrast text on solid colored badges, pills, and CTAs (Never unreadable)
    readonly property color textOnAccent:   textOn(paletteAccent)
    readonly property color textOnCinnabar: textOn(cinnabar)
    readonly property color textOnGreen:    textOn(statusGreen)

    // Tactile Borders & Dividers
    readonly property color borderSubtle:   isDark ? Qt.rgba(c4.r, c4.g, c4.b, 0.20) : Qt.rgba(c2.r, c2.g, c2.b, 0.08)
    readonly property color borderCard:     isDark ? Qt.rgba(c2.r, c2.g, c2.b, 0.12) : Qt.rgba(c2.r, c2.g, c2.b, 0.10)
    readonly property color borderCardHover: isDark ? Qt.rgba(c2.r, c2.g, c2.b, 0.28) : Qt.rgba(c2.r, c2.g, c2.b, 0.22)
    readonly property color borderActive:   c1
    readonly property color divider:        isDark ? Qt.rgba(c2.r, c2.g, c2.b, 0.08) : Qt.rgba(c2.r, c2.g, c2.b, 0.06)

    // Glassmorphism & Apple Liquid Specular Materials
    readonly property color glassFill:      isDark ? Qt.rgba(c3.r, c3.g, c3.b, 0.85) : Qt.rgba(1.0, 1.0, 1.0, 0.88)
    readonly property color glassBorder:    isDark ? Qt.rgba(c4.r, c4.g, c4.b, 0.30) : Qt.rgba(c2.r, c2.g, c2.b, 0.12)
    readonly property color glassSpecular:  isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.16) : Qt.rgba(1.0, 1.0, 1.0, 0.45)
    readonly property color cardHighlight:  isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.05) : Qt.rgba(1.0, 1.0, 1.0, 0.20)
    readonly property color tooltipFill:    isDark ? Qt.rgba(c3.r * 0.65, c3.g * 0.65, c3.b * 0.65, 0.96)
                                                   : Qt.rgba(1.0, 1.0, 1.0, 0.96)

    // Status & Telemetry Accents
    readonly property color statusGreen:    isDark ? mix(c4, Qt.rgba(0.3, 0.75, 0.45, 1.0), 0.65)
                                                   : Qt.rgba(0.05, 0.65, 0.35, 1.0)
    readonly property color statusWarning:  mix(c1, isDark ? c2 : c4, 0.45)
    readonly property color statusAlert:    c1
    readonly property color statusInfo:     c4

    // Dynamic Microplate Compound Palette (16 harmonious colors)
    readonly property var compoundPalette: [
        c1,
        c4,
        isDark ? c2 : c0,
        isDark ? c0 : c4,
        mix(c3, c4, 0.60),
        lighten(c1, 0.25),
        mix(c4, c1, 0.45),
        mix(c1, c0, 0.40),
        darken(c0, 0.15),
        mix(c4, c1, 0.35),
        lighten(c4, 0.30),
        mix(c1, c0, 0.50),
        mix(c4, Qt.rgba(0.3, 0.7, 0.45, 1.0), 0.60),
        mix(c0, c4, 0.50),
        mix(c4, Qt.rgba(0.2, 0.65, 0.6, 1.0), 0.60),
        mix(c1, Qt.rgba(0.95, 0.5, 0.1, 1.0), 0.50)
    ]

    // Dynamic DNA Helix Particle Colors
    readonly property var helixColors: [
        c1,
        mix(c1, c0, 0.5),
        c0,
        mix(c1, c2, 0.35),
        c4
    ]

    // =========================================================================
    // TYPOGRAPHIC SYSTEM
    // Display: High-contrast transitional editorial serif (Cormorant Garamond)
    // Telemetry & Code: Monospace geometric sans with micro tracking (JetBrains Mono)
    // Body: Clean, unslanted modern sans (Inter)
    // =========================================================================

    readonly property string fontDisplay:   "Cormorant Garamond"
    readonly property string fontMono:      "JetBrains Mono"
    readonly property string fontBody:      "Inter"
    readonly property string fontIcon:      "Material Symbols Outlined"

    // Modular Scale (Base 16px, Perfect Fourth / Golden steps)
    readonly property real sizeHero:        64.0 // Display title
    readonly property real sizeH1:          38.0 // Section headers
    readonly property real sizeH2:          26.0 // Subheaders & card titles
    readonly property real sizeH3:          20.0 // Subsection titles
    readonly property real sizeBody:        15.5 // Prose text (65-75ch readability)
    readonly property real sizeBodySm:      13.5 // Secondary descriptors
    readonly property real sizeTelemetry:   11.5 // Monospace telemetry & caps badges
    readonly property real sizeMicro:       9.5  // Micro coordinates & timestamps

    // Letter Spacing (Apple Optical Sizing & Tracking: negative on display, positive on micro)
    readonly property real trackDisplay:   -1.5  // Tight tracking for giant display headlines (-0.02em)
    readonly property real trackHeading:   -0.5  // Sub-tight tracking for H1/H2
    readonly property real trackBody:       0.0  // Neutral tracking for readable prose
    readonly property real trackMicro:      1.2  // Micro tracking for telemetry uppercase (+0.10em)
    readonly property real trackWide:       1.8  // Wide tracking for eyebrow category badges (+0.15em)

    // =========================================================================
    // RADII & SPACING SCALES
    // =========================================================================

    readonly property real radiusSm:   6.0
    readonly property real radiusMd:   12.0
    readonly property real radiusLg:   20.0
    readonly property real radiusPill: 999.0

    readonly property real spaceXs:    4.0
    readonly property real spaceSm:    8.0
    readonly property real spaceMd:    16.0
    readonly property real spaceLg:    24.0
    readonly property real spaceXl:    36.0
    readonly property real space2Xl:   56.0
    readonly property real space3Xl:   84.0

    // Animation Timings (Strictly < 400ms for responsiveness)
    readonly property int animFast:    140
    readonly property int animNormal:  240
    readonly property int animSlow:    380
}
