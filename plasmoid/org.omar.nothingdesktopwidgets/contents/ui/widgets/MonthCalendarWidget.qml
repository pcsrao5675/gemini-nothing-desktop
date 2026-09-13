import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 240

    readonly property var monthNames: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    readonly property var dayHeaders: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property int currentDay: new Date().getDate()

    // Generate days grid: 35 or 42 cells
    property var daysGrid: []

    function updateGrid() {
        const firstDay = new Date(currentYear, currentMonth, 1).getDay(); // 0 is Sun
        // Adjust so Monday is index 0
        const startOffset = (firstDay === 0 ? 6 : firstDay - 1);
        const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();

        var grid = [];
        for (var i = 0; i < startOffset; i++) {
            grid.push({ day: 0, isCurrent: false });
        }
        for (var d = 1; d <= daysInMonth; d++) {
            grid.push({ day: d, isCurrent: (d === currentDay) });
        }
        while (grid.length < 35) {
            grid.push({ day: 0, isCurrent: false });
        }
        root.daysGrid = grid;
    }

    Component.onCompleted: updateGrid()

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: Theme.iconCalendar
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: `${root.monthNames[root.currentMonth]} ${root.currentYear}`
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Day Headers
            Grid {
                width: parent.width
                columns: 7
                spacing: 4

                Repeater {
                    model: root.dayHeaders
                    delegate: Item {
                        width: (parent.width - 24) / 7
                        height: 18

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.fontDots
                            font.pixelSize: 9
                            color: Theme.fgDim
                        }
                    }
                }
            }

            // Days Grid
            Grid {
                width: parent.width
                columns: 7
                spacing: 4

                Repeater {
                    model: root.daysGrid
                    delegate: Rectangle {
                        width: (parent.width - 24) / 7
                        height: 24
                        radius: 12
                        color: modelData.isCurrent ? root.accentColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? "" + modelData.day : ""
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.bold: modelData.isCurrent
                            color: modelData.isCurrent ? "#050505" : (modelData.day > 0 ? Theme.fg : "transparent")
                        }
                    }
                }
            }
        }
    }
}
