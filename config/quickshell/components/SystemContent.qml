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

    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property int fs: 0
    property var coreUsages: []

    Process {
        id: resourceExec
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/resources.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.cpu = data.cpu ?? 0;
                    root.mem = data.mem ?? 0;
                    root.temp = data.temp ?? 0;
                    root.fs = data.fs ?? 0;
                    root.coreUsages = data.core_usages ?? [];
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            resourceExec.running = false;
            resourceExec.running = true;
        }
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "SYSTEM MONITOR"
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

    // Main 4 Stat Cards
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 12
        columnSpacing: 12

        Repeater {
            model: [
                { t: "PROCESSOR", v: root.cpu,  i: "", a: Theme.accent, s: "%" },
                { t: "MEMORY",    v: root.mem,  i: "", a: "#cba6f7", s: "%" },
                { t: "THERMAL",   v: root.temp, i: "", a: root.temp > 70 ? Theme.error : "#94e2d5", s: "°C" },
                { t: "STORAGE",   v: root.fs,   i: "󰋊", a: Theme.warning, s: "%" }
            ]

            delegate: Rectangle {
                id: cardRoot
                Layout.fillWidth: true
                height: 110
                color: Theme.surface
                radius: 20
                border.color: Theme.border
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    opacity: 0.05
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: modelData.a }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: modelData.i
                            font.family: Theme.iconFont
                            font.pixelSize: 20
                            color: modelData.a
                        }
                        Text {
                            text: modelData.t
                            color: Theme.subtle
                            font.pixelSize: 10
                            font.weight: Font.Black
                            font.letterSpacing: 1.5
                            Layout.fillWidth: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: modelData.v
                            color: "white"
                            font.pixelSize: 28
                            font.weight: Font.Black
                        }
                        Text {
                            text: modelData.s
                            color: modelData.a
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 4
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: "transparent"
                            border.color: Theme.border
                            border.width: 2.5
                            Rectangle {
                                anchors.fill: parent
                                radius: 19
                                color: Qt.alpha(modelData.a, 0.12)
                                border.color: modelData.a
                                border.width: 2.5
                                opacity: Math.min(modelData.v / 100.0, 1.0)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: Theme.iconFont
                                font.pixelSize: 12
                                color: modelData.a
                                visible: modelData.v < 90
                            }
                        }
                    }
                }
            }
        }
    }

    // Logical Cores
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "LOGICAL CORES"
            color: Theme.subtle
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1
        }

        GridLayout {
            columns: 4
            Layout.fillWidth: true
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: root.coreUsages
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 10
                    border.width: 1
                    border.color: modelData > 70 ? Qt.alpha(Theme.error, 0.4) : Theme.border
                    color: Theme.surface

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Theme.surface
                        }
                        GradientStop {
                            position: Math.max(0.0, 1.0 - (modelData / 100.0))
                            color: Theme.surface
                        }
                        GradientStop {
                            position: Math.max(0.0, 1.0 - (modelData / 100.0))
                            color: Qt.alpha(modelData > 70 ? Theme.error : Theme.accent, 0.20)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.alpha(modelData > 70 ? Theme.error : Theme.accent, 0.20)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: modelData > 70 ? Theme.error : Theme.fg
                        font.pixelSize: 11
                        font.weight: Font.Black
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
