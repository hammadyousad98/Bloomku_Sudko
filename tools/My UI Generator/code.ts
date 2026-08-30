figma.showUI(__html__, { width: 440, height: 680, themeColors: true });

const W = 1080;
const H = 1920;
const PAGE = "Zenduko Generated UI";
const SCREEN = "Screen / Gameplay / 1080x1920";
const LIBRARY = "Components / Gameplay / Sprite Masters";

type AssetSource = { bytes: number[]; width: number; height: number };
type Asset = { hash: string; width: number; height: number };
type Assets = Record<string, Asset>;
type Parent = FrameNode | ComponentNode;

const ink = "#4B2918";
const cream = "#FFF0C7";
const gold = "#E7A83A";
const parchment = "#FFE1A9";
let fontBold: FontName = { family: "Inter", style: "Bold" };
let fontRegular: FontName = { family: "Inter", style: "Regular" };

const hex = (value: string): RGB => ({
  r: parseInt(value.slice(1, 3), 16) / 255,
  g: parseInt(value.slice(3, 5), 16) / 255,
  b: parseInt(value.slice(5, 7), 16) / 255,
});
const fill = (value: string, opacity = 1): SolidPaint => ({
  type: "SOLID",
  color: hex(value),
  opacity,
});

async function loadFonts() {
  try {
    await Promise.all([
      figma.loadFontAsync({ family: "Nunito", style: "Regular" }),
      figma.loadFontAsync({ family: "Nunito", style: "ExtraBold" }),
    ]);
    fontRegular = { family: "Nunito", style: "Regular" };
    fontBold = { family: "Nunito", style: "ExtraBold" };
  } catch (_) {
    await Promise.all([
      figma.loadFontAsync(fontRegular),
      figma.loadFontAsync(fontBold),
    ]);
  }
}

function frame(parent: BaseNode & ChildrenMixin, name: string, x: number, y: number, width: number, height: number) {
  const node = figma.createFrame();
  node.name = name;
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.fills = [];
  node.clipsContent = false;
  parent.appendChild(node);
  return node;
}

function image(parent: Parent, name: string, asset: Asset, x: number, y: number, width: number, height: number) {
  const node = figma.createRectangle();
  node.name = name;
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.fills = [{ type: "IMAGE", imageHash: asset.hash, scaleMode: "FIT" }];
  parent.appendChild(node);
  return node;
}

function text(parent: Parent, name: string, value: string, x: number, y: number, width: number, height: number, size: number, align: "LEFT" | "CENTER" = "CENTER", color = cream) {
  const node = figma.createText();
  node.name = name;
  node.fontName = fontBold;
  node.fontSize = size;
  node.characters = value;
  node.textAutoResize = "NONE";
  node.textAlignHorizontal = align;
  node.textAlignVertical = "CENTER";
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.fills = [fill(color)];
  node.strokes = [fill(ink, 0.85)];
  node.strokeWeight = Math.max(1.5, size * 0.04);
  node.strokeAlign = "OUTSIDE";
  parent.appendChild(node);
  return node;
}

function sprite(parent: Parent, assets: Assets, key: string, name: string, x: number, y: number, width: number, height: number) {
  const asset = assets[key];
  if (!asset) throw new Error(`Missing gameplay asset: ${key}`);
  return image(parent, name, asset, x, y, width, height);
}

function component(library: FrameNode, assets: Assets, key: string, name: string, width: number, height: number) {
  const asset = assets[key];
  if (!asset) throw new Error(`Missing component asset: ${key}`);
  const node = figma.createComponent();
  node.name = name;
  node.description = `Editable Zenduko gameplay sprite master. Source: assets/images/sprites/gameplay/${key}.png`;
  node.resize(width, height);
  node.fills = [];
  node.clipsContent = false;
  library.appendChild(node);
  image(node, `${name} / Artwork`, asset, 0, 0, width, height);
  return node;
}

function placeInstance(parent: Parent, master: ComponentNode, name: string, x: number, y: number, width?: number, height?: number) {
  const node = master.createInstance();
  node.name = name;
  if (width && height) node.resize(width, height);
  node.x = x;
  node.y = y;
  parent.appendChild(node);
  return node;
}

function createLibrary(page: PageNode, assets: Assets) {
  const library = frame(page, LIBRARY, 1280, 0, 2400, 1680);
  library.fills = [fill("#21180F")];
  const definitions: Array<[string, string, number, number]> = [
    ["back_button", "Button / Back", 110, 128],
    ["pause_button", "Button / Pause", 110, 128],
    ["level_plaque", "Header / Level Plaque", 570, 150],
    ["heart_counter", "HUD / Lives", 290, 82],
    ["timer_counter", "HUD / Timer", 245, 82],
    ["flower_counter", "HUD / Flowers", 300, 82],
    ["rules_panel", "Rules / Panel", 900, 120],
    ["board_frame", "Board / Frame", 930, 930],
    ["flower_piece", "Board / Flower", 108, 96],
    ["lock_badge", "Board / Lock", 55, 55],
    ["power_button", "Power / Button", 430, 126],
    ["hint_bulb", "Power / Hint Icon", 90, 90],
    ["undo_arrow", "Power / Undo Icon", 82, 88],
    ["inventory_badge", "Power / Inventory Badge", 70, 72],
    ["score_counter", "Progress / Score", 230, 92],
    ["star_empty", "Progress / Star Empty", 66, 66],
    ["star_gold", "Progress / Star Gold", 72, 66],
  ];
  const masters: Record<string, ComponentNode> = {};
  definitions.forEach(([key, name, width, height], index) => {
    const master = component(library, assets, key, name, width, height);
    master.x = 40 + (index % 4) * 570;
    master.y = 70 + Math.floor(index / 4) * 300;
    masters[key] = master;
  });
  return { library, masters };
}

function createHeader(screen: FrameNode, masters: Record<string, ComponentNode>) {
  const section = frame(screen, "layout.header", 0, 34, W, 165);
  placeInstance(section, masters.back_button, "header.back", 34, 10, 112, 132);
  placeInstance(section, masters.level_plaque, "header.levelPlaque", 255, 0, 570, 150);
  placeInstance(section, masters.pause_button, "header.pause", 934, 10, 112, 132);
  text(section, "header.levelText", "LEVEL 14", 340, 30, 400, 62, 54);
  text(section, "header.chapterText", "BLOSSOM GARDEN", 345, 91, 390, 42, 30);
}

function createStats(screen: FrameNode, masters: Record<string, ComponentNode>, assets: Assets) {
  const section = frame(screen, "layout.stats", 0, 200, W, 88);
  placeInstance(section, masters.heart_counter, "stats.lives.container", 90, 0, 290, 82);
  [0, 1, 2].forEach(index => sprite(section, assets, "heart_clean", `stats.lives.heart.${index + 1}`, 118 + index * 76, 15, 58, 58));
  placeInstance(section, masters.timer_counter, "stats.timer.container", 418, 0, 245, 82);
  text(section, "stats.timer.value", "01:42", 493, 10, 145, 58, 38);
  placeInstance(section, masters.flower_counter, "stats.flowers.container", 696, 0, 300, 82);
  text(section, "stats.flowers.value", "3 / 6 FLOWERS", 772, 10, 205, 58, 30);
}

function createRules(screen: FrameNode, masters: Record<string, ComponentNode>, assets: Assets) {
  const section = frame(screen, "layout.rules", 0, 295, W, 126);
  placeInstance(section, masters.rules_panel, "rules.panel", 90, 0, 900, 120);
  const labels = ["One flower\nper row", "One flower\nper column", "One flower\nper region", "Flowers\ncannot touch"];
  const icons = ["flower_pink", "flower_yellow", "flower_purple", "x_marker"];
  for (let index = 0; index < 4; index += 1) {
    const x = 120 + index * 222;
    sprite(section, assets, icons[index], `rules.icon.${index + 1}`, x, 32, 56, 56);
    const label = text(section, `rules.label.${index + 1}`, labels[index], x + 65, 19, 150, 80, 23, "LEFT", ink);
    label.strokes = [];
  }
}

const regionColors = ["#F5E4BF", "#F2AEB0", "#F6CC55", "#B9D08D", "#CDAFDF", "#93C3E8"];
const boardMap = [0,0,0,1,1,1, 0,0,0,1,1,1, 2,2,2,3,3,3, 2,2,2,3,3,3, 4,4,4,5,5,5, 4,4,4,5,5,5];

function createBoard(screen: FrameNode, masters: Record<string, ComponentNode>, assets: Assets) {
  const section = frame(screen, "layout.board", 75, 425, 930, 930);
  placeInstance(section, masters.board_frame, "board.frame", 0, 0, 930, 930);
  const inset = 17;
  const gap = 5;
  const size = (930 - inset * 2 - gap * 5) / 6;
  for (let index = 0; index < 36; index += 1) {
    const row = Math.floor(index / 6);
    const column = index % 6;
    const tile = figma.createRectangle();
    tile.name = `board.tile.${index}`;
    tile.resize(size, size);
    tile.x = inset + column * (size + gap);
    tile.y = inset + row * (size + gap);
    tile.cornerRadius = 12;
    tile.fills = [fill(regionColors[boardMap[index]])];
    tile.strokes = [fill("#8E662D", 0.55)];
    tile.strokeWeight = 2;
    section.appendChild(tile);
  }
  [3, 19, 28].forEach((index, flowerIndex) => {
    const row = Math.floor(index / 6);
    const column = index % 6;
    sprite(section, assets, "flower_piece", `board.flower.${flowerIndex + 1}`, inset + column * (size + gap) + 18, inset + row * (size + gap) + 23, size - 36, size - 36);
  });
  const lockedRow = 0;
  const lockedColumn = 3;
  sprite(section, assets, "lock_badge", "board.lockedBadge", inset + lockedColumn * (size + gap) + size - 54, inset + lockedRow * (size + gap) + size - 54, 50, 50);
  [2,4,9,13,18,20,25,27,29,34].forEach(index => {
    const row = Math.floor(index / 6);
    const column = index % 6;
    sprite(section, assets, "x_marker", `board.marker.${index}`, inset + column * (size + gap) + size * 0.34, inset + row * (size + gap) + size * 0.32, size * 0.32, size * 0.36);
  });
}

function createHintBar(screen: FrameNode) {
  const bar = frame(screen, "layout.interactionHint", 220, 1365, 640, 62);
  bar.cornerRadius = 31;
  bar.fills = [fill(parchment)];
  bar.strokes = [fill("#8A4D1E")];
  bar.strokeWeight = 4;
  const label = text(bar, "interactionHint.text", "☘  Tap to plant  •  Hold for X  ☘", 18, 4, 604, 52, 28, "CENTER", ink);
  label.strokes = [];
}

function createPower(screen: FrameNode, masters: Record<string, ComponentNode>, assets: Assets, name: string, label: string, count: string, x: number, y: number, icon: "hint" | "solve" | "undo" | "automark") {
  const group = frame(screen, `power.${name}`, x, y, 430, 126);
  placeInstance(group, masters.power_button, `power.${name}.surface`, 0, 0, 430, 126);
  if (icon === "hint") placeInstance(group, masters.hint_bulb, "power.hint.icon", 40, 18, 86, 88);
  if (icon === "undo") placeInstance(group, masters.undo_arrow, "power.undo.icon", 48, 20, 80, 84);
  if (icon === "solve") ["flower_yellow", "flower_pink", "flower_purple"].forEach((key, index) => sprite(group, assets, key, `power.solveRow.icon.${index + 1}`, 42 + index * 48, 36, 50, 50));
  if (icon === "automark") {
    sprite(group, assets, "flower_pink", "power.autoMark.flower", 73, 29, 64, 64);
    [[42,25],[130,25],[42,72],[130,72]].forEach((point, index) => sprite(group, assets, "x_marker", `power.autoMark.x.${index + 1}`, point[0], point[1], 31, 36));
  }
  text(group, `power.${name}.label`, label, 155, 26, 238, 74, label === "SOLVE ROW" ? 31 : 36);
  placeInstance(group, masters.inventory_badge, `power.${name}.badge`, 355, -10, 74, 76);
  text(group, `power.${name}.count`, count, 366, 0, 50, 54, 28);
}

function createPowers(screen: FrameNode, masters: Record<string, ComponentNode>, assets: Assets) {
  createPower(screen, masters, assets, "hint", "HINT", "3", 82, 1440, "hint");
  createPower(screen, masters, assets, "solveRow", "SOLVE ROW", "2", 568, 1440, "solve");
  createPower(screen, masters, assets, "undo", "UNDO", "4", 82, 1582, "undo");
  createPower(screen, masters, assets, "autoMark", "AUTOMARK", "5", 568, 1582, "automark");
}

function createProgress(screen: FrameNode, masters: Record<string, ComponentNode>) {
  const group = frame(screen, "layout.progress", 95, 1750, 890, 112);
  const track = figma.createRectangle();
  track.name = "progress.track";
  track.resize(650, 82);
  track.x = 0;
  track.y = 15;
  track.cornerRadius = 41;
  track.fills = [fill("#4A210E")];
  track.strokes = [fill(gold)];
  track.strokeWeight = 6;
  group.appendChild(track);
  const progress = figma.createRectangle();
  progress.name = "progress.fill";
  progress.resize(110, 50);
  progress.x = 18;
  progress.y = 31;
  progress.cornerRadius = 25;
  progress.fills = [fill("#79B514")];
  group.appendChild(progress);
  [0,1,2].forEach(index => placeInstance(group, masters.star_empty, `progress.star.${index + 1}`, 270 + index * 105, 24, 66, 66));
  placeInstance(group, masters.score_counter, "progress.score.container", 660, 10, 230, 92);
  text(group, "progress.score.value", "1,240", 683, 19, 184, 68, 38);
}

function createNotes(page: PageNode) {
  const notes = frame(page, "Flutter Handoff / Gameplay Layout", 1280, 1760, 1080, 700);
  notes.fills = [fill("#21180F")];
  text(notes, "Title", "ZENDUKO GAMEPLAY · FLUTTER HANDOFF", 50, 35, 980, 70, 38);
  const lines = [
    "Design canvas: 1080 × 1920 portrait. Scale from available width, then center vertically.",
    "Every movable region uses a stable layout key: layout.*, header.*, stats.*, board.*, power.*, progress.*.",
    "Keep gameplay values as Flutter text. Sprite components supply only frames, icons, and decorative art.",
    "Board is a dynamic 6×6 sample. Flutter must continue generating its cells and regions from GameState.",
    "The debug layout editor exports these same keys as JSON x/y/width/height values.",
    "Safe bounds: top 34 px, bottom 58 px. Minimum interactive target after scaling: 44 logical px.",
  ];
  lines.forEach((line, index) => {
    const node = text(notes, `Note ${index + 1}`, line, 55, 125 + index * 82, 970, 66, 25, "LEFT");
    node.fontName = fontRegular;
    node.strokes = [];
  });
}

async function generate(backgroundBytes: number[], sources: Record<string, AssetSource>) {
  await loadFonts();
  let page = figma.root.children.find(candidate => candidate.name === PAGE);
  if (!page) {
    page = figma.createPage();
    page.name = PAGE;
  }
  await figma.setCurrentPageAsync(page);
  [...page.children].forEach(node => node.remove());

  const background = figma.createImage(new Uint8Array(backgroundBytes));
  const assets: Assets = {};
  Object.entries(sources).forEach(([key, source]) => {
    assets[key] = { hash: figma.createImage(new Uint8Array(source.bytes)).hash, width: source.width, height: source.height };
  });
  const { masters } = createLibrary(page, assets);
  const screen = figma.createFrame();
  screen.name = SCREEN;
  screen.resize(W, H);
  screen.x = 0;
  screen.y = 0;
  screen.clipsContent = true;
  screen.fills = [{ type: "IMAGE", imageHash: background.hash, scaleMode: "FILL" }];
  page.appendChild(screen);

  createHeader(screen, masters);
  createStats(screen, masters, assets);
  createRules(screen, masters, assets);
  createBoard(screen, masters, assets);
  createHintBar(screen);
  createPowers(screen, masters, assets);
  createProgress(screen, masters);
  createNotes(page);

  screen.exportSettings = [{ format: "PNG", suffix: "@1x", constraint: { type: "SCALE", value: 1 } }];
  figma.currentPage.selection = [screen];
  figma.viewport.scrollAndZoomIntoView([screen]);
  figma.ui.postMessage({ type: "generated", screenId: screen.id, layerCount: screen.findAll(() => true).length });
}

figma.ui.onmessage = async (message: { type: string; backgroundBytes?: number[]; spriteAssets?: Record<string, AssetSource> }) => {
  if (message.type === "generate-gameplay") {
    try {
      if (!message.backgroundBytes?.length || !message.spriteAssets) throw new Error("Embedded gameplay assets are missing. Run npm run build.");
      await generate(message.backgroundBytes, message.spriteAssets);
    } catch (error) {
      figma.ui.postMessage({ type: "error", message: error instanceof Error ? error.message : String(error) });
    }
  }
  if (message.type === "close") figma.closePlugin();
};
