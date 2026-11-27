pragma ComponentBehavior: Bound
import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import InvenesisPortfolio

Node {
    id: lihaRoot

    // Kinematic inputs (TeMotion/LIHA:1/DRIVE coordinates in mm)
    property real axisX: 109.50       // DRIVE:X
    property real axisY: 204.00       // DRIVE:E,0 (Channel 0 Y coordinate)
    property real travelZ: 207.10     // DRIVE:Z safe travel height
    property real dispenseZ: 104.20   // DRIVE:Z dispense height
    property real currentZ: 207.10    // Active channels 0..4 DRIVE:Z (HeroAnimationController loop)
    property real idleDriveZ: 207.10  // Unused channels 5..7 DRIVE:Z (parked high)
    property bool tipsMounted: false

    // True 8-Channel Independent Kinematics (used during GWL Hitpick & Serial Dilution replay)
    property bool multiChannelGwlMode: false
    property real activeGroupZ: 207.10
    property var activeChannelsMask: [true, true, true, true, true, true, true, true]
    property var mountedTipsMask: [false, false, false, false, false, false, false, false]

    component LiHaChannelNode: Node {
        id: channelNode
        required property int channelIdx

        readonly property bool isChannelActive: lihaRoot.activeChannelsMask.length > channelIdx
                                                && Boolean(lihaRoot.activeChannelsMask[channelIdx])
        readonly property bool hasChannelTip: lihaRoot.mountedTipsMask.length > channelIdx
                                              && Boolean(lihaRoot.mountedTipsMask[channelIdx])

        x: 0
        y: -channelIdx * 9.0
        z: lihaRoot.multiChannelGwlMode
           ? (isChannelActive ? lihaRoot.activeGroupZ : (hasChannelTip ? 251.70 : 207.10))
           : (channelIdx < 5 ? lihaRoot.currentZ : lihaRoot.idleDriveZ)

        RuntimeLoader {
            source: AppConfig.asset("Robots/LiHa_Plungers_Ch0.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }

        RuntimeLoader {
            source: AppConfig.asset("Robots/LiHa_Tips_Ch0.glb")
            visible: lihaRoot.multiChannelGwlMode ? channelNode.hasChannelTip : (channelNode.channelIdx < 5 && lihaRoot.tipsMounted)
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }
    }

    // Gantry X translation
    x: axisX
    y: 0
    z: 0

    // Main LiHa Gantry Carriage (travels on top X rail)
    RuntimeLoader {
        id: lihaGantryMesh
        source: AppConfig.asset("Robots/LiHa_Gantry.glb")
        scale: Qt.vector3d(1.0, 1.0, 1.0)
    }

    // 8 Y-Carriages (slide along Y on the gantry rail; remain fixed at Z=0 on the rail)
    Node {
        id: yCarriagesNode
        x: 0
        y: lihaRoot.axisY - 31.5 // Channel 0 mesh is at local Y=+31.5mm; worldY(ch) = axisY - ch * 9.0
        z: 0

        RuntimeLoader {
            id: yCarriagesMesh
            source: AppConfig.asset("Robots/LiHa_YCarriages.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }

        // 8 Independent Liquid-Handling Fingers (Channels 0..7, 9mm SBS spacing)
        LiHaChannelNode { channelIdx: 0 }
        LiHaChannelNode { channelIdx: 1 }
        LiHaChannelNode { channelIdx: 2 }
        LiHaChannelNode { channelIdx: 3 }
        LiHaChannelNode { channelIdx: 4 }
        LiHaChannelNode { channelIdx: 5 }
        LiHaChannelNode { channelIdx: 6 }
        LiHaChannelNode { channelIdx: 7 }
    }
}
