pragma Singleton

import QtQuick

QtObject {
    id: root

    // Nothing OS Color Palette
    readonly property color bg: "#050505"
    readonly property color surface: "#0F0F0F"
    readonly property color surfaceAlt: "#171717"
    readonly property color surfaceHigh: "#222222"
    readonly property color outline: "#2A2A2A"
    readonly property color outlineFaint: "#1A1A1A"

    readonly property color fg: "#FFFFFF"
    readonly property color fgDim: "#888888"
    readonly property color fgFaint: "#444444"

    readonly property color accent: "#4DA3FF" // Nothing / Gemini Electric Blue
    readonly property color alert: "#D71921"  // Nothing Red

    // Typography Fonts
    readonly property FontLoader fontUiLoader: FontLoader {
        source: Qt.resolvedUrl("../fonts/SpaceGrotesk.ttf")
    }
    readonly property FontLoader fontDotsLoader: FontLoader {
        source: Qt.resolvedUrl("../fonts/ndot-47-inspired-by-nothing.otf")
    }
    readonly property FontLoader fontIconsLoader: FontLoader {
        source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf")
    }

    readonly property string fontUi: fontUiLoader.name || "Space Grotesk"
    readonly property string fontDots: fontDotsLoader.name || "NDot 47"
    readonly property string fontIcons: fontIconsLoader.name || "Material Symbols Rounded"

    // Material Symbol Glyph Constants
    readonly property string iconPlay: "play_arrow"
    readonly property string iconPause: "pause"
    readonly property string iconSkipNext: "skip_next"
    readonly property string iconSkipPrev: "skip_previous"
    readonly property string iconCpu: "memory"
    readonly property string iconRam: "storage"
    readonly property string iconBattery: "battery_full"
    readonly property string iconBatteryCharging: "battery_charging_full"
    readonly property string iconGpu: "developer_board"
    readonly property string iconCalendar: "calendar_today"
    readonly property string iconNotes: "edit_note"
    readonly property string iconSparkle: "auto_awesome"
    readonly property string iconClose: "close"

    // Component Dimensions
    readonly property int radiusSm: 8
    readonly property int radiusMd: 16
    readonly property int radiusLg: 24

    readonly property int durShort: 180
    readonly property int durMedium: 280
}
