# Zenduko Gameplay UI Generator

Local Figma plugin that creates the editable Zenduko gameplay screen from the project’s real background and isolated gameplay sprites.

## Generated design

- Exactly **1080 × 1920 portrait**
- Full-bleed Blossom Garden background
- Editable level, chapter, timer, flower count, inventory, and score text
- Reusable Figma sprite components for header controls, counters, board artwork, power buttons, badges, stars, and score UI
- Dynamic-looking 6×6 sample board with region tiles, flowers, X markers, and a locked flower
- Stable layer keys matching the Flutter layout editor: `layout.*`, `header.*`, `stats.*`, `board.*`, `power.*`, and `progress.*`
- Flutter handoff notes placed beside the screen

## Run

1. Run `npm install` once.
2. Run `python scripts/extract-gameplay-sprites.py` when the source atlas changes.
3. Run `npm run build`.
4. In Figma Desktop, choose **Plugins → Development → Import plugin from manifest…**.
5. Select this folder’s `manifest.json`.
6. Run **Zenduko Gameplay UI Generator v2** and click **Generate Gameplay Screen**.

The plugin clears only the dedicated `Zenduko Generated UI` page. Other pages and user-created frames are preserved.

## Asset sources

- `assets/images/backgrounds/main_menu_bg_v1.png`
- `assets/images/sprites/gameplay/`
- `assets/images/sprites/main_menu/heart.png`

## Flutter coordinate mapping

The design uses a 1080×1920 source canvas. Flutter scales layout rectangles uniformly from the available width and centers the result vertically. Every editable top-level region uses a stable name that can be copied into the game’s debug layout JSON.
