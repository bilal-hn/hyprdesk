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

    // Floating Bottom-Center Dock / Strip
    Rectangle {
        id: pickerCard
        width: Math.min(parent.width - 60, 880)
        height: 236
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48

        color: Theme.bg
        radius: 20
        border.color: Theme.border
        border.width: 1
        clip: true // Guarantees nothing bleeds outside the dock boundary

        // Smooth slide-up & pop-in animation from bottom
        y: pickerWindow.shown ? (parent.height - height - 48) : (parent.height - height)
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
            spacing: 8

            // Top Header Bar
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
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

                Item { Layout.fillWidth: true }

                // Counter badge
                Rectangle {
                    color: Qt.rgba(255, 255, 255, 0.08)
                    radius: 10
                    implicitWidth: countText.implicitWidth + 14
                    implicitHeight: 20

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: (pickerWindow.currentIndex + 1) + " / " + (pickerWindow.wallpapers.length || 0)
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.subtle
                    }
                }
            }

            // Horizontal Cards Carousel (Clipped cleanly within the dock)
            ListView {
                id: wallpaperList
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                orientation: ListView.Horizontal
                spacing: 12
                clip: true // Strictly clips items to stay inside the dock boundaries

                model: pickerWindow.wallpapers
                currentIndex: pickerWindow.currentIndex

                highlightFollowsCurrentItem: true
                preferredHighlightBegin: width / 2 - 85
                preferredHighlightEnd: width / 2 + 85
                highlightRangeMode: ListView.StrictlyEnforceRange

                header: Item { width: Math.max(0, (wallpaperList.width - 170) / 2) }
                footer: Item { width: Math.max(0, (wallpaperList.width - 170) / 2) }

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
                    width: 170
                    height: 110
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isCurrent: index === pickerWindow.currentIndex
                    property bool hovered: cardMouseArea.containsMouse

                    scale: isCurrent ? 1.07 : (hovered ? 1.02 : 0.94)
                    z: isCurrent ? 10 : 1
                    opacity: isCurrent ? 1.0 : (hovered ? 0.90 : 0.60)

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 180 }
                    }

                    // Card Container
                    Item {
                        anchors.fill: parent

                        // Smooth rounded mask for true anti-aliased rounded corners
                        Rectangle {
                            id: cardMask
                            anchors.fill: parent
                            radius: 14
                            visible: false
                            layer.enabled: true
                        }

                        // Raw thumbnail image
                        Image {
                            id: cardImg
                            anchors.fill: parent
                            source: modelData.thumbnail ? ("file://" + modelData.thumbnail) : ("file://" + modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }

                        // MultiEffect mask: completely removes square edgy corners!
                        MultiEffect {
                            anchors.fill: parent
                            source: cardImg
                            maskEnabled: true
                            maskSource: cardMask
                        }

                        // Rounded Border overlay matching the mask radius
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

            // Bottom Info Bar: Selected Name & Key Hints
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                // Selected Wallpaper Name Badge
                Rectangle {
                    color: Qt.rgba(255, 255, 255, 0.08)
                    radius: 999
                    border.color: Qt.rgba(255, 255, 255, 0.10)
                    border.width: 1
                    implicitWidth: titleText.implicitWidth + 20
                    implicitHeight: 24

                    Text {
                        id: titleText
                        anchors.centerIn: parent
                        text: (pickerWindow.wallpapers.length > pickerWindow.currentIndex && pickerWindow.wallpapers[pickerWindow.currentIndex])
                              ? pickerWindow.wallpapers[pickerWindow.currentIndex].name
                              : ""
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.fg
                    }
                }

                Item { Layout.fillWidth: true }

                // Navigation Hints
                RowLayout {
                    spacing: 8
                    Text {
                        text: "← / → Browse"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        color: Theme.subtle
                    }
                    Text {
                        text: "•"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        color: Qt.rgba(255, 255, 255, 0.2)
                    }
                    Text {
                        text: "Enter Apply"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.accent
                    }
                    Text {
                        text: "•"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        color: Qt.rgba(255, 255, 255, 0.2)
                    }
                    Text {
                        text: "Esc Cancel"
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        color: Theme.subtle
                    }
                }
            }
        }
    }
}
