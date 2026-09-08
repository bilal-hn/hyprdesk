#!/usr/bin/env bash
#
# hyprdesk Waybar Controller
# Handles dual-state toggling (Compact Island <-> Expanded Control Bar)
# and visibility toggling (Show / Hide via SIGUSR1 + dynamic Hyprland top gap)
#

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprdesk"
STATE_FILE="$CACHE_DIR/waybar-mode"
VISIBILITY_FILE="$CACHE_DIR/waybar-visibility"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
BAR_TOP_GAP=44

mkdir -p "$CACHE_DIR"

get_current_mode() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "compact"
    fi
}

get_visibility() {
    if [ -f "$VISIBILITY_FILE" ]; then
        cat "$VISIBILITY_FILE"
    else
        echo "visible"
    fi
}

set_top_gap() {
    local gap="$1"
    hyprctl eval "hl.config({ general = { gaps_out = { top = $gap, right = 0, bottom = 0, left = 0 } } })" >/dev/null 2>&1
}

start_waybar() {
    local mode="$1"
    [ -n "$mode" ] || mode="$(get_current_mode)"
    echo "$mode" > "$STATE_FILE"
    echo "visible" > "$VISIBILITY_FILE"

    # Ensure dedicated empty space is preserved for the bar
    set_top_gap "$BAR_TOP_GAP"

    local cfg="$CONFIG_DIR/$mode/config.jsonc"
    local css="$CONFIG_DIR/$mode/style.css"

    if [ ! -f "$cfg" ]; then
        cfg="$CONFIG_DIR/config.jsonc"
        css="$CONFIG_DIR/style.css"
    fi

    pkill -x waybar 2>/dev/null
    while pgrep -x waybar >/dev/null; do sleep 0.05; done

    waybar -c "$cfg" -s "$css" >/dev/null 2>&1 &
}

toggle_mode() {
    local current="$(get_current_mode)"
    local next="compact"
    local anim="collapse"
    if [ "$current" = "compact" ]; then
        next="expanded"
        anim="expand"
    else
        next="compact"
        anim="collapse"
    fi

    # Ensure top gap is locked so windows NEVER move during transition
    set_top_gap "$BAR_TOP_GAP"

    # Hide the current waybar instantly
    pkill -SIGUSR1 -x waybar 2>/dev/null

    # Launch the morph animation overlay
    local morph=""
    if command -v bar-morph >/dev/null 2>&1; then
        morph="bar-morph"
    elif [ -x "$HOME/.local/bin/bar-morph" ]; then
        morph="$HOME/.local/bin/bar-morph"
    fi
    [ -n "$morph" ] && "$morph" "$anim" &

    # Wait for animation to reach ~60% (the bloom phase), then swap waybar underneath
    sleep 0.42

    start_waybar "$next"
}

toggle_hide() {
    local vis="$(get_visibility)"
    if [ "$vis" = "visible" ] && pgrep -x waybar >/dev/null; then
        echo "hidden" > "$VISIBILITY_FILE"
        # Remove top gap so windows fill up the screen
        set_top_gap 0
        pkill -SIGUSR1 -x waybar 2>/dev/null
    else
        echo "visible" > "$VISIBILITY_FILE"
        # Restore top gap for the bar
        set_top_gap "$BAR_TOP_GAP"
        if pgrep -x waybar >/dev/null; then
            pkill -SIGUSR1 -x waybar 2>/dev/null
        else
            start_waybar
        fi
    fi
}

case "$1" in
    toggle-mode)
        toggle_mode
        ;;
    toggle-hide)
        toggle_hide
        ;;
    start)
        start_waybar "$2"
        ;;
    restart)
        start_waybar
        ;;
    *)
        echo "Usage: $0 {toggle-mode|toggle-hide|start [compact|expanded]|restart}"
        exit 1
        ;;
esac
