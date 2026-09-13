import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 180

    property string cityName: "LOCAL"
    property var forecastDays: [
        { day: "TODAY", temp: "28°C", cond: "wb_sunny", desc: "Clear" },
        { day: "TOM",   temp: "26°C", cond: "partly_cloudy_day", desc: "Partly Cloudy" },
        { day: "WED",   temp: "24°C", cond: "rainy", desc: "Showers" }
    ]

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (out) {
                try {
                    const lines = out.split("\n");
                    var items = [];
                    for (var i = 0; i < lines.length && i < 3; i++) {
                        var parts = lines[i].split("|");
                        if (parts.length >= 4) {
                            items.push({
                                day: parts[0],
                                temp: parts[1],
                                cond: parts[2],
                                desc: parts[3]
                            });
                        }
                    }
                    if (items.length > 0) root.forecastDays = items;
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            execSource.connectSource("python3 -c '\n" +
"import urllib.request, json\n" +
"try:\n" +
"    req = urllib.request.Request(\"https://wttr.in/?format=j1\", headers={\"User-Agent\": \"curl/7.68.0\"})\n" +
"    with urllib.request.urlopen(req, timeout=4) as response:\n" +
"        data = json.loads(response.read().decode())\n" +
"        weather = data.get(\"weather\", [])\n" +
"        days = [\"TODAY\", \"TOM\", \"NEXT\"]\n" +
"        for i, w in enumerate(weather[:3]):\n" +
"            day_name = days[i]\n" +
"            max_c = w.get(\"maxtempC\", \"--\")\n" +
"            min_c = w.get(\"mintempC\", \"--\")\n" +
"            desc = w.get(\"hourly\", [{}])[0].get(\"weatherDesc\", [{}])[0].get(\"value\", \"Clear\")\n" +
"            cond = \"wb_sunny\" if \"sun\" in desc.lower() or \"clear\" in desc.lower() else (\"rainy\" if \"rain\" in desc.lower() else \"cloud\")\n" +
"            print(f\"{day_name}|{min_c}°- {max_c}°C|{cond}|{desc}\")\n" +
"except Exception as e:\n" +
"    pass\n" +
"' || true");
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
                    text: Theme.iconWeather
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "3-DAY FORECAST"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // 3 Day Columns
            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.forecastDays
                    delegate: Rectangle {
                        width: (parent.width - 16) / 3
                        height: 95
                        radius: Theme.radiusMd
                        color: Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.6)
                        border.color: index === 0 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : Theme.outline
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: modelData.day
                                font.family: Theme.fontDots
                                font.pixelSize: 11
                                font.letterSpacing: 1
                                color: index === 0 ? root.accentColor : Theme.fgDim
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: modelData.cond === "wb_sunny" ? Theme.iconWeather : (modelData.cond === "rainy" ? "water_drop" : "cloud")
                                font.family: Theme.fontIcons
                                font.pixelSize: 22
                                color: index === 0 ? root.accentColor : Theme.fg
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: modelData.temp
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.fg
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: modelData.desc
                                font.family: Theme.fontUi
                                font.pixelSize: 9
                                color: Theme.fgDim
                                elide: Text.ElideRight
                                width: parent.parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                execSource.connectSource("which kweather >/dev/null 2>&1 && kweather & || xdg-open https://wttr.in &");
                            }
                        }
                    }
                }
            }
        }
    }
}
