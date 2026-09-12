import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property date today: new Date()
    property date viewDate: new Date(today.getFullYear(), today.getMonth(), 1)

    function nextMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1); }
    function prevMonth() { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1); }

    Layout.fillWidth: true
    height: 190
    color: Theme.surface
    radius: 16
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // Month and Navigation
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: Qt.formatDateTime(root.viewDate, "MMMM yyyy").toUpperCase()
                color: "white"
                font.pixelSize: 12
                font.weight: Font.Black
                font.letterSpacing: 1
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 4
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        font.family: Theme.iconFont
                        color: Theme.accent
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        font.family: Theme.iconFont
                        color: Theme.accent
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }
        }

        // Days Header
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    text: modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.subtle
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }

        // Days Grid
        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                model: 35
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property int firstDay: new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), 1).getDay()
                    readonly property int daysInMonth: new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + 1, 0).getDate()
                    readonly property int dayNum: index - firstDay + 1
                    readonly property bool isCurrentMonth: dayNum >= 1 && dayNum <= daysInMonth
                    readonly property bool isToday: isCurrentMonth &&
                        dayNum === root.today.getDate() &&
                        root.viewDate.getMonth() === root.today.getMonth() &&
                        root.viewDate.getFullYear() === root.today.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        radius: 10
                        color: isToday ? Theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: isCurrentMonth ? dayNum : ""
                            color: isToday ? "#11111b" : (isCurrentMonth ? Theme.fg : "transparent")
                            font.pixelSize: 10
                            font.weight: isToday ? Font.Black : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
