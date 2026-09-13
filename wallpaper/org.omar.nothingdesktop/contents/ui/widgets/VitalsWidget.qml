import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent

    implicitWidth: 340
    implicitHeight: showGraph ? 290 : 220

    Behavior on implicitHeight { NumberAnimation { duration: Theme.durMedium } }

    // Vitals Data Properties
    property int cpuVal: 0
    property int ramVal: 0
    property string ramText: ""
    property int batVal: 100
    property bool batCharging: false
    property int gpuTempVal: 0
    property string gpuVendor: "GPU"
    property bool gpuAvailable: false

    property var _prevCpu: null
    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var ramHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool showGraph: false
    property string activeMetric: "CPU" // "CPU" or "RAM"

    readonly property string vitalsCmd: "head -1 /proc/stat; head -3 /proc/meminfo; which nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || true; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); [ \"$n\" = \"amdgpu\" ] && { cat $h/temp2_input 2>/dev/null || cat $h/temp1_input 2>/dev/null; } && break; done"

    function launchSystemMonitor() {
        execSource.connectSource("which plasma-systemmonitor >/dev/null 2>&1 && plasma-systemmonitor & || { which ksysguard >/dev/null 2>&1 && ksysguard & || xterm -e htop &; }");
    }

    function launchPowerSettings() {
        execSource.connectSource("kcmshell6 kcm_powerdevilprofilesconfig & || kcmshell6 kcm_energyinfo &");
    }

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd.startsWith("which") || cmd.startsWith("kcmshell6")) return;
            const out = (data["stdout"] ?? "").trim();
            if (!out) return;

            const lines = out.split("\n");
            // Parse CPU
            if (lines.length > 0 && lines[0].startsWith("cpu ")) {
                const parts = lines[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = parts[3] + (parts[4] || 0);
                const total = parts.reduce((a, b) => a + b, 0);

                if (root._prevCpu) {
                    const diffTotal = total - root._prevCpu.total;
                    const diffIdle = idle - root._prevCpu.idle;
                    if (diffTotal > 0) {
                        const newCpu = Math.max(0, Math.min(100, Math.round(((diffTotal - diffIdle) / diffTotal) * 100)));
                        root.cpuVal = newCpu;
                        var hist = root.cpuHistory.slice(1);
                        hist.push(newCpu);
                        root.cpuHistory = hist;
                        if (root.showGraph) sparkCanvas.requestPaint();
                    }
                }
                root._prevCpu = { total: total, idle: idle };
            }

            // Parse RAM
            if (lines.length >= 3) {
                let totalKb = 0, availKb = 0;
                for (let i = 1; i <= 3; i++) {
                    const l = lines[i] || "";
                    if (l.startsWith("MemTotal:")) totalKb = parseInt(l.replace(/\D/g, ""), 10);
                    if (l.startsWith("MemAvailable:")) availKb = parseInt(l.replace(/\D/g, ""), 10);
                }
                if (totalKb > 0) {
                    const usedKb = totalKb - availKb;
                    const newRam = Math.round((usedKb / totalKb) * 100);
                    root.ramVal = newRam;
                    root.ramText = (usedKb / 1048576).toFixed(1) + "G";
                    var rHist = root.ramHistory.slice(1);
                    rHist.push(newRam);
                    root.ramHistory = rHist;
                    if (root.showGraph) sparkCanvas.requestPaint();
                }
            }

            // Parse GPU
            if (lines.length >= 4) {
                for (let j = 3; j < lines.length; j++) {
                    const val = parseInt(lines[j].trim(), 10);
                    if (!isNaN(val) && val > 0) {
                        root.gpuAvailable = true;
                        root.gpuTempVal = val > 150 ? Math.round(val / 1000) : val;
                        root.gpuVendor = (j === 3 && lines[j].length <= 3) ? "NVIDIA" : "AMD";
                        break;
                    }
                }
            }
        }
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }

    readonly property var batData: pmSource.data["Battery"] ?? ({})
    onBatDataChanged: {
        root.batVal = batData["Percent"] ?? 100;
        root.batCharging = (batData["State"] ?? "") === "Charging";
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: execSource.connectSource(root.vitalsCmd)
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

            // Header with System Monitor Launcher
            Row {
                width: parent.width
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iconCpu
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: root.accentColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SYSTEM VITALS"
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Theme.fgDim
                }

                Item { width: 1; height: 1 }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    
                    width: 26
                    height: 26
                    radius: 13
                    color: sysMonMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "insights"
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: sysMonMa.containsMouse ? Theme.fg : Theme.fgDim
                    }

                    MouseArea {
                        id: sysMonMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchSystemMonitor()
                    }
                }
            }

            // Vitals Grid (2x2)
            Grid {
                width: parent.width
                columns: 2
                spacing: 10

                // CPU Card (Click to toggle graph or double click for system monitor)
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 60
                    radius: Theme.radiusMd
                    color: cpuMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: root.showGraph && root.activeMetric === "CPU" ? root.accentColor : Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "CPU LOAD"
                            font.family: Theme.fontUi
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: Theme.fgFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.cpuVal + "%"
                            font.family: Theme.fontDots
                            font.pixelSize: 20
                            color: root.cpuVal > 80 ? Theme.alert : Theme.fg
                        }
                    }

                    MouseArea {
                        id: cpuMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                root.launchSystemMonitor();
                            } else {
                                if (root.showGraph && root.activeMetric === "CPU") {
                                    root.showGraph = false;
                                } else {
                                    root.activeMetric = "CPU";
                                    root.showGraph = true;
                                    sparkCanvas.requestPaint();
                                }
                            }
                        }
                        onDoubleClicked: root.launchSystemMonitor()
                    }
                }

                // RAM Card (Click to toggle graph or right click for system monitor)
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 60
                    radius: Theme.radiusMd
                    color: ramMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: root.showGraph && root.activeMetric === "RAM" ? root.accentColor : Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "RAM " + root.ramText
                            font.family: Theme.fontUi
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: Theme.fgFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.ramVal + "%"
                            font.family: Theme.fontDots
                            font.pixelSize: 20
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        id: ramMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                root.launchSystemMonitor();
                            } else {
                                if (root.showGraph && root.activeMetric === "RAM") {
                                    root.showGraph = false;
                                } else {
                                    root.activeMetric = "RAM";
                                    root.showGraph = true;
                                    sparkCanvas.requestPaint();
                                }
                            }
                        }
                        onDoubleClicked: root.launchSystemMonitor()
                    }
                }

                // BATTERY Card (Click to open KDE Power settings)
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 60
                    radius: Theme.radiusMd
                    color: batMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.batCharging ? "CHARGING" : "BATTERY"
                            font.family: Theme.fontUi
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: root.batCharging ? root.accentColor : Theme.fgFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.batVal + "%"
                            font.family: Theme.fontDots
                            font.pixelSize: 20
                            color: root.batVal < 20 ? Theme.alert : Theme.fg
                        }
                    }

                    MouseArea {
                        id: batMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchPowerSettings()
                    }
                }

                // GPU Card
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 60
                    radius: Theme.radiusMd
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gpuAvailable ? root.gpuVendor + " TEMP" : "GPU TEMP"
                            font.family: Theme.fontUi
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: Theme.fgFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gpuAvailable ? (root.gpuTempVal + "°C") : "—"
                            font.family: Theme.fontDots
                            font.pixelSize: 20
                            color: root.gpuTempVal > 82 ? Theme.alert : Theme.fg
                        }
                    }
                }
            }

            // Live 60s Sparkline Graph Section (Expands on click)
            Rectangle {
                width: parent.width
                height: 65
                visible: root.showGraph
                radius: Theme.radiusMd
                color: Theme.surfaceAlt
                border.color: Theme.outlineFaint
                border.width: 1
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Row {
                        width: parent.width
                        spacing: 6
                        Text {
                            text: root.activeMetric + " HISTORY (LAST 30S)"
                            font.family: Theme.fontUi
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                            color: Theme.fgDim
                        }
                        Item { width: 1; height: 1 }
                        Text {
                            
                            text: (root.activeMetric === "CPU" ? root.cpuVal : root.ramVal) + "% CURRENT"
                            font.family: Theme.fontDots
                            font.pixelSize: 9
                            color: root.accentColor
                        }
                    }

                    Canvas {
                        id: sparkCanvas
                        width: parent.width
                        height: 44

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var data = root.activeMetric === "CPU" ? root.cpuHistory : root.ramHistory;
                            if (!data || data.length < 2) return;

                            var step = width / (data.length - 1);
                            ctx.beginPath();
                            ctx.moveTo(0, height - (data[0] / 100) * height);
                            for (var i = 1; i < data.length; i++) {
                                var x = i * step;
                                var y = height - (data[i] / 100) * height;
                                ctx.lineTo(x, y);
                            }

                            ctx.strokeStyle = root.accentColor;
                            ctx.lineWidth = 2;
                            ctx.stroke();

                            // Fill gradient under curve
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15);
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }
}
