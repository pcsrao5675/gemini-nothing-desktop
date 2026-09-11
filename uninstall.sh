#!/usr/bin/env bash
# ==============================================================================
# Universal Uninstaller: Gemini Floating Assistant & Nothing OS Island Suite
# Cleans up all components, systemd units, shortcuts, and KWin rules
# ==============================================================================
set -euo pipefail

# Dynamic XDG path definitions - zero static user home references
TARGET_HOME="${HOME:-$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f6)}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$TARGET_HOME/.config}"
BIN_DIR="${XDG_BIN_HOME:-$TARGET_HOME/.local/bin}"

PLASMOID_DEST="$XDG_DATA_HOME/plasma/plasmoids/org.omar.nothingisland"
ASSISTANT_DEST="$XDG_DATA_HOME/gemini-assistant"
TOGGLE_DEST="$BIN_DIR/gemini-toggle.sh"
DESKTOP_DEST="$XDG_DATA_HOME/applications/gemini-overlay.desktop"
SYSTEMD_USER_DIR="$XDG_CONFIG_HOME/systemd/user"
KWIN_RULES_FILE="$XDG_CONFIG_HOME/kwinrulesrc"

DRY_RUN=0

show_help() {
    cat << 'EOF'
Usage: ./uninstall.sh [Options]

Universal uninstaller for the Gemini Floating Assistant and Nothing OS Island suite.

Options:
  -n, --dry-run       Simulate uninstallation and print removal plan without mutating system
  -h, --help          Show this usage guidance and exit

Target Removal Items:
  - Plasma Applet:    $XDG_DATA_HOME/plasma/plasmoids/org.omar.nothingisland (nothingisland)
  - Assistant Core:   $XDG_DATA_HOME/gemini-assistant/ (gemini-assistant)
  - Toggle Launcher:  $HOME/.local/bin/gemini-toggle.sh (gemini-toggle)
  - Desktop Entry:    $XDG_DATA_HOME/applications/gemini-overlay.desktop
  - Systemd Services: $XDG_CONFIG_HOME/systemd/user/gemini-*.service
  - KWin 6 Rules:     Clean rules matching brave-gemini in $XDG_CONFIG_HOME/kwinrulesrc
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
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

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "=== Gemini Floating Assistant & Nothing OS Island Suite Uninstaller ==="
    echo "Mode: DRY RUN (Simulation Only - No system mutations will be made)"
    echo ""
    echo "Planned Removals:"
    echo "  [1] Plasma Applet:    $PLASMOID_DEST (nothingisland)"
    echo "  [2] Assistant Suite:  $ASSISTANT_DEST (gemini-assistant)"
    echo "  [3] Binary Launcher:  $TOGGLE_DEST (gemini-toggle)"
    echo "  [4] Desktop Entry:    $DESKTOP_DEST"
    echo "  [5] Systemd Units:    $SYSTEMD_USER_DIR/gemini-screenshot.service"
    echo "                        $SYSTEMD_USER_DIR/gemini-assistant.service"
    echo "  [6] KWin Window Rule: Remove brave-gemini rules from $KWIN_RULES_FILE"
    echo ""
    echo "Planned Service and Desktop Actions:"
    echo "  [Systemd Services]    systemctl --user disable --now gemini-screenshot.service"
    echo "                        systemctl --user disable --now gemini-assistant.service"
    echo "  [KWin DBus Reload]    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure"
    echo "  [System Sycoca]       kbuildsycoca6 --noincremental"
    echo ""
    echo "Uninstaller dry-run completed successfully. No files removed."
    exit 0
fi

echo "=== Uninstalling Gemini Floating Assistant & Nothing OS Island Suite ==="

# 1. Stop and disable systemd services
if command -v systemctl >/dev/null 2>&1; then
    echo "-> Stopping and disabling user systemd services..."
    systemctl --user stop gemini-screenshot.service 2>/dev/null || true
    systemctl --user disable gemini-screenshot.service 2>/dev/null || true
    systemctl --user stop gemini-assistant.service 2>/dev/null || true
    systemctl --user disable gemini-assistant.service 2>/dev/null || true
    systemctl --user daemon-reload 2>/dev/null || true
fi

# 2. Remove files and directories
echo "-> Removing installed files..."
if [[ -d "$PLASMOID_DEST" ]]; then
    rm -rf "$PLASMOID_DEST"
    echo "   Removed: $PLASMOID_DEST (nothingisland)"
fi

if [[ -d "$ASSISTANT_DEST" ]]; then
    rm -rf "$ASSISTANT_DEST"
    echo "   Removed: $ASSISTANT_DEST (gemini-assistant)"
fi

if [[ -f "$TOGGLE_DEST" ]]; then
    rm -f "$TOGGLE_DEST"
    echo "   Removed: $TOGGLE_DEST (gemini-toggle)"
fi

if [[ -f "$DESKTOP_DEST" ]]; then
    rm -f "$DESKTOP_DEST"
    echo "   Removed: $DESKTOP_DEST"
fi

rm -f "$SYSTEMD_USER_DIR/gemini-screenshot.service"
rm -f "$SYSTEMD_USER_DIR/gemini-assistant.service"

# 3. Clean KWin 6 rules
if [[ -f "$KWIN_RULES_FILE" ]]; then
    echo "-> Cleaning KWin window rules in $KWIN_RULES_FILE..."
    python3 - "$KWIN_RULES_FILE" << 'PYEOF'
import configparser
import sys
import os

kwinrules_file = sys.argv[1]
if not os.path.exists(kwinrules_file):
    sys.exit(0)

config = configparser.RawConfigParser(strict=False)
try:
    config.read(kwinrules_file)
except Exception as e:
    print(f"Warning: Could not read kwinrulesrc: {e}", file=sys.stderr)
    sys.exit(0)

removed_any = False
for s in list(config.sections()):
    if s == "General":
        continue
    is_target = False
    if config.has_option(s, "wmclass") and config.get(s, "wmclass") == "brave-gemini.google.com__app-Default":
        is_target = True
    if config.has_option(s, "description") and config.get(s, "description") == "Gemini Floating Assistant Overlay":
        is_target = True
    if is_target:
        config.remove_section(s)
        removed_any = True

if removed_any:
    rule_ids = [s for s in config.sections() if s != "General"]
    if config.has_section("General"):
        config.set("General", "count", str(len(rule_ids)))
        config.set("General", "rules", ",".join(rule_ids))
    with open(kwinrules_file, "w") as f:
        config.write(f)
PYEOF

    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
fi

# 4. Clean shortcut configuration and rebuild sycoca
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    echo "-> Rebuilding KDE sycoca cache..."
    kbuildsycoca6 --noincremental 2>/dev/null || true
fi

echo "=== Uninstallation Completed Successfully! ==="
