import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 14
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var devices: []
    property bool powered: false
    property bool discovering: false

    function refresh() {
        statusProc.running = false;
        statusProc.running = true;
        devProc.running = false;
        devProc.running = true;
    }

    Process {
        id: statusProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.py", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.powered = data.powered ?? false;
                    root.discovering = data.discovering ?? false;
                } catch (e) {}
            }
        }
    }

    Process {
        id: devProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.py", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(text);
                } catch (e) {
                    root.devices = [];
                }
            }
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }

    Component.onCompleted: refresh()

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text {
                text: "BLUETOOTH"
                color: Theme.accent
                font.pixelSize: 13
                font.letterSpacing: 2
                font.weight: Font.Black
            }
            Text {
                text: root.powered ? (root.discovering ? "SCANNING..." : "ACTIVE") : "DISABLED"
                color: Theme.subtle
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1
            }
        }

        // Scan button
        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: Theme.surface
            border.color: root.discovering ? Theme.accent : Theme.border
            border.width: 1
            visible: root.powered

            Text {
                id: scanIcon
                anchors.centerIn: parent
                text: "󰑐"
                font.family: Theme.iconFont
                font.pixelSize: 16
                color: root.discovering ? Theme.accent : Theme.fg
            }
            RotationAnimation {
                target: scanIcon
                running: root.discovering
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    actionProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.py", "toggle_scan"];
                    actionProc.running = true;
                }
            }
        }

        // Power Toggle
        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: root.powered ? Theme.accent : Theme.surface
            border.color: root.powered ? Theme.accent : Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.powered ? "󰂯" : "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: 16
                color: root.powered ? "#11111b" : Theme.error
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    actionProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.py", "toggle_power"];
                    actionProc.running = true;
                }
            }
        }
    }

    // Devices List
    ListView {
        id: devList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.devices
        spacing: 8
        clip: true

        delegate: Rectangle {
            width: devList.width
            height: 54
            color: Theme.surface
            radius: 14
            border.color: modelData.connected ? Theme.accent : Theme.border
            border.width: modelData.connected ? 1.5 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    color: modelData.connected ? Qt.alpha(Theme.accent, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon === "audio-headset" ? "󰋋" : "󰂯"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: modelData.connected ? Theme.accent : Theme.fg
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: modelData.name
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.connected ? "CONNECTED" : "PAIRED"
                        color: modelData.connected ? Theme.accent : Theme.subtle
                        font.pixelSize: 9
                        font.weight: Font.Black
                        font.letterSpacing: 0.5
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: modelData.connected ? Qt.alpha(Theme.error, 0.15) : Qt.alpha(Theme.accent, 0.15)
                    border.color: modelData.connected ? Theme.error : Theme.accent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.connected ? "󱘖" : "󰂱"
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        color: modelData.connected ? Theme.error : Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const act = modelData.connected ? "disconnect" : "connect";
                            actionProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.py", act, modelData.mac];
                            actionProc.running = true;
                        }
                    }
                }
            }
        }

        // Empty state
        ColumnLayout {
            anchors.centerIn: parent
            visible: root.devices.length === 0
            spacing: 8
            opacity: 0.5

            Text {
                text: "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: 48
                color: Theme.subtle
                Layout.alignment: Qt.AlignCenter
            }
            Text {
                text: root.powered ? "No paired devices" : "Bluetooth is turned off"
                color: Theme.subtle
                font.pixelSize: 12
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
