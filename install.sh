#!/usr/bin/env bash
# ==============================================================================
# Universal Installer: Gemini Floating Assistant & Nothing OS Island Suite
# Compatible with KDE Plasma 6 (Wayland)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dynamic XDG path definitions - zero static user home references
TARGET_HOME="${HOME:-$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f6)}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}"
BIN_DIR="${XDG_BIN_HOME:-$TARGET_HOME/.local/bin}"

PLASMOID_DEST="$XDG_DATA_HOME/plasma/plasmoids/org.omar.nothingisland"
WALLPAPER_DEST="$XDG_DATA_HOME/plasma/wallpapers/org.omar.nothingdesktop"
ASSISTANT_DEST="$XDG_DATA_HOME/gemini-assistant"
EXTENSION_DEST="$ASSISTANT_DEST/extension"
TOGGLE_DEST="$BIN_DIR/gemini-toggle.sh"
DESKTOP_DEST="$XDG_DATA_HOME/applications/gemini-overlay.desktop"
SYSTEMD_USER_DIR="$XDG_CONFIG_HOME/systemd/user"
KWIN_RULES_FILE="$XDG_CONFIG_HOME/kwinrulesrc"

DRY_RUN=0
CHECK_MODE=0

show_help() {
    cat << 'EOF'
Usage: ./install.sh [Options]

Universal installer for the Gemini Floating Assistant and Nothing OS Island suite.

Options:
  -n, --dry-run       Simulate installation and print deployment plan without mutating system
  -c, --check         Verify system prerequisites, dependencies, and environment health
  -h, --help          Show this usage guidance and exit

Target Destinations:
  - Plasmoid:         $XDG_DATA_HOME/plasma/plasmoids/org.omar.nothingisland
  - Wallpaper Plugin: $XDG_DATA_HOME/plasma/wallpapers/org.omar.nothingdesktop
  - Assistant Core:   $XDG_DATA_HOME/gemini-assistant/
  - Toggle Launcher:  $HOME/.local/bin/gemini-toggle.sh
  - Desktop Entry:    $XDG_DATA_HOME/applications/gemini-overlay.desktop
  - Systemd Services: $XDG_CONFIG_HOME/systemd/user/
  - KWin 6 Rules:     $XDG_CONFIG_HOME/kwinrulesrc
EOF
}

run_check() {
    echo "=== Gemini Floating Assistant: Environment Health Check ==="
    local missing=0

    check_tool() {
        local name="$1"
        local cmd="$2"
        local req="$3"
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "  [OK] $name: $(command -v "$cmd")"
        else
            if [[ "$req" == "required" ]]; then
                echo "  [MISSING] $name ($cmd) - REQUIRED"
                missing=$((missing + 1))
            else
                echo "  [OPTIONAL] $name ($cmd) - Not found (optional)"
            fi
        fi
    }

    check_tool "Bash Shell" "bash" "required"
    check_tool "Python 3" "python3" "required"
    check_tool "KWin DBus Utility" "qdbus6" "optional"
    check_tool "KDE Package Tool" "kpackagetool6" "optional"
    check_tool "Spectacle Screenshot" "spectacle" "optional"
    check_tool "KDE Sycoca Rebuilder" "kbuildsycoca6" "optional"
    check_tool "KDE Config Tool" "kwriteconfig6" "optional"
    check_tool "Brave Browser" "brave" "optional"
    check_tool "Systemd User Manager" "systemctl" "optional"

    echo ""
    if [[ "$missing" -eq 0 ]]; then
        echo "Prerequisites check passed. System is ready for installation."
        return 0
    else
        echo "Prerequisites check failed: $missing required dependency missing."
        return 1
    fi
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -c|--check)
            CHECK_MODE=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

if [[ "$CHECK_MODE" -eq 1 ]]; then
    run_check
    exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "=== Gemini Floating Assistant & Nothing OS Island Suite Installer ==="
    echo "Mode: DRY RUN (Simulation Only - No system mutations will be made)"
    echo ""
    echo "Planned Target Deployments:"
    echo "  [1] Plasma Applet:    $PLASMOID_DEST"
    echo "  [2] Extension Assets: $EXTENSION_DEST"
    echo "  [3] Daemon Script:    $ASSISTANT_DEST/server.py"
    echo "  [4] Binary Launcher:  $TOGGLE_DEST"
    echo "  [5] Desktop Entry:    $DESKTOP_DEST"
    echo "  [6] Systemd Services: $SYSTEMD_USER_DIR/gemini-screenshot.service"
    echo "                        $SYSTEMD_USER_DIR/gemini-assistant.service"
    echo ""
    echo "Planned System Integrations:"
    echo "  [KWin 6 Rules]        Merge brave-gemini overlay rule into $KWIN_RULES_FILE"
    echo "  [KWin DBus Reload]    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure"
    echo "  [Global Shortcuts]    Configure Launch (2), Meta+Space via kwriteconfig6"
    echo "  [System Sycoca]       kbuildsycoca6 --noincremental"
    echo "  [Systemd Reload]      systemctl --user daemon-reload && systemctl --user enable gemini-screenshot.service"
    echo ""
    echo "Dry-run verification completed successfully. No filesystem or config mutations occurred."
    exit 0
fi

echo "=== Installing Gemini Floating Assistant & Nothing OS Island Suite ==="

# 1. Create target directories
mkdir -p "$PLASMOID_DEST"
mkdir -p "$EXTENSION_DEST"
mkdir -p "$BIN_DIR"
mkdir -p "$XDG_DATA_HOME/applications"
mkdir -p "$SYSTEMD_USER_DIR"
mkdir -p "$(dirname "$KWIN_RULES_FILE")"

# 2. Deploy Plasmoid
echo "-> Deploying Nothing OS Island plasmoid to $PLASMOID_DEST..."
cp -r "$SCRIPT_DIR/plasmoid/org.omar.nothingisland/"* "$PLASMOID_DEST/"

# 2b. Deploy Wallpaper Plugin
echo "-> Deploying Nothing OS Wallpaper plugin to $WALLPAPER_DEST..."
mkdir -p "$WALLPAPER_DEST"
cp -r "$SCRIPT_DIR/wallpaper/org.omar.nothingdesktop/"* "$WALLPAPER_DEST/"

# 3. Deploy Extension
echo "-> Deploying Brave Extension to $EXTENSION_DEST..."
cp -r "$SCRIPT_DIR/extension/"* "$EXTENSION_DEST/"

# 4. Deploy Daemon
echo "-> Deploying Daemon microservice to $ASSISTANT_DEST/server.py..."
cp "$SCRIPT_DIR/daemon/server.py" "$ASSISTANT_DEST/server.py"
chmod +x "$ASSISTANT_DEST/server.py"

# 4b. Deploy Notification Daemon
echo "-> Deploying Notification Daemon to $ASSISTANT_DEST/notifications/..."
mkdir -p "$ASSISTANT_DEST/notifications"
cp -r "$SCRIPT_DIR/daemon/notifications/"* "$ASSISTANT_DEST/notifications/"
chmod +x "$ASSISTANT_DEST/notifications/server.py"

# 5. Deploy Launchers & Tools
echo "-> Deploying launchers to $BIN_DIR..."
cp "$SCRIPT_DIR/bin/gemini-toggle.sh" "$TOGGLE_DEST"
chmod +x "$TOGGLE_DEST"

cp "$SCRIPT_DIR/bin/nothing-palette.sh" "$BIN_DIR/nothing-palette.sh"
chmod +x "$BIN_DIR/nothing-palette.sh"

cp "$SCRIPT_DIR/bin/nothing-settings.sh" "$BIN_DIR/nothing-settings.sh"
chmod +x "$BIN_DIR/nothing-settings.sh"

mkdir -p "$ASSISTANT_DEST/palette" "$ASSISTANT_DEST/settings"
cp -r "$SCRIPT_DIR/palette/"* "$ASSISTANT_DEST/palette/"
cp -r "$SCRIPT_DIR/settings/"* "$ASSISTANT_DEST/settings/"

# 6. Deploy Desktop Entry
echo "-> Deploying desktop entry to $DESKTOP_DEST..."
cp "$SCRIPT_DIR/desktop/gemini-overlay.desktop" "$DESKTOP_DEST"

# 7. Deploy Systemd User Units
echo "-> Deploying systemd services to $SYSTEMD_USER_DIR..."
cp "$SCRIPT_DIR/daemon/systemd/gemini-screenshot.service" "$SYSTEMD_USER_DIR/gemini-screenshot.service"
cp "$SCRIPT_DIR/daemon/systemd/gemini-assistant.service" "$SYSTEMD_USER_DIR/gemini-assistant.service"
cp "$SCRIPT_DIR/daemon/systemd/gemini-notifications.service" "$SYSTEMD_USER_DIR/gemini-notifications.service"

# 8. Merge KWin 6 Window Rules idempotently
echo "-> Configuring KWin 6 window rules in $KWIN_RULES_FILE..."
python3 - "$KWIN_RULES_FILE" << 'PYEOF'
import configparser
import sys
import os

kwinrules_file = sys.argv[1]
os.makedirs(os.path.dirname(os.path.abspath(kwinrules_file)), exist_ok=True)
config = configparser.RawConfigParser(strict=False)
if os.path.exists(kwinrules_file):
    try:
        config.read(kwinrules_file)
    except Exception as e:
        print(f"Warning: Could not parse existing kwinrulesrc: {e}", file=sys.stderr)

rule_section = None
for s in config.sections():
    if s == "General":
        continue
    if config.has_option(s, "wmclass") and config.get(s, "wmclass") == "brave-gemini.google.com__app-Default":
        rule_section = s
        break
    if config.has_option(s, "description") and config.get(s, "description") == "Gemini Floating Assistant Overlay":
        rule_section = s
        break

if not rule_section:
    idx = 1
    while config.has_section(str(idx)):
        idx += 1
    rule_section = str(idx)
    config.add_section(rule_section)

rule_data = {
    "description": "Gemini Floating Assistant Overlay",
    "above": "true",
    "aboverule": "3",
    "noborder": "true",
    "noborderrule": "3",
    "position": "1490,330",
    "positionrule": "3",
    "size": "410,710",
    "sizerule": "3",
    "skiptaskbar": "true",
    "skiptaskbarrule": "3",
    "skipswitcher": "true",
    "skipswitcherrule": "3",
    "wmclass": "brave-gemini.google.com__app-Default",
    "wmclassmatch": "1",
}
for k, v in rule_data.items():
    config.set(rule_section, k, v)

if not config.has_section("General"):
    config.add_section("General")

rule_ids = [s for s in config.sections() if s != "General"]
config.set("General", "count", str(len(rule_ids)))
config.set("General", "rules", ",".join(rule_ids))

with open(kwinrules_file, "w") as f:
    config.write(f)
PYEOF

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
fi

# 9. Register Global Shortcuts & Rebuild Sycoca
echo "-> Registering global shortcuts and updating KDE sycoca cache..."
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kglobalshortcutsrc --group "gemini-overlay.desktop" --key "_launch" "Launch (2)\tLaunch (1)\tLaunch (C)\tMeta+Space,Launch (2)\tLaunch (1)\tLaunch (C)\tMeta+Space,Gemini" 2>/dev/null || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental 2>/dev/null || true
fi

# 10. Configure Plasma Notification Suppression (Reversible)
echo "-> Configuring Plasma notification popup suppression (backed up to plasmanotifyrc.bak)..."
if command -v kwriteconfig6 >/dev/null 2>&1; then
    NOTIFY_RC="$XDG_CONFIG_HOME/plasmanotifyrc"
    if [[ -f "$NOTIFY_RC" ]] && [[ ! -f "$NOTIFY_RC.bak" ]]; then
        cp "$NOTIFY_RC" "$NOTIFY_RC.bak"
    fi
    # Inhibit Plasma popups cleanly so NothingNotificationDaemon handles all popups
    kwriteconfig6 --file plasmanotifyrc --group Notifications --key PopupPosition "None" 2>/dev/null || true
    kwriteconfig6 --file plasmanotifyrc --group Notifications --key PopupTimeout 0 2>/dev/null || true
fi

# 11. Reload and Enable Systemd Services
if command -v systemctl >/dev/null 2>&1; then
    echo "-> Reloading systemd user daemon and enabling services..."
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable gemini-screenshot.service 2>/dev/null || true
    systemctl --user enable --now gemini-notifications.service 2>/dev/null || true
fi

echo "=== Installation Completed Successfully! ==="
