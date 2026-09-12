pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

// Control de refrigeración y perfiles de ventilador de HP Victus / Omen
QtObject {
    id: root

    // "balanced" | "performance" | "low-power"
    property string profile: "balanced"

    readonly property string profileName: {
        if (profile === "performance") return Cfg.t("TURBO");
        if (profile === "low-power")   return Cfg.t("QUIET");
        return Cfg.t("BALANCED");
    }

    readonly property string profileDesc: {
        if (profile === "performance") return Cfg.t("MAX FANS");
        if (profile === "low-power")   return Cfg.t("SILENT");
        return Cfg.t("AUTO SPEED");
    }

    readonly property bool isTurbo: profile === "performance"
    readonly property bool isQuiet: profile === "low-power"
    readonly property bool isBalanced: profile === "balanced"

    readonly property color accent: {
        if (isTurbo)    return Theme.alert;
        if (isQuiet)    return Theme.secondary;
        return Theme.primary;
    }

    readonly property string readCmd: "cat /sys/firmware/acpi/platform_profile 2>/dev/null"

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd === root.readCmd) {
                const out = (data["stdout"] ?? "").trim();
                if (out === "performance" || out === "balanced" || out === "low-power") {
                    root.profile = out;
                }
            }
        }
    }

    function setProfile(mode) {
        root.profile = mode;
        const ppTarget = (mode === "low-power") ? "power-saver" : mode;
        const cmd = `if command -v powerprofilesctl >/dev/null 2>&1; then powerprofilesctl set ${ppTarget} 2>/dev/null || true; fi; echo ${mode} > /sys/firmware/acpi/platform_profile 2>/dev/null || true`;
        Exec.run(cmd);
        verifyTimer.restart();
    }

    function cycleProfile() {
        if (root.profile === "balanced")
            root.setProfile("performance");
        else if (root.profile === "performance")
            root.setProfile("low-power");
        else
            root.setProfile("balanced");
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
