import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 200

    property int workDuration: 25 * 60
    property int breakDuration: 5 * 60
    property int remainingSeconds: 25 * 60
    property bool isRunning: false
    property bool isBreak: false

    function toggleTimer() {
        isRunning = !isRunning;
    }

    function resetTimer() {
        isRunning = false;
        remainingSeconds = isBreak ? breakDuration : workDuration;
    }

    function switchMode() {
        isRunning = false;
        isBreak = !isBreak;
        remainingSeconds = isBreak ? breakDuration : workDuration;
    }

    function formatTime(totalSecs) {
        const m = Math.floor(totalSecs / 60);
        const s = totalSecs % 60;
        const mm = m < 10 ? "0" + m : "" + m;
        const ss = s < 10 ? "0" + s : "" + s;
        return `${mm}:${ss}`;
    }

    Timer {
        interval: 1000
        running: root.isRunning
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--;
            } else {
                root.switchMode();
            }
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
            spacing: 12

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: Theme.iconTimer
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.isBreak ? "#4DA3FF" : Theme.alert
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.isBreak ? "BREAK TIMER" : "FOCUS POMODORO"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1 }
            }

            // Big Clock Countdown Display
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    text: root.formatTime(root.remainingSeconds)
                    font.family: Theme.fontDots
                    font.pixelSize: 42
                    font.letterSpacing: 3
                    color: root.isRunning ? (root.isBreak ? root.accentColor : Theme.alert) : Theme.fg
                }
            }

            // Progress Bar
            Rectangle {
                width: parent.width - 20
                height: 4
                radius: 2
                color: Theme.outline
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: root.isBreak ? root.accentColor : Theme.alert
                    width: {
                        const total = root.isBreak ? root.breakDuration : root.workDuration;
                        return Math.max(0, Math.min(parent.width, parent.width * (1.0 - (root.remainingSeconds / total))));
                    }
                }
            }

            // Controls Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                // Start/Pause Button
                Rectangle {
                    width: 90
                    height: 32
                    radius: Theme.radiusMd
                    color: root.isRunning ? Qt.rgba(Theme.alert.r, Theme.alert.g, Theme.alert.b, 0.25) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                    border.color: root.isRunning ? Theme.alert : root.accentColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.isRunning ? "PAUSE" : "START"
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTimer()
                    }
                }

                // Reset Button
                Rectangle {
                    width: 70
                    height: 32
                    radius: Theme.radiusMd
                    color: Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: Theme.outline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "RESET"
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fgDim
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetTimer()
                    }
                }

                // Mode Toggle Button (25m / 5m)
                Rectangle {
                    width: 80
                    height: 32
                    radius: Theme.radiusMd
                    color: Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: Theme.outline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.isBreak ? "WORK" : "BREAK"
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.fgDim
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchMode()
                    }
                }
            }
        }
    }
}
