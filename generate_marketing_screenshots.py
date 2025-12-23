#!/usr/bin/env python3
"""
Generate App Store marketing screenshots with device frames and promotional text.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Directories
BASE_DIR = "/Users/sebastiandoyle/Documents/Local Programming/Claude Code Goes Wild/Duplicate Photos/CleanSnap"
SCREENSHOTS_DIR = os.path.join(BASE_DIR, "Screenshots")
MARKETING_DIR = os.path.join(BASE_DIR, "MarketingScreenshots")

# Marketing text for each screenshot
MARKETING_CONTENT = [
    {
        "file": "01_onboarding_welcome.png",
        "headline": "Free Up Storage",
        "subheadline": "Find and remove duplicate photos instantly",
        "bg_color": (0, 122, 255)  # Blue
    },
    {
        "file": "02_onboarding_duplicates.png",
        "headline": "Smart Detection",
        "subheadline": "AI-powered duplicate photo finder",
        "bg_color": (88, 86, 214)  # Purple
    },
    {
        "file": "03_onboarding_vault.png",
        "headline": "Private Vault",
        "subheadline": "Hide photos behind a secure PIN",
        "bg_color": (255, 149, 0)  # Orange
    },
    {
        "file": "04_onboarding_cleanup.png",
        "headline": "One-Tap Cleanup",
        "subheadline": "Delete unwanted files instantly",
        "bg_color": (52, 199, 89)  # Green
    },
]

def create_marketing_screenshot(screenshot_path, headline, subheadline, bg_color, output_path):
    """Create a marketing screenshot with text overlay."""

    # App Store screenshot dimensions for 6.7" display (iPhone 15 Pro Max)
    CANVAS_WIDTH = 1290
    CANVAS_HEIGHT = 2796

    # Create canvas with gradient background
    canvas = Image.new('RGB', (CANVAS_WIDTH, CANVAS_HEIGHT), bg_color)
    draw = ImageDraw.Draw(canvas)

    # Add gradient effect
    for y in range(CANVAS_HEIGHT):
        # Darken towards bottom
        factor = 1 - (y / CANVAS_HEIGHT * 0.3)
        r = int(bg_color[0] * factor)
        g = int(bg_color[1] * factor)
        b = int(bg_color[2] * factor)
        draw.line([(0, y), (CANVAS_WIDTH, y)], fill=(r, g, b))

    draw = ImageDraw.Draw(canvas)

    # Load and resize screenshot
    if os.path.exists(screenshot_path):
        screenshot = Image.open(screenshot_path)

        # Scale screenshot to fit nicely
        max_width = int(CANVAS_WIDTH * 0.85)
        max_height = int(CANVAS_HEIGHT * 0.6)

        # Calculate scale
        scale = min(max_width / screenshot.width, max_height / screenshot.height)
        new_width = int(screenshot.width * scale)
        new_height = int(screenshot.height * scale)

        screenshot = screenshot.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Add rounded corners to screenshot (simulate device frame)
        # Create mask for rounded corners
        mask = Image.new('L', screenshot.size, 0)
        mask_draw = ImageDraw.Draw(mask)
        corner_radius = 40
        mask_draw.rounded_rectangle([(0, 0), screenshot.size], radius=corner_radius, fill=255)

        # Apply shadow
        shadow_offset = 20
        shadow = Image.new('RGBA', (new_width + shadow_offset * 2, new_height + shadow_offset * 2), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow)
        shadow_draw.rounded_rectangle(
            [(shadow_offset, shadow_offset), (new_width + shadow_offset, new_height + shadow_offset)],
            radius=corner_radius,
            fill=(0, 0, 0, 80)
        )

        # Position screenshot (centered horizontally, lower portion of canvas)
        x = (CANVAS_WIDTH - new_width) // 2
        y = CANVAS_HEIGHT - new_height - 150

        # Paste shadow first
        canvas.paste(shadow, (x - shadow_offset, y - shadow_offset), shadow)

        # Paste screenshot with mask
        canvas.paste(screenshot, (x, y), mask)

    # Add text
    try:
        # Try to use SF Pro or fallback to system font
        headline_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 100)
        subheadline_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 50)
    except:
        headline_font = ImageFont.load_default()
        subheadline_font = ImageFont.load_default()

    # Draw headline
    headline_bbox = draw.textbbox((0, 0), headline, font=headline_font)
    headline_width = headline_bbox[2] - headline_bbox[0]
    headline_x = (CANVAS_WIDTH - headline_width) // 2
    headline_y = 200

    # Add text shadow
    draw.text((headline_x + 3, headline_y + 3), headline, font=headline_font, fill=(0, 0, 0, 128))
    draw.text((headline_x, headline_y), headline, font=headline_font, fill=(255, 255, 255))

    # Draw subheadline
    subheadline_bbox = draw.textbbox((0, 0), subheadline, font=subheadline_font)
    subheadline_width = subheadline_bbox[2] - subheadline_bbox[0]
    subheadline_x = (CANVAS_WIDTH - subheadline_width) // 2
    subheadline_y = headline_y + 130

    draw.text((subheadline_x + 2, subheadline_y + 2), subheadline, font=subheadline_font, fill=(0, 0, 0, 80))
    draw.text((subheadline_x, subheadline_y), subheadline, font=subheadline_font, fill=(255, 255, 255, 230))

    # Save
    canvas.save(output_path, 'PNG', quality=95)
    print(f"Created: {output_path}")

def main():
    # Create marketing directory
    os.makedirs(MARKETING_DIR, exist_ok=True)

    for i, content in enumerate(MARKETING_CONTENT, 1):
        screenshot_path = os.path.join(SCREENSHOTS_DIR, content["file"])
        output_path = os.path.join(MARKETING_DIR, f"marketing_{i:02d}_{content['headline'].lower().replace(' ', '_')}.png")

        create_marketing_screenshot(
            screenshot_path,
            content["headline"],
            content["subheadline"],
            content["bg_color"],
            output_path
        )

    print(f"\nMarketing screenshots created in: {MARKETING_DIR}")
    print(f"Total: {len(MARKETING_CONTENT)} screenshots")

if __name__ == "__main__":
    main()
