import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 110

    property string lastResponse: ""

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (out) {
                root.lastResponse = out;
            }
        }
    }

    function submitPrompt(query) {
        if (!query || query.trim() === "") return;
        askField.text = "";
        root.lastResponse = "Thinking...";
        // Call gemini toggle or directly invoke assistant bridge
        execSource.connectSource(`$HOME/.local/bin/gemini-toggle.sh "${query.replace(/"/g, '\\"')}" &`);
    }

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
                    text: Theme.iconSparkle
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "GEMINI QUICK ASK"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Input Row
            Rectangle {
                width: parent.width
                height: 38
                radius: Theme.radiusMd
                color: Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                border.color: askField.activeFocus ? root.accentColor : Theme.outline
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    QQC2.TextField {
                        id: askField
                        width: parent.width - 36
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "Ask Gemini anything..."
                        placeholderTextColor: Theme.fgDim
                        color: Theme.fg
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        background: null
                        onAccepted: root.submitPrompt(text)
                    }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: "#050505"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitPrompt(askField.text)
                        }
                    }
                }
            }
        }
    }
}
