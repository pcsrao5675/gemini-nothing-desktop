import QtQuick
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 140

    property real phase: 0.0

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            root.phase += 0.05;
            canvasMatrix.requestPaint();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: Theme.iconSparkle
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "NOTHING AMBIENT"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Decorative Matrix Canvas
            Canvas {
                id: canvasMatrix
                width: parent.width
                height: 70

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    const cols = 20;
                    const rows = 5;
                    const stepX = width / cols;
                    const stepY = height / rows;

                    for (var c = 0; c < cols; c++) {
                        for (var r = 0; r < rows; r++) {
                            const val = Math.sin(root.phase + c * 0.4 + r * 0.5);
                            const alpha = (val + 1) / 2 * 0.6 + 0.1;
                            ctx.fillStyle = Qt.rgba(1, 1, 1, alpha);
                            ctx.beginPath();
                            ctx.arc(c * stepX + stepX / 2, r * stepY + stepY / 2, 1.8, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }
}
