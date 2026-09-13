import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 180

    readonly property var links: [
        { label: "TERMINAL", icon: Theme.iconTerminal, cmd: "konsole &" },
        { label: "BROWSER",  icon: Theme.iconWeb,      cmd: "which brave >/dev/null 2>&1 && brave & || xdg-open https://google.com &" },
        { label: "CODE",     icon: Theme.iconCode,     cmd: "which code >/dev/null 2>&1 && code & || which vscodium >/dev/null 2>&1 && vscodium & || kate &" },
        { label: "FILES",    icon: Theme.iconFolder,   cmd: "dolphin &" },
        { label: "SETTINGS", icon: Theme.iconSettings, cmd: "systemsettings &" },
        { label: "MONITOR",  icon: Theme.iconCpu,      cmd: "plasma-systemmonitor &" }
    ]

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => disconnectSource(cmd)
    }

    function launch(cmd) {
        execSource.connectSource(cmd);
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
                    text: Theme.iconSparkle
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "QUICK LAUNCH"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Grid of 6 shortcut buttons (3x2)
            Grid {
                width: parent.width
                columns: 3
                spacing: 8

                Repeater {
                    model: root.links
                    delegate: Rectangle {
                        width: (parent.width - 16) / 3
                        height: 48
                        radius: Theme.radiusMd
                        color: btnMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.7)
                        border.color: btnMouse.containsMouse ? root.accentColor : Theme.outline
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontIcons
                                font.pixelSize: 18
                                color: btnMouse.containsMouse ? root.accentColor : Theme.fg
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: modelData.label
                                font.family: Theme.fontUi
                                font.pixelSize: 9
                                font.bold: true
                                color: btnMouse.containsMouse ? Theme.fg : Theme.fgDim
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launch(modelData.cmd)
                        }
                    }
                }
            }
        }
    }
}
