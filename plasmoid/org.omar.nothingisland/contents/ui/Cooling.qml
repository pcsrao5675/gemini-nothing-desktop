pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

// Cooling and HP Victus fan speed controller
QtObject {
    id: root

    // "balanced" | "performance" | "low-power"
    property string profile: "balanced"

    // Manual speed control (0 - 100%)
    property bool isManual: false
    property int manualSpeed: 80

    readonly property string profileName: {
        if (isManual) {
            if (manualSpeed >= 95) return "100% MAX";
            return manualSpeed + "%";
        }
        if (profile === "performance") return "TURBO";
        if (profile === "low-power")   return "QUIET";
        return "BALANCED";
    }

    readonly property string profileDesc: {
        if (isManual) return "MANUAL";
        if (profile === "performance") return "MAX FANS";
        if (profile === "low-power")   return "SILENT";
        return "AUTO";
    }

    readonly property bool isTurbo: !isManual && profile === "performance"
    readonly property bool isQuiet: !isManual && profile === "low-power"
    readonly property bool isBalanced: !isManual && profile === "balanced"

    readonly property color accent: {
        if (isManual) {
            if (manualSpeed >= 85) return Theme.alert;
            if (manualSpeed <= 35) return Theme.secondary;
            return Theme.primary;
        }
        if (isTurbo) return Theme.alert;
        if (isQuiet) return Theme.secondary;
        return Theme.primary;
    }

    // Animation duration for rotating fan icon (ms per 360 deg)
    readonly property int animDuration: {
        if (isManual) {
            if (manualSpeed <= 5) return 0;
            return Math.max(250, Math.round(1500 - (manualSpeed * 12.5)));
        }
        if (isTurbo) return 650;
        if (isBalanced) return 1300;
        return 2200;
    }

    readonly property string readCmd: "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && cat \"$p\" 2>/dev/null; cat /sys/firmware/acpi/platform_profile 2>/dev/null"

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd === root.readCmd) {
                const lines = (data["stdout"] ?? "").trim().split("\n");
                if (lines.length >= 2) {
                    const pwmEnable = lines[0].trim();
                    const prof = lines[1].trim();
                    if (prof === "performance" || prof === "balanced" || prof === "low-power") {
                        root.profile = prof;
                    }
                    if (pwmEnable === "0" && !root.isManual) {
                        root.isManual = true;
                        root.manualSpeed = 100;
                    }
                } else if (lines.length === 1) {
                    const prof = lines[0].trim();
                    if (prof === "performance" || prof === "balanced" || prof === "low-power") {
                        root.profile = prof;
                    }
                }
            }
        }
    }

    function setProfile(mode) {
        root.isManual = false;
        root.profile = mode;
        const ppTarget = (mode === "low-power") ? "power-saver" : mode;
        const cmd = "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && { echo 2 > \"$p\" 2>/dev/null || pkexec /bin/sh -c \"echo 2 > '$p'\"; }; powerprofilesctl set " + ppTarget + " 2>/dev/null || true; echo " + mode + " > /sys/firmware/acpi/platform_profile 2>/dev/null || true";
        Exec.run(cmd);
        verifyTimer.restart();
    }

    function setManualSpeed(pct) {
        root.manualSpeed = Math.max(0, Math.min(100, Math.round(pct)));
        root.isManual = true;
        const pwmVal = Math.round(root.manualSpeed * 2.55);

        let cmd = "";
        if (root.manualSpeed >= 95) {
            // HP Hardware Max Boost: pwm1_enable = 0 forces full fan RPM blast
            cmd = "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && { echo 0 > \"$p\" 2>/dev/null || pkexec /bin/sh -c \"echo 0 > '$p' && echo 255 > '$(dirname $p)/pwm1'\"; echo 255 > \"$(dirname $p)/pwm1\" 2>/dev/null; }; powerprofilesctl set performance 2>/dev/null || true";
        } else {
            const ppTarget = root.manualSpeed <= 30 ? "power-saver" : (root.manualSpeed >= 70 ? "performance" : "balanced");
            cmd = "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && { echo 1 > \"$p\" 2>/dev/null || pkexec /bin/sh -c \"echo 1 > '$p' && echo " + pwmVal + " > '$(dirname $p)/pwm1'\"; echo " + pwmVal + " > \"$(dirname $p)/pwm1\" 2>/dev/null; }; powerprofilesctl set " + ppTarget + " 2>/dev/null || true";
        }
        Exec.run(cmd);
        verifyTimer.restart();
    }

    function cycleProfile() {
        if (!root.isManual) {
            if (root.profile === "balanced")
                root.setProfile("performance");
            else if (root.profile === "performance")
                root.setProfile("low-power");
            else
                root.setManualSpeed(100);
        } else {
            root.setProfile("balanced");
        }
    }

    readonly property Timer pollTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.source.connectSource(root.readCmd)
    }

    readonly property Timer verifyTimer: Timer {
        interval: 800
        repeat: false
        onTriggered: root.source.connectSource(root.readCmd)
    }
}
