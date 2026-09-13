import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 200

    property var habits: [
        { title: "Deep Work Session", days: [true, true, true, false, true, false, false] },
        { title: "Review Pull Requests", days: [true, true, false, true, true, false, false] },
        { title: "Terminal Health Check", days: [true, true, true, true, true, false, false] }
    ]

    readonly property var dayLabels: ["M", "T", "W", "T", "F", "S", "S"]

    function toggleHabitDay(hIndex, dIndex) {
        var copy = JSON.parse(JSON.stringify(root.habits));
        copy[hIndex].days[dIndex] = !copy[hIndex].days[dIndex];
        root.habits = copy;
        saveHabits();
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd.startsWith("cat")) {
                const out = (data["stdout"] ?? "").trim();
                if (out) {
                    try {
                        const parsed = JSON.parse(out);
                        if (Array.isArray(parsed) && parsed.length > 0) root.habits = parsed;
                    } catch(e) {}
                }
            }
        }
    }

    function saveHabits() {
        const jsonStr = JSON.stringify(root.habits);
        const b64 = Qt.btoa(jsonStr);
        execSource.connectSource(`mkdir -p "$HOME/.local/share/nothing-desktop" && echo "${b64}" | base64 -d > "$HOME/.local/share/nothing-desktop/habits.json"`);
    }

    Component.onCompleted: {
        execSource.connectSource(`[ -f "$HOME/.local/share/nothing-desktop/habits.json" ] && cat "$HOME/.local/share/nothing-desktop/habits.json" || true`);
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
                    text: Theme.iconCheck
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "HABIT TRACKER"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Habits List
            Column {
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.habits
                    delegate: Row {
                        width: parent.width
                        spacing: 8
                        readonly property int hIdx: index

                        Text {
                            width: 110
                            text: modelData.title
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            color: Theme.fg
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: 7
                                delegate: Rectangle {
                                    readonly property int dIdx: index
                                    readonly property bool done: modelData.days[dIdx]
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: done ? root.accentColor : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                                    border.color: done ? root.accentColor : Theme.outline
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.dayLabels[dIdx]
                                        font.family: Theme.fontDots
                                        font.pixelSize: 8
                                        color: done ? "#050505" : Theme.fgDim
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleHabitDay(hIdx, dIdx)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
