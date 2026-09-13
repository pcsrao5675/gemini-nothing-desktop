import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property bool assistantActive: false

    implicitWidth: 420
    implicitHeight: 64

    property real wavePhase: 0.0

    Timer {
        interval: 25 // 40 FPS
        running: true
        repeat: true
        onTriggered: {
            root.wavePhase += 0.04;
            canvas.requestPaint();
        }
    }

    // Active state polling from daemon
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "http://127.0.0.1:8765/active");
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    var parts = xhr.responseText.trim().split(":");
                    root.assistantActive = (parts[0] === "1");
                }
            };
            xhr.send();
        }
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => disconnectSource(cmd)
    }

    function toggleAssistant() {
        execSource.connectSource("$HOME/.local/bin/gemini-toggle.sh &");
    }

    Rectangle {
        id: waveBox
        anchors.fill: parent
        color: waveMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.85) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        radius: Theme.radiusLg
        border.color: root.assistantActive ? root.accentColor : (waveMa.containsMouse ? Theme.fgDim : Theme.outline)
        border.width: root.assistantActive || waveMa.containsMouse ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: Theme.durMedium } }
        Behavior on color { ColorAnimation { duration: Theme.durShort } }

        MouseArea {
            id: waveMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleAssistant()
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            z: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: root.assistantActive ? root.accentColor : Theme.fgDim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.assistantActive ? "GEMINI ASSISTANT ACTIVE" : "NOTHING AMBIENT WAVE"
                font.family: Theme.fontUi
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: waveMa.containsMouse ? Theme.fg : Theme.fgDim
            }

            Item { width: 1; height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "auto_awesome"
                font.family: Theme.fontIcons
                font.pixelSize: 14
                color: root.assistantActive ? root.accentColor : (waveMa.containsMouse ? Theme.fg : Theme.fgFaint)
            }
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            anchors.margins: 4
            clip: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var p = root.wavePhase;
                var w = width;
                var h = height;
                var col = root.accentColor;
                var cr = Math.round(col.r * 255);
                var cg = Math.round(col.g * 255);
                var cb = Math.round(col.b * 255);

                var g = ctx.createLinearGradient(0, h, 0, 0);
                g.addColorStop(0.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.25)");
                g.addColorStop(1.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.00)");
                ctx.fillStyle = g;

                ctx.beginPath();
                ctx.moveTo(0, h);
                var amp = root.assistantActive ? 14 : 5;
                for (var x = 0; x <= w; x += 15) {
                    var y = h - (12 + amp * Math.sin(x * 0.015 + p) + (amp * 0.4) * Math.cos(x * 0.03 - p * 1.5));
                    ctx.lineTo(x, y);
                }
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fill();

                // Bright top crest stroke
                ctx.strokeStyle = "rgba(" + cr + "," + cg + "," + cb + (root.assistantActive ? ", 0.85)" : ", 0.35)");
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                for (var x2 = 0; x2 <= w; x2 += 15) {
                    var y2 = h - (12 + amp * Math.sin(x2 * 0.015 + p) + (amp * 0.4) * Math.cos(x2 * 0.03 - p * 1.5));
                    if (x2 === 0) ctx.moveTo(x2, y2);
                    else ctx.lineTo(x2, y2);
                }
                ctx.stroke();
            }
        }
    }
}
