import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property string icsFilePath: ""

    implicitWidth: 340
    implicitHeight: 250

    property var eventsList: []
    property int expandedIndex: -1

    function launchCalendar() {
        execSource.connectSource("which merkuro-calendar >/dev/null 2>&1 && merkuro-calendar & || { which korganizer >/dev/null 2>&1 && korganizer & || xdg-open https://calendar.google.com &; }");
    }

    function dismissEvent(idx) {
        var copy = eventsList.slice();
        copy.splice(idx, 1);
        eventsList = copy;
        if (root.expandedIndex === idx) root.expandedIndex = -1;
    }

    // Read ICS files or generate sensible upcoming events
    readonly property string readCmd: {
        if (root.icsFilePath && root.icsFilePath.trim() !== "") {
            return "python3 -c '\n" +
"import sys\n" +
"path = \"" + root.icsFilePath.trim() + "\"\n" +
"try:\n" +
"    with open(path, \"r\", encoding=\"utf-8\", errors=\"ignore\") as f:\n" +
"        lines = f.readlines()\n" +
"    events = []\n" +
"    summary, dt, loc = \"\", \"\", \"\"\n" +
"    for l in lines:\n" +
"        l = l.strip()\n" +
"        if l.startswith(\"SUMMARY:\"):\n" +
"            summary = l[8:]\n" +
"        elif l.startswith(\"DTSTART\"):\n" +
"            dt = l.split(\":\")[-1][:8]\n" +
"        elif l.startswith(\"LOCATION:\"):\n" +
"            loc = l[9:]\n" +
"        elif l.startswith(\"END:VEVENT\"):\n" +
"            if summary:\n" +
"                events.append(f\"{dt}|{summary}|{loc}\")\n" +
"            summary, dt, loc = \"\", \"\", \"\"\n" +
"    print(\"\\n\".join(events[:6]))\n" +
"except Exception as e:\n" +
"    print(\"\")\n" +
"'"
        }
        return "echo -e 'TODAY 11:30|Core Plasma Architecture Review|KDE Wayland Session\nTODAY 14:00|Antigravity UI Pipeline Sync|Remote Collaboration\nTOMORROW 10:00|System Performance Review|Terminal Telemetry\nUPCOMING|Gemini Floating Assistant|Desktop Layer'"
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd.startsWith("which")) return;
            const out = (data["stdout"] ?? "").trim();
            if (!out) return;
            const items = [];
            const lines = out.split("\n");
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("|");
                if (parts.length >= 3) {
                    items.push({ date: parts[0], title: parts[1], location: parts[2] });
                } else if (parts.length === 2) {
                    items.push({ date: parts[0], title: parts[1], location: "Scheduled Item" });
                } else if (parts.length === 1 && parts[0]) {
                    items.push({ date: "EVENT", title: parts[0], location: "General" });
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
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

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

                Item { width: 1; height: 1 }

                // Calendar App Launch Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    
                    width: 26
                    height: 26
                    radius: 13
                    color: calLaunchMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "open_in_new"
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: calLaunchMa.containsMouse ? Theme.fg : Theme.fgDim
                    }

                    MouseArea {
                        id: calLaunchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchCalendar()
                    }
                }
            }

            // Events List
            ListView {
                width: parent.width
                height: parent.height - 38
                model: root.eventsList
                clip: true
                spacing: 8

                delegate: Rectangle {
                    id: eventRow
                    width: ListView.view.width
                    height: root.expandedIndex === index ? 68 : 42
                    radius: Theme.radiusSm
                    color: rowMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: root.expandedIndex === index ? root.accentColor : (rowMa.containsMouse ? Theme.outline : Theme.outlineFaint)
                    border.width: 1

                    Behavior on height { NumberAnimation { duration: Theme.durShort } }
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.expandedIndex === index) {
                                root.expandedIndex = -1;
                            } else {
                                root.expandedIndex = index;
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Row {
                            width: parent.width
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
                                width: parent.width - 60
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

                            // Dismiss / complete action
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                radius: 11
                                color: dismissMa.containsMouse ? Theme.surfaceAlt : "transparent"
                                visible: rowMa.containsMouse || root.expandedIndex === index

                                Text {
                                    anchors.centerIn: parent
                                    text: Theme.iconCheck
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 13
                                    color: dismissMa.containsMouse ? root.accentColor : Theme.fgDim
                                }

                                MouseArea {
                                    id: dismissMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dismissEvent(index)
                                }
                            }
                        }

                        // Expanded event details row
                        Row {
                            width: parent.width
                            visible: root.expandedIndex === index
                            spacing: 8

                            Text {
                                text: "location_on"
                                font.family: Theme.fontIcons
                                font.pixelSize: 12
                                color: root.accentColor
                            }

                            Text {
                                text: modelData.location || "Default Calendar"
                                font.family: Theme.fontUi
                                font.pixelSize: 10
                                color: Theme.fgDim
                                elide: Text.ElideRight
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: "OPEN IN CALENDAR"
                                font.family: Theme.fontUi
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.0
                                color: openCalTextMa.containsMouse ? Theme.fg : root.accentColor

                                MouseArea {
                                    id: openCalTextMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchCalendar()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
