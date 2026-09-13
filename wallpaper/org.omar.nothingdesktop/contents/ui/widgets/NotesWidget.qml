import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import ".."

Item {
    id: root

    property color accentColor: Theme.accent
    property string notesText: ""
    signal notesUpdated(string newContent)

    implicitWidth: 340
    implicitHeight: 220

    readonly property string notesFilePath: "$HOME/.local/share/nothing-desktop/quicknotes.txt"

    P5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd.startsWith("cat")) {
                const out = data["stdout"] ?? "";
                if (out && out.trim() !== "") {
                    root.notesText = out;
                    noteEditor.text = out;
                }
            }
        }
    }

    function saveToDisk(content) {
        // Ensure directory exists and write content safely via base64
        const b64 = Qt.btoa(content);
        execSource.connectSource(`mkdir -p "$HOME/.local/share/nothing-desktop" && echo "${b64}" | base64 -d > "$HOME/.local/share/nothing-desktop/quicknotes.txt"`);
    }

    Component.onCompleted: {
        execSource.connectSource(`[ -f "$HOME/.local/share/nothing-desktop/quicknotes.txt" ] && cat "$HOME/.local/share/nothing-desktop/quicknotes.txt" || true`);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.75)
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

                Item { width: 1; height: 1 }

                // Clear note action
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 24
                    height: 24
                    radius: 12
                    color: clearMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.color: Theme.outlineFaint
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconDelete
                        font.family: Theme.fontIcons
                        font.pixelSize: 13
                        color: clearMa.containsMouse ? Theme.alert : Theme.fgDim
                    }

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            noteEditor.text = "";
                            root.notesText = "";
                            root.notesUpdated("");
                            root.saveToDisk("");
                        }
                    }
                }
            }

            // Editable Text Area
            Rectangle {
                width: parent.width
                height: parent.height - 36
                radius: Theme.radiusMd
                color: Theme.surfaceAlt
                border.color: noteEditor.activeFocus ? root.accentColor : Theme.outlineFaint
                border.width: 1
                clip: true

                Behavior on border.color { ColorAnimation { duration: Theme.durShort } }

                QQC2.ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10

                    QQC2.TextArea {
                        id: noteEditor
                        text: root.notesText
                        color: Theme.fg
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                        background: null
                        selectByMouse: true
                        placeholderText: "// Type quick notes, checklist items, or code snippets here..."
                        placeholderTextColor: Theme.fgFaint

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
        interval: 600
        repeat: false
        onTriggered: {
            root.notesText = noteEditor.text;
            root.notesUpdated(noteEditor.text);
            root.saveToDisk(noteEditor.text);
        }
    }
}
