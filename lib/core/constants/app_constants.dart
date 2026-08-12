export '../../core/utils/puzzle_generator.dart' show PuzzleTrack;

const int maxLevelCount = 80;
const int initialAutoMarkGrant = 5;
const int currentEconomyMigrationVersion = 1;
const int tutorialBoardCount = 3;

class CampaignChapter {
  const CampaignChapter({
    required this.id,
    required this.name,
    required this.startLevel,
    required this.endLevel,
    required this.themeId,
    required this.boardSkinId,
    required this.objectCollectionId,
    required this.musicTrackId,
  });

  final String id;
  final String name;
  final int startLevel;
  final int endLevel;
  final String themeId;
  final String boardSkinId;
  final String objectCollectionId;
  final String musicTrackId;

  bool contains(int level) => level >= startLevel && level <= endLevel;
}

const List<CampaignChapter> campaignChapters = [
  CampaignChapter(
    id: 'blossom_garden',
    name: 'Blossom Garden',
    startLevel: 1,
    endLevel: 15,
    themeId: 'theme_blossom_garden',
    boardSkinId: 'board_blossom_garden',
    objectCollectionId: 'collection_blossom_garden',
    musicTrackId: 'music_blossom_garden',
  ),
  CampaignChapter(
    id: 'ocean_cove',
    name: 'Ocean Cove',
    startLevel: 16,
    endLevel: 30,
    themeId: 'theme_ocean_cove',
    boardSkinId: 'board_ocean_cove',
    objectCollectionId: 'collection_ocean_cove',
    musicTrackId: 'music_ocean_cove',
  ),
  CampaignChapter(
    id: 'forest_trail',
    name: 'Forest Trail',
    startLevel: 31,
    endLevel: 50,
    themeId: 'theme_forest_trail',
    boardSkinId: 'board_forest_trail',
    objectCollectionId: 'collection_forest_trail',
    musicTrackId: 'music_forest_trail',
  ),
  CampaignChapter(
    id: 'cosmic_garden',
    name: 'Cosmic Garden',
    startLevel: 51,
    endLevel: 65,
    themeId: 'theme_cosmic_garden',
    boardSkinId: 'board_cosmic_garden',
    objectCollectionId: 'collection_cosmic_garden',
    musicTrackId: 'music_cosmic_garden',
  ),
  CampaignChapter(
    id: 'peach_orchard',
    name: 'Peach Orchard',
    startLevel: 66,
    endLevel: 80,
    themeId: 'theme_peach_orchard',
    boardSkinId: 'board_peach_orchard',
    objectCollectionId: 'collection_peach_orchard',
    musicTrackId: 'music_peach_orchard',
  ),
];

CampaignChapter? chapterForLevel(int level) {
  for (final chapter in campaignChapters) {
    if (chapter.contains(level)) return chapter;
  }
  return null;
}
