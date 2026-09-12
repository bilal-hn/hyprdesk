import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 140
    color: Theme.surface
    radius: 16
    border.color: Theme.border
    border.width: 1

    property var weatherData: null
    property bool loading: true

    function getIcon(code) {
        const c = parseInt(code);
        if (c === 113) return "󰖙";
        if (c === 116) return "󰖕";
        if (c === 119 || c === 122) return "󰖐";
        if ([143, 248, 260].includes(c)) return "󰖑";
        if ([176, 263, 266, 293, 296, 302, 308].includes(c)) return "󰖖";
        if ([200, 386, 389].includes(c)) return "󰖓";
        return "󰖐";
    }

    Process {
        id: weatherProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    root.weatherData = JSON.parse(text);
                } catch(e) {
                    root.weatherData = null;
                }
            }
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.loading = true;
            weatherProc.running = false;
            weatherProc.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "WEATHER"
                color: Theme.accent
                font.weight: Font.Black
                font.pixelSize: 11
                font.letterSpacing: 1
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || "Local"
                color: Theme.subtle
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14
            visible: !root.loading && root.weatherData

            // Current Weather Left
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: root.getIcon(root.weatherData?.current_condition?.[0]?.weatherCode)
                    font.family: Theme.iconFont
                    color: Theme.warning
                    font.pixelSize: 36
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: (root.weatherData?.current_condition?.[0]?.temp_C || "0") + "°C"
                    color: "white"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }
                Text {
                    text: root.weatherData?.current_condition?.[0]?.weatherDesc?.[0]?.value || "Clear"
                    color: Theme.subtle
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: 1
                height: 40
                color: Theme.border
            }

            // Forecast Right
            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: (root.weatherData?.weather || []).slice(1, 3)
                    delegate: RowLayout {
                        spacing: 8
                        Text {
                            text: Qt.formatDate(new Date(modelData.date), "ddd")
                            color: Theme.subtle
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.getIcon(modelData.hourly?.[4]?.weatherCode)
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                            color: Theme.fg
                        }
                        Text {
                            text: modelData.maxtempC + "°"
                            color: "white"
                            font.pixelSize: 10
                            font.weight: Font.Black
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
