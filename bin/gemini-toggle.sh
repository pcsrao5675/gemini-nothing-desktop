#!/usr/bin/env bash
# gemini-toggle.sh — toggle Gemini Assistant on KDE Plasma 6
APP_PROFILE="${XDG_DATA_HOME:-$HOME/.local/share}/gemini-assistant/brave-profile"
URL="https://gemini.google.com/app"
CLASS_NAME="gemini-floating-assistant"
EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gemini-assistant/extension"
ACTIVE_FILE="/tmp/gemini_active"

python3 - << 'PYEOF'
import os, sys, time, subprocess
import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib

ACTIVE_FILE = "/tmp/gemini_active"

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
loop = GLib.MainLoop()

actual_state = "0"

class Receiver(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.gemini.status', bus=bus)
        super().__init__(bus_name, '/Status')

    @dbus.service.method('org.gemini.status', in_signature='s')
    def set(self, val):
        global actual_state
        actual_state = val
        loop.quit()

rec = Receiver()

script = """
var wins = workspace.windowList();
var found = null;
for (var i = 0; i < wins.length; i++) {
    var w = wins[i];
    if (w.resourceClass && (w.resourceClass.indexOf("gemini.google.com") !== -1 || w.resourceClass === "gemini-floating-assistant")) {
        found = w;
        break;
    }
}
if (found) {
    if (found.minimized) {
        found.minimized = false;
        workspace.activeWindow = found;
        callDBus("org.gemini.status", "/Status", "org.gemini.status", "set", "1");
    } else {
        found.minimized = true;
        callDBus("org.gemini.status", "/Status", "org.gemini.status", "set", "0");
    }
} else {
    callDBus("org.gemini.status", "/Status", "org.gemini.status", "set", "0");
}
"""

with open("/tmp/gemini_kwin_toggle.js", "w") as f:
    f.write(script)

try:
    proc = subprocess.run(
        ["qdbus6", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting.loadScript", "/tmp/gemini_kwin_toggle.js", "gemini_toggle_act"],
        capture_output=True, text=True, timeout=1.0
    )
    run_id = proc.stdout.strip()
    if run_id and run_id != "-1":
        subprocess.run(["qdbus6", "org.kde.KWin", f"/Scripting/Script{run_id}", "org.kde.kwin.Script.run"], timeout=1.0)
        subprocess.run(["qdbus6", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting.unloadScript", "gemini_toggle_act"], timeout=1.0)
except Exception:
    pass

GLib.timeout_add_seconds(1, loop.quit)
loop.run()

with open(ACTIVE_FILE, "w") as f:
    f.write(actual_state)
PYEOF

# If Brave process is not running, launch it!
if ! pgrep -f "user-data-dir=$APP_PROFILE" > /dev/null 2>&1; then
    echo "1" > "$ACTIVE_FILE"
    BRAVE_BIN="$(command -v brave 2>/dev/null || command -v /opt/brave-bin/brave 2>/dev/null || command -v brave-browser 2>/dev/null || echo "brave")"
    "$BRAVE_BIN" \
          "--user-data-dir=$APP_PROFILE" \
          "--app=$URL" \
          "--class=$CLASS_NAME" \
          "--window-size=410,710" \
          "--window-position=1490,330" \
          "--load-extension=$EXT_DIR" \
          "--remote-debugging-port=9222" >/dev/null 2>&1 &
fi
