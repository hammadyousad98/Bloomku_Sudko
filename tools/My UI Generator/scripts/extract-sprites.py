from __future__ import annotations

import json
from collections import deque
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
            / "zenduko_main_menu_atlas_native_v1.png"
        ).exists()
    ),
    PROJECT_CANDIDATES[0],
)
ATLAS_PATH = PROJECT_DIR / "assets" / "images" / "sprites" / "zenduko_main_menu_atlas_native_v1.png"
OUTPUT_DIR = PROJECT_DIR / "assets" / "images" / "sprites" / "main_menu"

# Conservative source windows isolate one logical asset at a time. The alpha-bounds
# pass then removes transparent padding without resampling any source pixels.
CROPS: dict[str, tuple[int, int, int, int]] = {
    "logo_plaque": (10, 116, 446, 254),
    "logo_lotus": (194, 4, 392, 118),
    "logo_leaf_left": (410, 12, 582, 122),
    "logo_leaf_right": (585, 10, 716, 122),
    "logo_wordmark": (225, 265, 612, 346),
    "settings_frame": (746, 0, 872, 121),
    "gear": (883, 10, 981, 111),
    "hud_pill": (996, 14, 1218, 117),
    "heart": (758, 118, 848, 207),
    "auto_mark": (868, 116, 955, 207),
    "petal": (985, 115, 1080, 207),
    "streak_medal": (7, 333, 153, 493),
    "flame": (153, 281, 243, 453),
    "mascot": (601, 292, 819, 537),
    "butterfly_blue": (15, 538, 140, 640),
    "butterfly_orange": (458, 538, 580, 640),
    "falling_petals": (898, 544, 1014, 660),
    "green_button": (8, 662, 241, 761),
    "continue_word": (624, 673, 847, 739),
    "level_ribbon": (7, 764, 307, 835),
    "level_text": (467, 773, 604, 825),
    "blossom_text": (683, 773, 878, 825),
    "progress_panel": (8, 841, 374, 950),
    "progress_frame": (382, 840, 545, 952),
    "count_badge": (981, 850, 1094, 920),
    "flower_pink": (132, 1150, 220, 1249),
    "flower_purple": (220, 1150, 307, 1249),
    "flower_blue": (307, 1150, 395, 1249),
    "flower_white": (395, 1150, 482, 1249),
    "flower_yellow": (482, 1150, 570, 1249),
    "flower_red": (704, 873, 768, 944),
    "flower_placeholder": (867, 872, 932, 945),
    "book": (9, 947, 173, 1073),
    "calendar": (396, 954, 530, 1073),
    "daily_flower": (679, 960, 772, 1057),
    "chest": (767, 947, 903, 1068),
    "nav_base": (9, 1073, 131, 1148),
    "ready_badge": (672, 1059, 763, 1121),
    "corner_flower": (137, 1152, 216, 1248),
    "lotus_decoration": (7, 1152, 143, 1248),
}

KEEP_COMPONENTS = {
    "logo_plaque": 1,
    "logo_lotus": 1,
    "logo_leaf_left": 1,
    "logo_leaf_right": 1,
    "logo_wordmark": 7,
    "settings_frame": 1,
    "gear": 1,
    "hud_pill": 1,
    "heart": 1,
    "auto_mark": 1,
    "petal": 1,
    "streak_medal": 1,
    "flame": 1,
    "mascot": 2,
    "butterfly_blue": 1,
    "butterfly_orange": 1,
    "falling_petals": 4,
    "green_button": 1,
    "level_ribbon": 1,
    "progress_panel": 1,
    "progress_frame": 1,
    "count_badge": 1,
    "flower_pink": 1,
    "flower_purple": 1,
    "flower_blue": 1,
    "flower_white": 1,
    "flower_yellow": 1,
    "flower_red": 1,
    "flower_placeholder": 1,
    "book": 1,
    "calendar": 1,
    "daily_flower": 1,
    "chest": 1,
    "nav_base": 1,
    "ready_badge": 1,
    "corner_flower": 1,
    "lotus_decoration": 1,
}

# These are the exact master sizes used by the 1080×1920 Figma composition.
# Resizing occurs once here, after isolation, so Figma never crops or reveals a
# neighboring atlas cell while fitting an asset to its final UI footprint.
TARGET_SIZES: dict[str, tuple[int, int]] = {
    "logo_plaque": (780, 270),
    "logo_lotus": (230, 138),
    "logo_leaf_left": (190, 122),
    "logo_leaf_right": (170, 126),
    "logo_wordmark": (650, 156),
    "settings_frame": (132, 132),
    "gear": (82, 82),
    "hud_pill": (230, 108),
    "heart": (76, 76),
    "auto_mark": (76, 76),
    "petal": (76, 76),
    "streak_medal": (158, 176),
    "flame": (116, 196),
    "green_button": (700, 184),
    "continue_word": (530, 116),
    "level_ribbon": (644, 112),
    "level_text": (150, 52),
    "blossom_text": (220, 52),
    "progress_panel": (900, 230),
    "progress_frame": (920, 250),
    "count_badge": (110, 62),
    "flower_pink": (68, 68),
    "flower_purple": (68, 68),
    "flower_blue": (68, 68),
    "flower_white": (68, 68),
    "flower_yellow": (68, 68),
    "flower_red": (68, 68),
    "flower_placeholder": (68, 68),
    "book": (180, 140),
    "calendar": (145, 138),
    "daily_flower": (72, 72),
    "chest": (170, 148),
    "nav_base": (290, 150),
    "ready_badge": (100, 62),
    "corner_flower": (88, 82),
    "lotus_decoration": (150, 106),
}


def keep_largest_alpha_components(image: Image.Image, count: int) -> Image.Image:
    alpha = image.getchannel("A")
    width, height = image.size
    pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or pixels[x, y] <= 8:
                continue
            visited[offset] = 1
            queue = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for ny in range(max(0, py - 1), min(height, py + 2)):
                    for nx in range(max(0, px - 1), min(width, px + 2)):
                        index = ny * width + nx
                        if not visited[index] and pixels[nx, ny] > 8:
                            visited[index] = 1
                            queue.append((nx, ny))
            components.append(component)
    keep = {point for component in sorted(components, key=len, reverse=True)[:count] for point in component}
    cleaned = image.copy()
    cleaned_alpha = cleaned.getchannel("A")
    cleaned_pixels = cleaned_alpha.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                cleaned_pixels[x, y] = 0
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def extract(atlas: Image.Image, name: str, box: tuple[int, int, int, int]) -> Image.Image:
    crop = atlas.crop(box)
    if name == "flame":
        alpha = crop.getchannel("A")
        alpha_draw = ImageDraw.Draw(alpha)
        alpha_draw.rectangle((round(crop.width * 0.83), 0, crop.width, round(crop.height * 0.46)), fill=0)
        crop.putalpha(alpha)
    if name in KEEP_COMPONENTS:
        crop = keep_largest_alpha_components(crop, KEEP_COMPONENTS[name])
    alpha_bounds = crop.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise RuntimeError(f"{name} has no visible pixels")
    crop = crop.crop(alpha_bounds)
    padded = Image.new("RGBA", (crop.width + 4, crop.height + 4), (0, 0, 0, 0))
    padded.alpha_composite(crop, (2, 2))
    return padded


def make_contact_sheet(sprites: dict[str, Image.Image]) -> Image.Image:
    cell_width, cell_height = 320, 210
    columns = 4
    rows = (len(sprites) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * cell_width, rows * cell_height), (28, 24, 21, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (name, sprite) in enumerate(sprites.items()):
        column, row = index % columns, index // columns
        origin_x, origin_y = column * cell_width, row * cell_height
        checker = Image.new("RGBA", (cell_width - 16, cell_height - 42), (238, 234, 224, 255))
        checker_draw = ImageDraw.Draw(checker)
        for y in range(0, checker.height, 16):
            for x in range(0, checker.width, 16):
                if (x // 16 + y // 16) % 2:
                    checker_draw.rectangle((x, y, x + 15, y + 15), fill=(210, 205, 195, 255))
        scale = min((checker.width - 12) / sprite.width, (checker.height - 12) / sprite.height, 1.0)
        preview = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.Resampling.LANCZOS)
        checker.alpha_composite(preview, ((checker.width - preview.width) // 2, (checker.height - preview.height) // 2))
        sheet.alpha_composite(checker, (origin_x + 8, origin_y + 8))
        draw.text((origin_x + 10, origin_y + cell_height - 28), f"{name} · {sprite.width}×{sprite.height}", fill=(255, 242, 207, 255), font=font)
    return sheet


def main() -> None:
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sprites: dict[str, Image.Image] = {}
    manifest: dict[str, dict[str, int | str]] = {}
    for name, box in CROPS.items():
        sprite = extract(atlas, name, box)
        if name in TARGET_SIZES:
            sprite = sprite.resize(TARGET_SIZES[name], Image.Resampling.LANCZOS)
        path = OUTPUT_DIR / f"{name}.png"
        sprite.save(path, optimize=True)
        sprites[name] = sprite
        manifest[name] = {"file": path.name, "width": sprite.width, "height": sprite.height}
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    make_contact_sheet(sprites).save(OUTPUT_DIR / "contact_sheet.png", optimize=True)
    print(f"Extracted {len(sprites)} sprites to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
