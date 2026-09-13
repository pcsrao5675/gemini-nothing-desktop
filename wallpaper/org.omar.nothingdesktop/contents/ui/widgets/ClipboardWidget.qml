import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 180

    property var clipboardItems: [
        "https://github.com/pcsrao5675/gemini-nothing-desktop",
        "systemctl --user restart plasma-plasmashell",
        "qdbus org.kde.KWin /ColorCorrect"
    ]

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd.includes("wl-paste")) {
                const out = (data["stdout"] ?? "").trim();
                if (out && !root.clipboardItems.includes(out)) {
                    var copy = [out].concat(root.clipboardItems.slice(0, 2));
                    root.clipboardItems = copy;
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            execSource.connectSource("wl-paste -n 2>/dev/null | head -n 1 || true");
        }
    }

    function copyToClipboard(txt) {
        const b64 = Qt.btoa(txt);
        execSource.connectSource(`echo "${b64}" | base64 -d | wl-copy 2>/dev/null || true`);
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
                    text: Theme.iconClipboard
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "CLIPBOARD HISTORY"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Items List
            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.clipboardItems
                    delegate: Rectangle {
                        width: parent.width
                        height: 30
                        radius: Theme.radiusSm
                        color: clipMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.6)
                        border.color: clipMouse.containsMouse ? root.accentColor : Theme.outline
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: Theme.iconClipboard
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                                color: clipMouse.containsMouse ? root.accentColor : Theme.fgDim
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width - 30
                                text: modelData
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                color: clipMouse.containsMouse ? Theme.fg : Theme.fgDim
                                elide: Text.ElideMiddle
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: clipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyToClipboard(modelData)
                        }
                    }
                }
            }
        }
    }
}
