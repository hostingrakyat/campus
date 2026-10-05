"""Downloads the UI icon set (Lucide, ISC license) into data/icons.json.

The game rasterizes these SVGs at runtime (Kit.ico), so they stay crisp at any size and are
tinted per button. Pinned version for reproducible builds. Usage: python tools/gen_icons.py
"""
import json
import pathlib
import re
import urllib.request

VERSION = "1.52.0"
ICONS = [
    # actions
    "play", "compass", "shuffle", "fast-forward", "skip-forward", "x", "check", "arrow-left", "arrow-right",
    "rotate-ccw", "refresh-cw", "plus", "ban", "save", "log-out", "door-open", "settings", "menu", "house",
    "sparkles", "gift", "tv", "shopping-cart", "shopping-bag", "store", "shirt", "briefcase", "graduation-cap",
    "trophy", "life-buoy", "gamepad-2", "languages", "file-pen", "swords", "book-open", "gem", "frown",
    "arrow-left-right", "wallet", "hand-coins", "landmark", "users", "user", "lock",
    # stats & info
    "zap", "brain", "calendar-check", "clipboard-list", "scroll-text", "layers", "triangle-alert", "newspaper",
    "sunrise", "sun", "moon", "sofa", "coins", "heart", "star", "clock", "map-pin", "message-circle",
    # shop & wardrobe tabs
    "cup-soda", "scissors", "crown", "glasses", "backpack", "user-plus", "external-link",
]


def main() -> None:
    root = pathlib.Path(__file__).resolve().parent.parent
    out = {}
    for name in ICONS:
        url = f"https://unpkg.com/lucide-static@{VERSION}/icons/{name}.svg"
        svg = urllib.request.urlopen(url, timeout=30).read().decode("utf-8")
        svg = re.sub(r"<!--.*?-->", "", svg, flags=re.S)
        svg = re.sub(r'\s+class="[^"]*"', "", svg)
        # White strokes so the game can tint them; a touch heavier to read well on small phones.
        svg = svg.replace('stroke="currentColor"', 'stroke="#ffffff"').replace('stroke-width="2"', 'stroke-width="2.4"')
        out[name] = " ".join(svg.split())
    (root / "data" / "icons.json").write_text(json.dumps({"license": f"Lucide v{VERSION}, ISC License, https://lucide.dev/license", "icons": out}, indent=0), encoding="utf-8")
    print(f"wrote {len(out)} icons")


if __name__ == "__main__":
    main()
