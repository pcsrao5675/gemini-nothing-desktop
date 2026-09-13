import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "widgets"
import "."

WallpaperItem {
    id: root

    // Configuration Bindings
    readonly property color bgColor: root.configuration.backgroundColor || "#050505"
    readonly property color accentColor: root.configuration.accentColor || "#4DA3FF"
    readonly property bool showDotGrid: root.configuration.showDotGrid ?? true
    readonly property real dotGridOpacity: root.configuration.dotGridOpacity ?? 0.15

    // Core Widgets
    readonly property bool showClock: root.configuration.showClock ?? true
    readonly property bool clock24: root.configuration.clock24 ?? true
    readonly property string clockPos: root.configuration.clockPosition || "TopCenter"

    readonly property bool showVitals: root.configuration.showVitals ?? true
    readonly property string vitalsPos: root.configuration.vitalsPosition || "TopRight"

    readonly property bool showMedia: root.configuration.showMedia ?? true
    readonly property string mediaPos: root.configuration.mediaPosition || "BottomLeft"

    readonly property bool showAgenda: root.configuration.showAgenda ?? true
    readonly property string agendaPos: root.configuration.agendaPosition || "TopLeft"
    readonly property string icsFilePath: root.configuration.icsFilePath || ""

    readonly property bool showNotes: root.configuration.showNotes ?? true
    readonly property string notesPos: root.configuration.notesPosition || "BottomRight"
    property string notesContent: root.configuration.notesContent || ""

    readonly property bool showAssistantWave: root.configuration.showAssistantWave ?? true
    readonly property string wavePos: root.configuration.wavePosition || "BottomCenter"

    // Expanded Modular Widgets
    readonly property bool showQuickToggles: root.configuration.showQuickToggles ?? true
    readonly property bool showPomodoro: root.configuration.showPomodoro ?? true
    readonly property bool showWeatherForecast: root.configuration.showWeatherForecast ?? true
    readonly property bool showScreenshots: root.configuration.showScreenshots ?? true
    readonly property bool showQuickLinks: root.configuration.showQuickLinks ?? true
    readonly property bool showHabits: root.configuration.showHabits ?? true
    readonly property bool showQuickAsk: root.configuration.showQuickAsk ?? true
    readonly property bool showMonthCalendar: root.configuration.showMonthCalendar ?? false
    readonly property bool showNetDisk: root.configuration.showNetDisk ?? false
    readonly property bool showClipboard: root.configuration.showClipboard ?? false
    readonly property bool showAmbientTile: root.configuration.showAmbientTile ?? false

    // Background Canvas with Nothing OS Subtle Dot Grid & Ambient Load Light
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.bgColor

        // Ambient Lighting Glow (shifts with system load)
        Rectangle {
            anchors.fill: parent
            opacity: 0.12
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: (vitalsWidget && vitalsWidget.cpuVal > 80) ? "#D71921" : ((vitalsWidget && vitalsWidget.cpuVal > 50) ? "#FF8800" : root.accentColor)
                    Behavior on color { ColorAnimation { duration: 1000 } }
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        Canvas {
            id: gridCanvas
            anchors.fill: parent
            visible: root.showDotGrid
            opacity: root.dotGridOpacity

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#FFFFFF";

                var step = 32;
                for (var x = 16; x < width; x += step) {
                    for (var y = 16; y < height; y += step) {
                        ctx.beginPath();
                        ctx.arc(x, y, 1, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }
            }
        }
    }

    // Grid Columns Container for Balanced Layout
    // Left Column (Agenda, Weather Forecast, Quick Toggles, Quick Links)
    Column {
        id: leftColumn
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.top: parent.top
        anchors.topMargin: 48
        spacing: 20

        AgendaWidget {
            id: agendaWidget
            visible: root.showAgenda
            accentColor: root.accentColor
            icsFilePath: root.icsFilePath
        }

        WeatherForecastWidget {
            id: weatherForecastWidget
            visible: root.showWeatherForecast
            accentColor: root.accentColor
        }

        QuickTogglesWidget {
            id: quickTogglesWidget
            visible: root.showQuickToggles
            accentColor: root.accentColor
        }

        QuickLinksWidget {
            id: quickLinksWidget
            visible: root.showQuickLinks
            accentColor: root.accentColor
        }

        MonthCalendarWidget {
            id: monthCalWidget
            visible: root.showMonthCalendar
            accentColor: root.accentColor
        }
    }

    // Center Column (Clock, Quick Ask, Ambient Wave, Ambient Tile)
    Column {
        id: centerColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 56
        spacing: 24

        ClockWidget {
            id: clockWidget
            visible: root.showClock
            clock24: root.clock24
            accentColor: root.accentColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        QuickAskWidget {
            id: quickAskWidget
            visible: root.showQuickAsk
            accentColor: root.accentColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        AmbientTileWidget {
            id: ambientTileWidget
            visible: root.showAmbientTile
            accentColor: root.accentColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Center Bottom Floating Wave
    WaveWidget {
        id: waveWidget
        visible: root.showAssistantWave
        accentColor: root.accentColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
    }

    // Right Column (Vitals, Pomodoro, Habits, Screenshots, Notes, Net/Disk, Clipboard)
    Column {
        id: rightColumn
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.top: parent.top
        anchors.topMargin: 48
        spacing: 20

        VitalsWidget {
            id: vitalsWidget
            visible: root.showVitals
            accentColor: root.accentColor
        }

        PomodoroWidget {
            id: pomodoroWidget
            visible: root.showPomodoro
            accentColor: root.accentColor
        }

        HabitsWidget {
            id: habitsWidget
            visible: root.showHabits
            accentColor: root.accentColor
        }

        ScreenshotsWidget {
            id: screenshotsWidget
            visible: root.showScreenshots
            accentColor: root.accentColor
        }

        NotesWidget {
            id: notesWidget
            visible: root.showNotes
            accentColor: root.accentColor
            notesText: root.notesContent
            onNotesUpdated: (newTxt) => {
                root.configuration.notesContent = newTxt;
            }
        }

        NetDiskWidget {
            id: netDiskWidget
            visible: root.showNetDisk
            accentColor: root.accentColor
        }

        ClipboardWidget {
            id: clipboardWidget
            visible: root.showClipboard
            accentColor: root.accentColor
        }
    }

    // Bottom Left Media Widget (docked above bottom edge or alongside column)
    MediaWidget {
        id: mediaWidget
        visible: root.showMedia
        accentColor: root.accentColor
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
    }
}
