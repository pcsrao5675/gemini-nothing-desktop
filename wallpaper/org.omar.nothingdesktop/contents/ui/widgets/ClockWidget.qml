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

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 8

            // Giant Dot-Matrix Time
            Text {
                id: timeText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.currentTime, root.clock24 ? "HH:mm" : "hh:mm")
                font.family: Theme.fontDots
                font.pixelSize: 72
                font.letterSpacing: 4
                color: Theme.fg
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
        }
    }
}
