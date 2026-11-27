import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import InvenesisPortfolio

Node {
    id: mcaRoot

    // Kinematic inputs (TeMotion/MCA:1,384/DRIVE coordinates in mm)
    property real axisX: 1743.23      // Gantry travel along X (DRIVE:X)
    property real axisY: 147.00       // Carriage travel along Y (DRIVE:Y)
    property real axisZ: 235.07       // Elevator travel along Z (DRIVE:Z)
    property bool adapterMounted: false
    property bool tipsMounted: false

    x: axisX
    y: 0
    z: 0

    // MCA96 Gantry Rail & Main Carriage Model (travels along X rail)
    RuntimeLoader {
        id: mcaGantryMesh
        source: AppConfig.asset("Robots/MCA96_Gantry.glb")
        scale: Qt.vector3d(1.0, 1.0, 1.0)
    }

    // Moving Y Carriage (slides front-to-back along Y on the gantry rail via DRIVE:Y)
    Node {
        id: yCarriageNode
        x: 0
        y: mcaRoot.axisY
        z: 0

        RuntimeLoader {
            id: mcaCarriageMesh
            source: AppConfig.asset("Robots/MCA96_Carriage.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }

        // Moving Z Elevator + 96-Channel Head, Adapter & Tips (elevates up/down via DRIVE:Z)
        // Bare head bottom is at local Z=-7.4mm   -> World Z = DRIVE:Z - 7.4mm
        // Adapter bottom is at local Z=-15.6mm    -> World Z = DRIVE:Z - 15.6mm
        // 96 Tip bottoms are at local Z=-43.4mm   -> World Z = DRIVE:Z - 43.4mm
        Node {
            id: headElevatorNode
            x: 0
            y: 0
            z: mcaRoot.axisZ

            RuntimeLoader {
                id: mcaElevatorMesh
                source: AppConfig.asset("Robots/MCA96_Elevator.glb")
                scale: Qt.vector3d(1.0, 1.0, 1.0)
            }

            RuntimeLoader {
                id: mcaAdapterMesh
                source: AppConfig.asset("Robots/MCA96_Adapter.glb")
                visible: mcaRoot.adapterMounted
                scale: Qt.vector3d(1.0, 1.0, 1.0)
            }

            RuntimeLoader {
                id: mcaTipsMesh
                source: AppConfig.asset("Robots/MCA96_Tips.glb")
                visible: mcaRoot.tipsMounted
                scale: Qt.vector3d(1.0, 1.0, 1.0)
            }
        }
    }
}
