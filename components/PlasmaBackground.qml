import QtQuick
import InvenesisPortfolio
import ".."

Item {
    id: plasmaRoot

    property color color: Theme.paletteAccent
    property real speed: 0.18
    property real scale: 1.1
    property real effectOpacity: 0.55
    property bool mouseInteractive: true
    property bool running: true

    property real internalTime: 0.0
    property real mouseX: width * 0.5
    property real mouseY: height * 0.5

    function reset() {
        internalTime = 0.0;
    }

    FrameAnimation {
        running: plasmaRoot.running
        onTriggered: {
            plasmaRoot.internalTime += frameTime;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: plasmaRoot.mouseInteractive
        acceptedButtons: Qt.NoButton

        onPositionChanged: function(mouse) {
            if (plasmaRoot.mouseInteractive) {
                plasmaRoot.mouseX = mouse.x;
                plasmaRoot.mouseY = plasmaRoot.height - mouse.y;
            }
        }
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent

        readonly property vector2d iResolution: Qt.vector2d(Math.max(1.0, width), Math.max(1.0, height))
        readonly property real iTime: plasmaRoot.internalTime
        readonly property vector3d uCustomColor: Qt.vector3d(plasmaRoot.color.r, plasmaRoot.color.g, plasmaRoot.color.b)
        readonly property real uUseCustomColor: 1.0
        readonly property real uSpeed: plasmaRoot.speed
        readonly property real uDirection: 1.0
        readonly property real uScale: Math.max(0.01, plasmaRoot.scale)
        readonly property real uOpacity: plasmaRoot.effectOpacity
        readonly property vector2d uMouse: Qt.vector2d(plasmaRoot.mouseX, plasmaRoot.mouseY)
        readonly property real uMouseInteractive: plasmaRoot.mouseInteractive ? 1.0 : 0.0

        fragmentShader: "qrc:/InvenesisPortfolio/assets/plasma.frag.qsb"
    }
}
