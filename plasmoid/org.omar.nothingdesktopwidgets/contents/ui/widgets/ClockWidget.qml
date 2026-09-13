import QtQuick
import ".."

Item {
    id: root

    property bool clock24: true
    property color accentColor: Theme.accent

    implicitWidth: 380
    implicitHeight: 180

    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    property string displayedTimeString: Qt.formatDateTime(root.currentTime, root.clock24 ? "HH:mm" : "hh:mm")
    readonly property real dayProgress: (root.currentTime.getHours() * 3600 + root.currentTime.getMinutes() * 60 + root.currentTime.getSeconds()) / 86400.0

    onCurrentTimeChanged: {
        var newStr = Qt.formatDateTime(root.currentTime, root.clock24 ? "HH:mm" : "hh:mm");
        if (newStr !== root.displayedTimeString) {
            clockTransition.swapContent(function() {
                root.displayedTimeString = newStr;
            });
        }
    }

    onClock24Changed: {
        root.displayedTimeString = Qt.formatDateTime(root.currentTime, root.clock24 ? "HH:mm" : "hh:mm");
    }

    Rectangle {
        id: clockBox
        anchors.fill: parent
        color: clockMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.85) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
        radius: Theme.radiusLg
        border.color: clockMa.containsMouse ? root.accentColor : Theme.outline
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

        MouseArea {
            id: clockMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clock24 = !root.clock24;
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            // Giant Dot-Matrix Time with Dot-Dissolve Minute Tick
            DotDissolveTransition {
                id: clockTransition
                width: timeText.implicitWidth
                height: timeText.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                dotColor: root.accentColor
                duration: 400

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: root.displayedTimeString
                    font.family: Theme.fontDots
                    font.pixelSize: 72
                    font.letterSpacing: 4
                    color: Theme.fg
                }
            }

            // Date + Seconds Dot
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(root.currentTime, "dddd, MMMM d").toUpperCase()
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.0
                    color: Theme.fgDim
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: root.accentColor
                    opacity: root.currentTime.getSeconds() % 2 === 0 ? 1.0 : 0.2
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(root.currentTime, "ss")
                    font.family: Theme.fontDots
                    font.pixelSize: 15
                    color: root.accentColor
                }
            }

            // Day-Progress Hairline: Row of dot-matrix ticks
            Row {
                id: dayHairline
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3
                topPadding: 4

                Repeater {
                    model: 48 // 48 ticks = half-hour increments throughout 24 hours
                    Rectangle {
                        width: 3
                        height: (index % 12 === 0) ? 5 : (index % 2 === 0 ? 3 : 2)
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: (index / 48.0) <= root.dayProgress ? root.accentColor : Theme.outline
                        opacity: (index / 48.0) <= root.dayProgress ? 0.95 : 0.25

                        Behavior on color { ColorAnimation { duration: 300 } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }
}
