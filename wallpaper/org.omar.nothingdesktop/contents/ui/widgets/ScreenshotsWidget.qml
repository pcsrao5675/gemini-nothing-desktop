import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 180

    property var recentScreenshots: []

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (out) {
                var files = out.split("\n").filter(f => f && f.length > 0);
                root.recentScreenshots = files.slice(0, 3);
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            execSource.connectSource("find ~/Pictures/Screenshots ~/Pictures -maxdepth 2 -type f \\( -name '*.png' -o -name '*.jpg' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -nr | head -n 3 | cut -d' ' -f2- || true");
        }
    }

    function openFile(filePath) {
        execSource.connectSource(`xdg-open "${filePath}" &`);
    }

    function takeScreenshot() {
        execSource.connectSource("spectacle -r &");
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
            spacing: 12

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: Theme.iconScreenshot
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "CAPTURES"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1; Layout.fillWidth: true }

                // Quick Capture Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                    border.color: root.accentColor
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconAdd
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: root.accentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.takeScreenshot()
                    }
                }
            }

            // 3 Thumbnail Slots
            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: (parent.width - 16) / 3
                        height: 95
                        radius: Theme.radiusMd
                        color: Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.6)
                        border.color: Theme.outline
                        border.width: 1
                        clip: true

                        readonly property string path: root.recentScreenshots[index] || ""

                        Image {
                            anchors.fill: parent
                            source: path ? "file://" + path : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: path !== ""
                            asynchronous: true
                        }

                        // Placeholder when empty
                        Column {
                            anchors.centerIn: parent
                            visible: path === ""
                            spacing: 4

                            Text {
                                text: Theme.iconScreenshot
                                font.family: Theme.fontIcons
                                font.pixelSize: 20
                                color: Theme.fgFaint
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "EMPTY"
                                font.family: Theme.fontDots
                                font.pixelSize: 9
                                color: Theme.fgFaint
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: path ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (path) root.openFile(path);
                                else root.takeScreenshot();
                            }
                        }
                    }
                }
            }
        }
    }
}
