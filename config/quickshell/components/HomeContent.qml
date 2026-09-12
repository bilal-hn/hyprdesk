import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."

RowLayout {
    id: root
    spacing: 14
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Left Column: Notifications + Media Player
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 360
        spacing: 12

        // Notifications Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surface
            radius: 16
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "NOTIFICATIONS"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        font.weight: Font.Black
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 6
                        color: Qt.alpha(Theme.accent, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: (typeof Notifications !== "undefined" && Notifications.list) ? Notifications.list.length : "0"
                            color: Theme.accent
                            font.pixelSize: 10
                            font.weight: Font.Black
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "CLEAR"
                        color: clearMouse.containsMouse ? Theme.error : Theme.subtle
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof Notifications !== "undefined" && Notifications.list) {
                                    for (let i = Notifications.list.length - 1; i >= 0; i--) {
                                        Notifications.list[i].dismiss();
                                    }
                                }
                            }
                        }
                    }
                }

                // Notification List or Empty State
                ListView {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: (typeof Notifications !== "undefined") ? Notifications.list : []

                    delegate: Rectangle {
                        width: notifList.width
                        height: 50
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.color: Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 8
                                color: Qt.alpha(Theme.accent, 0.15)
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    font.family: Theme.iconFont
                                    font.pixelSize: 14
                                    color: Theme.accent
                                }
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.summary || "Notification"
                                    color: "white"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.body || ""
                                    color: Theme.subtle
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: "󰅖"
                                font.family: Theme.iconFont
                                font.pixelSize: 12
                                color: Theme.subtle
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.dismiss()
                                }
                            }
                        }
                    }

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: !notifList.count
                        spacing: 4
                        opacity: 0.5
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰂛"
                            font.family: Theme.iconFont
                            font.pixelSize: 32
                            color: Theme.subtle
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All caught up"
                            color: Theme.subtle
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }

        // Media Player
        MprisPlayer {
            Layout.fillWidth: true
        }
    }

    // Right Column: Calendar & Weather
    ColumnLayout {
        Layout.preferredWidth: 260
        Layout.fillHeight: true
        spacing: 12

        CalendarWidget {
            Layout.fillWidth: true
        }

        WeatherWidget {
            Layout.fillWidth: true
        }
    }
}
