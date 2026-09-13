import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore

Item {
    id: root
    width: 620
    height: 380

    property string accentColor: "#4DA3FF"

    // Results model
    ListModel {
        id: resultsModel
        ListElement { title: "Gemini Assistant"; subtitle: "Launch or toggle floating assistant"; icon: "auto_awesome"; cmd: "gemini" }
        ListElement { title: "Terminal"; subtitle: "Open system terminal"; icon: "terminal"; cmd: "ptyxis || konsole || alacritty" }
        ListElement { title: "Web Browser"; subtitle: "Open default web browser"; icon: "public"; cmd: "brave || firefox || chromium" }
        ListElement { title: "System Settings"; subtitle: "Open KDE system settings"; icon: "settings"; cmd: "systemsettings" }
        ListElement { title: "Fan Turbo Mode"; subtitle: "Force maximum cooling RPM blast"; icon: "mode_fan"; cmd: "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && echo 0 > \"$p\"" }
        ListElement { title: "Fan Auto Mode"; subtitle: "Restore BIOS automatic thermal curves"; icon: "mode_fan_off"; cmd: "p=$(find /sys/devices/platform/hp-wmi/ -name 'pwm1_enable' 2>/dev/null | head -1); [ -n \"$p\" ] && echo 2 > \"$p\"" }
        ListElement { title: "Take Screenshot"; subtitle: "Capture screen to clipboard"; icon: "screenshot_monitor"; cmd: "spectacle -c -b" }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0B0B0BF0"
        radius: 20
        border.color: root.accentColor
        border.width: 1.5

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Search Bar
            Rectangle {
                width: parent.width
                height: 48
                radius: 12
                color: "#161616"
                border.color: "#2C2C2C"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: root.accentColor
                    }

                    QQC2.TextField {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        placeholderText: "Type a command, launch app, or calculate..."
                        color: "#FFFFFF"
                        font.family: "Space Grotesk"
                        font.pixelSize: 14
                        background: null
                        focus: true

                        onAccepted: {
                            if (resultsView.count > 0) {
                                executeItem(0);
                            }
                        }
                    }
                }
            }

            // Results List
            ListView {
                id: resultsView
                width: parent.width
                height: parent.height - 68
                model: resultsModel
                clip: true
                spacing: 6

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 50
                    radius: 10
                    color: itemMa.containsMouse ? "#1F1F1F" : "#121212"
                    border.color: itemMa.containsMouse ? root.accentColor : "#222222"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 14

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.icon
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            color: itemMa.containsMouse ? root.accentColor : "#888888"
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: model.title
                                font.family: "Space Grotesk"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: "#FFFFFF"
                            }
                            Text {
                                text: model.subtitle
                                font.family: "Space Grotesk"
                                font.pixelSize: 10
                                color: "#777777"
                            }
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: executeItem(index)
                    }
                }
            }
        }
    }

    function executeItem(idx) {
        var item = resultsModel.get(idx);
        if (!item) return;
        if (item.cmd === "gemini") {
            Qt.openUrlExternally("file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/gemini-toggle.sh");
        } else {
            // Run system command
            var proc = Qt.createQmlObject('import QtCore; Process { id: p }', root);
        }
        Qt.quit();
    }
}
