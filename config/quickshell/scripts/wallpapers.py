#!/usr/bin/env python3
import os
import sys
import json
import subprocess
from pathlib import Path

WALLPAPER_DIR = Path(os.environ.get("WALLPAPER_DIR", os.path.expanduser("~/Pictures/Wallpapers")))
CACHE_DIR = Path(os.path.expanduser("~/.cache/hyprdesk/wallpapers/thumbnails"))
CACHE_DIR.mkdir(parents=True, exist_ok=True)

EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

def clean_title(name: str) -> str:
    base = Path(name).stem
    # Replace separators
    cleaned = base.replace("_", " ").replace("-", " ")
    # Clean multiple spaces and title case
    words = [w.capitalize() for w in cleaned.split() if w]
    return " ".join(words) or base

def get_wallpapers():
    if not WALLPAPER_DIR.exists():
        return []

    items = []
    files = sorted([f for f in WALLPAPER_DIR.iterdir() if f.is_file() and f.suffix.lower() in EXTENSIONS])

    for f in files:
        thumb_name = f"{f.stem}_{f.stat().st_size}.jpg"
        thumb_path = CACHE_DIR / thumb_name

        # Generate thumbnail if not cached or out of date
        if not thumb_path.exists() or thumb_path.stat().st_mtime < f.stat().st_mtime:
            try:
                subprocess.run(
                    [
                        "magick",
                        str(f),
                        "-thumbnail", "400x250^",
                        "-gravity", "center",
                        "-extent", "400x250",
                        "-quality", "85",
                        str(thumb_path)
                    ],
                    check=True,
                    capture_output=True
                )
            except Exception:
                # Fallback to original image if magick fails
                thumb_path = f

        items.append({
            "name": clean_title(f.name),
            "filename": f.name,
            "path": str(f.resolve()),
            "thumbnail": str(thumb_path.resolve())
        })

    return items

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "list"
    if action == "list":
        print(json.dumps(get_wallpapers()))
