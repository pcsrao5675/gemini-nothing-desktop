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

    // Background Canvas with Nothing OS Subtle Dot Grid
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.bgColor

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

    // Helper position anchoring function
    function applyPosition(item, posName, marginX, marginY) {
        if (!item) return;
        switch(posName) {
            case "TopLeft":
                item.anchors.left = root.left;
                item.anchors.top = root.top;
                item.anchors.leftMargin = marginX;
                item.anchors.topMargin = marginY;
                break;
            case "TopCenter":
                item.anchors.horizontalCenter = root.horizontalCenter;
                item.anchors.top = root.top;
                item.anchors.topMargin = marginY;
                break;
            case "TopRight":
                item.anchors.right = root.right;
                item.anchors.top = root.top;
                item.anchors.rightMargin = marginX;
                item.anchors.topMargin = marginY;
                break;
            case "BottomLeft":
                item.anchors.left = root.left;
                item.anchors.bottom = root.bottom;
                item.anchors.leftMargin = marginX;
                item.anchors.bottomMargin = marginY;
                break;
            case "BottomCenter":
                item.anchors.horizontalCenter = root.horizontalCenter;
                item.anchors.bottom = root.bottom;
                item.anchors.bottomMargin = marginY;
                break;
            case "BottomRight":
                item.anchors.right = root.right;
                item.anchors.bottom = root.bottom;
                item.anchors.rightMargin = marginX;
                item.anchors.bottomMargin = marginY;
                break;
            case "Center":
                item.anchors.centerIn = root;
                break;
            default:
                item.anchors.top = root.top;
                item.anchors.left = root.left;
                item.anchors.leftMargin = marginX;
                item.anchors.topMargin = marginY;
        }
    }

    // Widget Instances
    ClockWidget {
        id: clockWidget
        visible: root.showClock
        clock24: root.clock24
        accentColor: root.accentColor
        Component.onCompleted: root.applyPosition(clockWidget, root.clockPos, 60, 60)
    }

    VitalsWidget {
        id: vitalsWidget
        visible: root.showVitals
        accentColor: root.accentColor
        Component.onCompleted: root.applyPosition(vitalsWidget, root.vitalsPos, 60, 60)
    }

    MediaWidget {
        id: mediaWidget
        visible: root.showMedia
        accentColor: root.accentColor
        Component.onCompleted: root.applyPosition(mediaWidget, root.mediaPos, 60, 60)
    }

    AgendaWidget {
        id: agendaWidget
        visible: root.showAgenda
        accentColor: root.accentColor
        icsFilePath: root.icsFilePath
        Component.onCompleted: root.applyPosition(agendaWidget, root.agendaPos, 60, 60)
    }

    NotesWidget {
        id: notesWidget
        visible: root.showNotes
        accentColor: root.accentColor
        notesText: root.notesContent
        onNotesUpdated: (newTxt) => {
            root.configuration.notesContent = newTxt;
        }
        Component.onCompleted: root.applyPosition(notesWidget, root.notesPos, 60, 60)
    }

    WaveWidget {
        id: waveWidget
        visible: root.showAssistantWave
        accentColor: root.accentColor
        Component.onCompleted: root.applyPosition(waveWidget, root.wavePos, 60, 40)
    }
}
