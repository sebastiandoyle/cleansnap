#!/usr/bin/env python3
"""
Generate CleanSnap app icon programmatically.
Creates a clean, modern icon with overlapping photos and a sparkle effect.
"""

import math

def create_svg_icon():
    """Create SVG app icon."""
    svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Background gradient -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#007AFF"/>
      <stop offset="100%" style="stop-color:#5856D6"/>
    </linearGradient>

    <!-- Card shadow -->
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="20" flood-opacity="0.3"/>
    </filter>

    <!-- Sparkle gradient -->
    <linearGradient id="sparkleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFD60A"/>
      <stop offset="100%" style="stop-color:#FF9500"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="1024" height="1024" rx="224" fill="url(#bgGradient)"/>

  <!-- Back photo card -->
  <g transform="translate(512, 480) rotate(-12) translate(-512, -480)">
    <rect x="280" y="250" width="400" height="460" rx="24" fill="white" filter="url(#shadow)" opacity="0.7"/>
    <rect x="300" y="270" width="360" height="300" rx="12" fill="#E5E5EA"/>
  </g>

  <!-- Middle photo card -->
  <g transform="translate(512, 500) rotate(6) translate(-512, -500)">
    <rect x="300" y="260" width="400" height="460" rx="24" fill="white" filter="url(#shadow)" opacity="0.85"/>
    <rect x="320" y="280" width="360" height="300" rx="12" fill="#D1D1D6"/>
  </g>

  <!-- Front photo card -->
  <rect x="320" y="280" width="400" height="460" rx="24" fill="white" filter="url(#shadow)"/>
  <rect x="340" y="300" width="360" height="300" rx="12" fill="#F2F2F7"/>

  <!-- Photo placeholder icon -->
  <g transform="translate(520, 450)">
    <circle cx="0" cy="-30" r="35" fill="#C7C7CC"/>
    <ellipse cx="0" cy="50" rx="60" ry="40" fill="#C7C7CC"/>
  </g>

  <!-- Checkmark circle -->
  <circle cx="680" cy="680" r="100" fill="#34C759"/>
  <path d="M620 680 L660 720 L740 640" stroke="white" stroke-width="24" stroke-linecap="round" stroke-linejoin="round" fill="none"/>

  <!-- Sparkles -->
  <g fill="url(#sparkleGradient)">
    <!-- Top right sparkle -->
    <path d="M820 180 L835 220 L875 235 L835 250 L820 290 L805 250 L765 235 L805 220 Z"/>
    <!-- Small sparkle -->
    <path d="M750 320 L758 340 L778 348 L758 356 L750 376 L742 356 L722 348 L742 340 Z" transform="scale(0.7) translate(350, 100)"/>
  </g>
</svg>'''
    return svg

def svg_to_png_using_cairosvg(svg_content, output_path, size=1024):
    """Convert SVG to PNG using cairosvg if available."""
    try:
        import cairosvg
        cairosvg.svg2png(bytestring=svg_content.encode(), write_to=output_path,
                        output_width=size, output_height=size)
        return True
    except ImportError:
        return False

def svg_to_png_using_pillow(output_path, size=1024):
    """Create PNG using Pillow (fallback method)."""
    try:
        from PIL import Image, ImageDraw

        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Background with rounded corners (approximated)
        corner_radius = int(size * 0.22)

        # Draw gradient background (simplified to solid gradient simulation)
        for y in range(size):
            for x in range(size):
                # Check if inside rounded rect
                in_rect = True
                if x < corner_radius and y < corner_radius:
                    if (x - corner_radius) ** 2 + (y - corner_radius) ** 2 > corner_radius ** 2:
                        in_rect = False
                elif x > size - corner_radius and y < corner_radius:
                    if (x - (size - corner_radius)) ** 2 + (y - corner_radius) ** 2 > corner_radius ** 2:
                        in_rect = False
                elif x < corner_radius and y > size - corner_radius:
                    if (x - corner_radius) ** 2 + (y - (size - corner_radius)) ** 2 > corner_radius ** 2:
                        in_rect = False
                elif x > size - corner_radius and y > size - corner_radius:
                    if (x - (size - corner_radius)) ** 2 + (y - (size - corner_radius)) ** 2 > corner_radius ** 2:
                        in_rect = False

                if in_rect:
                    # Gradient from blue to purple
                    t = (x + y) / (2 * size)
                    r = int(0 + t * 88)
                    g = int(122 - t * 36)
                    b = int(255 - t * 41)
                    img.putpixel((x, y), (r, g, b, 255))

        # Draw photo cards (simplified)
        # Back card
        card_color = (255, 255, 255, 180)
        draw.rounded_rectangle([280, 250, 680, 710], radius=24, fill=card_color)

        # Front card
        card_color = (255, 255, 255, 255)
        draw.rounded_rectangle([320, 280, 720, 740], radius=24, fill=card_color)

        # Photo area
        draw.rounded_rectangle([340, 300, 700, 600], radius=12, fill=(242, 242, 247, 255))

        # Green checkmark circle
        draw.ellipse([580, 580, 780, 780], fill=(52, 199, 89, 255))

        # Checkmark (simplified)
        draw.line([(620, 680), (660, 720), (740, 640)], fill=(255, 255, 255, 255), width=24)

        img.save(output_path, 'PNG')
        return True
    except ImportError:
        return False

def create_png_with_sips(svg_path, png_path, size=1024):
    """Use macOS sips to convert (requires SVG support or use as fallback)."""
    import subprocess
    import os

    # First try using qlmanage to render
    try:
        subprocess.run(['qlmanage', '-t', '-s', str(size), '-o', '/tmp/', svg_path],
                      capture_output=True, timeout=10)
        tmp_png = f'/tmp/{os.path.basename(svg_path)}.png'
        if os.path.exists(tmp_png):
            subprocess.run(['mv', tmp_png, png_path])
            return True
    except:
        pass
    return False

def create_simple_png(output_path, size=1024):
    """Create a simple PNG icon using basic drawing."""
    try:
        from PIL import Image, ImageDraw

        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Create rounded rectangle background
        corner_radius = int(size * 0.22)

        # Draw rounded rectangle manually
        # Main rectangle parts
        draw.rectangle([corner_radius, 0, size - corner_radius, size], fill=(0, 122, 255, 255))
        draw.rectangle([0, corner_radius, size, size - corner_radius], fill=(0, 122, 255, 255))

        # Corners
        draw.ellipse([0, 0, corner_radius * 2, corner_radius * 2], fill=(0, 122, 255, 255))
        draw.ellipse([size - corner_radius * 2, 0, size, corner_radius * 2], fill=(0, 122, 255, 255))
        draw.ellipse([0, size - corner_radius * 2, corner_radius * 2, size], fill=(0, 122, 255, 255))
        draw.ellipse([size - corner_radius * 2, size - corner_radius * 2, size, size], fill=(0, 122, 255, 255))

        # Add gradient overlay (simulate by adding purple tint to bottom-right)
        overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        for i in range(size):
            alpha = int(80 * (i / size))
            overlay_draw.line([(i, 0), (i, size)], fill=(88, 86, 214, alpha))

        img = Image.alpha_composite(img, overlay)
        draw = ImageDraw.Draw(img)

        # Draw white photo cards
        # Back card (rotated effect - just offset)
        draw.rounded_rectangle([250, 220, 650, 680], radius=24, fill=(255, 255, 255, 200))

        # Middle card
        draw.rounded_rectangle([280, 250, 680, 710], radius=24, fill=(255, 255, 255, 230))

        # Front card
        draw.rounded_rectangle([320, 280, 720, 740], radius=24, fill=(255, 255, 255, 255))

        # Photo placeholder area
        draw.rounded_rectangle([350, 310, 690, 580], radius=12, fill=(242, 242, 247, 255))

        # Simple photo icon (mountain/sun)
        draw.ellipse([400, 360, 480, 440], fill=(199, 199, 204, 255))  # Sun
        draw.polygon([(380, 550), (520, 420), (660, 550)], fill=(174, 174, 178, 255))  # Mountain

        # Green checkmark circle
        cx, cy, r = 680, 680, 100
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(52, 199, 89, 255))

        # Checkmark
        draw.line([(620, 680), (665, 725)], fill=(255, 255, 255, 255), width=24)
        draw.line([(665, 725), (745, 635)], fill=(255, 255, 255, 255), width=24)

        # Sparkles (yellow stars)
        def draw_sparkle(cx, cy, size):
            points = []
            for i in range(8):
                angle = i * math.pi / 4
                r = size if i % 2 == 0 else size * 0.4
                x = cx + r * math.cos(angle - math.pi / 2)
                y = cy + r * math.sin(angle - math.pi / 2)
                points.append((x, y))
            draw.polygon(points, fill=(255, 214, 10, 255))

        draw_sparkle(820, 200, 50)
        draw_sparkle(880, 320, 30)

        img.save(output_path, 'PNG')
        print(f"Created icon at {output_path}")
        return True

    except ImportError as e:
        print(f"Pillow not available: {e}")
        return False

def main():
    import os

    script_dir = os.path.dirname(os.path.abspath(__file__))
    icon_path = os.path.join(script_dir, 'CleanSnap', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png')
    svg_path = os.path.join(script_dir, 'AppIcon.svg')

    # Create SVG
    svg_content = create_svg_icon()
    with open(svg_path, 'w') as f:
        f.write(svg_content)
    print(f"Created SVG at {svg_path}")

    # Try to create PNG
    success = False

    # Try cairosvg first
    if not success:
        success = svg_to_png_using_cairosvg(svg_content, icon_path)
        if success:
            print("Created PNG using cairosvg")

    # Try Pillow
    if not success:
        success = create_simple_png(icon_path)
        if success:
            print("Created PNG using Pillow")

    if not success:
        print("Could not create PNG - please install Pillow: pip install Pillow")
        print(f"SVG file is available at: {svg_path}")
        return False

    print(f"App icon created successfully at: {icon_path}")
    return True

if __name__ == '__main__':
    main()
