#!/usr/bin/env bash
#
# hyprdesk: Toggle or open dashboard tab
# Usage: toggle-dashboard.sh [home|network|bluetooth|audio|system|power|session]
#

TAB="${1:-}"

if ! pgrep -x quickshell >/dev/null 2>&1; then
    quickshell -d -p "$HOME/.config/quickshell" >/dev/null 2>&1 &
    sleep 0.25
fi

if [ -n "$TAB" ]; then
    quickshell ipc call dashboard open "$TAB" 2>/dev/null || quickshell -p "$HOME/.config/quickshell" ipc call dashboard open "$TAB" 2>/dev/null || true
else
    quickshell ipc call dashboard toggle 2>/dev/null || quickshell -p "$HOME/.config/quickshell" ipc call dashboard toggle 2>/dev/null || true
fi
