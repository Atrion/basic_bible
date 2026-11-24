#!/usr/bin/env python3
"""Generates every app icon from one vector-style drawing.

    pip install pillow
    python tools/generate_icons.py            # writes into the project
    python tools/generate_icons.py --preview  # only writes tools/icon_preview.png

The design follows the From Gravel Hill family: a flat solid-colour square with
a simple white glyph (as in the Hymns app), plus the lantern flame from the
From Gravel Hill logo above an open Bible: the light of the Word.

Change COLORS below to restyle every icon at once.
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

COLORS = {
    "background": (35, 62, 91),     # Hymns navy #233E5B
    "book": (255, 255, 255),
    "flame": (244, 183, 64),        # warm lantern gold #F4B740
}
VARIANTS = {
    "navy": COLORS,
    "burgundy": {**COLORS, "background": (110, 22, 40)},  # Rosebank maroon family
}

SS = 4  # supersampling factor for smooth edges


def bezier(p0, p1, p2, p3, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((
            u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
        ))
    return pts


def mirror(pts, cx=512):
    return [(2 * cx - x, y) for x, y in pts]


def glyph_shapes():
    """Shapes in a 1024x1024 design space. Returns (pages, cover, flame, flame_inner)."""
    gap = 9  # half the gap between the two pages at the spine
    # Left page: spine top -> outer top (curved) -> outer bottom -> spine bottom (curved)
    top = bezier((512 - gap, 506), (440, 470), (330, 448), (214, 468))
    bottom = bezier((214, 700), (330, 676), (440, 690), (512 - gap, 728))
    left_page = top + bottom
    right_page = mirror(left_page)
    # Cover: a slightly larger, lower shape peeking out under the pages
    cover_l = bezier((512, 742), (430, 712), (320, 700), (190, 718)) + \
        [(190, 690)] + [(214, 700)]
    cover_l = [(190, 480)] + bezier((190, 480), (190, 560), (190, 640), (190, 722))
    cover = bezier((200, 700), (330, 690), (440, 708), (512, 752)) + \
        mirror(bezier((200, 700), (330, 690), (440, 708), (512, 752)))[::-1]
    cover += [(812, 726), (512, 770), (212, 726)]

    # Flame (asymmetric teardrop, like the lantern flame in the logo)
    flame = (
        bezier((512, 478), (448, 478), (420, 420), (452, 352))
        + bezier((452, 352), (468, 318), (506, 296), (520, 236))[1:]
        + bezier((520, 236), (572, 292), (610, 340), (606, 408))[1:]
        + bezier((606, 408), (602, 450), (566, 478), (512, 478))[1:]
    )
    # Inner flame (cut-out in the background colour)
    inner = (
        bezier((520, 466), (484, 466), (470, 432), (490, 398))
        + bezier((490, 398), (500, 380), (516, 368), (520, 340))[1:]
        + bezier((520, 340), (548, 372), (566, 396), (562, 424))[1:]
        + bezier((562, 424), (558, 450), (546, 466), (520, 466))[1:]
    )
    return left_page, right_page, cover, flame, inner


def draw_icon(size, colors, shape="square", glyph_scale=1.0, transparent_bg=False,
              mono=False):
    """Draws the icon at `size` px.

    shape: 'square' (full bleed), 'rounded' (rounded square with transparent
           corners), 'none' (glyph only on transparent, for adaptive icons).
    glyph_scale: 1.0 fills the design; <1 shrinks it toward the centre.
    mono: draw the whole glyph as one flat colour (Android themed icons).
    """
    big = size * SS
    scale = big / 1024.0

    def tx(pts):
        out = []
        for x, y in pts:
            x = 512 + (x - 512) * glyph_scale
            y = 540 + (y - 540) * glyph_scale
            out.append((x * scale, y * scale))
        return out

    left, right, cover, flame, inner = glyph_shapes()

    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    book = colors["book"] + (255,)
    flame_c = (colors["book"] if mono else colors["flame"]) + (255,)
    bg_c = colors["background"] + (255,)

    d.polygon(tx(cover), fill=book)
    d.polygon(tx(left), fill=book)
    d.polygon(tx(right), fill=book)
    d.polygon(tx(flame), fill=flame_c)
    if not mono:
        d.polygon(tx(inner), fill=bg_c)
    else:
        # carve the inner flame out so the silhouette keeps its detail
        cut = Image.new("L", (big, big), 0)
        ImageDraw.Draw(cut).polygon(tx(inner), fill=255)
        a = layer.getchannel("A")
        layer.putalpha(ImageChops.subtract(a, cut))

    # page gap / spine: a thin line in the background colour between the pages
    if not mono:
        d.line(tx([(512, 500), (512, 750)]), fill=bg_c, width=max(1, int(8 * scale * glyph_scale)))
    else:
        cut = Image.new("L", (big, big), 0)
        ImageDraw.Draw(cut).line(tx([(512, 500), (512, 750)]), fill=255,
                                 width=max(1, int(8 * scale * glyph_scale)))
        a = layer.getchannel("A")
        layer.putalpha(ImageChops.subtract(a, cut))

    if shape == "none":
        canvas = layer
    else:
        canvas = Image.new("RGBA", (big, big), bg_c)
        canvas.alpha_composite(layer)
        if shape == "rounded":
            mask = Image.new("L", (big, big), 0)
            r = int(big * 0.2237)  # iOS-style continuous-corner approximation
            ImageDraw.Draw(mask).rounded_rectangle([0, 0, big - 1, big - 1], radius=r, fill=255)
            canvas.putalpha(mask)
    out = canvas.resize((size, size), Image.LANCZOS)
    if transparent_bg and shape == "square":
        pass
    return out


def opaque(img):
    bg = Image.new("RGB", img.size, (255, 255, 255))
    bg.paste(img.convert("RGBA"), mask=img.convert("RGBA").getchannel("A"))
    return bg


def make_preview(path):
    """A review sheet: both colour options at several sizes and shapes."""
    pad = 24
    rows = []
    sheet = Image.new("RGB", (1500, 760), (242, 242, 242))
    d = ImageDraw.Draw(sheet)
    y = pad
    for name, colors in VARIANTS.items():
        x = pad
        big = draw_icon(256, colors, "square")
        sheet.paste(opaque(big), (x, y)); x += 256 + pad
        rounded = draw_icon(256, colors, "rounded", 0.9)
        sheet.paste(opaque(rounded), (x, y)); x += 256 + pad
        # circle (Android round launchers)
        circ = draw_icon(256, colors, "square", 0.9)
        m = Image.new("L", (256, 256), 0)
        ImageDraw.Draw(m).ellipse([0, 0, 255, 255], fill=255)
        c = Image.new("RGB", (256, 256), (242, 242, 242)); c.paste(opaque(circ), mask=m)
        sheet.paste(c, (x, y)); x += 256 + pad
        for s in (96, 64, 48, 32):
            sheet.paste(opaque(draw_icon(s, colors, "rounded", 0.9)), (x, y + (256 - s) // 2))
            x += s + pad
        d.text((pad, y + 262), f"{name}", fill=(60, 60, 60))
        y += 256 + 2 * pad + 8
    sheet.save(path)


def save_png(img, rel_path, opaque_rgb=False):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (opaque(img) if opaque_rgb else img).save(path, optimize=True)
    print("  wrote", rel_path, img.size)


def feature_graphic(colors):
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), colors["background"])
    glyph = draw_icon(380, colors, "none", 1.0)
    img.paste(glyph.convert("RGB"), (40, 70), glyph.getchannel("A"))
    d = ImageDraw.Draw(img)
    from PIL import ImageFont
    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 56)
    sub_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 27)
    x = 430
    d.text((x, 150), "From Gravel", font=title_font, fill=colors["book"])
    d.text((x, 214), "Hill Bible", font=title_font, fill=colors["flame"])
    d.text((x, 300), "Read the Bible, keep notes,", font=sub_font, fill=(214, 224, 236))
    d.text((x, 338), "pray and remember.", font=sub_font, fill=(214, 224, 236))
    return img


def generate_all(variant="navy"):
    colors = VARIANTS[variant]
    print(f"Generating icons ({variant})")
    res = "android/app/src/main/res"

    # --- Android: legacy launcher icons -------------------------------------
    for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        icon = draw_icon(px, colors, "rounded", 0.92)
        for name in ("launcher_icon.png", "ic_launcher.png"):
            save_png(icon, f"{res}/mipmap-{density}/{name}")
    # --- Android: adaptive icon (API 26+) and themed/monochrome icon (API 33+)
    for density, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        save_png(draw_icon(px, colors, "none", 0.80), f"{res}/mipmap-{density}/launcher_foreground.png")
        save_png(draw_icon(px, colors, "none", 0.80, mono=True), f"{res}/mipmap-{density}/launcher_monochrome.png")
    bg_hex = "#%02X%02X%02X" % colors["background"]
    write(f"{res}/mipmap-anydpi-v26/launcher_icon.xml", """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/launcher_background"/>
    <foreground android:drawable="@mipmap/launcher_foreground"/>
    <monochrome android:drawable="@mipmap/launcher_monochrome"/>
</adaptive-icon>
""")
    write(f"{res}/values/launcher_colors.xml", f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="launcher_background">{bg_hex}</color>
</resources>
""")

    # --- Source image used by flutter_launcher_icons and the About dialog ----
    save_png(draw_icon(1024, colors, "square"), "assets/icon/app_icon.png", opaque_rgb=True)

    # --- iOS (no transparency allowed) ---------------------------------------
    import json
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.load(open(os.path.join(ROOT, ios_dir, "Contents.json")))
    for entry in contents["images"]:
        if "filename" not in entry:
            continue
        px = round(float(entry["size"].split("x")[0]) * int(entry["scale"][:-1]))
        save_png(draw_icon(px, colors, "square"), f"{ios_dir}/{entry['filename']}", opaque_rgb=True)

    # --- macOS (rounded icon inset in its canvas, as macOS expects) ----------
    mac_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.load(open(os.path.join(ROOT, mac_dir, "Contents.json")))
    for entry in contents["images"]:
        if "filename" not in entry:
            continue
        px = round(float(entry["size"].split("x")[0]) * int(entry["scale"][:-1]))
        inner = max(1, round(px * 0.82))
        canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        canvas.alpha_composite(draw_icon(inner, colors, "rounded", 0.92), ((px - inner) // 2, (px - inner) // 2))
        save_png(canvas, f"{mac_dir}/{entry['filename']}")

    # --- Web / PWA -----------------------------------------------------------
    save_png(draw_icon(32, colors, "rounded", 0.95), "web/favicon.png")
    for px in (192, 512):
        save_png(draw_icon(px, colors, "square"), f"web/icons/Icon-{px}.png", opaque_rgb=True)
        save_png(draw_icon(px, colors, "square", 0.80), f"web/icons/Icon-maskable-{px}.png", opaque_rgb=True)

    # --- Windows -------------------------------------------------------------
    ico_sizes = [16, 24, 32, 48, 64, 128, 256]
    master = draw_icon(256, colors, "rounded", 0.92)
    ico_path = os.path.join(ROOT, "windows/runner/resources/app_icon.ico")
    master.save(ico_path, format="ICO", sizes=[(s, s) for s in ico_sizes])
    print("  wrote windows/runner/resources/app_icon.ico", ico_sizes)

    # --- Google Play ---------------------------------------------------------
    save_png(draw_icon(512, colors, "square"), "play-store/icon-512.png", opaque_rgb=True)
    save_png(feature_graphic(colors), "play-store/feature-graphic-1024x500.png")


def write(rel_path, text):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("  wrote", rel_path)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        make_preview(os.path.join(ROOT, "tools", "icon_preview.png"))
        print("wrote tools/icon_preview.png")
    else:
        variant = "navy"
        for arg in sys.argv[1:]:
            if arg.startswith("--variant="):
                variant = arg.split("=", 1)[1]
        generate_all(variant)
