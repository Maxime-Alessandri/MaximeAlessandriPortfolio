import QtQuick

Item {
    id: controller

    // Targets to animate
    required property QtObject lihaArm
    required property QtObject romaArm
    required property QtObject mcaArm
    property QtObject workstationView: null

    // Status output for UI telemetry HUD
    property string activePhaseText: "Idle"
    property real progress: 0.0 // 0.0 to 1.0
    property bool isPlaying: true

    function restart() {
        heroSequence.stop()
        resetToHome()
        heroSequence.start()
    }

    function togglePlay() {
        isPlaying = !isPlaying
    }

    function resetToHome() {
        // Exact Fluent Simulator TeMotion DRIVE Park / Home Coordinates
        lihaArm.axisX = 109.50
        lihaArm.axisY = 204.00
        lihaArm.currentZ = 207.10
        lihaArm.idleDriveZ = 207.10
        lihaArm.tipsMounted = false

        romaArm.axisX = 1079.98
        romaArm.axisY = 181.27
        romaArm.axisZ = 339.67
        romaArm.rotationR = 90.0
        romaArm.jawSpread = 94.0
        romaArm.hasPlateGripped = false

        mcaArm.axisX = 1743.23
        mcaArm.axisY = 147.00
        mcaArm.axisZ = 235.07
        mcaArm.adapterMounted = false
        mcaArm.tipsMounted = false

        if (workstationView) {
            workstationView.sourcePlateVisible = true
            workstationView.destinationPlateVisible = false
        }
    }

    SequentialAnimation {
        id: heroSequence
        running: true
        paused: !controller.isPlaying
        loops: Animation.Infinite

        ScriptAction {
            script: {
                controller.resetToHome()
                controller.activePhaseText = "FCA (LiHa): Initializing at waste chute (Poubelle)"
                controller.progress = 0.02
            }
        }

        // =====================================================================
        // PHASE 1: FCA (LiHa 8-Channel Liquid Handling Arm Pipeline)
        // Exact TeMotion/LIHA:1/DRIVE:* trajectory from DemoFCA subroutine
        // =====================================================================

        // 1.1 Pre-run waste chute eject check at Poubelle (X=109.50, Y=204.00)
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 168.00; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 172.00; duration: 150; easing.type: Easing.Linear }
        ScriptAction { script: { lihaArm.tipsMounted = false } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 207.10; duration: 400; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "FCA (LiHa): Moving to DiTi 350µL Tip Rack (FCA_ 350ul SBS_ Stack5[001])"
                controller.progress = 0.06
            }
        }

        // 1.2 Transit at DRIVE:Z=207.10 (Z_adapter=160.90mm) to Tip Rack (X=159.73, Y=404.78)
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 159.73; duration: 750; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 404.78; duration: 750; easing.type: Easing.InOutCubic }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "FCA (LiHa): Mounting 5 disposable tips (Channels 1-5)"
                controller.progress = 0.11
            }
        }

        // 1.3 Press-fit Channels 0..4 onto tips: DRIVE:Z 207.10 -> 120.20 (Z_adapter=74.0) -> 99.20 (Z_adapter=53.0) -> 120.20 -> 251.70 (Z_tip=160.9)
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 120.20; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 99.20; duration: 380; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 120.20; duration: 200; easing.type: Easing.InOutQuad }
        ScriptAction { script: { lihaArm.tipsMounted = true } }
        PauseAnimation { duration: 120 }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 251.70; duration: 500; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "FCA (LiHa): Moving to DMSO reagent trough (100ml_Higher)"
                controller.progress = 0.15
            }
        }

        // 1.4 Transit at SAFE height DRIVE:Z=251.70 (Z_tip=160.9mm) above trough & tip rack BEFORE descending
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 123.00; duration: 650; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 289.50; duration: 650; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 196.30; duration: 350; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "FCA (LiHa): Aspirating DMSO reagent from 100ml_Higher"
                controller.progress = 0.19
            }
        }

        // 1.5 Aspirate DMSO: DRIVE:Z 196.30 -> 181.80 -> 179.95 (Z_tip=89.15mm) -> 185.04 -> retract UP to SAFE 251.70
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 181.80; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 179.95; duration: 450; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 185.04; duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 251.70; duration: 380; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "FCA (LiHa): Aligning to microplate Daughter[001]"
                controller.progress = 0.22
            }
        }

        // 1.6 Transit at SAFE height DRIVE:Z=251.70 over carriers, then lower onto Daughter[001] Column 1
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 309.73; duration: 800; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 212.78; duration: 600; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 450; easing.type: Easing.InOutQuad }

        // 1.7 Dispense Columns across Daughter[001] (DRIVE:Z=104.20 -> Z_tip=13.40mm inside wells)
        // Col 1
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 1 (Rows A-E)"; controller.progress = 0.24 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "axisY"; to: 185.78; duration: 180; easing.type: Easing.InOutCubic }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 1 (Rows F-H)"; controller.progress = 0.25 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }

        // Col 4
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 336.72; duration: 220; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 212.78; duration: 200; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 4 (Rows A-E)"; controller.progress = 0.27 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "axisY"; to: 185.78; duration: 180; easing.type: Easing.InOutCubic }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 4 (Rows F-H)"; controller.progress = 0.28 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }

        // Col 7
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 363.70; duration: 220; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 212.78; duration: 200; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 7 (Rows A-E)"; controller.progress = 0.29 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "axisY"; to: 185.78; duration: 180; easing.type: Easing.InOutCubic }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 7 (Rows F-H)"; controller.progress = 0.30 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }

        // Col 10
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 390.69; duration: 220; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 212.78; duration: 200; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 10 (Rows A-E)"; controller.progress = 0.31 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "axisY"; to: 185.78; duration: 180; easing.type: Easing.InOutCubic }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 10 (Rows F-H)"; controller.progress = 0.32 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }

        // Col 12
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 408.68; duration: 200; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 212.78; duration: 200; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 12 (Rows A-E)"; controller.progress = 0.33 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "axisY"; to: 185.78; duration: 180; easing.type: Easing.InOutCubic }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Dispensing Column 12 (Rows F-H)"; controller.progress = 0.34 } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 104.20; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 121.70; duration: 180; easing.type: Easing.InOutQuad }

        // 1.8 Retract & Return to Waste Chute (Poubelle) to Drop Tips
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "currentZ"; to: 251.70; duration: 500; easing.type: Easing.InOutQuad }
            NumberAnimation { target: lihaArm; property: "idleDriveZ"; to: 207.10; duration: 500; easing.type: Easing.InOutQuad }
        }
        ScriptAction { script: { controller.activePhaseText = "FCA (LiHa): Returning to waste chute (Poubelle) to drop tips"; controller.progress = 0.36 } }
        ParallelAnimation {
            NumberAnimation { target: lihaArm; property: "axisX"; to: 109.50; duration: 750; easing.type: Easing.InOutCubic }
            NumberAnimation { target: lihaArm; property: "axisY"; to: 204.00; duration: 500; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 168.00; duration: 450; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 172.00; duration: 180; easing.type: Easing.Linear }
        ScriptAction { script: { lihaArm.tipsMounted = false } }
        NumberAnimation { target: lihaArm; property: "currentZ"; to: 207.10; duration: 450; easing.type: Easing.InOutQuad }

        PauseAnimation { duration: 250 }

        // =====================================================================
        // PHASE 2: RGA (RoMa Robotic Gripper Arm Transfer Pipeline)
        // Exact TeMotion/CGA:1/DRIVE:* trajectory from DemoRGA subroutine
        // =====================================================================
        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Moving to 9 Nest Hotel[002] shelf 12"
                controller.progress = 0.40
            }
        }

        // 2.1 Approach Hotel hallway: DRIVE:X=497.00, DRIVE:Y=340.40, DRIVE:Z=250.80, DRIVE:R=90.00
        ParallelAnimation {
            NumberAnimation { target: romaArm; property: "axisX"; to: 497.00; duration: 900; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisY"; to: 340.40; duration: 700; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisZ"; to: 250.80; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { target: romaArm; property: "rotationR"; to: 90.00; duration: 400; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "jawSpread"; to: 94.00; duration: 300; easing.type: Easing.InOutQuad }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Reaching eccentric fingers into hotel to grasp RoMaPlate[004]"
                controller.progress = 0.45
            }
        }

        // 2.2 Reach into Hotel: DRIVE:Y 340.40 -> 518.00 (World Y_grip = 670.50), DRIVE:Z 250.80 -> 245.80 (World Z_grip = 160.50)
        NumberAnimation { target: romaArm; property: "axisY"; to: 518.00; duration: 650; easing.type: Easing.InOutCubic }
        NumberAnimation { target: romaArm; property: "axisZ"; to: 245.80; duration: 320; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Clamping gripper around RoMaPlate[004] (G=80mm)"
                controller.progress = 0.49
            }
        }

        // 2.3 Close gripper to 80mm: G 94 -> 80
        NumberAnimation { target: romaArm; property: "jawSpread"; to: 80.00; duration: 400; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                romaArm.hasPlateGripped = true
                if (workstationView) workstationView.sourcePlateVisible = false
            }
        }
        PauseAnimation { duration: 150 }

        // 2.4 Lift plate off shelf & retract out of Hotel: DRIVE:Z 245.80 -> 250.80, DRIVE:Y 518.00 -> 340.40
        NumberAnimation { target: romaArm; property: "axisZ"; to: 250.80; duration: 320; easing.type: Easing.InOutQuad }
        NumberAnimation { target: romaArm; property: "axisY"; to: 340.40; duration: 650; easing.type: Easing.InOutCubic }

        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Transferring microplate across deck & rotating wrist to 180°"
                controller.progress = 0.55
            }
        }

        // 2.5 Cross-deck transfer to Nest 8 (61mm Nest[191]):
        // DRIVE:X=1411.73, DRIVE:Y=181.27, DRIVE:R=180.00, DRIVE:Z=168.30 (World plate at 1259.23, 181.27, 83.00)
        ParallelAnimation {
            NumberAnimation { target: romaArm; property: "axisX"; to: 1411.73; duration: 1100; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisY"; to: 181.27; duration: 900; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "rotationR"; to: 180.00; duration: 900; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisZ"; to: 168.30; duration: 900; easing.type: Easing.InOutQuad }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Lowering microplate onto 61mm Nest[191] (Z=61mm)"
                controller.progress = 0.61
            }
        }

        // 2.6 Lower into Nest 8: DRIVE:Z 168.30 -> 146.30 (World Z_grip = 61.00mm)
        NumberAnimation { target: romaArm; property: "axisZ"; to: 146.30; duration: 450; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Opening gripper to release plate (G=94mm)"
                controller.progress = 0.65
            }
        }

        // 2.7 Open gripper & place plate on Nest 8
        NumberAnimation { target: romaArm; property: "jawSpread"; to: 94.00; duration: 400; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                romaArm.hasPlateGripped = false
                if (workstationView) workstationView.destinationPlateVisible = true
            }
        }
        PauseAnimation { duration: 150 }

        // 2.8 Retract vertically & Return to Park (DRIVE:X=1079.98, DRIVE:Y=181.27, DRIVE:Z=339.67, DRIVE:R=90.00)
        NumberAnimation { target: romaArm; property: "axisZ"; to: 168.30; duration: 300; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                controller.activePhaseText = "RGA (RoMa): Returning to park position"
                controller.progress = 0.68
            }
        }
        ParallelAnimation {
            NumberAnimation { target: romaArm; property: "axisZ"; to: 339.67; duration: 750; easing.type: Easing.InOutQuad }
            NumberAnimation { target: romaArm; property: "rotationR"; to: 90.00; duration: 600; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisX"; to: 1079.98; duration: 800; easing.type: Easing.InOutCubic }
            NumberAnimation { target: romaArm; property: "axisY"; to: 181.27; duration: 650; easing.type: Easing.InOutCubic }
        }

        PauseAnimation { duration: 250 }

        // =====================================================================
        // PHASE 3: MCA (MCA384 96-Channel Pipetting Pipeline)
        // Exact TeMotion/MCA:1,384/DRIVE:* trajectory from CheckHeadAdapter & DemoMCA
        // =====================================================================
        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Moving to MCA384 Adapter Nest[002] (Get Head Adapter)"
                controller.progress = 0.72
            }
        }

        // 3.1 CheckHeadAdapter -> Get Head Adapter at 96 MCA384 Tips[001] (DRIVE:X=1808.90, DRIVE:Y=345.40 -> 330.90, DRIVE:Z=98.90 -> 87.20 -> 107.50)
        ParallelAnimation {
            NumberAnimation { target: mcaArm; property: "axisX"; to: 1808.90; duration: 750; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisY"; to: 345.40; duration: 750; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisZ"; to: 98.90; duration: 750; easing.type: Easing.InOutQuad }
        }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 87.20; duration: 320; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisY"; to: 330.90; duration: 280; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                mcaArm.adapterMounted = true
                controller.activePhaseText = "MCA384: 96-Channel DiTi Head Adapter locked — lifting off nest"
                controller.progress = 0.75
            }
        }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 107.50; duration: 380; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Moving to 96-well Tip Rack (Tips New)"
                controller.progress = 0.78
            }
        }

        // 3.2 Move to Tips New (DRIVE:X=1633.92, DRIVE:Y=298.00, DRIVE:Z=169.60) & Mount 96 Tips
        ParallelAnimation {
            NumberAnimation { target: mcaArm; property: "axisX"; to: 1633.92; duration: 700; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisY"; to: 298.00; duration: 700; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisZ"; to: 169.60; duration: 500; easing.type: Easing.InOutQuad }
        }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 88.80; duration: 480; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Mounting 96 disposable tips simultaneously"
                controller.progress = 0.81
            }
        }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 77.80; duration: 450; easing.type: Easing.InOutQuad }
        ScriptAction { script: { mcaArm.tipsMounted = true } }
        PauseAnimation { duration: 150 }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 197.40; duration: 550; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Transit to source plate QC_plate (DRIVE:Z=235.07mm)"
                controller.progress = 0.84
            }
        }

        // 3.3 Transit at Safe Clearance DRIVE:Z=235.07 (Z_tip=191.67mm) to QC_plate (DRIVE:X=1411.48, DRIVE:Y=470.78)
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 235.07; duration: 350; easing.type: Easing.InOutQuad }
        ParallelAnimation {
            NumberAnimation { target: mcaArm; property: "axisX"; to: 1411.48; duration: 800; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisY"; to: 470.78; duration: 750; easing.type: Easing.InOutCubic }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Aspirating from 96 wells simultaneously (QC_plate)"
                controller.progress = 0.87
            }
        }

        // 3.4 Aspirate from QC_plate: DRIVE:Z 235.07 -> 128.30 -> 120.30 -> 108.80 (Z_tip=65.40mm) -> 128.30
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 128.30; duration: 480; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 120.30; duration: 200; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 108.80; duration: 450; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: 300 }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 128.30; duration: 550; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Transit to destination plate Test_plate[001]"
                controller.progress = 0.90
            }
        }

        // 3.5 Transit to Test_plate[001] (DRIVE:X=1413.73, DRIVE:Y=84.52, DRIVE:Z=120.40 -> Z_tip=77.00mm)
        ParallelAnimation {
            NumberAnimation { target: mcaArm; property: "axisX"; to: 1413.73; duration: 350; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisY"; to: 84.52; duration: 850; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisZ"; to: 120.40; duration: 450; easing.type: Easing.InOutQuad }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Dispensing into 96 wells (Test_plate[001])"
                controller.progress = 0.93
            }
        }

        // 3.6 Dispense into wells: DRIVE:Z 120.40 -> 110.40 -> 107.75 (Z_tip=64.35mm) -> 109.10 -> 110.40 (Z_tip=67.00mm)
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 110.40; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 107.75; duration: 220; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 109.10; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 110.40; duration: 280; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: 4-Way Cross Tip-Touch droplet wiping on well rims"
                controller.progress = 0.95
            }
        }

        // 3.7 4-Way Cross Tip-Touch Wiping at DRIVE:Z=110.40 (North -> South -> Center -> East -> West -> Center)
        NumberAnimation { target: mcaArm; property: "axisY"; to: 85.84; duration: 180; easing.type: Easing.InOutSine }
        NumberAnimation { target: mcaArm; property: "axisY"; to: 83.21; duration: 250; easing.type: Easing.InOutSine }
        NumberAnimation { target: mcaArm; property: "axisY"; to: 84.52; duration: 180; easing.type: Easing.InOutSine }
        NumberAnimation { target: mcaArm; property: "axisX"; to: 1415.05; duration: 180; easing.type: Easing.InOutSine }
        NumberAnimation { target: mcaArm; property: "axisX"; to: 1412.41; duration: 250; easing.type: Easing.InOutSine }
        NumberAnimation { target: mcaArm; property: "axisX"; to: 1413.73; duration: 180; easing.type: Easing.InOutSine }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Retracting & returning to Tips New to drop tips"
                controller.progress = 0.97
            }
        }

        // 3.8 Retract to clearance DRIVE:Z=235.07 & return to Tips New (DRIVE:X=1633.92, DRIVE:Y=298.00, DRIVE:Z=197.40)
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 235.07; duration: 550; easing.type: Easing.InOutQuad }
        ParallelAnimation {
            NumberAnimation { target: mcaArm; property: "axisX"; to: 1633.92; duration: 800; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisY"; to: 298.00; duration: 750; easing.type: Easing.InOutCubic }
            NumberAnimation { target: mcaArm; property: "axisZ"; to: 197.40; duration: 750; easing.type: Easing.InOutQuad }
        }

        ScriptAction {
            script: {
                controller.activePhaseText = "MCA384: Ejecting 96 disposable tips into tip rack"
                controller.progress = 0.99
            }
        }

        // 3.9 Eject tips: DRIVE:Z 197.40 -> 88.80 (Z_adapter=73.20mm above rack top 71.2mm) -> 91.80 -> 197.40
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 88.80; duration: 650; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 91.80; duration: 180; easing.type: Easing.Linear }
        ScriptAction { script: { mcaArm.tipsMounted = false } }
        NumberAnimation { target: mcaArm; property: "axisZ"; to: 197.40; duration: 550; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                controller.activePhaseText = "Complete Automated Run Finished — Restarting Demo Cycle"
                controller.progress = 1.0
            }
        }

        PauseAnimation { duration: 1000 }
    }
}
