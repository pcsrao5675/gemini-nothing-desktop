import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent

    implicitWidth: 320
    implicitHeight: 220

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

    readonly property string vitalsCmd: "head -1 /proc/stat; head -3 /proc/meminfo; which nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || true; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); [ \"$n\" = \"amdgpu\" ] && { cat $h/temp2_input 2>/dev/null || cat $h/temp1_input 2>/dev/null; } && break; done"

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
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
                        root.cpuVal = Math.max(0, Math.min(100, Math.round(((diffTotal - diffIdle) / diffTotal) * 100)));
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
                    root.ramVal = Math.round((usedKb / totalKb) * 100);
                    root.ramText = (usedKb / 1048576).toFixed(1) + "G";
                }
            }

            // Parse GPU
            if (lines.length >= 4) {
                for (let j = 3; j < lines.length; j++) {
                    const val = parseInt(lines[j].trim(), 10);
                    if (!isNaN(val) && val > 0) {
                        root.gpuAvailable = true;
                        // Hwmon AMD temperatures are often in millidegrees (e.g. 45000)
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
            }

            // Vitals Grid (2x2)
            Grid {
                width: parent.width
                columns: 2
                spacing: 12

                // CPU
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 65
                    radius: Theme.radiusMd
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
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
                            font.pixelSize: 22
                            color: root.cpuVal > 80 ? Theme.alert : Theme.fg
                        }
                    }
                }

                // RAM
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 65
                    radius: Theme.radiusMd
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
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
                            font.pixelSize: 22
                            color: Theme.fg
                        }
                    }
                }

                // BATTERY
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 65
                    radius: Theme.radiusMd
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
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
                            font.pixelSize: 22
                            color: root.batVal < 20 ? Theme.alert : Theme.fg
                        }
                    }
                }

                // GPU
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: 65
                    radius: Theme.radiusMd
                    color: Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
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
                            font.pixelSize: 22
                            color: root.gpuTempVal > 82 ? Theme.alert : Theme.fg
                        }
                    }
                }
            }
        }
    }
}
