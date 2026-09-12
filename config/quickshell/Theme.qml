pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Dynamic wallpaper-derived colors
    property color accent: "#81d5cc"
    property color bg: "#11111b"
    property color surface: "#181825"
    property color surfaceVariant: "#1e1e2e"
    property color border: "#313244"
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

    // Backend sync with wallpaper accent
    property var watcher: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/hyprdesk/theme.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.accent) theme.accent = data.accent;
                    if (data.bg) theme.bg = data.bg;
                    if (data.surface) theme.surface = data.surface;
                    if (data.border) theme.border = data.border;
                    if (data.fg) theme.fg = data.fg;
                    if (data.subtle) theme.subtle = data.subtle;
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
