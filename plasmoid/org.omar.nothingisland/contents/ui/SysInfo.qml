pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// mismos datos que quickshell, de /proc, amdgpu sysfs y nvidia-smi
QtObject {
    id: root

    property int cpu: 0
    property int cpuTemp: 0
    property int mem: 0
    property string memText: "0G / 0G"
    property string memShort: "0/0"

    // NVIDIA dGPU
    property int gpu: 0
    property int gpuTemp: 0
    property bool gpuAvailable: false

    // AMD iGPU
    property int amdGpu: 0
    property int amdGpuTemp: 0
    property bool amdGpuAvailable: false

    // which GPU is currently doing real work (for the label)
    // "AMD" | "NVIDIA" | "—"
    readonly property string activeGpuLabel: {
        if (gpuAvailable && gpu > 2)   return "NVIDIA";
        if (amdGpuAvailable)           return "AMD";
        return "—";
    }

    property var _prev: null

    // cpu + ram + cpu-temp
    readonly property string cpuCmd: 'head -1 /proc/stat; head -3 /proc/meminfo; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); case $n in k10temp|coretemp|zenpower) cat $h/temp1_input 2>/dev/null; break;; esac; done'

    // NVIDIA: utilisation + temp
    readonly property string gpuCmd: "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits"

    // AMD iGPU: busy% from sysfs (card2 = 0x1002 AMD), temp from hwmon4=amdgpu
    readonly property string amdCmd: 'f=""; for d in /sys/class/drm/card0 /sys/class/drm/card1 /sys/class/drm/card2 /sys/class/drm/card3; do [ -f "$d/device/vendor" ] && v=$(cat $d/device/vendor 2>/dev/null) && [ "$v" = "0x1002" ] && f="$d/device/gpu_busy_percent" && break; done; [ -n "$f" ] && cat "$f" 2>/dev/null || echo "0"; for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); [ "$n" = "amdgpu" ] && { cat $h/temp2_input 2>/dev/null || cat $h/temp1_input 2>/dev/null; } && break; done'


    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = data["stdout"] ?? "";
            if (cmd === root.cpuCmd)
                root.readCpu(out);
            else if (cmd === root.gpuCmd)
                root.readGpu(out, data["exit code"] ?? 0);
            else if (cmd === root.amdCmd)
                root.readAmd(out);
        }
    }

    function readCpu(text) {
        const lines = text.trim().split("\n");
        if (lines.length < 4) return;

        const c = lines[0].split(/\s+/).slice(1).map(Number);
        const idle  = c[3] + c[4];
        const total = c.reduce((a, b) => a + b, 0);

        if (root._prev) {
            const dTotal = total - root._prev.total;
            const dIdle  = idle  - root._prev.idle;
            if (dTotal > 0)
                root.cpu = Math.round(100 * (dTotal - dIdle) / dTotal);
        }
        root._prev = { total, idle };

        const kb      = l => Number(l.split(/\s+/)[1]);
        const totalKb = kb(lines[1]);
        const availKb = kb(lines[3]);
        root.mem      = Math.round(100 * (totalKb - availKb) / totalKb);
        const gb      = v => (v / 1048576).toFixed(1);
        root.memText  = gb(totalKb - availKb) + "G / " + gb(totalKb) + "G";
        root.memShort = gb(totalKb - availKb) + "/" + Math.round(totalKb / 1048576);

        if (lines.length >= 5) {
            const t = Number(lines[4]);
            if (!isNaN(t)) root.cpuTemp = Math.round(t / 1000);
        }
    }

    function readGpu(text, code) {
        const parts = text.trim().split(",");
        if (code !== 0 || parts.length < 2) { root.gpuAvailable = false; return; }
        const u = Number(parts[0].trim());
        const t = Number(parts[1].trim());
        if (isNaN(u) || isNaN(t)) { root.gpuAvailable = false; return; }
        root.gpu          = u;
        root.gpuTemp      = t;
        root.gpuAvailable = true;
    }

    function readAmd(text) {
        const lines = text.trim().split("\n");
        if (lines.length < 1) { root.amdGpuAvailable = false; return; }
        const u = Number(lines[0].trim());
        if (isNaN(u)) { root.amdGpuAvailable = false; return; }
        root.amdGpu          = u;
        root.amdGpuAvailable = true;
        if (lines.length >= 2) {
            const t = Number(lines[1].trim());
            if (!isNaN(t)) root.amdGpuTemp = Math.round(t / 1000);
        }
    }

    readonly property Timer tick: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.source.connectSource(root.cpuCmd);
            root.source.connectSource(root.gpuCmd);
            root.source.connectSource(root.amdCmd);
        }
    }
}
