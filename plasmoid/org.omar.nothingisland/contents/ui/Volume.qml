import QtQuick
import "."

MouseArea {
    id: root

    property var rootItem: null
    readonly property int percent: Audio.percent
    readonly property bool muted: Audio.muted

    implicitWidth: row.implicitWidth + 8
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
            Cfg.requestedOverlay = "audio";
            if (root.rootItem) root.rootItem.expanded = true;
        }
    }

    onWheel: wheel => {
        wheel.accepted = true;
        var dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
        if (dy > 0) {
            Audio.step(0.05);
        } else if (dy < 0) {
            Audio.step(-0.05);
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted || root.percent === 0 ? Icons.volMute : root.percent > 50 ? Icons.volHigh : Icons.volLow
            color: root.muted ? Theme.outline : root.percent > 100 ? Theme.alert : Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium
        }
    }
}
