pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

// Control de refrigeración, perfiles automáticos y control manual de ventiladores
QtObject {
    id: root

    // "balanced" | "performance" | "low-power"
    property string profile: "balanced"

    // Modo manual de velocidad
    property bool isManual: false
    property int manualSpeed: 80 // 0 a 100%

    readonly property string profileName: {
        if (isManual) {
            if (manualSpeed >= 95) return Cfg.t("MAX 100%");
            return manualSpeed + "%";
        }
        if (profile === "performance") return Cfg.t("TURBO");
        if (profile === "low-power")   return Cfg.t("QUIET");
        return Cfg.t("BALANCED");
    }

    readonly property string profileDesc: {
        if (isManual) return Cfg.t("MANUAL SPEED");
        if (profile === "performance") return Cfg.t("MAX FANS");
        if (profile === "low-power")   return Cfg.t("SILENT");
        return Cfg.t("AUTO SPEED");
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

    // Velocidad de animación del icono según el modo (ms por rotación)
    readonly property int animDuration: {
        if (isManual) {
            if (manualSpeed <= 10) return 0;
            return Math.max(300, Math.round(1600 - (manualSpeed * 13)));
        }
        if (isTurbo) return 700;
        if (isBalanced) return 1400;
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
                        // Max hardware fan boost active
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
        // Restore pwm1_enable = 2 (auto BIOS control) and set ACPI profile
        const cmd = `p=$(find /sys/devices/platform/hp-wmi/ -name "pwm1_enable" 2>/dev/null | head -1); [ -n "$p" ] && echo 2 > "$p" 2>/dev/null; if command -v powerprofilesctl >/dev/null 2>&1; then powerprofilesctl set ${ppTarget} 2>/dev/null || true; fi; echo ${mode} > /sys/firmware/acpi/platform_profile 2>/dev/null || true`;
        Exec.run(cmd);
        verifyTimer.restart();
    }

    function setManualSpeed(pct) {
        root.manualSpeed = Math.max(0, Math.min(100, Math.round(pct)));
        root.isManual = true;
        const pwmVal = Math.round(root.manualSpeed * 2.55);

        let cmd = "";
        if (root.manualSpeed >= 90) {
            // HP Hardware Max Boost: pwm1_enable = 0 forces full fan RPM
            cmd = `p=$(find /sys/devices/platform/hp-wmi/ -name "pwm1_enable" 2>/dev/null | head -1); [ -n "$p" ] && echo 0 > "$p" 2>/dev/null; p2=$(find /sys/devices/platform/hp-wmi/ -name "pwm1" 2>/dev/null | head -1); [ -n "$p2" ] && echo 255 > "$p2" 2>/dev/null; powerprofilesctl set performance 2>/dev/null || true`;
        } else if (root.manualSpeed <= 25) {
            // Low speed: power-saver + low PWM
            cmd = `p=$(find /sys/devices/platform/hp-wmi/ -name "pwm1_enable" 2>/dev/null | head -1); [ -n "$p" ] && echo 1 > "$p" 2>/dev/null; p2=$(find /sys/devices/platform/hp-wmi/ -name "pwm1" 2>/dev/null | head -1); [ -n "$p2" ] && echo ${pwmVal} > "$p2" 2>/dev/null; powerprofilesctl set power-saver 2>/dev/null || true`;
        } else {
            // Balanced / Custom PWM
            cmd = `p=$(find /sys/devices/platform/hp-wmi/ -name "pwm1_enable" 2>/dev/null | head -1); [ -n "$p" ] && echo 1 > "$p" 2>/dev/null; p2=$(find /sys/devices/platform/hp-wmi/ -name "pwm1" 2>/dev/null | head -1); [ -n "$p2" ] && echo ${pwmVal} > "$p2" 2>/dev/null; powerprofilesctl set balanced 2>/dev/null || true`;
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
                root.setManualSpeed(80); // Switch to manual preset
        } else {
            // From manual, go back to balanced auto
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
