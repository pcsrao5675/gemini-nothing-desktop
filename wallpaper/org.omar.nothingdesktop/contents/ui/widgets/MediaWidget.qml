import QtQuick
import org.kde.plasma.private.mpris as Mpris
import ".."

Item {
    id: root

    property color accentColor: Theme.accent

    implicitWidth: 360
    implicitHeight: 140

    Mpris.Mpris2Model {
        id: mprisModel
    }

    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasMedia: player !== null
    readonly property string trackTitle: player?.track || "NO MEDIA PLAYING"
    readonly property string artistName: player?.artist || "NOTHING OS DESKTOP"
    readonly property string albumArt: player?.artUrl || ""
    readonly property bool isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.Playing

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            // Album Artwork Card (Click to raise media player)
            Rectangle {
                width: 110
                height: 110
                radius: Theme.radiusMd
                color: Theme.surfaceAlt
                border.color: artMa.containsMouse ? root.accentColor : Theme.outlineFaint
                border.width: 1
                clip: true

                Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

                Image {
                    anchors.fill: parent
                    source: root.albumArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: root.albumArt !== ""
                }

                // Fallback glyph
                Text {
                    anchors.centerIn: parent
                    visible: root.albumArt === ""
                    text: "album"
                    font.family: Theme.fontIcons
                    font.pixelSize: 42
                    color: Theme.fgFaint
                }

                MouseArea {
                    id: artMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player && root.player.raise) {
                            root.player.raise();
                        }
                    }
                }
            }

            // Track Details & Controls
            Column {
                width: parent.width - 110 - 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Track Title
                Text {
                    width: parent.width
                    text: root.trackTitle
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                }

                // Artist Name
                Text {
                    width: parent.width
                    text: root.artistName
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    color: Theme.fgDim
                    elide: Text.ElideRight
                }

                // Interactive MPRIS Controls Row
                Row {
                    spacing: 12
                    anchors.left: parent.left
                    anchors.topMargin: 4

                    // Previous Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                        border.color: Theme.outlineFaint
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconSkipPrev
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: Theme.fg
                        }

                        MouseArea {
                            id: prevMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player) root.player.previous()
                        }
                    }

                    // Play / Pause Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: playMa.containsMouse ? Qt.darker(root.accentColor, 1.1) : root.accentColor

                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? Theme.iconPause : Theme.iconPlay
                            font.family: Theme.fontIcons
                            font.pixelSize: 20
                            color: "#000000"
                        }

                        MouseArea {
                            id: playMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player) root.player.playPause()
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                        border.color: Theme.outlineFaint
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconSkipNext
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: Theme.fg
                        }

                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player) root.player.next()
                        }
                    }
                }
            }
        }
    }
}
