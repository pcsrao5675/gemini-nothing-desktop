import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM
import "."

// bandeja de notificaciones: todas las que llegaron, silencio y vaciar
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 10

    readonly property int count: Notifs.count

    // ── relative timestamp helper ──
    function relativeTime(dt) {
        if (!dt || !(dt instanceof Date) || isNaN(dt.getTime()))
            return "";
        var now = new Date();
        var secs = Math.floor((now - dt) / 1000);
        if (secs < 5)  return Cfg.t("AHORA");
        if (secs < 60) return secs + "s";
        var mins = Math.floor(secs / 60);
        if (mins < 60) return mins + "m";
        var hrs = Math.floor(mins / 60);
        if (hrs < 24)  return hrs + "h";
        var days = Math.floor(hrs / 24);
        return days + "d";
    }

    // refreshes every 30s so relative timestamps stay fresh
    Timer {
        id: tsRefresh
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
    }

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
                text: Cfg.t("NOTIFICACIONES")
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
                    ColorAnimation {
                        duration: Theme.durShort
                    }
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

        // ── silencio + vaciar ──
        Row {
            width: parent.width
            spacing: 8

            // tarjeta invertida cuando el silencio está puesto
            Rectangle {
                width: (parent.width - 8) * 0.62
                height: 46
                radius: Theme.shapeLg
                color: Notifs.muted ? Theme.inverted : muteMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Text {
                    id: muteIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? "notifications_off" : "notifications"
                    color: Notifs.muted ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: muteIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? Cfg.t("SILENCIADAS") : Cfg.t("SILENCIAR")
                    color: Notifs.muted ? Theme.invertedFg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: muteMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.toggleMute()
                }
            }

            Rectangle {
                width: (parent.width - 8) * 0.38
                height: 46
                radius: Theme.shapeLg
                color: clearMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                opacity: popup.count > 0 ? 1 : 0.4

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    id: clearIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "delete_sweep"
                    color: Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: clearIcon.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cfg.t("VACIAR")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: popup.count > 0
                    onClicked: Notifs.clearAll()
                }
            }
        }

        Text {
            text: popup.count + (popup.count === 1 ? " EN LA BANDEJA" : " EN LA BANDEJA")
            color: Theme.outline
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
            visible: popup.count > 0
        }

        // ── lista con scroll ──
        Item {
            width: parent.width
            height: popup.count > 0 ? Math.min(340, notifListCol.implicitHeight) : 0
            visible: popup.count > 0
            clip: true

            Flickable {
                id: notifFlick
                anchors.fill: parent
                contentHeight: notifListCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notifListCol
                    width: parent.width
                    spacing: 5

                    Repeater {
                        model: Notifs.model

                        Rectangle {
                            id: nrow
                            required property int index
                            required property string summary
                            required property string body
                            required property string applicationIconName
                            required property string applicationName
                            required property var created          // Date
                            required property var actionNames      // list<string> | undefined
                            required property var actionLabels     // list<string> | undefined
                            required property int urgency          // 1=low, 2=normal, 4=critical

                            readonly property bool isCritical: nrow.urgency === 4   // NM.Notifications.CriticalUrgency
                            readonly property bool hasActions: Array.isArray(nrow.actionNames) && nrow.actionNames.length > 0

                            width: notifListCol.width
                            // base 56px; add room for action buttons below
                            height: 56 + (nrow.hasActions ? (Math.ceil(nrow.actionNames.length / 2) * 28 + 8) : 0)
                            radius: Theme.shapeMd
                            clip: true

                            color: nrowMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            // ── critical urgency: colored left stripe ──
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                radius: 1
                                color: Theme.alert
                                visible: nrow.isCritical
                            }

                            // ── app icon ──
                            Kirigami.Icon {
                                id: nicon
                                anchors.left: parent.left
                                anchors.leftMargin: nrow.isCritical ? 13 : 10
                                anchors.top: parent.top
                                anchors.topMargin: 14
                                implicitWidth: 26
                                implicitHeight: 26
                                source: nrow.applicationIconName
                                visible: nrow.applicationIconName !== ""
                            }

                            // fallback icon when no app icon
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: nrow.isCritical ? 13 : 10
                                anchors.top: parent.top
                                anchors.topMargin: 14
                                visible: !nicon.visible
                                text: "notifications"
                                color: Theme.fgFaint
                                font.family: Theme.fontIcons
                                font.pixelSize: 20
                            }

                            // ── text: summary + body + app name ──
                            Column {
                                id: ntextCol
                                anchors.left: parent.left
                                anchors.leftMargin: (nrow.isCritical ? 13 : 10) + 26 + 10
                                anchors.right: ndismiss.left
                                anchors.rightMargin: 6
                                anchors.top: parent.top
                                anchors.topMargin: nrow.body !== "" ? 8 : 18
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: nrow.summary
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.bodySmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    width: parent.width
                                    text: nrow.body
                                    color: Theme.fgVariant
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width
                                    text: nrow.applicationName
                                    color: Theme.fgFaint
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: 0.3
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            // ── timestamp (top-right, left of dismiss) ──
                            Text {
                                id: nts
                                anchors.right: ndismiss.left
                                anchors.rightMargin: 6
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                text: popup.relativeTime(nrow.created)
                                color: Theme.fgFaint
                                font.family: Theme.font
                                font.pixelSize: Theme.labelSmall
                                // re-evaluate every 30s via tsRefresh
                                property bool _tick: tsRefresh.running
                            }

                            // ── dismiss button ──
                            Text {
                                id: ndismiss
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                text: "close"
                                color: dismissMa.containsMouse ? Theme.fg : Theme.outline
                                font.family: Theme.fontIcons
                                font.pixelSize: 16

                                MouseArea {
                                    id: dismissMa
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.dismissAt(nrow.index)
                                }
                            }

                            // ── action buttons ──
                            Flow {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: (nrow.isCritical ? 13 : 10) + 26 + 10
                                anchors.rightMargin: 10
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6
                                spacing: 6
                                visible: nrow.hasActions

                                Repeater {
                                    model: nrow.hasActions ? nrow.actionNames : []

                                    Rectangle {
                                        id: actionBtn
                                        required property int index
                                        required property string modelData   // actionName (id)

                                        readonly property string actionLabel: {
                                            if (Array.isArray(nrow.actionLabels) && nrow.actionLabels.length > actionBtn.index)
                                                return nrow.actionLabels[actionBtn.index];
                                            return actionBtn.modelData;
                                        }

                                        height: 22
                                        width: Math.min(actionLabelTxt.implicitWidth + 18, 130)
                                        radius: height / 2
                                        color: actionBtnMa.containsMouse ? Theme.surfaceTop : Theme.surfaceHigh
                                        border.width: 1
                                        border.color: Theme.outline

                                        Behavior on color {
                                            ColorAnimation { duration: Theme.durShort }
                                        }

                                        Text {
                                            id: actionLabelTxt
                                            anchors.centerIn: parent
                                            text: actionBtn.actionLabel
                                            color: Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.labelSmall
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, 112)
                                        }

                                        MouseArea {
                                            id: actionBtnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Notifs.model.invokeAction(
                                                    Notifs.model.index(nrow.index, 0),
                                                    actionBtn.modelData
                                                );
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: nrowMa
                                anchors.fill: parent
                                anchors.rightMargin: 36
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    try {
                                        if (Notifs.model && Notifs.model.invokeDefaultAction) {
                                            Notifs.model.invokeDefaultAction(Notifs.model.index(nrow.index, 0));
                                        }
                                    } catch (e) {}
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── bandeja vacía ──
        Column {
            width: parent.width
            spacing: 8
            visible: popup.count === 0
            topPadding: 16
            bottomPadding: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "notifications_none"
                color: Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 34
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Cfg.t("SIN NOTIFICACIONES")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                font.letterSpacing: Theme.labelSpacing
            }
        }
    }
}
