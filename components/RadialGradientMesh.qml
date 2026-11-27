import QtQuick
import InvenesisPortfolio
import ".."

Item {
    id: gradRoot

    Canvas {
        id: gradCanvas
        anchors.fill: parent

        Connections {
            target: Theme
            function onPaletteChanged() { gradCanvas.requestPaint(); }
        }

        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;
            ctx.clearRect(0, 0, w, h);

            // Base deep void
            ctx.fillStyle = Theme.bgVoid;
            ctx.fillRect(0, 0, w, h);

            // Ambient warm glow behind helix (centered at ~58% width, 50% height)
            var cx = w * 0.58;
            var cy = h * 0.50;
            var r = Math.max(w, h) * 0.55;

            var cGlow = Theme.paletteTertiary;
            var cMid = Theme.paletteAccent;
            var cSur = Theme.bgSurface;
            var cVoid = Theme.bgVoid;

            var radGrad = ctx.createRadialGradient(cx, cy, 20, cx, cy, r);
            radGrad.addColorStop(0.0, Qt.rgba(cGlow.r, cGlow.g, cGlow.b, 0.32));
            radGrad.addColorStop(0.35, Qt.rgba(cMid.r, cMid.g, cMid.b, 0.22));
            radGrad.addColorStop(0.70, Qt.rgba(cSur.r, cSur.g, cSur.b, 0.12));
            radGrad.addColorStop(1.0, Qt.rgba(cVoid.r, cVoid.g, cVoid.b, 0.0));

            ctx.fillStyle = radGrad;
            ctx.fillRect(0, 0, w, h);
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}
