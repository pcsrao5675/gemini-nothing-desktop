import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    id: root

    // Appearance Properties
    property alias cfg_backgroundColor: bgColorButton.color
    property alias cfg_accentColor: accentColorButton.color
    property alias cfg_showDotGrid: showDotGridCheckBox.checked
    property alias cfg_dotGridOpacity: dotGridOpacitySlider.value

    // Clock Properties
    property alias cfg_showClock: showClockCheckBox.checked
    property alias cfg_clock24: clock24CheckBox.checked
    property string cfg_clockPosition: "TopCenter"

    // Vitals Properties
    property alias cfg_showVitals: showVitalsCheckBox.checked
    property string cfg_vitalsPosition: "TopRight"

    // Media Properties
    property alias cfg_showMedia: showMediaCheckBox.checked
    property string cfg_mediaPosition: "BottomLeft"

    // Agenda Properties
    property alias cfg_showAgenda: showAgendaCheckBox.checked
    property string cfg_agendaPosition: "TopLeft"
    property alias cfg_icsFilePath: icsPathField.text

    // Notes Properties
    property alias cfg_showNotes: showNotesCheckBox.checked
    property string cfg_notesPosition: "BottomRight"

    // Wave Properties
    property alias cfg_showAssistantWave: showWaveCheckBox.checked
    property string cfg_wavePosition: "BottomCenter"

    // New Widgets Properties
    property alias cfg_showQuickToggles: showQuickTogglesCheckBox.checked
    property alias cfg_showPomodoro: showPomodoroCheckBox.checked
    property alias cfg_showWeatherForecast: showWeatherForecastCheckBox.checked
    property alias cfg_showScreenshots: showScreenshotsCheckBox.checked
    property alias cfg_showQuickLinks: showQuickLinksCheckBox.checked
    property alias cfg_showHabits: showHabitsCheckBox.checked
    property alias cfg_showQuickAsk: showQuickAskCheckBox.checked
    property alias cfg_showMonthCalendar: showMonthCalendarCheckBox.checked
    property alias cfg_showNetDisk: showNetDiskCheckBox.checked
    property alias cfg_showClipboard: showClipboardCheckBox.checked
    property alias cfg_showAmbientTile: showAmbientTileCheckBox.checked

    // Visual Styling Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Appearance & Themes" }

    KQuickControls.ColorButton {
        id: bgColorButton
        Kirigami.FormData.label: "Background Color:"
    }

    KQuickControls.ColorButton {
        id: accentColorButton
        Kirigami.FormData.label: "Accent Color (Electric Blue):"
    }

    QQC2.CheckBox {
        id: showDotGridCheckBox
        Kirigami.FormData.label: "Dot Matrix Grid:"
        text: "Render subtle dot matrix wallpaper grid"
    }

    QQC2.Slider {
        id: dotGridOpacitySlider
        Kirigami.FormData.label: "Grid Opacity:"
        from: 0.05
        to: 0.50
        stepSize: 0.05
    }

    // Core Widgets Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Core Desktop Widgets" }

    QQC2.CheckBox {
        id: showClockCheckBox
        Kirigami.FormData.label: "Clock:"
        text: "Large dot-matrix digital clock"
    }

    QQC2.CheckBox {
        id: clock24CheckBox
        Kirigami.FormData.label: "24-Hour Format:"
        text: "Use 24-hour time notation"
    }

    QQC2.CheckBox {
        id: showVitalsCheckBox
        Kirigami.FormData.label: "System Vitals:"
        text: "Display CPU, RAM, Battery, and GPU monitors"
    }

    QQC2.CheckBox {
        id: showMediaCheckBox
        Kirigami.FormData.label: "Media Player:"
        text: "Interactive MPRIS now-playing card"
    }

    QQC2.CheckBox {
        id: showAgendaCheckBox
        Kirigami.FormData.label: "Agenda & Schedule:"
        text: "Upcoming schedule and events list"
    }

    QQC2.TextField {
        id: icsPathField
        Kirigami.FormData.label: "Calendar .ICS Path:"
        placeholderText: "/path/to/calendar.ics"
    }

    QQC2.CheckBox {
        id: showNotesCheckBox
        Kirigami.FormData.label: "Quick Notes:"
        text: "Editable desktop scratchpad with persistent auto-saving"
    }

    QQC2.CheckBox {
        id: showWaveCheckBox
        Kirigami.FormData.label: "Assistant Wave:"
        text: "Reactive 40 FPS sinusoidal assistant wave indicator"
    }

    // Expanded Desktop Widgets Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Expanded Modular Widgets" }

    QQC2.CheckBox {
        id: showQuickTogglesCheckBox
        Kirigami.FormData.label: "Quick Toggles:"
        text: "Wi-Fi, Bluetooth, DND, and Night Light switches"
    }

    QQC2.CheckBox {
        id: showPomodoroCheckBox
        Kirigami.FormData.label: "Pomodoro Focus Timer:"
        text: "25/5 min focus timer with work/break modes"
    }

    QQC2.CheckBox {
        id: showWeatherForecastCheckBox
        Kirigami.FormData.label: "Weather Forecast:"
        text: "3-day forecast strip from wttr.in"
    }

    QQC2.CheckBox {
        id: showScreenshotsCheckBox
        Kirigami.FormData.label: "Recent Captures:"
        text: "Gallery of recent Spectacle screenshots"
    }

    QQC2.CheckBox {
        id: showQuickLinksCheckBox
        Kirigami.FormData.label: "Quick Launch:"
        text: "Desktop app shortcuts tile (Terminal, Browser, IDE)"
    }

    QQC2.CheckBox {
        id: showHabitsCheckBox
        Kirigami.FormData.label: "Habit Tracker:"
        text: "7-day weekly habit completion tracker"
    }

    QQC2.CheckBox {
        id: showQuickAskCheckBox
        Kirigami.FormData.label: "Gemini Quick Ask:"
        text: "Embedded single-line assistant prompt bar"
    }

    QQC2.CheckBox {
        id: showMonthCalendarCheckBox
        Kirigami.FormData.label: "Month Calendar:"
        text: "Dot-matrix monthly calendar view"
    }

    QQC2.CheckBox {
        id: showNetDiskCheckBox
        Kirigami.FormData.label: "Network & Disk:"
        text: "Real-time throughput and I/O sparkline"
    }

    QQC2.CheckBox {
        id: showClipboardCheckBox
        Kirigami.FormData.label: "Clipboard History:"
        text: "Recent clipboard snippets with click-to-copy"
    }

    QQC2.CheckBox {
        id: showAmbientTileCheckBox
        Kirigami.FormData.label: "Ambient Tile:"
        text: "Decorative Nothing OS dot-matrix art tile"
    }
}
