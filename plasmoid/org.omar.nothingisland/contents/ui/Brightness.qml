pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// brillo del panel interno via brightnessctl
// lee cada 3 s (igual que SysInfo); al arrastrar, "holding" bloquea las lecturas para no saltar
QtObject {
    id: root

    property int brightness: 50      // 0..100 porcentaje
    property bool available: false   // false hasta que llegue la primera lectura

    // arrastrando la barra no pisar con el sondeo
    property bool holding: false

    // — comandos —
    // brightnessctl info imprime "Current brightness: N (P%)" — extraemos el porcentaje
    readonly property string readCmd: "brightnessctl info"
    // set acepta "N%" directamente
    function writeCmd(pct: int): string {
        return "brightnessctl set " + Math.max(1, Math.min(100, pct)) + "%";
    }

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd === root.readCmd)
                root.parse(data["stdout"] ?? "");
        }
    }

    function parse(text: string): void {
        // "Current brightness: 5702 (8%)" → 8
        const m = text.match(/\((\d+)%\)/);
        if (!m)
            return;
        const v = Number(m[1]);
        if (!isNaN(v)) {
            root.available = true;
            if (!root.holding)
                root.brightness = v;
        }
    }

    function set(pct: int): void {
        const clamped = Math.max(1, Math.min(100, pct));
        root.brightness = clamped;
        root.holding = true;
        Exec.run(root.writeCmd(clamped));
        holdTimer.restart();
    }

    function step(delta: int): void {
        root.set(root.brightness + delta);
    }

    // soltar "holding" 600 ms después de la última escritura, para que el sondeo retome
    readonly property Timer holdTimer: Timer {
        interval: 600
        onTriggered: root.holding = false
    }

    readonly property Timer tick: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.source.connectSource(root.readCmd)
    }
}
