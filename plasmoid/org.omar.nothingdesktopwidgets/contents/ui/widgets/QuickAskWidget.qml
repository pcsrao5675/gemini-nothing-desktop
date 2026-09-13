import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 360
    implicitHeight: 38

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => disconnectSource(cmd)
    }

    function submitPrompt(query) {
        if (!query || query.trim() === "") return;
        askField.text = "";
        execSource.connectSource(`$HOME/.local/bin/gemini-toggle.sh "${query.replace(/"/g, '\\"')}" &`);
    }

    Rectangle {
        anchors.fill: parent
        radius: 19
        color: askField.activeFocus ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.95) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.80)
        border.color: askField.activeFocus ? root.accentColor : Theme.outline
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 6
            spacing: 8

            // AI Sparkle Icon
            Text {
                text: Theme.iconSparkle
                font.family: Theme.fontIcons
                font.pixelSize: 16
                color: root.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            // Input text field
            QQC2.TextField {
                id: askField
                width: parent.width - 64
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Ask Gemini anything..."
                placeholderTextColor: Theme.fgDim
                color: Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 12
                background: null
                onAccepted: root.submitPrompt(text)
            }

            // Submit Arrow Button
            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: sendMa.containsMouse ? Qt.lighter(root.accentColor, 1.15) : root.accentColor
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "arrow_forward"
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                    color: "#050505"
                }

                MouseArea {
                    id: sendMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submitPrompt(askField.text)
                }
            }
        }
    }
}
