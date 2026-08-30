import { access, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const pluginDir = join(dirname(fileURLToPath(import.meta.url)), "..");
const projectCandidates = [
  join(pluginDir, "..", ".."),
  join(pluginDir, "..", "..", "sudko", "bloomku"),
];
let projectDir;
for (const candidate of projectCandidates) {
  try {
    await access(join(candidate, "assets", "images", "backgrounds", "main_menu_bg_v1.png"));
    projectDir = candidate;
    break;
  } catch (_error) {
    // Try the next supported plugin location.
  }
}
if (!projectDir) throw new Error("Could not locate the Bloomku project assets from this plugin folder.");
const templatePath = join(pluginDir, "ui.template.html");
const outputPath = join(pluginDir, "ui.html");
const backgroundPath = join(projectDir, "assets", "images", "backgrounds", "main_menu_bg_v1.png");
const spriteDir = join(projectDir, "assets", "images", "sprites", "gameplay");
const spriteManifestPath = join(spriteDir, "manifest.json");
const cleanHeartPath = join(projectDir, "assets", "images", "sprites", "main_menu", "heart.png");

const [template, background, spriteManifestText, cleanHeart] = await Promise.all([
  readFile(templatePath, "utf8"),
  readFile(backgroundPath),
  readFile(spriteManifestPath, "utf8"),
  readFile(cleanHeartPath),
]);

const spriteManifest = JSON.parse(spriteManifestText);
const spritePayload = {};
let spriteByteCount = 0;
for (const [name, metadata] of Object.entries(spriteManifest)) {
  const bytes = await readFile(join(spriteDir, metadata.file));
  spriteByteCount += bytes.length;
  spritePayload[name] = {
    base64: bytes.toString("base64"),
    width: metadata.width,
    height: metadata.height,
  };
}
spriteByteCount += cleanHeart.length;
spritePayload.heart_clean = {
  base64: cleanHeart.toString("base64"),
  width: 76,
  height: 76,
};

const html = template
  .replace("__BACKGROUND_BASE64__", background.toString("base64"))
  .replace("__SPRITES_JSON__", JSON.stringify(spritePayload));

await writeFile(outputPath, html, "utf8");
console.log(`Embedded ${background.length} background bytes and ${spriteByteCount} isolated sprite bytes into ui.html`);
