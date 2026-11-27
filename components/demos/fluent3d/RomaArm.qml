import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import InvenesisPortfolio

Node {
    id: romaRoot

    property real axisX: 1079.98      // Gantry travel along X (DRIVE:X)
    property real axisY: 181.27       // Carriage travel along Y (DRIVE:Y)
    property real axisZ: 339.67       // Elevator travel along Z (DRIVE:Z)
    property real rotationR: 90.0     // Rotary joint angle in degrees around Z-axis (DRIVE:R: 90° at park/hotel, 180° at nest)
    property real jawSpread: 94.0     // Gripper opening width in mm (80mm clamps SBS plate, 94mm open)
    property bool hasPlateGripped: false

    x: axisX
    y: 0
    z: 0

    // RoMa Gantry Base Carriage (travels on X rail)
    RuntimeLoader {
        id: romaGantryMesh
        source: AppConfig.asset("Robots/Roma_Gantry.glb")
        scale: Qt.vector3d(1.0, 1.0, 1.0)
    }

    // Y/Z Elevator Carriage Node (travels along Y and elevates along Z)
    Node {
        id: elevatorNode
        x: 0
        y: romaRoot.axisY
        z: romaRoot.axisZ

        RuntimeLoader {
            id: elevatorMesh
            source: AppConfig.asset("Robots/Roma_ZElevator.glb")
            scale: Qt.vector3d(1.0, 1.0, 1.0)
        }

        // Rotary Joint (R-Axis around Z)
        Node {
            id: rotaryJoint
            eulerRotation.z: romaRoot.rotationR

            // Centric Gripper Rotary Wrist & Housing
            RuntimeLoader {
                id: gripperBody
                source: AppConfig.asset("Robots/Roma_RotaryHead.glb")
                scale: Qt.vector3d(1.0, 1.0, 1.0)
            }

            // Gripper Head Node (inherits GRIPPER_HEAD +90 deg orientation from CgaVx.x3d)
            Node {
                id: gripperHead
                eulerRotation.z: 90.0

                // Left Gripper Jaw & Eccentric Finger (clamps at -43mm for 86mm SBS plate)
                Node {
                    id: leftFingerNode
                    x: -romaRoot.jawSpread / 2.0
                    y: 0
                    z: 0

                    RuntimeLoader {
                        id: leftFingerMesh
                        source: AppConfig.asset("Robots/Roma_LeftJawFinger.glb")
                        scale: Qt.vector3d(1.0, 1.0, 1.0)
                    }
                }

                // Right Gripper Jaw & Eccentric Finger (clamps at +43mm for 86mm SBS plate)
                Node {
                    id: rightFingerNode
                    x: romaRoot.jawSpread / 2.0
                    y: 0
                    z: 0

                    RuntimeLoader {
                        id: rightFingerMesh
                        source: AppConfig.asset("Robots/Roma_RightJawFinger.glb")
                        scale: Qt.vector3d(1.0, 1.0, 1.0)
                    }
                }

                // Gripped Plate Attachment Point (moves locked with the gripper when gripped)
                Node {
                    id: grippedPlateNode
                    visible: romaRoot.hasPlateGripped
                    x: 0
                    y: -152.5 // Exact Tecan eccentricFingers CenterOffset
                    z: -85.3  // Exact Tecan eccentricFingers ZOffset
                    eulerRotation.z: 90.0

                    RuntimeLoader {
                        id: grippedPlateMesh
                        source: AppConfig.asset("Robots/plate96.glb")
                        position: Qt.vector3d(-63.88, -42.74, 0) // Center plate96 (127.76 x 85.48) around grip center
                        scale: Qt.vector3d(1.0, 1.0, 1.0)
                    }
                }
            }
        }
    }
}
