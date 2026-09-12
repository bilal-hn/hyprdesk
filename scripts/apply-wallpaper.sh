#!/usr/bin/env bash
#
# hyprdesk: Fast, hardware-accelerated wallpaper application and dynamic theme sync
#
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

SELECTED="${1:-}"
[ -n "$SELECTED" ] || exit 0
[ -f "$SELECTED" ] || exit 1

# Ensure awww-daemon is running
if ! pgrep -x awww-daemon >/dev/null; then
    systemd-run --user --unit=awww-daemon awww-daemon --no-cache
    sleep 0.3
fi

# Close the wallpaper picker overlay immediately so user sees desktop transition
quickshell ipc call wallpaper close 2>/dev/null || quickshell -p "$HOME/.config/quickshell" ipc call wallpaper close 2>/dev/null || true

# Apply wallpaper with buttery smooth fade transition
awww img "$SELECTED" --transition-type fade --transition-duration 1.2

# Cache current wallpaper path for hyprlock
mkdir -p "$HOME/.cache/hyprdesk"
cp -f "$SELECTED" "$HOME/.cache/hyprdesk/current_wallpaper" 2>/dev/null || true

# Instant dynamic theme extraction using downscaled thumbnail (takes < 0.08s)
THUMB_CACHE="$HOME/.cache/hyprdesk/wallpapers/thumbnails"
FILENAME=$(basename "$SELECTED")
THUMB="$THUMB_CACHE/${FILENAME%.*}_thumb.jpg"
mkdir -p "$THUMB_CACHE"

if [ ! -f "$THUMB" ]; then
    magick "$SELECTED" -thumbnail 300x200^ -gravity center -extent 300x200 "$THUMB" 2>/dev/null || THUMB="$SELECTED"
fi

if command -v noctalia >/dev/null 2>&1; then
    SCHEME="vibrant"
    if command -v magick >/dev/null 2>&1; then
        SAT=$(magick "$THUMB" -colorspace HSL -channel G -separate -format "%[mean]" info: 2>/dev/null || echo "10000")
        if awk "BEGIN {exit !($SAT < 2000)}"; then
            SCHEME="m3-monochrome"
        fi
    fi

    PALETTE="$(noctalia theme "$THUMB" --scheme "$SCHEME" --dark 2>/dev/null)"
    PRIMARY="$(echo "$PALETTE" | grep '"primary":' | head -1 | cut -d'"' -f4)"
    
    if [ -n "$PRIMARY" ]; then
        HEX="${PRIMARY#\#}"
        R=$((16#${HEX:0:2}))
        G=$((16#${HEX:2:2}))
        B=$((16#${HEX:4:2}))

        echo "$R, $G, $B" > "$HOME/.cache/hyprdesk/accent_color"
        
        # Sync Waybar colors
        cat <<EOF > "$HOME/Projects/Personal/hyprdesk/config/waybar/colors.css"
/* Auto-generated palette from wallpaper */
@define-color accent $PRIMARY;
@define-color bg-glass rgba(14, 21, 19, 0.88);
@define-color fg #dee4e0;
@define-color subtle #89938f;
@define-color border-glass rgba($R, $G, $B, 0.20);
EOF

        # Sync Hyprlock colors
        cat <<EOF > "$HOME/.cache/hyprdesk/hyprlock-colors.conf"
\$accent = rgb($R, $G, $B)
\$accentAlpha = $HEX
\$base = rgb(14, 21, 19)
\$text = rgb(222, 228, 224)
\$subtle = rgb(137, 147, 143)
\$surface = rgba(14, 21, 19, 0.75)
EOF

        # Sync Quickshell Dashboard colors
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

        # Reload Waybar styles live
        pkill -SIGUSR2 -x waybar 2>/dev/null || true

        # Update Hyprland window borders live
        hyprctl eval "hl.config({ general = { col = { active_border = 'rgba(${HEX}ff)', inactive_border = 'rgba(${HEX}33)' } } })" 2>/dev/null || true
    fi

    # Update Noctalia background theme
    noctalia msg wallpaper-set "$SELECTED" 2>/dev/null || true
fi

notify-send -a "Wallpaper" "Wallpaper Updated" "$(basename "$SELECTED")" -i "$THUMB"
