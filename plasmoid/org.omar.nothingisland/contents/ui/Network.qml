import QtQuick
import "."

MouseArea {
    id: root

    property var rootItem: null
    property var pill: null

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    onClicked: {
        if (root.pill && root.pill.toggleDropdown) {
            root.pill.toggleDropdown("wifi", root);
        } else if (root.rootItem) {
            if (root.rootItem.expanded && Cfg.currentOverlay === "wifi") {
                root.rootItem.expanded = false;
                Cfg.currentOverlay = "";
                Cfg.requestedOverlay = "";
            } else {
                Cfg.requestedOverlay = "wifi";
                Cfg.currentOverlay = "wifi";
                root.rootItem.expanded = true;
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: !Net.connected ? Icons.wifiOff : Net.isWifi ? Icons.wifi : Icons.ethernet
            color: Net.connected ? Theme.fg : Theme.error
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: Net.isWifi
            text: Net.signal_
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium
        }
    }
}
