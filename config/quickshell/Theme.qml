pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Dynamic accent color from wallpaper (Material 3)
    property color accent: "#81d5cc"

    // Transparency Controls (Adjust these values to your liking!)
    // 0.0 = completely transparent, 1.0 = completely solid
    property real bgOpacity: 0.65       // Overall dashboard window opacity
    property real cardOpacity: 0.35     // Transparency of all inner cards (Calendar, Notifications, System cards, etc.)

    // Backgrounds (using the controllable opacities)
    property color bg: Qt.rgba(0.067, 0.067, 0.106, bgOpacity)
    property color surface: Qt.rgba(0.094, 0.094, 0.145, cardOpacity)
    property color surfaceVariant: Qt.rgba(0.118, 0.118, 0.180, cardOpacity)
    property color border: Qt.rgba(1.0, 1.0, 1.0, 0.10)

    // Foreground / Accents
    property color fg: "#cdd6f4"
    property color subtle: "#6c7086"
    property color error: "#f38ba8"
    property color warning: "#f9e2af"
    property color success: "#a6e3a1"

    // Card styling
    property int cardRadius: 20
    property int pillRadius: 999

    // Font
    property string iconFont: "MesloLGS NF"
    property string textFont: "Inter"

    // Backend sync: ONLY syncs dynamic wallpaper accent color, never overwriting your opacity settings
    property var watcher: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/hyprdesk/theme.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.accent) theme.accent = data.accent;
                } catch (e) {}
            }
        }
    }

    property var timer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            watcher.running = false;
            watcher.running = true;
        }
    }
}
