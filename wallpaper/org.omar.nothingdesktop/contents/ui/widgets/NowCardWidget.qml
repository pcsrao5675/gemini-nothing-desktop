import QtQuick
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property string icsFilePath: ""

    implicitWidth: 360
    implicitHeight: activeMode === "hidden" ? 0 : 150
    visible: opacity > 0.01

    Behavior on implicitHeight { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

    signal pomodoroCompleted()

    // ── Mode determination ─────────────────────────────
    // Priority: Pomodoro (active/paused) > Media (playing) > Calendar Event > Hidden
    readonly property string activeMode: {
        if (pomoRunning || (pomoRemaining < pomoDuration && pomoRemaining > 0)) {
            return "pomodoro";
        }
        if (hasMedia && isPlaying) {
            return "media";
        }
        if (nextEvent !== null && nextEvent.title !== "") {
            return "calendar";
        }
        return "hidden";
    }

    property string displayedMode: "hidden"

    onActiveModeChanged: {
        if (root.activeMode !== root.displayedMode) {
            transition.swapContent(function() {
                root.displayedMode = root.activeMode;
                root.opacity = root.activeMode === "hidden" ? 0.0 : 1.0;
            });
        }
    }

    Component.onCompleted: {
        root.displayedMode = root.activeMode;
        root.opacity = root.activeMode === "hidden" ? 0.0 : 1.0;
    }

    // ── 1. Pomodoro Subsystem ──────────────────────────
    property int pomoDuration: 25 * 60
    property int pomoBreak: 5 * 60
    property int pomoRemaining: 25 * 60
    property bool pomoRunning: false
    property bool pomoIsBreak: false

    function startPomodoro() {
        pomoRunning = true;
    }

    function togglePomodoro() {
        pomoRunning = !pomoRunning;
    }

    function resetPomodoro() {
        pomoRunning = false;
        pomoRemaining = pomoIsBreak ? pomoBreak : pomoDuration;
    }

    Timer {
        interval: 1000
        running: root.pomoRunning
        repeat: true
        onTriggered: {
            if (root.pomoRemaining > 0) {
                root.pomoRemaining--;
            } else {
                root.pomodoroCompleted();
                root.pomoIsBreak = !root.pomoIsBreak;
                root.pomoRemaining = root.pomoIsBreak ? root.pomoBreak : root.pomoDuration;
                root.pomoRunning = false;
            }
        }
    }

    function formatTime(totalSecs) {
        const m = Math.floor(totalSecs / 60);
        const s = totalSecs % 60;
        return `${m < 10 ? "0" + m : m}:${s < 10 ? "0" + s : s}`;
    }

    // ── 2. Media Subsystem ─────────────────────────────
    Mpris.Mpris2Model {
        id: mprisModel
    }

    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasMedia: player !== null
    readonly property bool isPlaying: player ? (player.playbackStatus === Mpris.PlaybackStatus.Playing) : false
    readonly property string trackTitle: player ? (player.track || "No Track") : "No Track"
    readonly property string artistName: player ? (player.artist || "Unknown Artist") : "Unknown Artist"
    readonly property string albumArt: player ? (player.artUrl || "") : ""

    function raisePlayer() {
        if (player) {
            execSource.connectSource(`qdbus ${player.service} /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Raise 2>/dev/null || true`);
        }
    }

    // ── 3. Calendar Next Event Subsystem ───────────────
    property var nextEvent: ({
        time: "TODAY 14:00",
        title: "Antigravity UI Pipeline Sync",
        loc: "Remote Collaboration"
    })

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (out.length > 0) {
                const firstLine = out.split("\n")[0];
                const parts = firstLine.split("|");
                if (parts.length >= 2) {
                    root.nextEvent = {
                        time: parts[0] || "TODAY",
                        title: parts[1] || "",
                        loc: parts[2] || ""
                    };
                }
            }
        }
    }

    // ── Visual Card Container with Dot-Dissolve Transition ──
    Rectangle {
        id: cardBg
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.82)
        radius: Theme.radiusLg
        border.color: cardMa.containsMouse ? root.accentColor : Theme.outline
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

        MouseArea {
            id: cardMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        DotDissolveTransition {
            id: transition
            anchors.fill: parent
            anchors.margins: 14
            dotColor: root.accentColor
            duration: 380

            // Content item swapped dynamically
            Item {
                anchors.fill: parent

                // ── POMODORO VIEW ──
                Item {
                    id: pomoView
                    anchors.fill: parent
                    visible: root.displayedMode === "pomodoro"

                    Row {
                        id: pomoHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: root.pomoIsBreak ? "#4DA3FF" : Theme.alert
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: root.pomoRunning ? 1.0 : 0.4
                        }

                        Text {
                            text: (root.pomoIsBreak ? "NOW // BREAK TIME" : "NOW // FOCUS SESSION")
                            font.family: Theme.fontDots
                            font.pixelSize: 10
                            font.letterSpacing: 2
                            color: Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 1; height: 1 }

                        Rectangle {
                            height: 18
                            radius: 9
                            color: Qt.rgba(1, 1, 1, 0.08)
                            implicitWidth: modeTxt.implicitWidth + 12
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: modeTxt
                                anchors.centerIn: parent
                                text: root.pomoIsBreak ? "BREAK" : "WORK"
                                font.family: Theme.fontUi
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.fg
                            }
                        }
                    }

                    // Digital Readout + Controls
                    Row {
                        anchors.top: pomoHeader.bottom
                        anchors.topMargin: 12
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        spacing: 16

                        Text {
                            text: root.formatTime(root.pomoRemaining)
                            font.family: Theme.fontDots
                            font.pixelSize: 42
                            color: Theme.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter

                            // Play / Pause Button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: pomoBtnMa.containsMouse ? root.accentColor : Theme.surfaceAlt
                                border.color: root.accentColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: root.pomoRunning ? "pause" : "play_arrow"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 18
                                    color: pomoBtnMa.containsMouse ? Theme.bg : Theme.fg
                                }

                                MouseArea {
                                    id: pomoBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.togglePomodoro()
                                }
                            }

                            // Reset Button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: resetBtnMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                                border.color: Theme.outlineFaint
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "refresh"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 18
                                    color: Theme.fgDim
                                }

                                MouseArea {
                                    id: resetBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.resetPomodoro()
                                }
                            }
                        }
                    }
                }

                // ── MEDIA VIEW ──
                Item {
                    id: mediaView
                    anchors.fill: parent
                    visible: root.displayedMode === "media"

                    Row {
                        anchors.fill: parent
                        spacing: 14

                        // Thumbnail / Art
                        Rectangle {
                            width: 80
                            height: 80
                            radius: Theme.radiusMd
                            color: Theme.surfaceAlt
                            border.color: artClickMa.containsMouse ? root.accentColor : Theme.outlineFaint
                            border.width: 1
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: root.albumArt
                                fillMode: Image.PreserveAspectCrop
                                visible: root.albumArt !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.albumArt === ""
                                text: "music_note"
                                font.family: Theme.fontIcons
                                font.pixelSize: 28
                                color: Theme.fgFaint
                            }

                            MouseArea {
                                id: artClickMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.raisePlayer()
                            }
                        }

                        // Info & Controls Column
                        Column {
                            width: parent.width - 94
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                spacing: 6
                                Rectangle {
                                    width: 6; height: 6; radius: 3; color: root.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "NOW // PLAYING"
                                    font.family: Theme.fontDots
                                    font.pixelSize: 9
                                    font.letterSpacing: 2
                                    color: Theme.fgDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.trackTitle
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.fg
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.artistName
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                color: Theme.fgDim
                                elide: Text.ElideRight
                            }

                            // Minimal Controls Row
                            Row {
                                spacing: 12
                                topPadding: 4

                                Text {
                                    text: "skip_previous"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 20
                                    color: prevMa.containsMouse ? root.accentColor : Theme.fgDim
                                    MouseArea {
                                        id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player) root.player.Previous();
                                        }
                                    }
                                }

                                Text {
                                    text: root.isPlaying ? "pause" : "play_arrow"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 20
                                    color: playMa.containsMouse ? root.accentColor : Theme.fg
                                    MouseArea {
                                        id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player) root.player.PlayPause();
                                        }
                                    }
                                }

                                Text {
                                    text: "skip_next"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 20
                                    color: nextMa.containsMouse ? root.accentColor : Theme.fgDim
                                    MouseArea {
                                        id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.player) root.player.Next();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── CALENDAR EVENT VIEW ──
                Item {
                    id: calView
                    anchors.fill: parent
                    visible: root.displayedMode === "calendar"

                    Column {
                        anchors.fill: parent
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            spacing: 6
                            Rectangle {
                                width: 6; height: 6; radius: 3; color: root.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "NOW // UPCOMING EVENT"
                                font.family: Theme.fontDots
                                font.pixelSize: 9
                                font.letterSpacing: 2
                                color: Theme.fgDim
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.nextEvent ? (root.nextEvent.title || "Upcoming Task") : "Upcoming Task"
                            font.family: Theme.fontUi
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        Row {
                            spacing: 12
                            Row {
                                spacing: 4
                                Text {
                                    text: "schedule"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 14
                                    color: root.accentColor
                                }
                                Text {
                                    text: root.nextEvent ? (root.nextEvent.time || "TODAY") : "TODAY"
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    color: Theme.fgDim
                                }
                            }

                            Row {
                                spacing: 4
                                Text {
                                    text: "location_on"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 14
                                    color: Theme.fgFaint
                                }
                                Text {
                                    text: root.nextEvent ? (root.nextEvent.loc || "Local") : "Local"
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    color: Theme.fgDim
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
