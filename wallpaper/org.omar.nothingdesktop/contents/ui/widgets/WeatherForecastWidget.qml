import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 260
    implicitHeight: 38

    property string temp: "22°C"
    property string condIcon: "wb_sunny"
    property string condDesc: "CLEAR SKY"

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (out) {
                try {
                    const parts = out.split("|");
                    if (parts.length >= 3) {
                        root.temp = parts[0] + "°C";
                        root.condIcon = parts[1] || "wb_sunny";
                        root.condDesc = (parts[2] || "CLEAR").toUpperCase();
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1800000 // 30 mins
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
"        curr = data.get(\"current_condition\", [{}])[0]\n" +
"        temp_c = curr.get(\"temp_C\", \"22\")\n" +
"        desc = curr.get(\"weatherDesc\", [{}])[0].get(\"value\", \"Clear\")\n" +
"        desc_l = desc.lower()\n" +
"        icon = \"wb_sunny\"\n" +
"        if \"rain\" in desc_l or \"shower\" in desc_l: icon = \"rainy\"\n" +
"        elif \"snow\" in desc_l: icon = \"ac_unit\"\n" +
"        elif \"cloud\" in desc_l or \"overcast\" in desc_l: icon = \"partly_cloudy_day\"\n" +
"        elif \"thunder\" in desc_l: icon = \"thunderstorm\"\n" +
"        print(f\"{temp_c}|{icon}|{desc}\")\n" +
"except Exception:\n" +
"    print(\"22|wb_sunny|Clear Sky\")\n" +
"'");
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 19
        color: weatherMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.90) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        border.color: weatherMa.containsMouse ? root.accentColor : Theme.outline
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.condIcon
                font.family: Theme.fontIcons
                font.pixelSize: 16
                color: "#FFB95C"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.temp
                font.family: Theme.fontDots
                font.pixelSize: 13
                color: Theme.fg
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: 12
                color: Theme.outlineFaint
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.condDesc
                font.family: Theme.fontUi
                font.pixelSize: 10
                font.letterSpacing: 1.2
                color: Theme.fgDim
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: weatherMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                execSource.connectSource("which kweather >/dev/null 2>&1 && kweather & || xdg-open https://wttr.in &");
            }
        }
    }
}
