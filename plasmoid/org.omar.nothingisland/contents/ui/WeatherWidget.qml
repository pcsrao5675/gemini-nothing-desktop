import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."

MouseArea {
    id: root
    implicitWidth: row.implicitWidth + 4
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    visible: Weather.ready

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (cmd, data) => disconnectSource(cmd)
    }

    onClicked: {
        Weather.fetch();
    }

    onDoubleClicked: {
        execSource.connectSource("which kweather >/dev/null 2>&1 && kweather & || xdg-open https://wttr.in &");
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.icon
            color: root.containsMouse ? Theme.fg : Theme.tertiary
            font.family: Theme.fontIcons
            font.pixelSize: 18

            Behavior on color { ColorAnimation { duration: Theme.durShort } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.temp
            color: root.containsMouse ? Theme.fg : Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium

            Behavior on color { ColorAnimation { duration: Theme.durShort } }
        }
    }
}
