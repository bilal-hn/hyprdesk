# hyprdesk

A minimal, sleek, and lightweight Hyprland desktop setup built with a **functionality-first** philosophy on CachyOS.

## Philosophy

- **Zero Unnecessary Bloat**: No heavy background daemons, webviews, or high RAM consumers.
- **Single-Folder Management**: The entire rice lives in this repository and can be pushed to GitHub.
- **Modular**: Built component-by-component, keeping configs clean and readable.

## Structure

```text
hyprdesk/
├── config/     # Application configurations (hypr, waybar, kitty, etc.)
├── themes/     # Curated color schemes and wallpapers
├── scripts/    # Lightweight management scripts (symlinking, switching)
└── README.md
```

## Quick Start

1. Symlink configurations to `~/.config/`:
   ```bash
   ./scripts/link.sh
   ```
