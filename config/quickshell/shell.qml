import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "./components"

Scope {
    id: root

    property string currentTab: "home"
    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
        if (root.shown) {
            Qt.callLater(() => mainContainer.forceActiveFocus());
        }
    }

    function open(tab: string) {
        if (tab && tab.length > 0) {
            root.currentTab = tab;
        }
        root.shown = true;
        Qt.callLater(() => mainContainer.forceActiveFocus());
    }

    function close() {
        root.shown = false;
    }

    IpcHandler {
        target: "dashboard"

        function toggle() {
            root.toggle();
        }

        function open(tab: string) {
            root.open(tab);
        }

        function close() {
            root.close();
        }
    }

    // The Dashboard Card Panel Window
    PanelWindow {
        id: dashboardWindow
        visible: root.shown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "hyprdesk-dashboard"

        implicitWidth: 680
        implicitHeight: 520
        anchors.top: true
        anchors.right: true
        margins.top: 48
        margins.right: 16
        color: "transparent"

        // Native focus grab: clears ONLY when clicking outside the window
        HyprlandFocusGrab {
            active: root.shown
            windows: [dashboardWindow]
            onCleared: root.close()
        }

        Rectangle {
            id: mainContainer
            anchors.fill: parent
            color: Theme.bg
            radius: 22
            border.color: Theme.border
            border.width: 1
            clip: true

            focus: true
            Keys.onEscapePressed: root.close()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // --- HORIZONTAL PILL TAB BAR ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    color: Qt.rgba(0, 0, 0, 0.25)
                    radius: 999
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        TabButton {
                            tabId: "home"
                            icon: "󰀉"
                            title: "HOME"
                            active: root.currentTab === "home"
                            onClicked: root.currentTab = "home"
                        }

                        TabButton {
                            tabId: "network"
                            icon: "󰤨"
                            title: "NETWORK"
                            active: root.currentTab === "network"
                            onClicked: root.currentTab = "network"
                        }

                        TabButton {
                            tabId: "bluetooth"
                            icon: "󰂯"
                            title: "BT"
                            active: root.currentTab === "bluetooth"
                            onClicked: root.currentTab = "bluetooth"
                        }

                        TabButton {
                            tabId: "audio"
                            icon: "󰕾"
                            title: "AUDIO"
                            active: root.currentTab === "audio"
                            onClicked: root.currentTab = "audio"
                        }

                        TabButton {
                            tabId: "system"
                            icon: "󰘚"
                            title: "SYSTEM"
                            active: root.currentTab === "system"
                            onClicked: root.currentTab = "system"
                        }

                        TabButton {
                            tabId: "power"
                            icon: "󰁹"
                            title: "POWER"
                            active: root.currentTab === "power"
                            onClicked: root.currentTab = "power"
                        }

                        TabButton {
                            tabId: "session"
                            icon: "󰐥"
                            title: "SESSION"
                            active: root.currentTab === "session"
                            onClicked: root.currentTab = "session"
                        }
                    }
                }

                // --- TAB CONTENT AREA ---
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    HomeContent {
                        anchors.fill: parent
                        visible: root.currentTab === "home"
                    }

                    NetworkContent {
                        anchors.fill: parent
                        visible: root.currentTab === "network"
                    }

                    BluetoothContent {
                        anchors.fill: parent
                        visible: root.currentTab === "bluetooth"
                    }

                    AudioContent {
                        anchors.fill: parent
                        visible: root.currentTab === "audio"
                    }

                    SystemContent {
                        anchors.fill: parent
                        visible: root.currentTab === "system"
                    }

                    PowerContent {
                        anchors.fill: parent
                        visible: root.currentTab === "power"
                    }

                    SessionContent {
                        anchors.fill: parent
                        visible: root.currentTab === "session"
                    }
                }
            }
        }
    }

    // Horizontal Row Wallpaper Picker
    WallpaperRowPicker {
        id: wallpaperPicker
    }

    IpcHandler {
        target: "wallpaper"

        function toggle() {
            wallpaperPicker.toggle();
        }

        function open() {
            wallpaperPicker.open();
        }

        function close() {
            wallpaperPicker.close();
        }
    }
}
