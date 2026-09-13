import QtQuick
import QtQuick.Controls as QQC2
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property string notesText: ""
    signal notesUpdated(string newContent)

    implicitWidth: 320
    implicitHeight: 200

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        radius: Theme.radiusLg
        border.color: Theme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            Row {
                width: parent.width
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iconNotes
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: root.accentColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "QUICK NOTES"
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Theme.fgDim
                }
            }

            // Editable Text Area
            Rectangle {
                width: parent.width
                height: parent.height - 30
                radius: Theme.radiusMd
                color: Theme.surfaceAlt
                border.color: Theme.outlineFaint
                border.width: 1
                clip: true

                QQC2.ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8

                    QQC2.TextArea {
                        id: noteEditor
                        text: root.notesText
                        color: Theme.fg
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                        background: null
                        selectByMouse: true

                        onTextChanged: {
                            if (noteEditor.text !== root.notesText) {
                                saveDebounce.restart();
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 1000
        repeat: false
        onTriggered: root.notesUpdated(noteEditor.text)
    }
}
