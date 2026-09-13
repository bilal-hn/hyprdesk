import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import QtQuick.Effects
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
        color: Qt.rgba(0, 0, 0, 0.40)
        opacity: pickerWindow.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    // Floating Bottom-Center Dock
    Rectangle {
        id: pickerCard
        width: Math.min(parent.width - 60, 880)
        height: 200
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 42

        color: Theme.bg
        radius: 20
        border.color: Theme.border
        border.width: 1
        clip: true // Cleanly clips items within dock boundaries

        // Smooth slide-up & pop-in animation from bottom
        y: pickerWindow.shown ? (parent.height - height - 42) : (parent.height - height)
        scale: pickerWindow.shown ? 1.0 : 0.95
        opacity: pickerWindow.shown ? 1.0 : 0.0
        Behavior on y {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180 }
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
            anchors.margins: 14
            spacing: 6

            // Top Header Bar: ONLY "WALLPAPERS" header text
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "󰸉"
                    font.family: Theme.iconFont
                    font.pixelSize: 15
                    color: Theme.accent
                }
                Text {
                    text: "WALLPAPERS"
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
            }

            // Horizontal Cards Carousel with Dynamic Size Scale Animation
            ListView {
                id: wallpaperList
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: 16
                clip: true

                model: pickerWindow.wallpapers
                currentIndex: pickerWindow.currentIndex

                highlightFollowsCurrentItem: true
                preferredHighlightBegin: width / 2 - 88
                preferredHighlightEnd: width / 2 + 88
                highlightRangeMode: ListView.StrictlyEnforceRange

                header: Item { width: Math.max(0, (wallpaperList.width - 175) / 2) }
                footer: Item { width: Math.max(0, (wallpaperList.width - 175) / 2) }

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
                    width: 175
                    height: 112
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isCurrent: index === pickerWindow.currentIndex
                    property bool hovered: cardMouseArea.containsMouse

                    // Dynamic scale: Selected card grows to 1.18, unselected shrink to 0.88
                    scale: isCurrent ? 1.18 : (hovered ? 0.98 : 0.88)
                    z: isCurrent ? 10 : 1
                    opacity: isCurrent ? 1.0 : (hovered ? 0.85 : 0.50)

                    // Bouncy fluid animation when selecting/deselecting via arrow keys
                    Behavior on scale {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Card Container
                    Item {
                        anchors.fill: parent

                        // Smooth rounded mask for anti-aliased rounded corners
                        Rectangle {
                            id: cardMask
                            anchors.fill: parent
                            radius: 14
                            visible: false
                            layer.enabled: true
                        }

                        // Thumbnail image
                        Image {
                            id: cardImg
                            anchors.fill: parent
                            source: modelData.thumbnail ? ("file://" + modelData.thumbnail) : ("file://" + modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }

                        // MultiEffect mask: completely removes square edgy corners
                        MultiEffect {
                            anchors.fill: parent
                            source: cardImg
                            maskEnabled: true
                            maskSource: cardMask
                        }

                        // Rounded Border overlay: bright accent for current, subtle for others
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: cardItem.isCurrent ? Theme.accent : (cardItem.hovered ? Qt.rgba(255, 255, 255, 0.28) : Qt.rgba(255, 255, 255, 0.12))
                            border.width: cardItem.isCurrent ? 2 : 1
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
        }
    }
}
