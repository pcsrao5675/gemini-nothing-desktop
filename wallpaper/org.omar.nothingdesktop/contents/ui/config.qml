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

    // Clock Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Clock Widget" }

    QQC2.CheckBox {
        id: showClockCheckBox
        Kirigami.FormData.label: "Enable Clock:"
        text: "Show large dot-matrix digital clock"
    }

    QQC2.CheckBox {
        id: clock24CheckBox
        Kirigami.FormData.label: "24-Hour Format:"
        text: "Use 24-hour time notation"
    }

    QQC2.ComboBox {
        id: clockPosCombo
        Kirigami.FormData.label: "Clock Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_clockPosition)
        onActivated: root.cfg_clockPosition = model[currentIndex]
    }

    // Vitals Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "System Vitals Widget" }

    QQC2.CheckBox {
        id: showVitalsCheckBox
        Kirigami.FormData.label: "Enable Vitals:"
        text: "Display CPU, RAM, Battery, and GPU monitors"
    }

    QQC2.ComboBox {
        id: vitalsPosCombo
        Kirigami.FormData.label: "Vitals Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_vitalsPosition)
        onActivated: root.cfg_vitalsPosition = model[currentIndex]
    }

    // Media Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "MPRIS Media Widget" }

    QQC2.CheckBox {
        id: showMediaCheckBox
        Kirigami.FormData.label: "Enable Media Player:"
        text: "Display interactive MPRIS now-playing card"
    }

    QQC2.ComboBox {
        id: mediaPosCombo
        Kirigami.FormData.label: "Media Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_mediaPosition)
        onActivated: root.cfg_mediaPosition = model[currentIndex]
    }

    // Agenda Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Agenda Widget" }

    QQC2.CheckBox {
        id: showAgendaCheckBox
        Kirigami.FormData.label: "Enable Agenda:"
        text: "Show upcoming schedule and events"
    }

    QQC2.TextField {
        id: icsPathField
        Kirigami.FormData.label: "Calendar .ICS File Path:"
        placeholderText: "/path/to/calendar.ics"
    }

    QQC2.ComboBox {
        id: agendaPosCombo
        Kirigami.FormData.label: "Agenda Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_agendaPosition)
        onActivated: root.cfg_agendaPosition = model[currentIndex]
    }

    // Quick Notes Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Quick Notes Scratchpad" }

    QQC2.CheckBox {
        id: showNotesCheckBox
        Kirigami.FormData.label: "Enable Notes:"
        text: "Display editable desktop quick notes card"
    }

    QQC2.ComboBox {
        id: notesPosCombo
        Kirigami.FormData.label: "Notes Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_notesPosition)
        onActivated: root.cfg_notesPosition = model[currentIndex]
    }

    // Assistant Wave Section
    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Assistant Wave Indicator" }

    QQC2.CheckBox {
        id: showWaveCheckBox
        Kirigami.FormData.label: "Enable Assistant Wave:"
        text: "Show reactive 40 FPS sinusoidal wave indicator"
    }

    QQC2.ComboBox {
        id: wavePosCombo
        Kirigami.FormData.label: "Wave Placement:"
        model: ["TopLeft", "TopCenter", "TopRight", "Center", "BottomLeft", "BottomCenter", "BottomRight"]
        Component.onCompleted: currentIndex = model.indexOf(root.cfg_wavePosition)
        onActivated: root.cfg_wavePosition = model[currentIndex]
    }
}
