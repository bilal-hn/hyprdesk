import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property string tabId
    property string icon
    property string title
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 999
    color: active ? Theme.accent : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

    Behavior on color { ColorAnimation { duration: 180 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            font.family: Theme.iconFont
            font.pixelSize: 14
            color: root.active ? "#11111b" : (mouseArea.containsMouse ? "white" : Theme.subtle)
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Text {
            text: root.title
            font.family: Theme.textFont
            font.pixelSize: 10
            font.weight: root.active ? Font.Black : Font.Bold
            font.letterSpacing: 1
            color: root.active ? "#11111b" : (mouseArea.containsMouse ? "white" : Theme.subtle)
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
