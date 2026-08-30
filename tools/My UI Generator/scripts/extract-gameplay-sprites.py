from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PLUGIN_DIR = Path(__file__).resolve().parent.parent
PROJECT_CANDIDATES = (
    PLUGIN_DIR.parent.parent,
    PLUGIN_DIR.parent.parent / "sudko" / "bloomku",
)
PROJECT_DIR = next(
    (
        candidate
        for candidate in PROJECT_CANDIDATES
        if (
            candidate
            / "assets"
            / "images"
            / "sprites"
            / "zenduko_gameplay_atlas_v1_chroma.png"
        ).exists()
    ),
    PROJECT_CANDIDATES[0],
)
ATLAS_PATH = (
    PROJECT_DIR
    / "assets"
    / "images"
    / "sprites"
    / "zenduko_gameplay_atlas_v1_chroma.png"
)
OUTPUT_DIR = PROJECT_DIR / "assets" / "images" / "sprites" / "gameplay"

# Coordinates target the generated 1254x1254 source atlas. Each crop contains
# one reusable logical sprite and generous transparent padding after keying.
CROPS: dict[str, tuple[int, int, int, int]] = {
    "back_button": (10, 8, 103, 105),
    "pause_button": (270, 8, 360, 105),
    "level_plaque": (530, 7, 1045, 126),
    "heart_counter": (230, 132, 405, 195),
    "heart": (22, 136, 82, 194),
    "timer_counter": (606, 132, 786, 195),
    "flower_counter": (938, 132, 1093, 195),
    "generic_counter": (1088, 132, 1235, 195),
    "rules_panel": (8, 248, 665, 336),
    "board_frame": (8, 340, 375, 671),
    "flower_piece": (185, 682, 263, 758),
    "flower_yellow": (8, 760, 82, 833),
    "flower_pink": (82, 760, 151, 833),
    "flower_purple": (147, 760, 217, 833),
    "lock_badge": (680, 680, 736, 738),
    "x_marker": (1065, 678, 1125, 738),
    "power_button": (8, 902, 170, 978),
    "power_button_active": (328, 902, 500, 978),
    "power_button_disabled": (498, 902, 665, 978),
    "power_button_ad": (1040, 895, 1234, 980),
    "hint_bulb": (330, 982, 405, 1068),
    "undo_arrow": (810, 990, 875, 1065),
    "inventory_badge": (8, 1070, 80, 1145),
    "progress_track": (8, 1140, 220, 1205),
    "progress_fill": (210, 1142, 430, 1192),
    "star_empty": (620, 1138, 685, 1207),
    "star_gold": (770, 1138, 835, 1207),
    "score_counter": (1087, 132, 1237, 195),
}


def chroma_to_alpha(image: Image.Image) -> Image.Image:
    """Remove the magenta key while mathematically unmixing edge pixels."""
    key = (235.0, 3.0, 231.0)
    transparent_distance = 18.0
    opaque_distance = 105.0
    source = image.convert("RGBA")
    output = Image.new("RGBA", source.size, (0, 0, 0, 0))
    source_pixels = source.load()
    output_pixels = output.load()

    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, _ = source_pixels[x, y]
            distance = math.sqrt(
                (red - key[0]) ** 2
                + (green - key[1]) ** 2
                + (blue - key[2]) ** 2
            )
            if distance <= transparent_distance:
                continue
            if distance >= opaque_distance:
                output_pixels[x, y] = (red, green, blue, 255)
                continue

            alpha = (distance - transparent_distance) / (
                opaque_distance - transparent_distance
            )
            alpha = alpha * alpha * (3.0 - 2.0 * alpha)
            if alpha <= 0.02:
                continue
            # Reverse the chroma composite: observed = fg*a + key*(1-a).
            foreground = []
            for observed, key_channel in zip((red, green, blue), key):
                value = (observed - key_channel * (1.0 - alpha)) / alpha
                foreground.append(max(0, min(255, round(value))))
            output_pixels[x, y] = (*foreground, round(alpha * 255))

    bounds = output.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Crop contained no visible sprite")
    cropped = output.crop(bounds)
    padded = Image.new(
        "RGBA", (cropped.width + 12, cropped.height + 12), (0, 0, 0, 0)
    )
    padded.alpha_composite(cropped, (6, 6))
    return padded


def make_contact_sheet(sprites: dict[str, Image.Image]) -> Image.Image:
    columns = 4
    cell_width, cell_height = 330, 220
    rows = (len(sprites) + columns - 1) // columns
    sheet = Image.new(
        "RGBA", (columns * cell_width, rows * cell_height), (31, 25, 20, 255)
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (name, sprite) in enumerate(sprites.items()):
        column, row = index % columns, index // columns
        x, y = column * cell_width, row * cell_height
        preview_scale = min(290 / sprite.width, 170 / sprite.height, 1.0)
        preview = sprite.resize(
            (
                max(1, round(sprite.width * preview_scale)),
                max(1, round(sprite.height * preview_scale)),
            ),
            Image.Resampling.LANCZOS,
        )
        sheet.alpha_composite(
            preview,
            (x + (cell_width - preview.width) // 2, y + 10),
        )
        draw.text((x + 10, y + 194), name, fill=(255, 241, 207, 255), font=font)
    return sheet


def main() -> None:
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sprites: dict[str, Image.Image] = {}
    manifest: dict[str, dict[str, int | str]] = {}
    for name, box in CROPS.items():
        sprite = chroma_to_alpha(atlas.crop(box))
        path = OUTPUT_DIR / f"{name}.png"
        sprite.save(path, optimize=True)
        sprites[name] = sprite
        manifest[name] = {
            "file": path.name,
            "width": sprite.width,
            "height": sprite.height,
        }
    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )
    make_contact_sheet(sprites).save(OUTPUT_DIR / "contact_sheet.png", optimize=True)
    print(f"Extracted {len(sprites)} gameplay sprites to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
