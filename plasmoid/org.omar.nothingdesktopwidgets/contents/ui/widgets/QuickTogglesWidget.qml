import QtQuick
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    implicitWidth: 320
    implicitHeight: 180

    property bool wifiEnabled: true
    property bool btEnabled: false
    property bool dndEnabled: false
    property bool nightLightEnabled: false

    property string currentNetwork: "Wi-Fi Connected"

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = (data["stdout"] ?? "").trim();
            if (cmd.includes("nmcli radio wifi")) {
                root.wifiEnabled = out.includes("enabled");
            } else if (cmd.includes("bluetoothctl show")) {
                root.btEnabled = out.includes("Powered: yes");
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            execSource.connectSource("nmcli radio wifi 2>/dev/null || true");
            execSource.connectSource("bluetoothctl show 2>/dev/null | grep 'Powered:' || true");
        }
    }

    function toggleWifi() {
        root.wifiEnabled = !root.wifiEnabled;
        const state = root.wifiEnabled ? "on" : "off";
        execSource.connectSource(`nmcli radio wifi ${state} 2>/dev/null || true`);
    }

    function toggleBt() {
        root.btEnabled = !root.btEnabled;
        const state = root.btEnabled ? "power on" : "power off";
        execSource.connectSource(`bluetoothctl ${state} 2>/dev/null || true`);
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
    }

    function toggleNightLight() {
        root.nightLightEnabled = !root.nightLightEnabled;
        if (root.nightLightEnabled) {
            execSource.connectSource("qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightLight 1 2>/dev/null || true");
        } else {
            execSource.connectSource("qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightLight 0 2>/dev/null || true");
        }
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
                    text: Theme.iconSettings
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "QUICK TOGGLES"
                    font.family: Theme.fontDots
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Grid of 4 toggles (2x2)
            Grid {
                width: parent.width
                columns: 2
                spacing: 10

                // 1. Wi-Fi
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 48
                    radius: Theme.radiusMd
                    color: root.wifiEnabled ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: root.wifiEnabled ? root.accentColor : Theme.outline
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: Theme.iconWifi
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: root.wifiEnabled ? root.accentColor : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "WI-FI"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: root.wifiEnabled ? Theme.fg : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleWifi()
                    }
                }

                // 2. Bluetooth
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 48
                    radius: Theme.radiusMd
                    color: root.btEnabled ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: root.btEnabled ? root.accentColor : Theme.outline
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: Theme.iconBluetooth
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: root.btEnabled ? root.accentColor : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "BLUETOOTH"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: root.btEnabled ? Theme.fg : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleBt()
                    }
                }

                // 3. Do Not Disturb
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 48
                    radius: Theme.radiusMd
                    color: root.dndEnabled ? Qt.rgba(Theme.alert.r, Theme.alert.g, Theme.alert.b, 0.25) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: root.dndEnabled ? Theme.alert : Theme.outline
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: Theme.iconDnd
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: root.dndEnabled ? Theme.alert : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "DND"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: root.dndEnabled ? Theme.fg : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleDnd()
                    }
                }

                // 4. Night Light
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 48
                    radius: Theme.radiusMd
                    color: root.nightLightEnabled ? Qt.rgba(255/255, 180/255, 50/255, 0.22) : Qt.rgba(Theme.surfaceAlt.r, Theme.surfaceAlt.g, Theme.surfaceAlt.b, 0.8)
                    border.color: root.nightLightEnabled ? "#FFB432" : Theme.outline
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: Theme.iconNightLight
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: root.nightLightEnabled ? "#FFB432" : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "NIGHT LIGHT"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: root.nightLightEnabled ? Theme.fg : Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleNightLight()
                    }
                }
            }

            // Subtitle state info
            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: root.wifiEnabled ? root.accentColor : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.wifiEnabled ? "Network active" : "Wi-Fi disabled"
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    color: Theme.fgDim
                }
            }
        }
    }
}
