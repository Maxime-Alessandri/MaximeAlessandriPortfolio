import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick3D
import InvenesisPortfolio
import "./fluent3d"

Rectangle {
    id: robotDemoRoot

    implicitWidth: 840
    implicitHeight: 560
    radius: Theme.radiusMd
    color: Theme.bgCard
    border.color: Theme.glassBorder
    border.width: 1
    clip: true

    property bool active: true
    property bool userPaused: false

    // External GWL Hitpick Job State (driven by ClientPortalWorkflowDemo Stage 5)
    property var activeGwlJob: null
    property int gwlStepIndex: -1
    property bool gwlJobCompleted: false
    property string gwlPhaseText: ""
    property real gwlSpeedFactor: 1.0

    readonly property var currentGwlStep: (activeGwlJob && activeGwlJob.steps && gwlStepIndex >= 0 && gwlStepIndex < activeGwlJob.steps.length)
                                          ? activeGwlJob.steps[gwlStepIndex] : null
    readonly property int currentGwlLineIdx: currentGwlStep ? (currentGwlStep.gwlLineIdx !== undefined ? currentGwlStep.gwlLineIdx : -1) : -1
    readonly property real effectiveProgress: {
        if (activeGwlJob && activeGwlJob.steps && activeGwlJob.steps.length > 0) {
            if (gwlJobCompleted) return 1.0;
            return Math.max(0.02, (gwlStepIndex + 1) / activeGwlJob.steps.length);
        }
        return heroTimeline.progress;
    }

    signal continueToPortalResults()

    onGwlStepIndexChanged: {
        if (activeGwlJob !== null && currentGwlLineIdx >= 0) {
            gwlListView.positionViewAtIndex(currentGwlLineIdx, ListView.Center);
        }
    }

    // Camera preset animation
    ParallelAnimation {
        id: cameraAnim
        property real targetYaw: 35.0
        property real targetPitch: -28.0
        property real targetDist: 2200.0
        property vector3d targetLook: Qt.vector3d(950.0, 450.0, 200.0)

        NumberAnimation { target: scene3d; property: "cameraYaw"; to: cameraAnim.targetYaw; duration: 600; easing.type: Easing.OutCubic }
        NumberAnimation { target: scene3d; property: "cameraPitch"; to: cameraAnim.targetPitch; duration: 600; easing.type: Easing.OutCubic }
        NumberAnimation { target: scene3d; property: "cameraDistance"; to: cameraAnim.targetDist; duration: 600; easing.type: Easing.OutCubic }
    }

    function setCameraPreset(yaw, pitch, dist, look) {
        cameraAnim.stop()
        cameraAnim.targetYaw = yaw
        cameraAnim.targetPitch = pitch
        cameraAnim.targetDist = dist
        if (look) scene3d.lookTarget = look
        cameraAnim.start()
    }

    // Scroll Lock helper: Prevents parent Flickable from stealing mouse drag when orbiting 3D camera
    function setPageScrollEnabled(enabled) {
        var p = robotDemoRoot.parent;
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
    // 3D WORKSTATION VIEWPORT
    // =========================================================================
    TecanWorkstationView {
        id: scene3d
        anchors.fill: parent

        // Mouse Orbit & Zoom Controller (Drag to Orbit, Right-Drag to Pan, Ctrl+Wheel to Zoom)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            preventStealing: true // Stops Flickable from stealing mouse drag gestures
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property point lastPos

            onPressed: function(mouse) {
                cameraAnim.stop()
                setPageScrollEnabled(false) // Temporarily lock Flickable during 3D camera drag
                lastPos = Qt.point(mouse.x, mouse.y)
                mouse.accepted = true
            }

            onReleased: function(mouse) {
                setPageScrollEnabled(true) // Re-enable Flickable page scroll on release
                mouse.accepted = true
            }

            onCanceled: {
                setPageScrollEnabled(true)
            }

            onPositionChanged: function(mouse) {
                if (pressedButtons & Qt.LeftButton) {
                    var dx = mouse.x - lastPos.x
                    var dy = mouse.y - lastPos.y
                    scene3d.cameraYaw = (scene3d.cameraYaw - dx * 0.4)
                    scene3d.cameraPitch = Math.max(-85, Math.min(10, scene3d.cameraPitch - dy * 0.3))
                } else if (pressedButtons & Qt.RightButton) {
                    var dPan = mouse.y - lastPos.y
                    scene3d.cameraDistance = Math.max(600, Math.min(3500, scene3d.cameraDistance + dPan * 3.0))
                }
                lastPos = Qt.point(mouse.x, mouse.y)
                mouse.accepted = true
            }

            // Never trap normal page scrolling: only zoom 3D view when Ctrl is pressed
            onWheel: function(wheel) {
                if (wheel.modifiers & Qt.ControlModifier) {
                    var factor = wheel.angleDelta.y > 0 ? 0.9 : 1.1
                    scene3d.cameraDistance = Math.max(600, Math.min(3500, scene3d.cameraDistance * factor))
                    wheel.accepted = true
                } else {
                    // Let wheel events propagate to parent Flickable for effortless page scrolling
                    wheel.accepted = false
                }
            }
        }
    }

    // =========================================================================
    // PROTOCOL ANIMATION CONTROLLER
    // =========================================================================
    HeroAnimationController {
        id: heroTimeline
        workstationView: scene3d
        lihaArm: scene3d.liha
        romaArm: scene3d.roma
        mcaArm: scene3d.mca
        isPlaying: robotDemoRoot.active && !robotDemoRoot.userPaused && robotDemoRoot.activeGwlJob === null
    }

    onActiveChanged: syncGwlPauseState()
    onUserPausedChanged: syncGwlPauseState()

    function syncGwlPauseState() {
        if (!gwlStepAnim.running) return;
        var shouldPause = !robotDemoRoot.active || robotDemoRoot.userPaused;
        if (shouldPause && !gwlStepAnim.paused) {
            gwlStepAnim.pause();
        } else if (!shouldPause && gwlStepAnim.paused) {
            gwlStepAnim.resume();
        }
    }

    // =========================================================================
    // LIVE GWL HITPICK REPLAY ENGINE (Driven by Client Portal Stage 5)
    // =========================================================================
    SequentialAnimation {
        id: gwlStepAnim

        property real targetX: 109.50
        property real targetY: 204.00
        property real targetTransitZ: 251.70
        property real targetDipZ: 168.00
        property real targetRetractZ: 251.70
        property var targetTipsMaskAfterDip: [false, false, false, false, false, false, false, false]
        property int liftMs: 180
        property int moveMs: 500
        property int dipMs: 260
        property int retractMs: 240

        NumberAnimation {
            target: scene3d.liha
            property: "activeGroupZ"
            to: gwlStepAnim.targetTransitZ
            duration: gwlStepAnim.liftMs
            easing.type: Easing.InOutQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: scene3d.liha
                property: "axisX"
                to: gwlStepAnim.targetX
                duration: gwlStepAnim.moveMs
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: scene3d.liha
                property: "axisY"
                to: gwlStepAnim.targetY
                duration: gwlStepAnim.moveMs
                easing.type: Easing.InOutCubic
            }
        }
        NumberAnimation {
            target: scene3d.liha
            property: "activeGroupZ"
            to: gwlStepAnim.targetDipZ
            duration: gwlStepAnim.dipMs
            easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: { scene3d.liha.mountedTipsMask = gwlStepAnim.targetTipsMaskAfterDip.slice(); }
        }
        NumberAnimation {
            target: scene3d.liha
            property: "activeGroupZ"
            to: gwlStepAnim.targetRetractZ
            duration: gwlStepAnim.retractMs
            easing.type: Easing.InOutQuad
        }

        onFinished: {
            if (!robotDemoRoot.activeGwlJob || !robotDemoRoot.activeGwlJob.steps) return;
            var nextIdx = robotDemoRoot.gwlStepIndex + 1;
            if (nextIdx < robotDemoRoot.activeGwlJob.steps.length) {
                robotDemoRoot.runGwlStep(nextIdx);
            } else {
                robotDemoRoot.gwlJobCompleted = true;
                robotDemoRoot.gwlPhaseText = "HITPICK BATCH COMPLETE (" + robotDemoRoot.activeGwlJob.requestId + ") — READY FOR OPTICAL READER";
            }
        }
    }

    function runGwlStep(idx) {
        if (!activeGwlJob || !activeGwlJob.steps || idx < 0 || idx >= activeGwlJob.steps.length) return;
        var step = activeGwlJob.steps[idx];
        gwlStepIndex = idx;
        gwlPhaseText = step.label;
        var spd = gwlSpeedFactor > 1.5 ? 0.52 : 1.0;

        // Keep idle channels parked safely above all labware (Z_tip = 160.9 mm)
        scene3d.liha.idleDriveZ = 207.10;
        scene3d.liha.activeChannelsMask = step.activeMask ? step.activeMask.slice() : [true, true, true, true, true, true, true, true];

        // Never drop vertically before horizontal transit (prevents box clipping)
        var requestedTransit = step.transitZ !== undefined ? step.transitZ : 251.70;
        var safeStartZ = Math.max(scene3d.liha.activeGroupZ, requestedTransit);

        gwlStepAnim.targetX = step.x;
        gwlStepAnim.targetY = step.y;
        gwlStepAnim.targetTransitZ = safeStartZ;
        gwlStepAnim.targetDipZ = step.dipZ;
        gwlStepAnim.targetRetractZ = step.retractZ !== undefined ? step.retractZ : 251.70;
        gwlStepAnim.targetTipsMaskAfterDip = step.tipsMaskAfterDip ? step.tipsMaskAfterDip.slice() : scene3d.liha.mountedTipsMask.slice();
        gwlStepAnim.liftMs = Math.abs(scene3d.liha.activeGroupZ - safeStartZ) < 1.0 ? 20 : Math.max(110, Math.round(210 * spd));
        gwlStepAnim.moveMs = Math.max(110, Math.round((step.moveMs || 480) * spd));
        gwlStepAnim.dipMs = Math.max(90, Math.round((step.dipMs || 220) * spd));
        gwlStepAnim.retractMs = Math.max(120, Math.round((step.retractMs || 260) * spd));
        gwlStepAnim.start();
        syncGwlPauseState();
    }

    function startGwlHitpickJob(job) {
        gwlStepAnim.stop();
        activeGwlJob = job;
        gwlStepIndex = -1;
        gwlJobCompleted = false;
        userPaused = false;
        heroTimeline.resetToHome();
        scene3d.liha.multiChannelGwlMode = true;
        scene3d.liha.activeGroupZ = 207.10;
        scene3d.liha.mountedTipsMask = [false, false, false, false, false, false, false, false];
        scene3d.liha.activeChannelsMask = [true, true, true, true, true, true, true, true];
        scene3d.showHousing = false;
        setCameraPreset(26.0, -32.0, 1520.0, Qt.vector3d(440.0, 285.0, 120.0));
        runGwlStep(0);
    }

    function exitGwlJobMode() {
        gwlStepAnim.stop();
        activeGwlJob = null;
        gwlStepIndex = -1;
        gwlJobCompleted = false;
        gwlPhaseText = "";
        userPaused = false;
        scene3d.liha.multiChannelGwlMode = false;
        scene3d.liha.activeGroupZ = 207.10;
        scene3d.liha.mountedTipsMask = [false, false, false, false, false, false, false, false];
        scene3d.liha.activeChannelsMask = [true, true, true, true, true, true, true, true];
        scene3d.showHousing = true;
        setCameraPreset(35.0, -28.0, 2200.0, Qt.vector3d(950.0, 450.0, 200.0));
        heroTimeline.restart();
    }

    // Graceful status pill while 3D CAD .glb assets load or if unavailable
    Rectangle {
        visible: !scene3d.assetsReady
        anchors.centerIn: parent
        z: 5
        width: assetStatusRow.implicitWidth + 28
        height: 36
        radius: Theme.radiusPill
        color: Theme.glassFill
        border.color: scene3d.assetsError ? Theme.cinnabar : Theme.borderCard
        border.width: 1

        Row {
            id: assetStatusRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontIcon
                font.pixelSize: 15
                color: scene3d.assetsError ? Theme.cinnabar : Theme.paletteAccent
                text: scene3d.assetsError ? "warning" : "view_in_ar"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Theme.textPrimary
                text: scene3d.assetsError ? "3D CAD ASSETS UNAVAILABLE IN THIS BUILD" : "LOADING TECAN FLUENT 3D CAD WORKCELL..."
            }
        }
    }

    // =========================================================================
    // TOP OVERLAY: Header + Camera Presets
    // =========================================================================
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spaceMd
        height: 44

        RowLayout {
            anchors.fill: parent
            spacing: Theme.spaceSm

            // Title & Status
            Column {
                spacing: 2
                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.sizeH3
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    text: "TECAN FLUENT 1080 DIGITAL TWIN"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMicro
                    font.letterSpacing: Theme.trackMicro
                    color: Theme.terracottaGlow
                    text: "3-ARM FORWARD KINEMATICS // 60 FPS PBR"
                }
            }

            Item { Layout.fillWidth: true }

            // Camera Preset Selector Buttons
            Row {
                spacing: 6

                Repeater {
                    model: [
                        { name: "ORBIT", yaw: 35.0, pitch: -28.0, dist: 2200.0, look: Qt.vector3d(950, 450, 200) },
                        { name: "HITPICK", yaw: 26.0, pitch: -32.0, dist: 1520.0, look: Qt.vector3d(440, 285, 120) },
                        { name: "LiHa",  yaw: 22.0, pitch: -20.0, dist: 1300.0, look: Qt.vector3d(240, 320, 150) },
                        { name: "RoMa",  yaw: 48.0, pitch: -26.0, dist: 1400.0, look: Qt.vector3d(1080, 330, 200) },
                        { name: "MCA96", yaw: 18.0, pitch: -22.0, dist: 1400.0, look: Qt.vector3d(1580, 330, 200) },
                        { name: "TOP-DOWN", yaw: 0.0, pitch: -84.0, dist: 2400.0, look: Qt.vector3d(950, 450, 200) }
                    ]

                    Rectangle {
                        width: presetText.implicitWidth + 14
                        height: 26
                        radius: Theme.radiusPill
                        color: presetMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                        border.color: presetMouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
                        border.width: 1

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            color: Theme.textPrimary
                            text: modelData.name
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: robotDemoRoot.setCameraPreset(modelData.yaw, modelData.pitch, modelData.dist, modelData.look)
                        }
                    }
                }

                // Camera Zoom In / Out Buttons
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: zoomOutMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: zoomOutMouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
                    border.width: 1
                    scale: zoomOutMouse.pressed ? 0.94 : (zoomOutMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "−"
                    }

                    MouseArea {
                        id: zoomOutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scene3d.cameraDistance = Math.min(3500, scene3d.cameraDistance * 1.18)
                    }
                }

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: zoomInMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: zoomInMouse.containsMouse ? Theme.terracottaGlow : Theme.glassBorder
                    border.width: 1
                    scale: zoomInMouse.pressed ? 0.94 : (zoomInMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                        text: "+"
                    }

                    MouseArea {
                        id: zoomInMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scene3d.cameraDistance = Math.max(600, scene3d.cameraDistance * 0.85)
                    }
                }

                // Enclosure Toggle
                Rectangle {
                    width: hoodText.implicitWidth + 14
                    height: 26
                    radius: Theme.radiusPill
                    color: scene3d.showHousing ? Theme.cinnabar : Theme.bgSurface
                    border.color: scene3d.showHousing ? Theme.terracottaGlow : Theme.glassBorder
                    border.width: 1

                    Text {
                        id: hoodText
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        color: scene3d.showHousing ? Theme.textOnCinnabar : Theme.textPrimary
                        text: scene3d.showHousing ? "HOOD: ON" : "HOOD: OFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scene3d.showHousing = !scene3d.showHousing
                    }
                }

                // Navigation Guidance Chip
                Rectangle {
                    height: 26
                    width: navHintText.implicitWidth + 14
                    radius: Theme.radiusPill
                    color: Theme.glassFill
                    border.color: Theme.borderSubtle
                    border.width: 1
                    visible: robotDemoRoot.width > 700

                    Text {
                        id: navHintText
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.letterSpacing: 0.4
                        color: Theme.textDim
                        text: "DRAG: Orbit • CTRL+SCROLL: Zoom"
                    }
                }
            }
        }
    }

    // =========================================================================
    // LIVE GWL HITPICK SIDE HUD (Visible when triggered from Client Portal)
    // =========================================================================
    Rectangle {
        id: gwlHudPanel
        visible: robotDemoRoot.activeGwlJob !== null
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 68
        anchors.bottomMargin: 88
        anchors.rightMargin: Theme.spaceMd
        width: 324
        z: 10
        radius: Theme.radiusMd
        color: Theme.glassFill
        border.color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.paletteAccent
        border.width: 1.5

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // HUD Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.terracottaGlow

                    SequentialAnimation on opacity {
                        running: gwlHudPanel.visible && robotDemoRoot.active && !robotDemoRoot.gwlJobCompleted && !robotDemoRoot.userPaused
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 450 }
                        NumberAnimation { to: 1.0; duration: 450 }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.paletteAccent
                    text: robotDemoRoot.gwlJobCompleted
                          ? "GWL HITPICK COMPLETED ✓"
                          : ("LIVE GWL • " + (robotDemoRoot.activeGwlJob ? robotDemoRoot.activeGwlJob.requestId : ""))
                }

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 22
                    radius: Theme.radiusPill
                    color: robotDemoRoot.gwlSpeedFactor > 1.5 ? Theme.paletteAccent : Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: robotDemoRoot.gwlSpeedFactor > 1.5 ? Theme.textOnAccent : Theme.textPrimary
                        text: robotDemoRoot.gwlSpeedFactor > 1.5 ? "2x" : "1x"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: robotDemoRoot.gwlSpeedFactor = robotDemoRoot.gwlSpeedFactor > 1.5 ? 1.0 : 2.0
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 22
                    radius: Theme.radiusPill
                    color: Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: Theme.textMuted
                        text: "Exit"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: robotDemoRoot.exitGwlJobMode()
                    }
                }
            }

            // Active Step Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 6
                color: Theme.bgVoid
                border.color: Theme.borderCard
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 10
                        Layout.preferredHeight: 10
                        radius: 5
                        color: robotDemoRoot.currentGwlStep ? robotDemoRoot.currentGwlStep.color : Theme.statusGreen
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            text: robotDemoRoot.currentGwlStep
                                  ? (robotDemoRoot.currentGwlStep.compoundId + " ➔ " + robotDemoRoot.currentGwlStep.wellId)
                                  : "Batch Complete"
                        }
                        Text {
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            color: Theme.textMuted
                            text: robotDemoRoot.currentGwlStep
                                  ? ((robotDemoRoot.currentGwlStep.channelLabel || "LiHa FCA") + " • " + robotDemoRoot.currentGwlStep.concText + " • X=" + scene3d.liha.axisX.toFixed(0) + " Y=" + scene3d.liha.axisY.toFixed(0))
                                  : "All Daughter[001] wells dispensed"
                        }
                    }

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.paletteAccent
                        text: (robotDemoRoot.activeGwlJob && robotDemoRoot.activeGwlJob.steps)
                              ? (Math.max(0, robotDemoRoot.gwlStepIndex + 1) + "/" + robotDemoRoot.activeGwlJob.steps.length)
                              : ""
                    }
                }
            }

            // Scrolling Compiled GWL Worklist
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: Theme.bgVoid
                border.color: Theme.borderCard
                border.width: 1
                clip: true

                ListView {
                    id: gwlListView
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3
                    clip: true
                    model: robotDemoRoot.activeGwlJob ? robotDemoRoot.activeGwlJob.gwlLines : []

                    delegate: Rectangle {
                        id: gwlLineDelegate
                        required property int index
                        required property var modelData

                        readonly property bool isActiveLine: !robotDemoRoot.gwlJobCompleted && robotDemoRoot.currentGwlLineIdx === index
                        readonly property bool isDoneLine: robotDemoRoot.gwlJobCompleted || (robotDemoRoot.currentGwlLineIdx > index)

                        width: gwlListView.width
                        height: 22
                        radius: 3
                        color: isActiveLine ? Theme.alpha(Theme.paletteAccent, 0.22)
                             : (isDoneLine ? Theme.alpha(Theme.statusGreen, 0.08) : "transparent")
                        border.color: isActiveLine ? Theme.paletteAccent : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: gwlLineDelegate.isActiveLine ? Theme.paletteAccent
                                     : (gwlLineDelegate.isDoneLine ? Theme.statusGreen : Theme.textDim)
                                text: gwlLineDelegate.isActiveLine ? "▸" : (gwlLineDelegate.isDoneLine ? "✓" : "·")
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.weight: gwlLineDelegate.isActiveLine ? Font.Bold : Font.Normal
                                color: gwlLineDelegate.isActiveLine ? Theme.textPrimary
                                     : (gwlLineDelegate.isDoneLine ? Theme.textSecondary : Theme.textDim)
                                text: String(gwlLineDelegate.modelData)
                            }
                        }
                    }
                }
            }

            // Continue to Stage 6 Reader / Client 4PL Results Button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Theme.radiusPill
                color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.cinnabar
                border.color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.terracottaGlow
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: robotDemoRoot.gwlJobCompleted ? Theme.textOnGreen : Theme.textOnCinnabar
                    text: robotDemoRoot.gwlJobCompleted
                          ? "Run Optical Reader & View 4PL Curves ➔"
                          : "Skip Ahead to Reader & 4PL Results ➔"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: robotDemoRoot.continueToPortalResults()
                }
            }
        }
    }

    // =========================================================================
    // BOTTOM OVERLAY: Protocol Telemetry & Control Bar
    // =========================================================================
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spaceMd
        height: 64
        radius: Theme.radiusMd
        color: Theme.glassFill
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: Theme.spaceMd

            // Play / Pause / Restart Buttons
            Row {
                spacing: 6

                Rectangle {
                    width: 38
                    height: 38
                    radius: Theme.radiusPill
                    color: playMouse.containsMouse ? Theme.cinnabarHover : Theme.cinnabar
                    border.color: Theme.terracottaGlow
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 18
                        color: Theme.textOnCinnabar
                        text: robotDemoRoot.userPaused ? "play_arrow" : "pause"
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: robotDemoRoot.userPaused = !robotDemoRoot.userPaused
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: Theme.radiusPill
                    color: restartMouse.containsMouse ? Theme.bgSurfaceHover : Theme.bgSurface
                    border.color: Theme.borderCard
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcon
                        font.pixelSize: 17
                        color: Theme.textPrimary
                        text: "refresh"
                    }

                    MouseArea {
                        id: restartMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            robotDemoRoot.userPaused = false;
                            if (robotDemoRoot.activeGwlJob !== null) {
                                robotDemoRoot.startGwlHitpickJob(robotDemoRoot.activeGwlJob);
                            } else {
                                heroTimeline.restart();
                            }
                        }
                    }
                }
            }

            // Live Protocol Execution Telemetry
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: Theme.trackMicro
                        color: robotDemoRoot.activeGwlJob !== null ? Theme.paletteAccent : Theme.terracottaGlow
                        text: robotDemoRoot.activeGwlJob !== null ? "GWL HITPICK STEP:" : "PROTOCOL STEP:"
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        text: robotDemoRoot.activeGwlJob !== null ? robotDemoRoot.gwlPhaseText : heroTimeline.activePhaseText
                    }
                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.goldAccent
                        text: Math.round(robotDemoRoot.effectiveProgress * 100) + "%"
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Theme.stoneDark

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0.02, robotDemoRoot.effectiveProgress)
                        radius: 2
                        color: robotDemoRoot.gwlJobCompleted ? Theme.statusGreen : Theme.terracottaGlow
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.divider }

            // Live Kinematics Telemetry
            Column {
                spacing: 2
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textDim
                    text: "LiHa: " + scene3d.liha.axisX.toFixed(0) + " / " + scene3d.liha.axisY.toFixed(0) + " / " + (scene3d.liha.multiChannelGwlMode ? scene3d.liha.activeGroupZ : scene3d.liha.currentZ).toFixed(0)
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textDim
                    text: "RoMa: " + scene3d.roma.axisX.toFixed(0) + " / " + scene3d.roma.axisY.toFixed(0) + " / " + scene3d.roma.axisZ.toFixed(0) + " (R:" + scene3d.roma.rotationR.toFixed(0) + "°)"
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textDim
                    text: "MCA: " + scene3d.mca.axisX.toFixed(0) + " / " + scene3d.mca.axisY.toFixed(0) + " / " + scene3d.mca.axisZ.toFixed(0)
                }
            }
        }
    }
}
