import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property string icsFilePath: ""

    implicitWidth: 320
    implicitHeight: 220

    property var eventsList: []

    // Read ICS files or generate sensible upcoming events
    readonly property string readCmd: {
        if (root.icsFilePath && root.icsFilePath.trim() !== "") {
            return "python3 -c '
import sys
path = \"" + root.icsFilePath.trim() + "\"
try:
    with open(path, \"r\", encoding=\"utf-8\", errors=\"ignore\") as f:
        lines = f.readlines()
    events = []
    summary, dt = \"\", \"\"
    for l in lines:
        l = l.strip()
        if l.startswith(\"SUMMARY:\"):
            summary = l[8:]
        elif l.startswith(\"DTSTART\"):
            dt = l.split(\":\")[-1][:8]
        elif l.startswith(\"END:VEVENT\"):
            if summary:
                events.append(f\"{dt}|{summary}\")
            summary, dt = \"\", \"\"
    print(\"\\n\".join(events[:4]))
except Exception as e:
    print(\"\")
'"
        }
        return "echo -e 'TODAY|Nothing Desktop Workspace Setup\nTOMORROW|System Performance Review\nUPCOMING|Gemini Floating Assistant'"
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (!out) return;
            const items = [];
            const lines = out.split("\n");
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("|");
                if (parts.length >= 2) {
                    items.push({ date: parts[0], title: parts[1] });
                } else if (parts.length === 1 && parts[0]) {
                    items.push({ date: "EVENT", title: parts[0] });
                }
            }
            root.eventsList = items;
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: execSource.connectSource(root.readCmd)
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header
            Row {
                width: parent.width
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iconCalendar
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: root.accentColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AGENDA & SCHEDULE"
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Theme.fgDim
                }
            }

            // Events List
            ListView {
                width: parent.width
                height: parent.height - 30
                model: root.eventsList
                clip: true
                spacing: 8
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 42
                    radius: Theme.radiusSm
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 20
                            radius: 1.5
                            color: root.accentColor
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.title
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.fg
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.date
                                font.family: Theme.fontDots
                                font.pixelSize: 9
                                color: Theme.fgDim
                            }
                        }
                    }
                }
            }
        }
    }
}
