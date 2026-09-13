import QtQuick
import ".."

Item {
    id: root

    default property alias content: contentContainer.data
    property color dotColor: Theme.accent
    property int duration: 360
    property real progress: 1.0 // 1.0 = fully solid, 0.0 = completely dissolved

    property var _pendingUpdateFn: null
    property var _pendingCallback: null

    Item {
        id: contentContainer
        anchors.fill: parent
        opacity: Math.max(0.0, Math.min(1.0, (root.progress - 0.2) / 0.8))
        scale: 0.95 + (0.05 * root.progress)
    }

    // Dot-matrix scatter canvas
    Canvas {
        id: dotCanvas
        anchors.fill: parent
        visible: root.progress < 0.98
        opacity: Math.sin(root.progress * Math.PI) // Peak dot visibility mid-transition

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (root.progress >= 0.98 || root.progress <= 0.02) return;

            ctx.fillStyle = root.dotColor;
            var step = 10;
            var currentP = root.progress;

            for (var x = 4; x < width; x += step) {
                for (var y = 4; y < height; y += step) {
                    // Deterministic pseudo-random noise threshold
                    var n = Math.abs(Math.sin(x * 12.9898 + y * 78.233) * 43758.5453) % 1.0;
                    if (Math.abs(n - currentP) < 0.35) {
                        var r = 1.0 + (1.5 * (1.0 - Math.abs(n - currentP) / 0.35));
                        ctx.beginPath();
                        ctx.arc(x, y, r, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }
            }
        }
    }

    onProgressChanged: {
        if (dotCanvas.visible) {
            dotCanvas.requestPaint();
        }
    }

    // Dissolve out to 0.0
    function dissolve(onDone) {
        root._pendingCallback = onDone || null;
        dissolveAnim.restart();
    }

    // Assemble in from 0.0 to 1.0
    function assemble(onDone) {
        root._pendingCallback = onDone || null;
        assembleAnim.restart();
    }

    // Swap content: dissolve out -> updateFn() -> assemble in
    function swapContent(updateFn) {
        root._pendingUpdateFn = updateFn || null;
        swapAnim.restart();
    }

    NumberAnimation {
        id: dissolveAnim
        target: root
        property: "progress"
        to: 0.0
        duration: root.duration * 0.5
        easing.type: Easing.InQuad
        onFinished: {
            if (root._pendingCallback) {
                var cb = root._pendingCallback;
                root._pendingCallback = null;
                cb();
            }
        }
    }

    NumberAnimation {
        id: assembleAnim
        target: root
        property: "progress"
        to: 1.0
        duration: root.duration * 0.5
        easing.type: Easing.OutQuad
        onFinished: {
            if (root._pendingCallback) {
                var cb = root._pendingCallback;
                root._pendingCallback = null;
                cb();
            }
        }
    }

    SequentialAnimation {
        id: swapAnim
        NumberAnimation {
            target: root
            property: "progress"
            to: 0.0
            duration: root.duration * 0.5
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                if (root._pendingUpdateFn) {
                    root._pendingUpdateFn();
                    root._pendingUpdateFn = null;
                }
            }
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: 1.0
            duration: root.duration * 0.5
            easing.type: Easing.OutQuad
        }
    }
}
