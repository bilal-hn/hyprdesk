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

    Process { id: powerProc }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "SESSION MANAGEMENT"
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

    GridLayout {
        columns: 3
        Layout.fillWidth: true
        rowSpacing: 12
        columnSpacing: 12

        Repeater {
            model: [
                { icon: "󰌾", label: "LOCK",     cmd: "hyprlock", color: Theme.accent },
                { icon: "󰤄", label: "SUSPEND",  cmd: "systemctl suspend", color: Theme.warning },
                { icon: "󰗼", label: "LOGOUT",   cmd: "hyprctl dispatch exit", color: Theme.subtle },
                { icon: "󰑐", label: "REBOOT",   cmd: "reboot", color: "#89b4fa" },
                { icon: "󰐥", label: "SHUTDOWN", cmd: "shutdown now", color: Theme.error },
                { icon: "󰒲", label: "UEFI / BIOS", cmd: "systemctl reboot --firmware-setup", color: "#cba6f7" }
            ]

            delegate: Rectangle {
                id: btn
                Layout.fillWidth: true
                height: 95
                color: Theme.surface
                radius: 16
                border.color: mouseArea.containsMouse ? modelData.color : Theme.border
                border.width: mouseArea.containsMouse ? 1.5 : 1
                scale: mouseArea.pressed ? 0.96 : 1.0

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: 26
                        color: mouseArea.containsMouse ? modelData.color : Theme.fg
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Black
                        font.letterSpacing: 1
                        color: mouseArea.containsMouse ? "white" : Theme.subtle
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerProc.command = ["sh", "-c", modelData.cmd];
                        powerProc.running = true;
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
