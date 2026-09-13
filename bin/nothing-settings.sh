#!/usr/bin/env bash
# Nothing OS Unified Settings GUI Launcher
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML_FILE="$SCRIPT_DIR/settings/UnifiedSettings.qml"

if [[ ! -f "$QML_FILE" ]]; then
    QML_FILE="$HOME/.local/share/gemini-assistant/settings/UnifiedSettings.qml"
fi

if command -v qml6 >/dev/null 2>&1; then
    exec qml6 "$QML_FILE"
elif command -v qmlscene >/dev/null 2>&1; then
    exec qmlscene "$QML_FILE"
else
    echo "Error: Neither qml6 nor qmlscene found." >&2
    exit 1
fi
