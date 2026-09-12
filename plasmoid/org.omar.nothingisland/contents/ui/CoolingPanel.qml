import QtQuick
import "."

// Panel de control de refrigeración: perfiles automáticos y control manual de velocidad
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 20

    // Tab activo: "auto" o "manual"
    property string activeTab: Cooling.isManual ? "manual" : "auto"

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

        // ── selector de pestaña: AUTO vs MANUAL ──
        Rectangle {
            width: parent.width
            height: 38
            radius: Theme.shapeMd
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.outline

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                // Pestaña Auto
                Rectangle {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    radius: Theme.shapeMd - 2
                    color: popup.activeTab === "auto" ? Theme.inverted : autoTabMa.containsMouse ? Theme.surfaceHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "auto_mode"
                            color: popup.activeTab === "auto" ? Theme.invertedFg : Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Cfg.t("PERFILES AUTO")
                            color: popup.activeTab === "auto" ? Theme.invertedFg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: autoTabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.activeTab = "auto";
                            if (Cooling.isManual)
                                Cooling.setProfile("balanced");
                        }
                    }
                }

                // Pestaña Manual
                Rectangle {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    radius: Theme.shapeMd - 2
                    color: popup.activeTab === "manual" ? Theme.inverted : manualTabMa.containsMouse ? Theme.surfaceHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "tune"
                            color: popup.activeTab === "manual" ? Theme.invertedFg : Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Cfg.t("VELOCIDAD MANUAL")
                            color: popup.activeTab === "manual" ? Theme.invertedFg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: manualTabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.activeTab = "manual";
                            if (!Cooling.isManual)
                                Cooling.setManualSpeed(80);
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════
        // VISTA MANUAL: Slider + Presets
        // ══════════════════════════════════════════════════════════
        Column {
            width: parent.width
            spacing: 12
            visible: popup.activeTab === "manual"

            // Tarjeta de estado de ventilador manual
            Rectangle {
                width: parent.width
                height: 70
                radius: Theme.shapeLg
                color: Cooling.manualSpeed >= 85 ? Qt.alpha(Theme.alert, 0.12) : Theme.surfaceAlt
                border.width: 1
                border.color: Cooling.manualSpeed >= 85 ? Theme.alert : Theme.outline

                Rectangle {
                    id: fanSpinBox
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    radius: 22
                    color: "transparent"
                    border.width: 1.5
                    border.color: Cooling.accent

                    Text {
                        anchors.centerIn: parent
                        text: "mode_fan"
                        color: Cooling.accent
                        font.family: Theme.fontIcons
                        font.pixelSize: 24

                        RotationAnimation on rotation {
                            running: Cooling.animDuration > 0
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: Math.max(300, Cooling.animDuration)
                        }
                    }
                }

                Column {
                    anchors.left: fanSpinBox.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: Cooling.manualSpeed >= 95 ? "100% MAX BLAST" : Cooling.manualSpeed + "% SPEED"
                        color: Cooling.manualSpeed >= 85 ? Theme.alert : Theme.fg
                        font.family: Theme.fontDots
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Text {
                        text: Cooling.manualSpeed >= 90 ? Cfg.t("TURBO HARDWARE FAN BOOST ACTIVADO")
                            : Cooling.manualSpeed <= 30 ? Cfg.t("MODO SILENCIOSO BAJA VELOCIDAD")
                            : Cfg.t("CONTROL MANUAL PERSONALIZADO")
                        color: Cooling.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                    }
                }
            }

            // ── Slider interactivo ──
            Item {
                width: parent.width
                height: 38

                Rectangle {
                    id: trackBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    radius: 4
                    color: Theme.containerHighest

                    Rectangle {
                        id: fillBar
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(8, trackBar.width * (Cooling.manualSpeed / 100))
                        radius: 4
                        color: Cooling.accent

                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                    }

                    // Botón arrastrable (Thumb)
                    Rectangle {
                        id: sliderThumb
                        x: Math.max(0, Math.min(trackBar.width - width, (trackBar.width * (Cooling.manualSpeed / 100)) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        radius: 11
                        color: Theme.fg
                        border.width: 2
                        border.color: Cooling.accent
                        scale: sliderMa.pressed ? 1.2 : sliderMa.containsMouse ? 1.1 : 1.0

                        Behavior on scale { NumberAnimation { duration: Theme.durShort } }
                    }
                }

                MouseArea {
                    id: sliderMa
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updatePos(mx) {
                        const clampedX = Math.max(0, Math.min(trackBar.width, mx));
                        const pct = Math.round((clampedX / trackBar.width) * 100);
                        Cooling.setManualSpeed(pct);
                    }

                    onPressed: mouse => updatePos(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) updatePos(mouse.x);
                    }
                }
            }

            // ── Botones de ajuste rápido (Presets) ──
            Row {
                width: parent.width
                spacing: 6

                component QuickPresetBtn: Rectangle {
                    id: qb
                    property int speedValue: 50
                    property string label: ""

                    readonly property bool selected: Cooling.isManual && Math.abs(Cooling.manualSpeed - speedValue) < 5

                    width: (parent.width - 18) / 4
                    height: 32
                    radius: Theme.shapeMd
                    color: selected ? Theme.inverted : qbMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.width: 1
                    border.color: selected ? Theme.inverted : Theme.outline

                    Behavior on color { ColorAnimation { duration: Theme.durShort } }

                    Text {
                        anchors.centerIn: parent
                        text: qb.label
                        color: qb.selected ? Theme.invertedFg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: qbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Cooling.setManualSpeed(qb.speedValue)
                    }
                }

                QuickPresetBtn { speedValue: 25; label: "25% SILENT" }
                QuickPresetBtn { speedValue: 50; label: "50% MED" }
                QuickPresetBtn { speedValue: 75; label: "75% HIGH" }
                QuickPresetBtn { speedValue: 100; label: "100% MAX" }
            }
        }

        // ══════════════════════════════════════════════════════════
        // VISTA AUTO: 3 Perfiles HP
        // ══════════════════════════════════════════════════════════
        Column {
            width: parent.width
            spacing: 8
            visible: popup.activeTab === "auto"

            component ProfileCard: Rectangle {
                id: pc
                property string targetProfile: ""
                property string title: ""
                property string desc: ""
                property string icon: ""
                property color highlightColor: Theme.primary

                readonly property bool active: !Cooling.isManual && Cooling.profile === targetProfile

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
                    onClicked: {
                        popup.activeTab = "auto";
                        Cooling.setProfile(pc.targetProfile);
                    }
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
