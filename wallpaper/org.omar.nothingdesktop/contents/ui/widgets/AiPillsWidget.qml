import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: pillRow.implicitWidth
    implicitHeight: 34

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => disconnectSource(cmd)
    }

    function openUrl(url) {
        execSource.connectSource(`xdg-open "${url}" &`);
    }

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 12

        // Claude Pill
        Rectangle {
            height: 32
            radius: 16
            color: claudeMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.95) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.85)
            border.color: claudeMa.containsMouse ? "#D97706" : Theme.outline
            border.width: 1
            implicitWidth: claudeContent.implicitWidth + 24

            Behavior on color { ColorAnimation { duration: Theme.durShort } }
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

            Row {
                id: claudeContent
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: claudeMa.containsMouse ? "#D97706" : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Claude"
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                    color: claudeMa.containsMouse ? Theme.fg : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: claudeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openUrl("https://claude.ai")
            }
        }

        // Gemini Pill
        Rectangle {
            height: 32
            radius: 16
            color: geminiMa.containsMouse ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.95) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.85)
            border.color: geminiMa.containsMouse ? root.accentColor : Theme.outline
            border.width: 1
            implicitWidth: geminiContent.implicitWidth + 24

            Behavior on color { ColorAnimation { duration: Theme.durShort } }
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

            Row {
                id: geminiContent
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: geminiMa.containsMouse ? root.accentColor : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Gemini"
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                    color: geminiMa.containsMouse ? Theme.fg : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: geminiMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openUrl("https://gemini.google.com")
            }
        }
    }
}
