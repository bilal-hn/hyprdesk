#!/usr/bin/env bash
#
# hyprdesk: Fast, lightweight horizontal row wallpaper picker
#
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

# Ensure quickshell daemon is running
if ! pgrep -x quickshell >/dev/null 2>&1; then
    quickshell -d -p "$HOME/.config/quickshell" >/dev/null 2>&1 &
    sleep 0.25
fi

# Ensure awww-daemon is running for desktop transitions
if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    systemd-run --user --unit=awww-daemon awww-daemon --no-cache >/dev/null 2>&1 || true
fi

# Toggle the animated horizontal wallpaper picker
quickshell ipc call wallpaper toggle 2>/dev/null || quickshell -p "$HOME/.config/quickshell" ipc call wallpaper toggle 2>/dev/null || true
