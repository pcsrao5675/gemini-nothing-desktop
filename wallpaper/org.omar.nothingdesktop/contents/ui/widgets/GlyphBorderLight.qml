import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.notificationmanager as NM
import ".."

Item {
    id: root
    anchors.fill: parent
    enabled: false // Never block clicks or pointer events

    property color accentColor: Theme.accent
    property color alertColor: Theme.alert
    property bool focusMode: false

    // State properties
    property bool isCharging: false
    property color currentColor: root.accentColor
    property real currentOpacity: 0.0

    // Power management for laptop charging detection
    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }

    readonly property var batData: pmSource.data["Battery"] ?? ({})
    onBatDataChanged: {
        root.isCharging = (batData["State"] ?? "") === "Charging";
    }

    // System notifications listener
    NM.Notifications {
        id: notifModel
        showExpired: false
        showDismissed: false
        showJobs: false
        sortMode: NM.Notifications.SortByDate
        groupMode: NM.Notifications.GroupDisabled
    }

    Connections {
        target: notifModel
        function onRowsInserted(parent, first) {
            // Suppress notification pulses if Focus Mode is active or DND is on
            if (root.focusMode || NM.Server.inhibited) {
                return;
            }
            root.triggerNotificationPulse();
        }
    }

    // Triggers
    function triggerNotificationPulse() {
        if (pomoFlashAnim.running) return; // Pomodoro flash has higher priority
        root.currentColor = root.accentColor;
        notifPulseAnim.restart();
    }

    function triggerPomodoroFlash() {
        notifPulseAnim.stop();
        chargeBreatheAnim.stop();
        root.currentColor = root.alertColor;
        pomoFlashAnim.restart();
    }

    // Breathing animation for charging
    SequentialAnimation {
        id: chargeBreatheAnim
        running: root.isCharging && !notifPulseAnim.running && !pomoFlashAnim.running
        loops: Animation.Infinite

        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.12
            to: 0.60
            duration: 1800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.60
            to: 0.12
            duration: 1800
            easing.type: Easing.InOutSine
        }
    }

    // Swift single pulse for new notification
    SequentialAnimation {
        id: notifPulseAnim
        running: false

        ScriptAction { script: root.currentColor = root.accentColor }
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.0
            to: 0.90
            duration: 220
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.90
            to: 0.0
            duration: 480
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                if (root.isCharging) {
                    chargeBreatheAnim.restart();
                }
            }
        }
    }

    // Warm red double-flash when Pomodoro completes
    SequentialAnimation {
        id: pomoFlashAnim
        running: false

        ScriptAction { script: root.currentColor = root.alertColor }
        // Flash 1
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 1.0
            to: 0.25
            duration: 250
            easing.type: Easing.InOutQuad
        }
        // Flash 2
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 0.25
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "currentOpacity"
            from: 1.0
            to: 0.0
            duration: 550
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                if (root.isCharging) {
                    root.currentColor = root.accentColor;
                    chargeBreatheAnim.restart();
                }
            }
        }
    }

    // Border Glow Visual Rendering
    Rectangle {
        id: borderStrip
        anchors.fill: parent
        color: "transparent"
        border.color: root.currentColor
        border.width: 2.5
        radius: 4
        opacity: (!root.isCharging && !notifPulseAnim.running && !pomoFlashAnim.running) ? 0.0 : root.currentOpacity
        visible: opacity > 0.005

        // Subtle inner glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1.5
            color: "transparent"
            border.color: Qt.rgba(root.currentColor.r, root.currentColor.g, root.currentColor.b, 0.4)
            border.width: 1.5
            radius: 3
        }
    }
}
