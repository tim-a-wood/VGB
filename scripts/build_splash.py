#!/usr/bin/env python3
"""Build LaunchLogo.png from the exact IconKitchen app icon + 'Checkpoint' text. Deterministic: no AI."""
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESOURCES_DIR = os.path.join(SCRIPT_DIR, "..", "VGB", "App", "Resources")
# Prefer project-local Pillow
sys.path.insert(0, os.path.join(RESOURCES_DIR, "pip_vendor"))
from PIL import Image, ImageDraw, ImageFont

ICON_PATH = os.path.join(RESOURCES_DIR, "IconKitchen-Output", "ios", "AppIcon~ios-marketing.png")
OUT_PATH = os.path.join(RESOURCES_DIR, "Assets.xcassets", "LaunchLogo.imageset", "LaunchLogo.png")

# Portrait: 400pt × 533pt @3x = 1200×1600 — output goes to Assets.xcassets/LaunchLogo.imageset (UIImageName in Info.plist)
W, H = 1200, 1600
ICON_SIZE = 520   # larger icon on splash
ICON_TOP = 200   # space from top to icon
GAP = 44         # gap between icon and text
TEXT_SIZE = 72   # larger, bolder-feel text

def main():
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon = icon.resize((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS)

    out = Image.new("RGB", (W, H), (0, 0, 0))
    x_center = (W - ICON_SIZE) // 2
    out.paste(icon, (x_center, ICON_TOP), icon)

    draw = ImageDraw.Draw(out)
    # Prefer bold/medium weight for subtle standout (index 1 = Bold in HelveticaNeue.ttc)
    font = None
    for font_path, index in [
        ("/System/Library/Fonts/HelveticaNeue.ttc", 1),
        ("/System/Library/Fonts/HelveticaNeue.ttc", 0),
        ("/System/Library/Fonts/Supplemental/Avenir Next.ttc", 0),
        ("/System/Library/Fonts/Helvetica.ttc", 0),
    ]:
        try:
            font = ImageFont.truetype(font_path, TEXT_SIZE, index=index)
            break
        except Exception:
            continue
    if font is None:
        font = ImageFont.load_default()

    text = "Checkpoint"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    text_y = ICON_TOP + ICON_SIZE + GAP
    draw.text(((W - tw) // 2, text_y - bbox[1]), text, fill=(255, 255, 255), font=font)

    out.save(OUT_PATH, "PNG")
    print("Saved", OUT_PATH)

if __name__ == "__main__":
    main()
