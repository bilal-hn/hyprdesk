#!/usr/bin/env bash
#
# hyprdesk symlink script
# Links folders from hyprdesk/config/ into ~/.config/
#

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$REPO_DIR/config"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> hyprdesk: Linking configurations to $TARGET_DIR"

mkdir -p "$TARGET_DIR"

for item in "$CONFIG_DIR"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    target="$TARGET_DIR/$name"

    # If target exists and is not a symlink, back it up
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        backup="$target.bak.$(date +%s)"
        echo "  [backup] Backing up existing $target -> $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        rm "$target"
    fi

    echo "  [link]   $name -> $target"
    ln -s "$item" "$target"
done

# Build custom helpers if needed
if [ -f "$REPO_DIR/scripts/bar-morph.c" ]; then
    mkdir -p "$HOME/.local/bin"
    echo "==> hyprdesk: Compiling bar-morph animator..."
    gcc -O3 "$REPO_DIR/scripts/bar-morph.c" -o "$HOME/.local/bin/bar-morph" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0) -lm 2>/dev/null || true
fi

echo "==> Done! All available configs linked."
