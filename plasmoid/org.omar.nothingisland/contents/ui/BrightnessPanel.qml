import QtQuick
import "."

// panel de brillo: barra grande arrastrable, mismo estilo que AudioPanel
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 44

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        // ── barra de título ──
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("BRILLO")
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

                Behavior on color {
                    ColorAnimation { duration: Theme.durShort }
                }

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

        // ── barra de brillo ──
        Rectangle {
            id: briCard
            width: parent.width
            height: 56
            radius: Theme.shapeLg
            color: Theme.surfaceAlt

            // icono a la izquierda: cambia entre brightness_low y brightness_high
            Text {
                id: briIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Brightness.brightness < 30 ? "brightness_low"
                    : Brightness.brightness < 70 ? "brightness_medium"
                    : "brightness_high"
                color: Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 20

                Behavior on text {
                    // texto cambia de golpe, sin animación cruzada
                }
            }

            // porcentaje a la derecha
            Text {
                id: briNum
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                horizontalAlignment: Text.AlignRight
                text: Brightness.brightness + "%"
                color: Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            // track arrastrable
            Rectangle {
                id: briTrack
                anchors.left: briIcon.right
                anchors.leftMargin: 12
                anchors.right: briNum.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Theme.surfaceHigh

                Rectangle {
                    width: Math.max(parent.radius * 2, briTrack.width * (Brightness.brightness / 100))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.fg

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor

                    function apply(mx) {
                        const pct = Math.round((mx / briTrack.width) * 100);
                        Brightness.set(pct);
                    }

                    onPressed: mouse => {
                        Brightness.holding = true;
                        apply(mouse.x);
                    }
                    onPositionChanged: mouse => {
                        if (pressed)
                            apply(mouse.x);
                    }
                    onReleased: Brightness.holding = false
                }
            }
        }

        // ── presets rápidos ──
        Row {
            width: parent.width
            spacing: 8

            component Preset: Rectangle {
                id: pr
                property int value: 50
                property string label: "50%"

                readonly property bool current: Math.abs(Brightness.brightness - pr.value) <= 4

                width: (parent.width - parent.spacing * 3) / 4
                height: 38
                radius: Theme.shapeMd
                color: pr.current ? Theme.inverted
                    : prMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover)
                    : Qt.alpha(Theme.fg, 0)

                Behavior on color {
                    ColorAnimation { duration: Theme.durShort }
                }

                Text {
                    anchors.centerIn: parent
                    text: pr.label
                    color: pr.current ? Theme.invertedFg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: prMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Brightness.set(pr.value)
                }
            }

            Preset { value: 10; label: "10%" }
            Preset { value: 30; label: "30%" }
            Preset { value: 60; label: "60%" }
            Preset { value: 100; label: "100%" }
        }
    }
}
