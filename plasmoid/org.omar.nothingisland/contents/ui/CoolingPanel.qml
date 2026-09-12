import QtQuick
import "."

// Panel de control de refrigeración y perfiles de ventiladores
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 20

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        // ── encabezado ──
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("CONTROL DE VENTILACIÓN")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: height / 2
                color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color { ColorAnimation { duration: Theme.durShort } }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.closed()
                }
            }
        }

        // ── tarjeta de estado actual ──
        Rectangle {
            width: parent.width
            height: 64
            radius: Theme.shapeLg
            color: Cooling.isTurbo ? Qt.alpha(Theme.alert, 0.12) : Theme.surfaceAlt
            border.width: 1
            border.color: Cooling.isTurbo ? Theme.alert : Theme.outline

            Behavior on color { ColorAnimation { duration: Theme.durMedium } }
            Behavior on border.color { ColorAnimation { duration: Theme.durMedium } }

            // ventilador grande giratorio
            Rectangle {
                id: fanRing
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: height / 2
                color: "transparent"
                border.width: 1.5
                border.color: Cooling.accent

                Text {
                    id: fanSpinIcon
                    anchors.centerIn: parent
                    text: "mode_fan"
                    color: Cooling.accent
                    font.family: Theme.fontIcons
                    font.pixelSize: 22

                    RotationAnimation on rotation {
                        running: Cooling.isTurbo
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 800
                    }
                }
            }

            Column {
                anchors.left: fanRing.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: Cooling.profileName
                    color: Theme.fg
                    font.family: Theme.fontDots
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }

                Text {
                    text: Cooling.profileDesc + " · " + Cfg.t("PERFIL ACTIVO")
                    color: Cooling.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: 0.5
                }
            }

            // botón de cambio rápido
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: cycleTxt.implicitWidth + 20
                height: 32
                radius: height / 2
                color: cycleMa.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh
                border.width: 1
                border.color: Theme.outline

                Text {
                    id: cycleTxt
                    anchors.centerIn: parent
                    text: Cfg.t("CAMBIAR")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: cycleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Cooling.cycleProfile()
                }
            }
        }

        // ── 3 opciones de perfil ──
        component ProfileCard: Rectangle {
            id: pc
            property string targetProfile: ""
            property string title: ""
            property string desc: ""
            property string icon: ""
            property color highlightColor: Theme.primary

            readonly property bool active: Cooling.profile === targetProfile

            width: parent.width
            height: 52
            radius: Theme.shapeMd
            color: active ? Qt.alpha(highlightColor, 0.12) : pcMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
            border.width: active ? 1.5 : 1
            border.color: active ? highlightColor : Theme.outline

            Behavior on color { ColorAnimation { duration: Theme.durShort } }
            Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

            Text {
                id: picon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: pc.icon
                color: pc.active ? pc.highlightColor : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 22
            }

            Column {
                anchors.left: picon.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: pc.title
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                }

                Text {
                    text: pc.desc
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                }
            }

            // indicador de selección
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: "transparent"
                border.width: 1.5
                border.color: pc.active ? pc.highlightColor : Theme.outline

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: pc.highlightColor
                    visible: pc.active
                }
            }

            MouseArea {
                id: pcMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Cooling.setProfile(pc.targetProfile)
            }
        }

        ProfileCard {
            targetProfile: "performance"
            title: Cfg.t("TURBO / RENDIMIENTO")
            desc: Cfg.t("Ventiladores al máximo, mayor disipación térmica")
            icon: "mode_fan"
            highlightColor: Theme.alert
        }

        ProfileCard {
            targetProfile: "balanced"
            title: Cfg.t("EQUILIBRADO")
            desc: Cfg.t("Curva automática estándar del BIOS HP")
            icon: "tune"
            highlightColor: Theme.primary
        }

        ProfileCard {
            targetProfile: "low-power"
            title: Cfg.t("SILENCIOSO / ECO")
            desc: Cfg.t("Ventiladores silenciosos a bajas RPM, bajo consumo")
            icon: "air"
            highlightColor: Theme.secondary
        }

        // ── temperaturas de referencia ──
        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2
                height: 38
                radius: Theme.shapeMd
                color: Theme.surfaceAlt
                border.width: 1
                border.color: Theme.outline

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "memory"
                        color: Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CPU " + SysInfo.cpuTemp + "°C"
                        color: Theme.fg
                        font.family: Theme.fontDots
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2
                height: 38
                radius: Theme.shapeMd
                color: Theme.surfaceAlt
                border.width: 1
                border.color: Theme.outline

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "videogame_asset"
                        color: Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GPU " + (SysInfo.gpuAvailable ? SysInfo.gpuTemp + "°C" : "OFF")
                        color: Theme.fg
                        font.family: Theme.fontDots
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
