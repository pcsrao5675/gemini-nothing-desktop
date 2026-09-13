import QtQuick
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 220
    implicitHeight: 44

    property int workDuration: 25 * 60
    property int breakDuration: 5 * 60
    property int remainingSeconds: 25 * 60
    property bool isRunning: false
    property bool isBreak: false

    signal pomodoroCompleted()

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
        return `${m < 10 ? "0" + m : m}:${s < 10 ? "0" + s : s}`;
    }

    Timer {
        interval: 1000
        running: root.isRunning
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--;
            } else {
                root.pomodoroCompleted();
                root.switchMode();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: pomoMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.90) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        border.color: pomoMa.containsMouse ? root.accentColor : Theme.outline
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

        MouseArea {
            id: pomoMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            // Status Indicator Dot
            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                color: root.isBreak ? "#4DA3FF" : Theme.alert
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.isRunning ? 1.0 : 0.45
            }

            // Compact Digital Display
            Text {
                text: root.formatTime(root.remainingSeconds)
                font.family: Theme.fontDots
                font.pixelSize: 16
                color: Theme.fg
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.isBreak ? "BRK" : "FOCUS"
                font.family: Theme.fontUi
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.0
                color: Theme.fgDim
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: 14
                color: Theme.outlineFaint
                anchors.verticalCenter: parent.verticalCenter
            }

            // Start / Pause
            Text {
                text: root.isRunning ? "pause" : "play_arrow"
                font.family: Theme.fontIcons
                font.pixelSize: 18
                color: playBtnMa.containsMouse ? root.accentColor : Theme.fg
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: playBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTimer()
                }
            }

            // Reset
            Text {
                text: "refresh"
                font.family: Theme.fontIcons
                font.pixelSize: 16
                color: resetBtnMa.containsMouse ? root.accentColor : Theme.fgDim
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: resetBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetTimer()
                }
            }
        }
    }
}
