#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[+] Syncing Nothing Desktop Widgets applet..."
mkdir -p "$HOME/.local/share/plasma/plasmoids/org.omar.nothingdesktopwidgets"
cp -r "$REPO_ROOT/plasmoid/org.omar.nothingdesktopwidgets/"* "$HOME/.local/share/plasma/plasmoids/org.omar.nothingdesktopwidgets/"

echo "[+] Syncing Nothing Desktop Wallpaper plugin..."
mkdir -p "$HOME/.local/share/plasma/wallpapers/org.omar.nothingdesktop"
cp -r "$REPO_ROOT/wallpaper/org.omar.nothingdesktop/"* "$HOME/.local/share/plasma/wallpapers/org.omar.nothingdesktop/"

echo "[+] Placing Nothing Desktop Widgets applet on KDE desktop containment..."
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktopForScreen(0);
if (!d) {
    print('ERROR: No desktop containment found');
} else {
    var geom = screenGeometry(0);
    var found = false;
    var wIds = d.widgetIds || [];
    for (var i = 0; i < wIds.length; i++) {
        var w = d.widgetById(wIds[i]);
        if (w && w.type === 'org.omar.nothingdesktopwidgets') {
            found = true;
            w.geometry = QRectF(0, 0, geom.width, geom.height);
            w.userBackgroundHints = 0;
            print('Updated existing desktop widgets widget ID: ' + w.id);
            break;
        }
    }
    if (!found) {
        var nw = d.addWidget('org.omar.nothingdesktopwidgets');
        if (nw) {
            nw.geometry = QRectF(0, 0, geom.width, geom.height);
            nw.userBackgroundHints = 0;
            print('Successfully placed desktop widgets widget ID: ' + nw.id);
        } else {
            print('ERROR: Failed to add widget');
        }
    }
}
" || true
echo "[+] Ensuring full-screen desktop item geometries in plasma configuration..."
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$CONFIG_FILE" ]]; then
    sed -i -E 's/ItemGeometries-1920x1080=Applet-([0-9]+):[0-9]+,[0-9]+,[0-9]+,[0-9]+,0;/ItemGeometries-1920x1080=Applet-\1:0,0,1920,1044,0;/g' "$CONFIG_FILE"
    sed -i -E 's/ItemGeometriesHorizontal=Applet-([0-9]+):[0-9]+,[0-9]+,[0-9]+,[0-9]+,0;/ItemGeometriesHorizontal=Applet-\1:0,0,1920,1044,0;/g' "$CONFIG_FILE"
fi

echo "[+] Reloading plasmashell..."
systemctl --user restart plasma-plasmashell || true
echo "[✓] Nothing Desktop Widgets installed and interactive."
