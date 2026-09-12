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

# Extract dynamic color palette from wallpaper and sync with Waybar
if command -v noctalia >/dev/null 2>&1; then
    # Auto-detect scheme: if grayscale / monochrome, use m3-monochrome; otherwise use vibrant for true reds/oranges/greens
    SCHEME="vibrant"
    if command -v magick >/dev/null 2>&1; then
        SAT=$(magick "$SELECTED" -colorspace HSL -channel G -separate -format "%[mean]" info: 2>/dev/null || echo "10000")
        if awk "BEGIN {exit !($SAT < 2000)}"; then
            SCHEME="m3-monochrome"
        fi
    fi
    PALETTE="$(noctalia theme "$SELECTED" --scheme "$SCHEME" --dark 2>/dev/null)"
    PRIMARY="$(echo "$PALETTE" | grep '"primary":' | head -1 | cut -d'"' -f4)"
    if [ -n "$PRIMARY" ]; then
        HEX="${PRIMARY#\#}"
        R=$((16#${HEX:0:2}))
        G=$((16#${HEX:2:2}))
        B=$((16#${HEX:4:2}))
        mkdir -p "$HOME/.cache/hyprdesk"
        echo "$R, $G, $B" > "$HOME/.cache/hyprdesk/accent_color"
        cat <<EOF > "$HOME/Projects/Personal/hyprdesk/config/waybar/colors.css"
/* Auto-generated palette from wallpaper */
@define-color accent $PRIMARY;
@define-color bg-glass rgba(14, 21, 19, 0.88);
@define-color fg #dee4e0;
@define-color subtle #89938f;
@define-color border-glass rgba($R, $G, $B, 0.20);
EOF
        # Sync colors with hyprlock
        cat <<EOF > "$HOME/.cache/hyprdesk/hyprlock-colors.conf"
\$accent = rgb($R, $G, $B)
\$accentAlpha = $HEX
\$base = rgb(14, 21, 19)
\$text = rgb(222, 228, 224)
\$subtle = rgb(137, 147, 143)
\$surface = rgba(14, 21, 19, 0.75)
EOF
        # Sync colors with quickshell dashboard
        cat <<EOF > "$HOME/.cache/hyprdesk/theme.json"
{
  "accent": "$PRIMARY",
  "r": $R,
  "g": $G,
  "b": $B,
  "bg": "#11111b",
  "surface": "#181825",
  "surfaceVariant": "#1e1e2e",
  "border": "#313244",
  "fg": "#cdd6f4",
  "subtle": "#6c7086"
}
EOF
        # Reload Waybar styles
        pkill -SIGUSR2 -x waybar 2>/dev/null || true
        # Update Hyprland window borders dynamically
        hyprctl eval "hl.config({ general = { col = { active_border = 'rgba(${HEX}ff)', inactive_border = 'rgba(${HEX}33)' } } })" 2>/dev/null || true
    fi
    # Cache wallpaper path for hyprlock
    cp -f "$SELECTED" "$HOME/.cache/hyprdesk/current_wallpaper" 2>/dev/null || true
    # Update Noctalia's wallpaper theme so Control Center & panels sync immediately
    noctalia msg wallpaper-set "$SELECTED" 2>/dev/null || true
fi

# Desktop notification
notify-send "Wallpaper Changed" "$(basename "$SELECTED")" -i "$SELECTED"
