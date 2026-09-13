import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "widgets"
import "."

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    compactRepresentation: null

    // Sizing hints for desktop containment
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 1200
    Layout.minimumHeight: 700
    Layout.preferredWidth: 1920
    Layout.preferredHeight: 1044
    implicitWidth: 1920
    implicitHeight: 1044
    width: 1920
    height: 1044

    // Configuration Bindings
    readonly property color accentColor: Plasmoid.configuration.accentColor || "#4DA3FF"

    // Core Widgets
    readonly property bool showClock: Plasmoid.configuration.showClock ?? true
    readonly property bool clock24: Plasmoid.configuration.clock24 ?? true
    readonly property bool showVitals: Plasmoid.configuration.showVitals ?? true
    readonly property bool showNotes: Plasmoid.configuration.showNotes ?? true
    property string notesContent: Plasmoid.configuration.notesContent || ""
    readonly property bool showAssistantWave: Plasmoid.configuration.showAssistantWave ?? true

    // Expanded Modular Widgets
    readonly property bool showQuickToggles: Plasmoid.configuration.showQuickToggles ?? true
    readonly property bool showWeatherForecast: Plasmoid.configuration.showWeatherForecast ?? true
    readonly property bool showQuickLinks: Plasmoid.configuration.showQuickLinks ?? true
    readonly property bool showQuickAsk: Plasmoid.configuration.showQuickAsk ?? true
    readonly property bool showMonthCalendar: Plasmoid.configuration.showMonthCalendar ?? false

    // Signature Behavior: One-Click Focus Mode
    property bool focusModeActive: false

    fullRepresentation: Item {
        id: container
        anchors.fill: parent

        // ── 1. Glyph-Style Ambient Border Light (Screen Edge) ──
        GlyphBorderLight {
            id: glyphBorderLight
            accentColor: root.accentColor
            focusMode: root.focusModeActive
        }

        // ── Focus Mode Background Dimmer ──
        Rectangle {
            id: focusDimmer
            anchors.fill: parent
            color: "#000000"
            opacity: root.focusModeActive ? 0.35 : 0.0
            visible: opacity > 0.01
            enabled: false
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        }

        // Main 3-Column Widgets Grid (Anchored from top of desktop with comfortable margin)
        Item {
            id: gridContainer
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.left: parent.left
            anchors.leftMargin: 36
            anchors.right: parent.right
            anchors.rightMargin: 36
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: 20

            // LEFT COLUMN: System Vitals Telemetry + Quick Notes (Restrained, negative space)
            Column {
                id: leftCol
                anchors.left: parent.left
                anchors.top: parent.top
                width: 360
                spacing: 16

                VitalsWidget {
                    id: vitalsWidget
                    width: parent.width
                    visible: root.showVitals && !root.focusModeActive
                    opacity: visible ? 1.0 : 0.0
                    accentColor: root.accentColor
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                NotesWidget {
                    id: notesWidget
                    width: parent.width
                    visible: root.showNotes
                    accentColor: root.accentColor
                    notesText: root.notesContent
                    onNotesUpdated: (newTxt) => {
                        Plasmoid.configuration.notesContent = newTxt;
                    }
                }
            }

            // CENTER COLUMN: Big Clock Hero + AI Pills ("Claude" & "Gemini") + Compact Weather Chip
            Column {
                id: centerCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Math.max(300, parent.width - 760)
                spacing: 16

                ClockWidget {
                    id: clockWidget
                    width: parent.width
                    height: implicitHeight
                    visible: root.showClock
                    clock24: root.clock24
                    accentColor: root.accentColor
                }

                // AI Launchers (Claude & Gemini Pills)
                AiPillsWidget {
                    id: aiPills
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: implicitHeight
                    accentColor: root.accentColor
                }

                // Exit Focus Mode pill (only appears when Focus Mode is active)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 32
                    radius: 16
                    color: Qt.rgba(30/255, 30/255, 30/255, 0.92)
                    border.color: root.accentColor
                    border.width: 1
                    visible: root.focusModeActive
                    implicitWidth: focusExitRow.implicitWidth + 24

                    Row {
                        id: focusExitRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "close"
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "EXIT FOCUS MODE"
                            font.family: Theme.fontDots
                            font.pixelSize: 10
                            font.letterSpacing: 1.5
                            color: Theme.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.focusModeActive = false;
                            quickTogglesWidget.focusModeEnabled = false;
                        }
                    }
                }

                // Compact "Today" Weather Chip
                WeatherForecastWidget {
                    id: weatherChip
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: implicitHeight
                    visible: root.showWeatherForecast && !root.focusModeActive
                    opacity: visible ? 1.0 : 0.0
                    accentColor: root.accentColor
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }

            // RIGHT COLUMN: Unified "Now" Card + Quick System Toggles + Month Calendar
            Column {
                id: rightCol
                anchors.right: parent.right
                anchors.top: parent.top
                width: 360
                spacing: 16
                visible: !root.focusModeActive
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // Unified "Now" Card (Priority: Pomodoro > Media > Calendar Event > Hidden)
                NowCardWidget {
                    id: nowCardWidget
                    width: parent.width
                    accentColor: root.accentColor
                    onPomodoroCompleted: {
                        glyphBorderLight.triggerPomodoroFlash();
                    }
                }

                // Quick Toggles with Focus Mode Toggle
                QuickTogglesWidget {
                    id: quickTogglesWidget
                    width: parent.width
                    visible: root.showQuickToggles
                    accentColor: root.accentColor
                    focusModeEnabled: root.focusModeActive
                    onFocusModeToggled: (active) => {
                        root.focusModeActive = active;
                    }
                }

                MonthCalendarWidget {
                    id: monthCalWidget
                    width: parent.width
                    visible: root.showMonthCalendar || true
                    accentColor: root.accentColor
                }
            }
        }

        // BOTTOM BAR: Slim Quick Ask (Left) + Ambient Wave (Center) + Quick Launch Dock (Right)
        // Clean layout with ZERO overlap/collision
        Item {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            height: 72
            visible: !root.focusModeActive
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Left: Slim Single-Line Quick Ask Bar
            QuickAskWidget {
                id: quickAskWidget
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 340
                visible: root.showQuickAsk
                accentColor: root.accentColor
            }

            // Center: Nothing Ambient Wave
            WaveWidget {
                id: waveWidget
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showAssistantWave
                accentColor: root.accentColor
            }

            // Right: Quick Launch Utilities Dock
            QuickLinksWidget {
                id: quickLinksWidget
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 360
                height: parent.height
                visible: root.showQuickLinks
                accentColor: root.accentColor
            }
        }
    }
}
