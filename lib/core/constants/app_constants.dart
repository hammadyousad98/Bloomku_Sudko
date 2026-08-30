export '../../core/utils/puzzle_generator.dart' show PuzzleTrack;

const int maxLevelCount = 80;
const int initialAutoMarkGrant = 5;
const int currentEconomyMigrationVersion = 1;
const int tutorialBoardCount = 3;

class ChapterCollectible {
  const ChapterCollectible({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final String id;
  final String name;
  final String emoji;
}

class ChapterUnlockReward {
  const ChapterUnlockReward({
    required this.label,
    this.themeId,
    this.boardSkinId,
    this.objectId,
    this.musicTrackId,
  });

  final String label;
  final String? themeId;
  final String? boardSkinId;
  final String? objectId;
  final String? musicTrackId;
}

/// Single source of truth for the campaign journey and its presentation.
class ChapterDefinition {
  const ChapterDefinition({
    required this.id,
    required this.name,
    required this.startLevel,
    required this.endLevel,
    required this.themeId,
    required this.boardSkinId,
    required this.objectCollectionId,
    required this.musicTrackId,
    required this.pathArtAsset,
    required this.pathEmoji,
    required this.collectibles,
    required this.completionReward,
  });

  final String id;
  final String name;
  final int startLevel;
  final int endLevel;
  final String themeId;
  final String boardSkinId;
  final String objectCollectionId;
  final String musicTrackId;
  final String pathArtAsset;
  final String pathEmoji;
  final List<ChapterCollectible> collectibles;
  final ChapterUnlockReward completionReward;

  int get levelCount => endLevel - startLevel + 1;
  bool contains(int level) => level >= startLevel && level <= endLevel;
}

// Compatibility for the Phase 1 repository API.
typedef CampaignChapter = ChapterDefinition;

const List<ChapterDefinition> campaignChapters = [
  ChapterDefinition(
    id: 'blossom_garden',
    name: 'Blossom Garden',
    startLevel: 1,
    endLevel: 15,
    themeId: 'theme_blossom_garden',
    boardSkinId: 'board_blossom_garden',
    objectCollectionId: 'collection_blossom_garden',
    musicTrackId: 'music_blossom_garden',
    pathArtAsset: 'assets/icons/blossom.png',
    pathEmoji: '🌸',
    collectibles: [
      ChapterCollectible(id: 'rose', name: 'Rose', emoji: '🌹'),
      ChapterCollectible(id: 'sunflower', name: 'Sunflower', emoji: '🌻'),
      ChapterCollectible(id: 'tulip', name: 'Tulip', emoji: '🌷'),
      ChapterCollectible(id: 'daisy', name: 'Daisy', emoji: '🌼'),
      ChapterCollectible(id: 'hibiscus', name: 'Hibiscus', emoji: '🌺'),
      ChapterCollectible(id: 'lotus', name: 'Lotus', emoji: '🪷'),
      ChapterCollectible(id: 'lavender', name: 'Lavender', emoji: '🪻'),
      ChapterCollectible(id: 'seedling', name: 'Seedling', emoji: '🌱'),
      ChapterCollectible(id: 'clover', name: 'Clover', emoji: '☘️'),
      ChapterCollectible(id: 'bouquet', name: 'Garden Bouquet', emoji: '💐'),
    ],
    completionReward: ChapterUnlockReward(
      label: 'Ocean Cove theme, board and music',
      themeId: 'theme_ocean_cove',
      boardSkinId: 'board_ocean_cove',
      musicTrackId: 'music_ocean_cove',
    ),
  ),
  ChapterDefinition(
    id: 'ocean_cove',
    name: 'Ocean Cove',
    startLevel: 16,
    endLevel: 30,
    themeId: 'theme_ocean_cove',
    boardSkinId: 'board_ocean_cove',
    objectCollectionId: 'collection_ocean_cove',
    musicTrackId: 'music_ocean_cove',
    pathArtAsset: 'assets/icons/seashell.png',
    pathEmoji: '🐚',
    collectibles: [
      ChapterCollectible(id: 'shell', name: 'Pearl Shell', emoji: '🐚'),
      ChapterCollectible(id: 'coral', name: 'Coral', emoji: '🪸'),
      ChapterCollectible(id: 'fish', name: 'Reef Fish', emoji: '🐠'),
      ChapterCollectible(id: 'dolphin', name: 'Dolphin', emoji: '🐬'),
      ChapterCollectible(id: 'turtle', name: 'Sea Turtle', emoji: '🐢'),
      ChapterCollectible(id: 'crab', name: 'Cove Crab', emoji: '🦀'),
      ChapterCollectible(id: 'octopus', name: 'Octopus', emoji: '🐙'),
      ChapterCollectible(id: 'whale', name: 'Blue Whale', emoji: '🐋'),
      ChapterCollectible(id: 'wave', name: 'Crystal Wave', emoji: '🌊'),
      ChapterCollectible(id: 'island', name: 'Secret Island', emoji: '🏝️'),
    ],
    completionReward: ChapterUnlockReward(
      label: 'Forest Trail theme, board and music',
      themeId: 'theme_forest_trail',
      boardSkinId: 'board_forest_trail',
      musicTrackId: 'music_forest_trail',
    ),
  ),
  ChapterDefinition(
    id: 'forest_trail',
    name: 'Forest Trail',
    startLevel: 31,
    endLevel: 50,
    themeId: 'theme_forest_trail',
    boardSkinId: 'board_forest_trail',
    objectCollectionId: 'collection_forest_trail',
    musicTrackId: 'music_forest_trail',
    pathArtAsset: 'assets/icons/forest.png',
    pathEmoji: '🌲',
    collectibles: [
      ChapterCollectible(id: 'leaf', name: 'Maple Leaf', emoji: '🍁'),
      ChapterCollectible(id: 'mushroom', name: 'Mushroom', emoji: '🍄'),
      ChapterCollectible(id: 'acorn', name: 'Acorn', emoji: '🌰'),
      ChapterCollectible(id: 'owl', name: 'Forest Owl', emoji: '🦉'),
      ChapterCollectible(id: 'fox', name: 'Trail Fox', emoji: '🦊'),
      ChapterCollectible(id: 'deer', name: 'Woodland Deer', emoji: '🦌'),
      ChapterCollectible(id: 'bee', name: 'Honey Bee', emoji: '🐝'),
      ChapterCollectible(id: 'butterfly', name: 'Butterfly', emoji: '🦋'),
      ChapterCollectible(id: 'tree', name: 'Ancient Tree', emoji: '🌳'),
      ChapterCollectible(id: 'cabin', name: 'Forest Cabin', emoji: '🛖'),
    ],
    completionReward: ChapterUnlockReward(
      label: 'Cosmic Garden theme, board and music',
      themeId: 'theme_cosmic_garden',
      boardSkinId: 'board_cosmic_garden',
      musicTrackId: 'music_cosmic_garden',
    ),
  ),
  ChapterDefinition(
    id: 'cosmic_garden',
    name: 'Cosmic Garden',
    startLevel: 51,
    endLevel: 65,
    themeId: 'theme_cosmic_garden',
    boardSkinId: 'board_cosmic_garden',
    objectCollectionId: 'collection_cosmic_garden',
    musicTrackId: 'music_cosmic_garden',
    pathArtAsset: 'assets/icons/galaxy.png',
    pathEmoji: '🌌',
    collectibles: [
      ChapterCollectible(id: 'moon', name: 'Moon', emoji: '🌙'),
      ChapterCollectible(id: 'star', name: 'Bright Star', emoji: '⭐'),
      ChapterCollectible(id: 'planet', name: 'Ringed Planet', emoji: '🪐'),
      ChapterCollectible(id: 'rocket', name: 'Rocket', emoji: '🚀'),
      ChapterCollectible(id: 'satellite', name: 'Satellite', emoji: '🛰️'),
      ChapterCollectible(id: 'comet', name: 'Comet', emoji: '☄️'),
      ChapterCollectible(id: 'alien', name: 'Garden Visitor', emoji: '👽'),
      ChapterCollectible(id: 'earth', name: 'Blue Earth', emoji: '🌍'),
      ChapterCollectible(id: 'milky_way', name: 'Milky Way', emoji: '🌠'),
      ChapterCollectible(id: 'observatory', name: 'Observatory', emoji: '🔭'),
    ],
    completionReward: ChapterUnlockReward(
      label: 'Peach Orchard theme, board and music',
      themeId: 'theme_peach_orchard',
      boardSkinId: 'board_peach_orchard',
      musicTrackId: 'music_peach_orchard',
    ),
  ),
  ChapterDefinition(
    id: 'peach_orchard',
    name: 'Peach Orchard',
    startLevel: 66,
    endLevel: 80,
    themeId: 'theme_peach_orchard',
    boardSkinId: 'board_peach_orchard',
    objectCollectionId: 'collection_peach_orchard',
    musicTrackId: 'music_peach_orchard',
    pathArtAsset: 'assets/icons/peach.png',
    pathEmoji: '🍑',
    collectibles: [
      ChapterCollectible(id: 'peach', name: 'Golden Peach', emoji: '🍑'),
      ChapterCollectible(id: 'cherry', name: 'Sweet Cherries', emoji: '🍒'),
      ChapterCollectible(id: 'orange', name: 'Orchard Orange', emoji: '🍊'),
      ChapterCollectible(id: 'apple', name: 'Crisp Apple', emoji: '🍎'),
      ChapterCollectible(id: 'pear', name: 'Sun Pear', emoji: '🍐'),
      ChapterCollectible(id: 'grapes', name: 'Vine Grapes', emoji: '🍇'),
      ChapterCollectible(id: 'bee', name: 'Orchard Bee', emoji: '🐝'),
      ChapterCollectible(id: 'basket', name: 'Harvest Basket', emoji: '🧺'),
      ChapterCollectible(id: 'blossom', name: 'Peach Blossom', emoji: '🌸'),
      ChapterCollectible(id: 'festival', name: 'Harvest Festival', emoji: '🏮'),
    ],
    completionReward: ChapterUnlockReward(
      label: 'Golden Blossom object and finale music',
      objectId: 'object_golden_blossom',
      musicTrackId: 'music_campaign_finale',
    ),
  ),
];

ChapterDefinition? chapterForLevel(int level) {
  for (final chapter in campaignChapters) {
    if (chapter.contains(level)) return chapter;
  }
  return null;
}

ChapterDefinition? chapterById(String id) {
  for (final chapter in campaignChapters) {
    if (chapter.id == id) return chapter;
  }
  return null;
}
