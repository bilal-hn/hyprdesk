import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 14
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var networks: []
    property string selectedSsid: ""
    property bool isScanning: false
    property bool isAirplane: false

    function refreshNetworks() {
        isScanning = true;
        wifiProc.running = false;
        wifiProc.running = true;
    }

    Process {
        id: wifiProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi.py", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false;
                try {
                    root.networks = JSON.parse(text);
                } catch (e) {
                    root.networks = [];
                }
            }
        }
    }

    Process {
        id: connectProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshNetworks();
            }
        }
    }

    Process {
        id: rfkillProc
        onExited: root.refreshNetworks()
    }

    Component.onCompleted: refreshNetworks()

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text {
                text: "NETWORKS"
                color: Theme.accent
                font.pixelSize: 13
                font.letterSpacing: 2
                font.weight: Font.Black
            }
            Text {
                text: root.isAirplane ? "AIRPLANE MODE" : (root.networks.length + " IN RANGE")
                color: Theme.subtle
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1
            }
        }

        // Quick Scan / Refresh Button
        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: Theme.surface
            border.color: root.isScanning ? Theme.accent : Theme.border
            border.width: 1

            Text {
                id: refreshIcon
                anchors.centerIn: parent
                text: "󰑐"
                font.family: Theme.iconFont
                font.pixelSize: 16
                color: root.isScanning ? Theme.accent : Theme.fg
            }
            RotationAnimation {
                target: refreshIcon
                running: root.isScanning
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshNetworks()
            }
        }

        // Airplane Mode Toggle
        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: root.isAirplane ? Theme.error : Theme.surface
            border.color: root.isAirplane ? Theme.error : Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰀝"
                font.family: Theme.iconFont
                font.pixelSize: 16
                color: root.isAirplane ? "#11111b" : Theme.fg
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isAirplane = !root.isAirplane;
                    rfkillProc.command = ["rfkill", root.isAirplane ? "block" : "unblock", "wifi"];
                    rfkillProc.running = true;
                }
            }
        }
    }

    // Network List
    ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.networks
        spacing: 8
        clip: true

        delegate: Rectangle {
            id: netCard
            width: listView.width
            height: (root.selectedSsid === modelData.ssid) ? 120 : 54
            color: Theme.surface
            radius: 14
            border.color: modelData.active ? Theme.accent : (root.selectedSsid === modelData.ssid ? Theme.accent : Theme.border)
            border.width: modelData.active ? 1.5 : 1

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 10
                        color: modelData.active ? Qt.alpha(Theme.accent, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                        Text {
                            anchors.centerIn: parent
                            text: modelData.signal > 70 ? "󰤨" : (modelData.signal > 40 ? "󰤥" : "󰤢")
                            font.family: Theme.iconFont
                            font.pixelSize: 16
                            color: modelData.active ? Theme.accent : Theme.fg
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: modelData.ssid
                            color: "white"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.active ? "CONNECTED" : (modelData.security ? modelData.security : "OPEN")
                            color: modelData.active ? Theme.accent : Theme.subtle
                            font.pixelSize: 9
                            font.weight: Font.Black
                            font.letterSpacing: 0.5
                        }
                    }

                    // Action button
                    Rectangle {
                        width: modelData.active ? 70 : 34
                        height: 34
                        radius: 10
                        color: modelData.active ? Qt.alpha(Theme.error, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                        border.color: modelData.active ? Theme.error : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.active ? "DISCONNECT" : "󰅂"
                            font.family: modelData.active ? Theme.textFont : Theme.iconFont
                            font.pixelSize: modelData.active ? 9 : 14
                            font.weight: Font.Bold
                            color: modelData.active ? Theme.error : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) {
                                    connectProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi.py", "disconnect"];
                                    connectProc.running = true;
                                } else {
                                    if (modelData.security === "") {
                                        connectProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi.py", "connect", modelData.ssid];
                                        connectProc.running = true;
                                    } else {
                                        root.selectedSsid = (root.selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                                    }
                                }
                            }
                        }
                    }
                }

                // Password input expandable row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.selectedSsid === modelData.ssid && !modelData.active

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: Theme.border

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "white"
                            font.pixelSize: 12
                            echoMode: TextInput.Password

                            Text {
                                text: "Password..."
                                color: Theme.subtle
                                font.pixelSize: 12
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: !passInput.text && !passInput.activeFocus
                            }
                            onAccepted: {
                                connectProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi.py", "connect", modelData.ssid, passInput.text];
                                connectProc.running = true;
                                root.selectedSsid = "";
                            }
                        }
                    }

                    Rectangle {
                        width: 60
                        height: 36
                        radius: 8
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "JOIN"
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Black
                            color: "#11111b"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                connectProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi.py", "connect", modelData.ssid, passInput.text];
                                connectProc.running = true;
                                root.selectedSsid = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
