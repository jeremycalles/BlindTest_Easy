#!/usr/bin/env python3
"""
Process AppIcon: remove gray border and enlarge inner graphic to 1024x1024.
"""
from PIL import Image
import sys

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    img = Image.open(path).convert("RGBA")
    w, h = img.size

    data = img.load()
    # Inner icon is dark (low luminance); gray frame is mid luminance. 
    # Only count pixels that are clearly part of the dark inner graphic.
    luminance_threshold = 100  # strict: only dark pixels (inner icon)
    margin = 0

    min_x, min_y = w, h
    max_x, max_y = 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = data[x, y]
            lum = (r * 299 + g * 587 + b * 114) // 1000
            # Inner graphic: dark (low lum) or strong color (heart glow)
            is_dark = lum < luminance_threshold
            has_color = max(abs(r - g), abs(g - b), abs(r - b)) > 40  # saturated
            if is_dark or (has_color and lum < 180):
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

    if min_x >= max_x or min_y >= max_y:
        # Fallback: center crop 70% (typical inner icon ratio)
        pad = int(0.15 * min(w, h))
        min_x, min_y = pad, pad
        max_x, max_y = w - pad, h - pad

    # Add a tiny padding so we don't clip rounded corners
    pad = max(1, int(0.02 * min(max_x - min_x, max_y - min_y)))
    min_x = max(0, min_x - pad)
    min_y = max(0, min_y - pad)
    max_x = min(w, max_x + pad)
    max_y = min(h, max_y + pad)

    cropped = img.crop((min_x, min_y, max_x, max_y))
    out = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    out_path = sys.argv[2] if len(sys.argv) > 2 else path.replace(".png", "_out.png")
    if out_path == path:
        out_path = path
    out.save(out_path)
    print(f"Cropped to ({min_x},{min_y})-({max_x},{max_y}), resized to 1024x1024, saved to {out_path}")

if __name__ == "__main__":
    main()
