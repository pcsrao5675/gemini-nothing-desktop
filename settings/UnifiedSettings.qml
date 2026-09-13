import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore

Item {
    id: root
    width: 780
    height: 520

    property string currentTab: "general"

    Rectangle {
        anchors.fill: parent
        color: "#080808"

        Row {
            anchors.fill: parent

            // Sidebar
            Rectangle {
                width: 220
                height: parent.height
                color: "#0E0E0E"
                border.color: "#1C1C1C"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Title
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: "#4DA3FF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "NOTHING DESKTOP"
                            font.family: "Space Grotesk"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                            color: "#FFFFFF"
                        }
                    }

                    Item { width: 1; height: 16 }

                    // Navigation Tabs
                    Repeater {
                        model: [
                            { id: "general", name: "Island Topbar", icon: "dock_to_bottom" },
                            { id: "wallpaper", name: "Wallpaper Widgets", icon: "wallpaper" },
                            { id: "notifications", name: "Notifications", icon: "notifications" },
                            { id: "cooling", name: "Fan & Cooling", icon: "mode_fan" },
                            { id: "shortcuts", name: "Shortcuts & Palette", icon: "keyboard" }
                        ]

                        delegate: Rectangle {
                            width: parent.width
                            height: 40
                            radius: 10
                            color: root.currentTab === modelData.id ? "#1A1A1A" : (navMa.containsMouse ? "#141414" : "transparent")
                            border.color: root.currentTab === modelData.id ? "#4DA3FF" : "transparent"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 10
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                    color: root.currentTab === modelData.id ? "#4DA3FF" : "#888888"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 13
                                    font.weight: root.currentTab === modelData.id ? Font.DemiBold : Font.Normal
                                    color: root.currentTab === modelData.id ? "#FFFFFF" : "#AAAAAA"
                                }
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = modelData.id
                            }
                        }
                    }
                }
            }

            // Main Settings Content
            Rectangle {
                width: parent.width - 220
                height: parent.height
                color: "#080808"

                Column {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 16

                    Text {
                        text: root.currentTab.toUpperCase() + " SETTINGS"
                        font.family: "Space Grotesk"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: "#FFFFFF"
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#222222"
                    }

                    // Dynamic Setting Toggles
                    Column {
                        spacing: 16
                        width: parent.width

                        QQC2.CheckBox {
                            text: "Electric Blue Undulating Wave Animation"
                            checked: true
                        }

                        QQC2.CheckBox {
                            text: "Replace System Notifications with Nothing OS Popups"
                            checked: true
                        }

                        QQC2.CheckBox {
                            text: "Enable Desktop Wallpaper Live Widgets"
                            checked: true
                        }

                        QQC2.CheckBox {
                            text: "Spotlight Command Palette (Meta+Space / Launch(2))"
                            checked: true
                        }

                        QQC2.CheckBox {
                            text: "Ambient Load-Adaptive Dynamic Lighting"
                            checked: true
                        }
                    }
                }
            }
        }
    }
}
