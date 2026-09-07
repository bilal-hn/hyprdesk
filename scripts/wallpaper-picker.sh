#!/usr/bin/env bash
#
# hyprdesk Wallpaper Picker
# Combines hellpaper (3D interactive UI) with awww (Wayland animated wallpaper engine)
#

# Ensure ~/.local/bin is in PATH for graphical shortcuts
export PATH="$HOME/.local/bin:$PATH"

WALLPAPER_DIR="${1:-$HOME/Pictures/Wallpapers}"
HELLPAPER="${HOME}/.local/bin/hellpaper"

# Ensure awww-daemon is running
if ! pgrep -x awww-daemon >/dev/null; then
    systemd-run --user --unit=awww-daemon awww-daemon --no-cache
    sleep 0.5
fi

# Launch hellpaper picker and capture chosen wallpaper
SELECTED="$("$HELLPAPER" "$WALLPAPER_DIR")"

# Exit cleanly if user cancelled (ESC) or nothing was selected
[ -n "$SELECTED" ] || exit 0

# Smoothly animate the new wallpaper onto the desktop
awww img "$SELECTED" --transition-type wipe --transition-fps 60

# Desktop notification
notify-send "Wallpaper Changed" "$(basename "$SELECTED")" -i "$SELECTED"
