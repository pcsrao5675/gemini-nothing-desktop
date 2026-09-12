import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.core as PlasmaCore
import QtCore
import "."

// píldora colapsada, la parte que vive dentro del panel de plasma
Item {
    id: root

    implicitWidth: Theme.collapsedWidth
    implicitHeight: Theme.collapsedHeight

    property var rootItem: null

    // ── Individual Below-Icon Popups ──
    property string activeDropdown: ""
    property var dropdownTarget: null

    function toggleDropdown(name, targetItem) {
        // If center expanded panel was open, close it first
        if (root.rootItem && root.rootItem.expanded) {
            root.rootItem.expanded = false;
            Cfg.currentOverlay = "";
            Cfg.requestedOverlay = "";
        }

        if (dropdownDialog.visible && root.activeDropdown === name) {
            dropdownDialog.visible = false;
            root.activeDropdown = "";
            root.dropdownTarget = null;
        } else {
            root.dropdownTarget = targetItem;
            root.activeDropdown = name;
            dropdownDialog.visualParent = targetItem;
            dropdownDialog.visible = true;
        }
    }

    function toggleOverlay(name) {
        // If any standalone dropdown is open, close it first
        if (dropdownDialog.visible) {
            dropdownDialog.visible = false;
            root.activeDropdown = "";
            root.dropdownTarget = null;
        }

        if (!root.rootItem) return;
        if (root.rootItem.expanded) {
            if (Cfg.currentOverlay === name) {
                // Same overlay was open: close the whole panel!
                root.rootItem.expanded = false;
                Cfg.currentOverlay = "";
                Cfg.requestedOverlay = "";
            } else {
                // Different overlay: switch to requested overlay!
                Cfg.requestedOverlay = name;
                Cfg.currentOverlay = name;
            }
        } else {
            // Panel was closed: open it with requested overlay!
            Cfg.requestedOverlay = name;
            Cfg.currentOverlay = name;
            root.rootItem.expanded = true;
        }
    }

    // ── Power & Charging State ──
    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
    }

    readonly property var bat: pmSource.data["Battery"] ?? ({})
    readonly property var ac: pmSource.data["AC Adapter"] ?? ({})
    readonly property bool isCharging: (bat["State"] === "Charging") || (ac["Plugged in"] === true)

    // ── Active State & Dual-Color Engine ──
    property bool geminiActive: false
    readonly property color nothingRed: Theme.alert     // Signature Nothing Red (#D71921)
    readonly property color geminiBlue: "#4DA3FF"      // Electric Gemini Blue (#4DA3FF)

    // When Gemini is active, color is Electric Blue; when charging, color is Nothing Red
    readonly property color activeColor: root.geminiActive ? root.geminiBlue : root.nothingRed
    readonly property bool animActive: root.geminiActive || root.isCharging

    property real wavePhase: 0.0

    onActiveColorChanged: auroraCanvas.requestPaint()

    Timer {
        id: waveTimer
        interval: 25 // ~40 FPS butter-smooth undulating motion
        running: root.animActive
        repeat: true
        onTriggered: {
            root.wavePhase += 0.035;
            auroraCanvas.requestPaint();
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "http://127.0.0.1:8765/active");
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        var text = xhr.responseText.trim();
                        var parts = text.split(":");
                        root.geminiActive = (parts[0] === "1");
                        if (parts.length > 1 && parts[1] !== "") {
                            var cmd = parts[1];
                            if (cmd === "wifi" && netItem) root.toggleDropdown("wifi", netItem);
                            else if (cmd === "audio" && volItem) root.toggleDropdown("audio", volItem);
                            else if (cmd === "brightness" && briItem) root.toggleDropdown("brightness", briItem);
                            else if (cmd === "power" && batItem) root.toggleDropdown("power", batItem);
                            else if (cmd === "media" && mini) root.toggleDropdown("media", mini);
                            else if (cmd === "close") {
                                dropdownDialog.visible = false;
                                root.activeDropdown = "";
                            }
                        }
                    }
                }
            };
            xhr.send();
        }
    }

    // ── Bottom Ambient Bloom ──
    Rectangle {
        id: auroraOuterMist
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.animActive ? 8 : 0
        color: root.activeColor
        opacity: root.animActive ? 0.25 : 0.0
        z: 2

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
        Behavior on color {
            ColorAnimation { duration: 250 }
        }
    }

    // ── Bottom Accent Line ──
    Rectangle {
        id: auroraBottomLine
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.animActive ? 1.5 : 1
        color: root.animActive ? root.activeColor : Theme.outline
        z: 4

        Behavior on color {
            ColorAnimation { duration: 250 }
        }
        Behavior on height {
            NumberAnimation { duration: 200 }
        }
    }

    // ── Edge-to-Edge Status Bar Surface ──
    Rectangle {
        id: pill
        anchors.fill: parent
        color: Theme.surface
        clip: true
        z: 1

        // ── Rising Aurora Wave Curtains across the entire empty bar space ──
        Canvas {
            id: auroraCanvas
            anchors.fill: parent
            z: 2
            opacity: root.animActive ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var p = root.wavePhase;
                var w = width;
                var h = height;
                var col = root.activeColor;
                var cr = Math.round(col.r * 255);
                var cg = Math.round(col.g * 255);
                var cb = Math.round(col.b * 255);

                // ── Wave 1: Deep Slow Swell (Background Curtain) ──
                var g1 = ctx.createLinearGradient(0, h, 0, 0);
                g1.addColorStop(0.0, "rgba(" + Math.round(cr * 0.8) + "," + Math.round(cg * 0.8) + "," + Math.round(cb * 0.8) + ", 0.45)");
                g1.addColorStop(0.6, "rgba(" + cr + "," + cg + "," + cb + ", 0.18)");
                g1.addColorStop(1.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.00)");
                ctx.fillStyle = g1;
                ctx.beginPath();
                ctx.moveTo(0, h);
                for (var x = 0; x <= w; x += 20) {
                    var y1 = h - (12 + 10 * Math.sin(x * 0.004 + p * 0.8) + 6 * Math.cos(x * 0.008 - p * 0.5));
                    ctx.lineTo(x, y1);
                }
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fill();

                // ── Wave 2: Middle Surging Curtain (Fills empty space upward) ──
                var g2 = ctx.createLinearGradient(0, h, 0, 0);
                g2.addColorStop(0.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.55)");
                g2.addColorStop(0.5, "rgba(" + Math.min(255, cr + 35) + "," + Math.min(255, cg + 35) + "," + Math.min(255, cb + 35) + ", 0.25)");
                g2.addColorStop(1.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.00)");
                ctx.fillStyle = g2;
                ctx.beginPath();
                ctx.moveTo(0, h);
                for (var x = 0; x <= w; x += 16) {
                    var y2 = h - (18 + 12 * Math.sin(x * 0.006 - p * 1.1) + 5 * Math.sin(x * 0.012 + p * 1.5));
                    ctx.lineTo(x, y2);
                }
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fill();

                // ── Wave 3: High Luminous Aurora Crest (Dancing light wisps) ──
                var g3 = ctx.createLinearGradient(0, h, 0, 0);
                g3.addColorStop(0.0, "rgba(" + Math.min(255, cr + 50) + "," + Math.min(255, cg + 50) + "," + Math.min(255, cb + 50) + ", 0.40)");
                g3.addColorStop(0.4, "rgba(" + Math.min(255, cr + 90) + "," + Math.min(255, cg + 90) + "," + Math.min(255, cb + 90) + ", 0.20)");
                g3.addColorStop(1.0, "rgba(" + cr + "," + cg + "," + cb + ", 0.00)");
                ctx.fillStyle = g3;
                ctx.beginPath();
                ctx.moveTo(0, h);
                for (var x = 0; x <= w; x += 20) {
                    var y3 = h - (24 + 9 * Math.sin(x * 0.009 + p * 1.4) + 4 * Math.cos(x * 0.018 - p * 2.0));
                    ctx.lineTo(x, y3);
                }
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fill();
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            z: 10

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWorkspaces
            }

            WeatherWidget {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWeather
            }

            MiniPlayer {
                id: mini
                rootItem: root.rootItem
                pill: root
                anchors.verticalCenter: parent.verticalCenter

                // entra creciendo suavemente cuando hay reproducción activa
                opacity: active ? 1 : 0
                scale: active ? 1 : 0.72
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                    }
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: 9.0
                        damping: 0.5
                        mass: 0.35
                        epsilon: 0.005
                    }
                }
            }

            // ── gemini ai button (nothing os style) ──
            Rectangle {
                id: geminiBtn
                anchors.verticalCenter: parent.verticalCenter
                width: geminiRow.implicitWidth + 16
                height: 24
                radius: height / 2
                color: root.geminiActive ? Qt.rgba(root.geminiBlue.r, root.geminiBlue.g, root.geminiBlue.b, 0.18) : (geminiMa.containsMouse ? Theme.surfaceHigh : "transparent")
                border.width: root.geminiActive ? 1 : (geminiMa.containsMouse ? 1 : 0)
                border.color: root.geminiActive ? root.geminiBlue : Theme.outline

                Behavior on color {
                    ColorAnimation { duration: Theme.durShort }
                }

                Row {
                    id: geminiRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Electric Blue active indicator dot
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "●"
                        color: root.geminiActive ? root.geminiBlue : Theme.fgDim
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GEMINI"
                        color: root.geminiActive ? Theme.fg : Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: Theme.labelMedium
                        font.letterSpacing: Theme.labelSpacing
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: geminiMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var p = StandardPaths.findExecutable("gemini-toggle.sh")
                        var pathStr = p ? p.toString().replace(/^file:\/\//, "") : ""
                        if (!pathStr || pathStr.indexOf("gemini-toggle.sh") === -1) {
                            pathStr = (StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "") + "/.local/bin/gemini-toggle.sh")
                        }
                        Exec.run(pathStr)
                    }
                }
            }
        }

        MouseArea {
            id: clockArea
            anchors.centerIn: parent
            width: clockItem.implicitWidth + 16
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            z: 10
            onClicked: {
                if (dropdownDialog.visible) {
                    dropdownDialog.visible = false;
                    root.activeDropdown = "";
                    root.dropdownTarget = null;
                }

                if (root.rootItem) {
                    if (root.rootItem.expanded) {
                        if (Cfg.currentOverlay !== "" && Cfg.currentOverlay !== "main") {
                            // Sub-overlay was open: clear it to reveal the clean full control panel
                            root.toggleOverlay("main");
                        } else {
                            // Clean full control panel was open: close it
                            root.rootItem.expanded = false;
                            Cfg.currentOverlay = "";
                            Cfg.requestedOverlay = "";
                        }
                    } else {
                        // Closed: open the clean full control panel
                        Cfg.requestedOverlay = "main";
                        Cfg.currentOverlay = "main";
                        root.rootItem.expanded = true;
                    }
                }
            }

            Clock {
                id: clockItem
                anchors.centerIn: parent
                visible: Cfg.showClock
            }
        }

        // grupo derecho: controles del sistema (red, volumen, brillo, batería, notificaciones)
        // MiniPlayer se ha movido al grupo izquierdo para aparecer junto a gemini/workspaces
        Row {
            id: rightGroup
            z: 10
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Row {
                id: rightRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Network {
                    id: netItem
                    rootItem: root.rootItem
                    pill: root
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Cfg.showNetwork
                }

                // ── volumen compact (exactamente igual que brillo) ──
                MouseArea {
                    id: volItem
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Cfg.showVolume
                    implicitWidth: volRow.implicitWidth + 8
                    implicitHeight: 28
                    width: implicitWidth
                    height: implicitHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Audio.toggleMute();
                        } else {
                            root.toggleDropdown("audio", volItem);
                        }
                    }
                    onWheel: wheel => {
                        wheel.accepted = true;
                        var dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                        if (dy > 0) {
                            Audio.step(5);
                        } else if (dy < 0) {
                            Audio.step(-5);
                        }
                    }

                    Row {
                        id: volRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Audio.muted || Audio.percent === 0 ? Icons.volMute : Audio.percent > 50 ? Icons.volHigh : Icons.volLow
                            color: Audio.muted ? Theme.outline : Audio.percent > 100 ? Theme.alert : Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Audio.percent
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelMedium
                        }
                    }
                }

                // ── brillo compact ──
                MouseArea {
                    id: briItem
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Brightness.available
                    implicitWidth: briRow.implicitWidth + 8
                    implicitHeight: 28
                    width: implicitWidth
                    height: implicitHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.toggleDropdown("brightness", briItem)
                    onWheel: wheel => {
                        wheel.accepted = true;
                        var dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                        if (dy > 0) {
                            Brightness.step(5);
                        } else if (dy < 0) {
                            Brightness.step(-5);
                        }
                    }

                    Row {
                        id: briRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Brightness.brightness < 30 ? "brightness_low"
                                : Brightness.brightness < 70 ? "brightness_medium"
                                : "brightness_high"
                            color: Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Brightness.brightness
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelMedium
                        }
                    }
                }

                Battery {
                    id: batItem
                    rootItem: root.rootItem
                    pill: root
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Cfg.showBattery && present
                }

                // ── notificaciones compact ──
                Item {
                    id: notifItem
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 28
                    implicitHeight: 28
                    width: implicitWidth
                    height: implicitHeight

                    Text {
                        id: notifBell
                        anchors.centerIn: parent
                        text: Notifs.muted ? "notifications_off" : "notifications"
                        color: Notifs.muted ? Theme.outline
                             : Notifs.count > 0 ? Theme.fg
                             : Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                    }

                    // red badge with unread count
                    Rectangle {
                        id: notifBadge
                        visible: Notifs.count > 0 && !Notifs.muted
                        anchors.top: notifBell.top
                        anchors.topMargin: -3
                        anchors.right: notifBell.right
                        anchors.rightMargin: -4
                        width: notifBadgeTxt.implicitWidth + 6
                        height: 14
                        radius: 7
                        color: Theme.alert

                        Text {
                            id: notifBadgeTxt
                            anchors.centerIn: parent
                            text: Notifs.count > 99 ? "99+" : Notifs.count
                            color: "#ffffff"
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleDropdown("notif", notifItem)
                    }
                }
            }
        }
    }


    // ── Dedicated Standalone Dropdown Dialog (opens directly below clicked icon) ──
    PlasmaCore.Dialog {
        id: dropdownDialog
        location: PlasmaCore.Types.TopEdge
        hideOnWindowDeactivate: true

        onVisibleChanged: {
            if (!visible) {
                root.activeDropdown = "";
                root.dropdownTarget = null;
            }
        }

        mainItem: Rectangle {
            id: dropdownBox
            width: root.activeDropdown === "media" ? 400 : (root.activeDropdown === "notif" ? 390 : 380)
            implicitHeight: dropdownLoader.item ? dropdownLoader.item.implicitHeight + 28 : 200
            height: implicitHeight
            radius: Theme.shapeLg
            color: Theme.surface
            border.width: 1
            border.color: Theme.outline
            clip: true

            Loader {
                id: dropdownLoader
                anchors.fill: parent
                anchors.margins: 14
                active: dropdownDialog.visible && root.activeDropdown !== ""

                sourceComponent: {
                    if (root.activeDropdown === "wifi")
                        return wifiComp;
                    if (root.activeDropdown === "audio")
                        return audioComp;
                    if (root.activeDropdown === "brightness")
                        return brightnessComp;
                    if (root.activeDropdown === "power")
                        return powerComp;
                    if (root.activeDropdown === "media")
                        return mediaComp;
                    if (root.activeDropdown === "notif")
                        return notifComp;
                    return null;
                }
            }

            Component {
                id: wifiComp
                ConnPanel {
                    mode: "wifi"
                    onClosed: {
                        dropdownDialog.visible = false;
                        root.activeDropdown = "";
                    }
                }
            }

            Component {
                id: audioComp
                AudioPanel {
                    onClosed: {
                        dropdownDialog.visible = false;
                        root.activeDropdown = "";
                    }
                }
            }

            Component {
                id: brightnessComp
                BrightnessPanel {
                    onClosed: {
                        dropdownDialog.visible = false;
                        root.activeDropdown = "";
                    }
                }
            }

            Component {
                id: powerComp
                PowerView {
                    onClosed: {
                        dropdownDialog.visible = false;
                        root.activeDropdown = "";
                    }
                }
            }

            Component {
                id: mediaComp
                MediaCard {
                    width: parent.width
                }
            }

            Component {
                id: notifComp
                NotifPanel {
                    onClosed: {
                        dropdownDialog.visible = false;
                        root.activeDropdown = "";
                    }
                }
            }
        }
    }
}
