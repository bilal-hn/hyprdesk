import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    id: root
    spacing: 16
    Layout.fillWidth: true
    Layout.fillHeight: true

    property int batteryPerc: 100
    property string batteryState: "fully-charged"
    property string currentProfile: "balanced"

    function refresh() {
        powerProc.running = false;
        powerProc.running = true;
    }

    Process {
        id: powerProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/power.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.batteryPerc = d.percentage ?? 100;
                    root.batteryState = d.state ?? "fully-charged";
                    root.currentProfile = d.profile ?? "balanced";
                } catch (e) {}
            }
        }
    }

    Process {
        id: setProfileProc
        onExited: root.refresh()
    }

    Component.onCompleted: refresh()

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "POWER & BATTERY"
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

    // Battery Card
    Rectangle {
        Layout.fillWidth: true
        height: 110
        color: Theme.surface
        radius: 20
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            Rectangle {
                width: 54
                height: 54
                radius: 16
                color: Qt.alpha(Theme.accent, 0.15)
                border.color: Theme.accent
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.batteryState === "charging" ? "󰂄" : (root.batteryPerc > 80 ? "󰁹" : (root.batteryPerc > 40 ? "󰁿" : "󰁼"))
                    font.family: Theme.iconFont
                    font.pixelSize: 26
                    color: Theme.accent
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: "BATTERY LEVEL"
                    color: Theme.subtle
                    font.pixelSize: 10
                    font.weight: Font.Black
                    font.letterSpacing: 1.5
                }
                RowLayout {
                    spacing: 4
                    Text {
                        text: root.batteryPerc
                        color: "white"
                        font.pixelSize: 32
                        font.weight: Font.Black
                    }
                    Text {
                        text: "%"
                        color: Theme.accent
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4
                    }
                }
                Text {
                    text: root.batteryState.toUpperCase()
                    color: root.batteryState === "charging" ? Theme.success : Theme.subtle
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }
    }

    // Power Profiles Section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: "SYSTEM PROFILE"
            color: Theme.subtle
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { id: "performance", label: "PERFORMANCE", icon: "󰓅", color: "#f38ba8" },
                    { id: "balanced",    label: "BALANCED",    icon: "󰾅", color: Theme.accent },
                    { id: "power-saver", label: "POWER SAVER", icon: "󰌪", color: "#a6e3a1" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    radius: 14
                    color: (root.currentProfile === modelData.id) ? Theme.accent : Theme.surface
                    border.color: (root.currentProfile === modelData.id) ? Theme.accent : Theme.border
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 180 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                            color: (root.currentProfile === modelData.id) ? "#11111b" : Theme.fg
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            font.family: Theme.textFont
                            font.pixelSize: 9
                            font.weight: Font.Black
                            font.letterSpacing: 0.5
                            color: (root.currentProfile === modelData.id) ? "#11111b" : Theme.subtle
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            setProfileProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/power.py", "set_profile", modelData.id];
                            setProfileProc.running = true;
                            root.currentProfile = modelData.id;
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
