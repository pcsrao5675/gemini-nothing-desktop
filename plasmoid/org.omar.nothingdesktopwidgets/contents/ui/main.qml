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
    readonly property bool showMedia: Plasmoid.configuration.showMedia ?? true
    readonly property bool showAgenda: Plasmoid.configuration.showAgenda ?? true
    readonly property string icsFilePath: Plasmoid.configuration.icsFilePath || ""
    readonly property bool showNotes: Plasmoid.configuration.showNotes ?? true
    property string notesContent: Plasmoid.configuration.notesContent || ""
    readonly property bool showAssistantWave: Plasmoid.configuration.showAssistantWave ?? true

    // Expanded Modular Widgets
    readonly property bool showQuickToggles: Plasmoid.configuration.showQuickToggles ?? true
    readonly property bool showPomodoro: Plasmoid.configuration.showPomodoro ?? true
    readonly property bool showWeatherForecast: Plasmoid.configuration.showWeatherForecast ?? true
    readonly property bool showScreenshots: Plasmoid.configuration.showScreenshots ?? false
    readonly property bool showQuickLinks: Plasmoid.configuration.showQuickLinks ?? true
    readonly property bool showHabits: Plasmoid.configuration.showHabits ?? false
    readonly property bool showQuickAsk: Plasmoid.configuration.showQuickAsk ?? true
    readonly property bool showMonthCalendar: Plasmoid.configuration.showMonthCalendar ?? false
    readonly property bool showNetDisk: Plasmoid.configuration.showNetDisk ?? false
    readonly property bool showClipboard: Plasmoid.configuration.showClipboard ?? false
    readonly property bool showAmbientTile: Plasmoid.configuration.showAmbientTile ?? false

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

        // Top System Beacon Strip
        Rectangle {
            id: beaconStrip
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            height: 36
            radius: 18
            color: Qt.rgba(13/255, 14/255, 15/255, 0.90)
            border.color: Qt.rgba(64/255, 71/255, 82/255, 0.35)
            border.width: 1
            visible: !root.focusModeActive
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Row {
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.alert
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "SYS // LIVE"
                        font.family: Theme.fontDots
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        color: Theme.fgDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.15); anchors.verticalCenter: parent.verticalCenter }

                Row {
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Theme.iconWeather
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: "#FFB95C"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "22°C TOKYO"
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Center Gemini Indicator
            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    height: 22
                    radius: 11
                    color: Qt.rgba(31/255, 32/255, 33/255, 0.9)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    implicitWidth: badgeRow.implicitWidth + 16

                    Row {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.alert
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "GEMINI ACTIVE"
                            font.family: Theme.fontDots
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                            color: Theme.fg
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Text {
                    text: "STATION: 1920×1080@144HZ"
                    font.family: Theme.fontUi
                    font.pixelSize: 10
                    color: Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Right Beacon Cluster
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Theme.iconWifi
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "MIMO_5G"
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        color: Theme.fgDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "volume_up"
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: Theme.fgDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "68%"
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    height: 20
                    radius: 10
                    color: Qt.rgba(31/255, 32/255, 33/255, 0.9)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    implicitWidth: batRow.implicitWidth + 12

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "bolt"
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: (vitalsWidget ? vitalsWidget.batVal : "94") + "%"
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // Main 3-Column Widgets Grid
        Item {
            id: gridContainer
            anchors.top: beaconStrip.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: 16

            // LEFT COLUMN: Vitals Telemetry + Scratchpad Notes (Notes persists in Focus Mode)
            Column {
                id: leftCol
                anchors.left: parent.left
                anchors.top: parent.top
                width: 360
                spacing: 14

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

            // CENTER COLUMN: Big Clock Hero (minute-dissolve + day-progress ticks) + Weather Forecast + Focus Exit Pill
            Column {
                id: centerCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Math.max(300, parent.width - 760)
                spacing: 14

                ClockWidget {
                    id: clockWidget
                    width: parent.width
                    visible: root.showClock
                    clock24: root.clock24
                    accentColor: root.accentColor
                }

                // Exit Focus Mode pill (appears under clock when Focus Mode is on)
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

                WeatherForecastWidget {
                    id: weatherForecastWidget
                    width: parent.width
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
                spacing: 14
                visible: !root.focusModeActive
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // ── 3. Unified "Now" Card (Priority: Pomodoro > Media > Calendar Event > Hidden) ──
                NowCardWidget {
                    id: nowCardWidget
                    width: parent.width
                    accentColor: root.accentColor
                    icsFilePath: root.icsFilePath
                    onPomodoroCompleted: {
                        glyphBorderLight.triggerPomodoroFlash();
                    }
                }

                // ── Quick Toggles with Focus Mode Toggle ──
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

                HabitsWidget {
                    id: habitsWidget
                    width: parent.width
                    visible: root.showHabits
                    accentColor: root.accentColor
                }

                ScreenshotsWidget {
                    id: screenshotsWidget
                    width: parent.width
                    visible: root.showScreenshots
                    accentColor: root.accentColor
                }
            }
        }

        // BOTTOM INTERACTIVE BAR: AI Prompt Runtime Bar & Quick Launch Dock
        Item {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            height: 125
            visible: !root.focusModeActive
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 16

                // Left: QuickAsk / Assistant Bar
                QuickAskWidget {
                    id: quickAskWidget
                    width: parent.width - 380
                    visible: root.showQuickAsk
                    accentColor: root.accentColor
                }

                // Right: Quick Launch Utilities Dock
                QuickLinksWidget {
                    id: quickLinksWidget
                    width: 364
                    visible: root.showQuickLinks
                    accentColor: root.accentColor
                }
            }

            // Ambient Wave Floating Indicator at center bottom
            WaveWidget {
                id: waveWidget
                visible: root.showAssistantWave
                accentColor: root.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            }
        }
    }
}
