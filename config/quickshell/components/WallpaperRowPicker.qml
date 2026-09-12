import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

PanelWindow {
    id: pickerWindow

    property bool shown: false
    property var wallpapers: []
    property int currentIndex: 0

    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "hyprdesk-wallpaper-picker"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    function open() {
        shown = true;
        fetchProc.running = false;
        fetchProc.running = true;
        Qt.callLater(() => pickerCard.forceActiveFocus());
    }

    function close() {
        shown = false;
    }

    function toggle() {
        if (shown) {
            close();
        } else {
            open();
        }
    }

    function applyCurrent() {
        if (wallpapers.length > 0 && currentIndex >= 0 && currentIndex < wallpapers.length) {
            var wp = wallpapers[currentIndex];
            applyProc.command = [
                Quickshell.env("HOME") + "/Projects/Personal/hyprdesk/scripts/apply-wallpaper.sh",
                wp.path
            ];
            applyProc.running = true;
            close();
        }
    }

    // Process to fetch wallpapers list & thumbnails
    Process {
        id: fetchProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpapers.py", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var list = JSON.parse(text);
                    pickerWindow.wallpapers = list;
                    if (pickerWindow.currentIndex >= list.length) {
                        pickerWindow.currentIndex = 0;
                    }
                } catch (e) {
                    pickerWindow.wallpapers = [];
                }
            }
        }
    }

    // Process to apply wallpaper
    Process {
        id: applyProc
    }

    // Click backdrop to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: pickerWindow.close()
    }

    // Subtle dark backdrop overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: pickerWindow.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    // Floating Center Dock / Strip
    Rectangle {
        id: pickerCard
        width: Math.min(parent.width - 80, 1120)
        height: 330
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.bg
        radius: 24
        border.color: Theme.border
        border.width: 1

        // Smooth pop-in animation
        scale: pickerWindow.shown ? 1.0 : 0.94
        opacity: pickerWindow.shown ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        // Prevent click-through closing when clicking inside the dock
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Keyboard Controls
        focus: true
        Keys.onEscapePressed: pickerWindow.close()
        Keys.onLeftPressed: {
            if (pickerWindow.currentIndex > 0) {
                pickerWindow.currentIndex--;
            } else {
                pickerWindow.currentIndex = pickerWindow.wallpapers.length - 1;
            }
            wallpaperList.positionViewAtIndex(pickerWindow.currentIndex, ListView.Center);
        }
        Keys.onRightPressed: {
            if (pickerWindow.currentIndex < pickerWindow.wallpapers.length - 1) {
                pickerWindow.currentIndex++;
            } else {
                pickerWindow.currentIndex = 0;
            }
            wallpaperList.positionViewAtIndex(pickerWindow.currentIndex, ListView.Center);
        }
        Keys.onReturnPressed: pickerWindow.applyCurrent()
        Keys.onEnterPressed: pickerWindow.applyCurrent()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Top Header Bar
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰸉"
                        font.family: Theme.iconFont
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                    Text {
                        text: "WALLPAPERS"
                        font.family: Theme.textFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                }

                Item { Layout.fillWidth: true }

                // Counter badge
                Rectangle {
                    color: Qt.rgba(255, 255, 255, 0.08)
                    radius: 12
                    implicitWidth: countText.implicitWidth + 16
                    implicitHeight: 24

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: (pickerWindow.currentIndex + 1) + " / " + (pickerWindow.wallpapers.length || 0)
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.subtle
                    }
                }
            }

            // Horizontal Cards Carousel
            ListView {
                id: wallpaperList
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                orientation: ListView.Horizontal
                spacing: 16
                clip: false

                model: pickerWindow.wallpapers
                currentIndex: pickerWindow.currentIndex

                highlightFollowsCurrentItem: true
                preferredHighlightBegin: width / 2 - 120
                preferredHighlightEnd: width / 2 + 120
                highlightRangeMode: ListView.StrictlyEnforceRange

                // Mouse wheel horizontal scroll
                WheelHandler {
                    orientation: Qt.Horizontal | Qt.Vertical
                    onWheel: (event) => {
                        if (event.angleDelta.y < 0 || event.angleDelta.x > 0) {
                            pickerCard.Keys.onRightPressed(null);
                        } else if (event.angleDelta.y > 0 || event.angleDelta.x < 0) {
                            pickerCard.Keys.onLeftPressed(null);
                        }
                    }
                }

                delegate: Item {
                    id: cardItem
                    width: 240
                    height: 160
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isCurrent: index === pickerWindow.currentIndex
                    property bool hovered: cardMouseArea.containsMouse

                    scale: isCurrent ? 1.08 : (hovered ? 1.02 : 0.94)
                    z: isCurrent ? 10 : 1
                    opacity: isCurrent ? 1.0 : (hovered ? 0.92 : 0.60)

                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: Theme.surface
                        border.color: cardItem.isCurrent ? Theme.accent : (cardItem.hovered ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12))
                        border.width: cardItem.isCurrent ? 2 : 1
                        clip: true

                        // Wallpaper preview image
                        Image {
                            anchors.fill: parent
                            source: modelData.thumbnail ? ("file://" + modelData.thumbnail) : ("file://" + modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        // Subtle active border glow
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: "transparent"
                            border.color: Theme.accent
                            border.width: 1
                            opacity: cardItem.isCurrent ? 0.7 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pickerWindow.currentIndex = index;
                            pickerWindow.applyCurrent();
                        }
                    }
                }
            }

            // Bottom Info Bar: Selected Name & Key Hints
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                // Selected Wallpaper Name Badge
                Rectangle {
                    color: Qt.rgba(255, 255, 255, 0.08)
                    radius: 999
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    implicitWidth: titleText.implicitWidth + 24
                    implicitHeight: 28

                    Text {
                        id: titleText
                        anchors.centerIn: parent
                        text: (pickerWindow.wallpapers.length > pickerWindow.currentIndex && pickerWindow.wallpapers[pickerWindow.currentIndex])
                              ? pickerWindow.wallpapers[pickerWindow.currentIndex].name
                              : ""
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.fg
                    }
                }

                Item { Layout.fillWidth: true }

                // Navigation Hints
                RowLayout {
                    spacing: 10
                    Text {
                        text: "← / → Browse"
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        color: Theme.subtle
                    }
                    Text {
                        text: "•"
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        color: Qt.rgba(255, 255, 255, 0.2)
                    }
                    Text {
                        text: "Enter Apply"
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.accent
                    }
                    Text {
                        text: "•"
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        color: Qt.rgba(255, 255, 255, 0.2)
                    }
                    Text {
                        text: "Esc Cancel"
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        color: Theme.subtle
                    }
                }
            }
        }
    }
}
