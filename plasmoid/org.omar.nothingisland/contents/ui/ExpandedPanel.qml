import QtQuick
import org.kde.kirigami as Kirigami
import "."

// interior de la isla abierta, mismo contenido y overlays que hyprland
Item {
    id: root

    implicitWidth: Theme.expandedWidth

    // plasma dibuja el popup del tamaño que le pidamos, sale del alto real del contenido
    implicitHeight: mainColumn.implicitHeight + 14 + 12 + (root.notifying ? Theme.notifStrip : 0)

    // vista activa: "", "wifi", "bt", "rec", "audio", "notif", "cal", "power"
    property string overlay: ""

    readonly property bool notifying: Notifs.current !== null

    function openOverlay(name) {
        if (name === "media" || name === "main" || name === "") {
            overlay = "";
            Cfg.currentOverlay = name || "main";
        } else {
            overlay = name;
            Cfg.currentOverlay = name;
        }
    }
    function closeOverlay() {
        overlay = "";
        Cfg.currentOverlay = "";
    }

    Component.onCompleted: {
        if (Cfg.requestedOverlay !== "") {
            root.openOverlay(Cfg.requestedOverlay);
            Cfg.requestedOverlay = "";
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (Cfg.requestedOverlay !== "") {
                root.openOverlay(Cfg.requestedOverlay);
                Cfg.requestedOverlay = "";
            }
        } else {
            root.closeOverlay();
            Cfg.requestedOverlay = "";
        }
    }



    Connections {
        target: Cfg
        function onRequestedOverlayChanged() {
            if (Cfg.requestedOverlay !== "") {
                root.openOverlay(Cfg.requestedOverlay);
                Cfg.requestedOverlay = "";
            }
        }
    }

    Rectangle {
        id: island
        anchors.fill: parent
        radius: Theme.expandedRadius
        color: Theme.surface
        clip: true

        // ── notificación entrante ──
        // franja fija abajo, se suma al alto del panel sin tapar lo de arriba
        Item {
            id: notifView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.notifStrip

            opacity: root.notifying ? 1 : 0
            visible: opacity > 0
            z: 3

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durShort
                }
            }

            transform: Translate {
                y: root.notifying ? 0 : 10
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: Theme.outline
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                spacing: 12

                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: (Notifs.current && Notifs.current.icon) ? Notifs.current.icon : ""
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: source !== ""
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 1

                    Text {
                        width: parent.width
                        text: (Notifs.current && Notifs.current.summary) ? Notifs.current.summary : ""
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.bodySmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: (Notifs.current && Notifs.current.body) ? Notifs.current.body : ""
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ── panel ──
        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }

            // se apaga y achica un poco cuando hay overlay encima
            // nada de layer.enabled + multieffect, revienta plasmashell (ver readme)
            Item {
                id: panelContent
                anchors.fill: parent

                opacity: root.overlay !== "" ? 0.45 : 1
                scale: root.overlay !== "" ? 0.97 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Column {
                    id: mainColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 10

                    // ── encabezado: hora grande + fecha ──
                    Item {
                        width: parent.width
                        height: 44

                        Timer {
                            id: panelClock
                            property date now: new Date()
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: now = new Date()
                        }

                        // hora y segundos separados, un solo Text no deja mezclar tamaños
                        // ancho fijo con dígitos en cero: en Doto no miden igual y el reloj bailaba
                        Row {
                            id: bigClock
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            TextMetrics {
                                id: moldeHora
                                font: horaTxt.font
                                text: horaTxt.text.replace(/[0-9]/g, "0")
                            }

                            Text {
                                id: horaTxt
                                anchors.bottom: parent.bottom
                                width: moldeHora.width
                                text: Qt.formatDateTime(panelClock.now, Cfg.fmtHora)
                                color: Theme.fg
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displayLarge
                                font.weight: Font.Bold
                            }

                            TextMetrics {
                                id: moldeSeg
                                font: segTxt.font
                                text: "00"
                            }

                            Text {
                                id: segTxt
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                width: moldeSeg.width
                                text: Qt.formatDateTime(panelClock.now, "ss")
                                color: Theme.fgDim
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displaySmall
                                font.weight: Font.Bold
                            }
                        }

                        // la fecha abre el calendario, mismo sistema de overlay que wifi/bt
                        Rectangle {
                            anchors.left: bigClock.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: fechaCol.implicitWidth + 20
                            height: 42
                            radius: Theme.shapeMd
                            color: fechaMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            Column {
                                id: fechaCol
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: Cfg.locale.toString(panelClock.now, "dddd, d MMMM").toUpperCase()
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelMedium
                                    font.letterSpacing: Theme.labelSpacing
                                }

                                Text {
                                    text: Cfg.t("CALENDARIO")
                                    color: fechaMa.containsMouse ? Theme.fgDim : Theme.fgFaint
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: Theme.labelSpacing
                                }
                            }

                            MouseArea {
                                id: fechaMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openOverlay("cal")
                            }
                        }
                    }

                    // ── reproductor ──
                    MediaCard {
                        width: parent.width
                    }

                    // ── red · bluetooth · sonido ──
                    StatusPills {
                        width: parent.width
                        onRequestPanel: mode => root.openOverlay(mode)
                    }

                    // ── grabación + medidores ──
                    Item {
                        width: parent.width
                        height: SysInfo.amdGpuAvailable ? 150 : 106

                        Rectangle {
                            id: fanCard
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.42
                            radius: Theme.shapeLg
                            color: Cooling.isTurbo ? Qt.alpha(Theme.alert, 0.12) : fanMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                            border.width: 1
                            border.color: Cooling.isTurbo ? Theme.alert : Theme.outline

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            MouseArea {
                                id: fanMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        root.openOverlay("fan");
                                    } else {
                                        Cooling.cycleProfile();
                                    }
                                }
                            }

                            // Fan circle icon with rotation animation
                            Rectangle {
                                id: fanRing
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 34
                                radius: height / 2
                                color: Cooling.isTurbo ? Qt.alpha(Theme.alert, 0.2) : "transparent"
                                border.width: 1.5
                                border.color: Cooling.accent

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.durShort
                                    }
                                }

                                Text {
                                    id: fanIcon
                                    anchors.centerIn: parent
                                    text: "mode_fan"
                                    color: Cooling.accent
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 20

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
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: Cfg.t("COOLING")
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: Theme.labelSpacing
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: Cooling.profileName
                                    color: Cooling.isTurbo ? Theme.alert : Theme.fg
                                    font.family: Theme.fontDots
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: Cooling.profileDesc
                                    color: Cooling.accent
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.4
                                    elide: Text.ElideRight
                                }
                            }

                            // 3 mini indicator dots at bottom-right
                            Row {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                spacing: 4

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Cooling.isQuiet ? Theme.secondary : Theme.containerHighest
                                }
                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Cooling.isBalanced ? Theme.primary : Theme.containerHighest
                                }
                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Cooling.isTurbo ? Theme.alert : Theme.containerHighest
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: fanCard.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            radius: Theme.shapeLg
                            color: Theme.containerHigh

                            Meters {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                            }
                        }
                    }

                    // ── modo café + acciones ──
                    QuickActions {
                        width: parent.width
                        onRequestNotifs: root.openOverlay("notif")
                        onRequestPower: root.openOverlay("power")
                        onRequestLauncher: root.openOverlay("apps")
                    }
                }
            }

        }

        // ── vistas superpuestas ──
        // cuelgan de la isla entera, no del recuadro interior, si no queda un borde sin oscurecer
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.overlay !== "" ? 0.55 : 0
            visible: opacity > 0
            z: 4

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeOverlay()
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)
            z: 5
            visible: overlayBox.opacity > 0

                Rectangle {
                    id: overlayBox
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.min(parent.height, overlayLoader.item ? overlayLoader.item.implicitHeight + 28 : parent.height)
                    radius: Theme.shapeLg
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    opacity: root.overlay !== "" ? 1 : 0
                    scale: root.overlay !== "" ? 1 : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
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
                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.durMedium
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }

                    Loader {
                        id: overlayLoader
                        anchors.fill: parent
                        anchors.margins: 14
                        active: root.overlay !== ""

                        sourceComponent: {
                            if (root.overlay === "fan")
                                return fanComp;
                            if (root.overlay === "rec")
                                return recComp;
                            if (root.overlay === "wifi" || root.overlay === "bt")
                                return connComp;
                            if (root.overlay === "audio")
                                return audioComp;
                            if (root.overlay === "brightness")
                                return brightnessComp;
                            if (root.overlay === "notif")
                                return notifComp;
                            if (root.overlay === "cal")
                                return calComp;
                            if (root.overlay === "power")
                                return powerComp;
                            if (root.overlay === "apps")
                                return appsComp;
                            return null;
                        }
                    }

                    Component {
                        id: fanComp
                        CoolingPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: recComp
                        RecordView {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: connComp
                        ConnPanel {
                            mode: root.overlay
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: audioComp
                        AudioPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: brightnessComp
                        BrightnessPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: notifComp
                        NotifPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: calComp
                        CalendarPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: powerComp
                        PowerView {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: appsComp
                        AppLauncher {
                            onClosed: root.closeOverlay()
                        }
                    }
                }
        }
    }
}
