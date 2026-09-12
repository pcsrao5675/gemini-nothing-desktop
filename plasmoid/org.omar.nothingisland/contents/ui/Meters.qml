import QtQuick
import "."

// medidores en filas: icono, etiqueta, barra, valor y temperatura
Column {
    id: root
    spacing: 7

    // ancho fijo para las filas
    readonly property int anchoValor: Cfg.ramUsage ? 58 : 32

    component Meter: Item {
        id: m

        property string icon: ""
        property string label: ""
        property real value: 0     // 0..1
        property color accent: Theme.primary
        property int temp: -1      // <0 = sin temperatura
        property int valorAncho: 32
        // vacío = el porcentaje de siempre
        property string valorTexto: ""

        readonly property real v: Math.max(0, Math.min(1, value))
        readonly property bool hot: temp > 80

        width: parent.width
        height: 24

        // insignia del icono
        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.outline

            Text {
                anchors.centerIn: parent
                text: m.icon
                color: m.accent
                font.family: Theme.fontIcons
                font.pixelSize: 14
            }
        }

        Text {
            id: nameText
            anchors.left: badge.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            text: m.label
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.letterSpacing: Theme.labelSpacing
        }

        // barra de progreso
        Rectangle {
            id: track
            anchors.left: nameText.right
            anchors.leftMargin: 4
            anchors.right: pct.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 2.5
            color: Theme.containerHighest

            Rectangle {
                width: Math.max(parent.radius * 2, track.width * m.v)
                height: parent.height
                radius: parent.radius
                color: m.accent

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durLong
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }

        // margen siempre igual
        Text {
            id: pct
            anchors.right: tempRow.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: m.valorAncho
            horizontalAlignment: Text.AlignRight
            text: m.valorTexto !== "" ? m.valorTexto : Math.round(m.v * 100) + "%"
            color: Theme.fg
            font.family: Theme.fontDots
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // temperatura a la derecha
        Row {
            id: tempRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            width: 34
            visible: m.temp >= 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "local_fire_department"
                color: Theme.alert
                font.family: Theme.fontIcons
                font.pixelSize: 11
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: m.temp + "°"
                color: m.hot ? Theme.alert : Theme.fgDim
                font.family: Theme.fontDots
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }
    }

    // CPU (Ryzen)
    Meter {
        icon: "memory"
        label: "CPU"
        value: SysInfo.cpu / 100
        temp: SysInfo.cpuTemp
        valorAncho: root.anchoValor
        accent: SysInfo.cpu > 85 ? Theme.error : Theme.primary
    }

    // RAM
    Meter {
        icon: "database"
        label: "RAM"
        value: SysInfo.mem / 100
        valorAncho: root.anchoValor
        valorTexto: Cfg.ramUsage ? SysInfo.memShort : ""
        accent: SysInfo.mem > 85 ? Theme.error : Theme.tertiary
    }

    // AMD iGPU
    Meter {
        icon: "developer_board"
        label: "iGPU"
        value: SysInfo.amdGpu / 100
        temp: SysInfo.amdGpuAvailable ? SysInfo.amdGpuTemp : -1
        valorAncho: root.anchoValor
        accent: SysInfo.amdGpu > 85 ? Theme.error : (SysInfo.activeGpuLabel === "AMD" ? Theme.primary : Theme.fgDim)
        visible: SysInfo.amdGpuAvailable
    }

    // NVIDIA dGPU
    Meter {
        icon: "videogame_asset"
        label: "dGPU"
        value: SysInfo.gpu / 100
        temp: SysInfo.gpuAvailable ? SysInfo.gpuTemp : -1
        valorAncho: root.anchoValor
        accent: SysInfo.gpu > 85 ? Theme.error : (SysInfo.activeGpuLabel === "NVIDIA" ? Theme.secondary : Theme.fgDim)
        visible: SysInfo.gpuAvailable
    }

    // Active GPU Indicator badge
    Item {
        width: parent.width
        height: 14
        visible: SysInfo.amdGpuAvailable || SysInfo.gpuAvailable

        Row {
            anchors.right: parent.right
            spacing: 5

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: SysInfo.activeGpuLabel === "NVIDIA" ? Theme.secondary : Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "ACTIVE: " + SysInfo.activeGpuLabel
                color: SysInfo.activeGpuLabel === "NVIDIA" ? Theme.secondary : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Medium
                font.letterSpacing: 0.8
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
