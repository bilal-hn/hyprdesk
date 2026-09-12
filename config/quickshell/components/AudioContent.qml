import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 16
    Layout.fillWidth: true
    Layout.fillHeight: true

    property int outVol: 50
    property bool outMuted: false
    property int inVol: 50
    property bool inMuted: false

    function refresh() {
        audioProc.running = false;
        audioProc.running = true;
    }

    Process {
        id: audioProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/audio.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.outVol = d.output ?? 50;
                    root.outMuted = d.output_muted ?? false;
                    root.inVol = d.input ?? 50;
                    root.inMuted = d.input_muted ?? false;
                } catch (e) {}
            }
        }
    }

    Process {
        id: cmdProc
        onExited: root.refresh()
    }

    Component.onCompleted: refresh()

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "AUDIO CONTROL"
            color: Theme.accent
            font.pixelSize: 13
            font.letterSpacing: 2
            font.weight: Font.Black
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            opacity: 0.6
        }
    }

    // Two Audio Cards
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        // Output / Speaker Card
        Rectangle {
            Layout.fillWidth: true
            height: 170
            color: Theme.surface
            radius: 20
            border.color: root.outMuted ? Theme.error : Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.outMuted ? "󰝟" : (root.outVol > 60 ? "󰕾" : "󰖀")
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                        color: root.outMuted ? Theme.error : Theme.accent
                    }
                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: "OUTPUT"
                            color: "white"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.outMuted ? "MUTED" : (root.outVol + "%")
                            color: root.outMuted ? Theme.error : Theme.accent
                            font.pixelSize: 10
                            font.weight: Font.Black
                        }
                    }
                }

                Slider {
                    id: outSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.outVol
                    onMoved: {
                        cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/audio.py", "set_output", Math.round(outSlider.value).toString()];
                        cmdProc.running = true;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 10
                    color: root.outMuted ? Qt.alpha(Theme.error, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: root.outMuted ? Theme.error : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.outMuted ? "UNMUTE" : "MUTE"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Black
                        font.letterSpacing: 1
                        color: root.outMuted ? Theme.error : Theme.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/audio.py", "toggle_output_mute"];
                            cmdProc.running = true;
                        }
                    }
                }
            }
        }

        // Input / Microphone Card
        Rectangle {
            Layout.fillWidth: true
            height: 170
            color: Theme.surface
            radius: 20
            border.color: root.inMuted ? Theme.error : Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.inMuted ? "󰍭" : "󰍬"
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                        color: root.inMuted ? Theme.error : Theme.warning
                    }
                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: "INPUT"
                            color: "white"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.inMuted ? "MUTED" : (root.inVol + "%")
                            color: root.inMuted ? Theme.error : Theme.warning
                            font.pixelSize: 10
                            font.weight: Font.Black
                        }
                    }
                }

                Slider {
                    id: inSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.inVol
                    onMoved: {
                        cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/audio.py", "set_input", Math.round(inSlider.value).toString()];
                        cmdProc.running = true;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 10
                    color: root.inMuted ? Qt.alpha(Theme.error, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: root.inMuted ? Theme.error : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.inMuted ? "UNMUTE" : "MUTE"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Black
                        font.letterSpacing: 1
                        color: root.inMuted ? Theme.error : Theme.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/audio.py", "toggle_input_mute"];
                            cmdProc.running = true;
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
