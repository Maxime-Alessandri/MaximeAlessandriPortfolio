import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import InvenesisPortfolio
import "."

View3D {
    id: view3d
    camera: mainCamera

    property alias liha: lihaItem
    property alias roma: romaItem
    property alias mca: mcaItem

    property bool showHousing: true
    property bool sourcePlateVisible: true
    property bool destinationPlateVisible: false

    readonly property bool assetsReady: worktableModel.status === RuntimeLoader.Success
    readonly property bool assetsError: worktableModel.status === RuntimeLoader.Error

    // Orbit Camera controls centered on Fluent 1080 deck
    property real cameraPitch: -28.0
    property real cameraYaw: 35.0
    property real cameraDistance: 2200.0
    property vector3d lookTarget: Qt.vector3d(950.0, 450.0, 200.0)

    environment: SceneEnvironment {
        backgroundMode: SceneEnvironment.Color
        clearColor: Theme.bgCard

        // PBR & Shadow enhancements - Optimized for 60 FPS
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.Medium
        aoEnabled: false
        tonemapMode: SceneEnvironment.TonemapModeLinear
    }

    // Pivot root for orbiting camera
    Node {
        id: cameraPivot
        position: view3d.lookTarget

        eulerRotation.x: view3d.cameraPitch
        eulerRotation.z: view3d.cameraYaw

        PerspectiveCamera {
            id: mainCamera
            position: Qt.vector3d(0, -view3d.cameraDistance, 0)
            eulerRotation.x: 90 // Point towards pivot center
            clipNear: 10.0
            clipFar: 25000.0
            fieldOfView: 42.0
        }
    }

    // =========================================================================
    // PHYSICAL STUDIO LIGHTING (Constant True Luminance across Dark & Light Modes)
    // =========================================================================

    // 01. Key Cleanroom Daylight LED (High-intensity key light from front-right)
    DirectionalLight {
        eulerRotation.x: -45
        eulerRotation.y: 35
        eulerRotation.z: 15
        color: "#FFFFFF"
        brightness: Theme.isDark ? 1.8 : 2.4
        castsShadow: false
    }

    // 02. Soft Ambient Fill Light (Eliminates harsh shadows from front-left)
    DirectionalLight {
        eulerRotation.x: -30
        eulerRotation.y: -140
        color: Theme.isDark ? Theme.mix(Theme.paletteAccent, Qt.color("#E2E8F0"), 0.5) : "#E8F0FE"
        brightness: Theme.isDark ? 1.0 : 1.6
        castsShadow: false
    }

    // 03. Top-Rear Metallic Rim Light (Defines gantry chamfers, grippers & acrylic hood)
    DirectionalLight {
        eulerRotation.x: 60
        eulerRotation.y: 0
        color: "#FFFFFF"
        brightness: Theme.isDark ? 0.8 : 1.2
        castsShadow: false
    }

    // 04. Ground Bounce Light (Upward reflection from deck floor - prevents crushed shadows in Light Mode)
    DirectionalLight {
        eulerRotation.x: 65
        eulerRotation.y: -40
        color: Theme.isDark ? "#2A3444" : "#FFFFFF"
        brightness: Theme.isDark ? 0.4 : 1.0
        castsShadow: false
    }

    // =========================================================================
    // STATIC SCENE: Worktable & Fluent 1080 Housing
    // =========================================================================
    Node {
        id: staticWorldRoot

        // Fluent 1080 Outer Enclosure & Acrylic Hood (visible by default)
        RuntimeLoader {
            id: housingModel
            source: AppConfig.asset("Robots/Myrius1080.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
            visible: view3d.showHousing
        }

        // Invenesis Worktable Deck, Waste Chute, Labware Carriers & SBS Plates
        RuntimeLoader {
            id: worktableModel
            source: AppConfig.asset("Invenesis_worktable_New.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }
    }

    // =========================================================================
    // DYNAMIC MICROPLATES & ADAPTER ON DECK (Pick and Place Handover)
    // =========================================================================
    Node {
        id: dynamicPlatesRoot

        // Source microplate RoMaPlate[004] sitting in Hotel shelf 12 before RoMa pickup
        Node {
            id: sourcePlateNode
            position: Qt.vector3d(497.0, 670.5, 160.5)
            eulerRotation.z: 270.0
            visible: view3d.sourcePlateVisible

            RuntimeLoader {
                id: sourcePlateModel
                source: AppConfig.asset("Robots/plate96.glb")
                position: Qt.vector3d(-63.88, -42.74, 0)
            }
        }

        // Destination microplate sitting at target Nest 8 (61mm Nest[191]) after RoMa placement
        Node {
            id: targetPlateNode
            position: Qt.vector3d(1259.23, 181.27, 61.0)
            eulerRotation.z: 0.0
            visible: view3d.destinationPlateVisible

            RuntimeLoader {
                id: targetPlateModel
                source: AppConfig.asset("Robots/plate96.glb")
                position: Qt.vector3d(-63.88, -42.74, 0)
            }
        }

        // 96 MCA384 Head Adapter sitting on MCA384 Adapter Nest[002] before MCA pickup
        Node {
            id: mcaAdapterOnNestNode
            position: Qt.vector3d(1808.90, 330.90, 87.20)
            visible: !mcaItem.adapterMounted

            RuntimeLoader {
                id: mcaAdapterNestModel
                source: AppConfig.asset("Robots/MCA96_Adapter.glb")
            }
        }
    }

    // =========================================================================
    // DYNAMIC ROBOT ARMS (Kinematic Node Trees)
    // =========================================================================
    LiHaArm {
        id: lihaItem
    }

    RomaArm {
        id: romaItem
    }

    Mca96Arm {
        id: mcaItem
    }
}
