import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import '../models/player_progress.dart';
import '../../core/constants/app_constants.dart';

/// Repository for handling player progress and items.
class ProgressRepository {
  ProgressRepository(this._box);
  final Box<PlayerProgress> _box;

  /// Returns the single PlayerProgress record, creating it if absent.
  PlayerProgress getProgress() {
    final existing = _box.getAll();
    if (existing.isNotEmpty) return _applyMigrations(existing.first);

    // New object MUST have id = 0 for ObjectBox to auto-assign
    final defaults = PlayerProgress(); // id defaults to 0
    _box.put(defaults);
    return defaults;
  }

  PlayerProgress _applyMigrations(PlayerProgress progress) {
    if (progress.economyMigrationVersion < 1) {
      progress.autoMarks += initialAutoMarkGrant;
      for (final chapter in campaignChapters) {
        if (chapter.startLevel > progress.normalHighest) continue;
        progress.unlockedChapterIdsJson =
            _addId(progress.unlockedChapterIdsJson, chapter.id);
        progress.unlockedThemeIdsJson =
            _addId(progress.unlockedThemeIdsJson, chapter.themeId);
        progress.unlockedBoardSkinIdsJson =
            _addId(progress.unlockedBoardSkinIdsJson, chapter.boardSkinId);
        progress.unlockedMusicTrackIdsJson =
            _addId(progress.unlockedMusicTrackIdsJson, chapter.musicTrackId);
      }
      progress.economyMigrationVersion = 1;
      _box.put(progress);
    }
    return progress;
  }

  /// Saves the progress object back to the box.
  void saveProgress(PlayerProgress progress) {
    _box.put(progress);
  }

  /// Marks a level as complete on the given track.
  /// Only Normal track completions advance the unlock counter.
  void completeLevel(int levelNumber, PuzzleTrack track) {
    final progress = getProgress();
    progress.levelsCompletedCount += 1;

    if (track == PuzzleTrack.normal) {
      if (levelNumber >= progress.normalHighest) {
        final completedChapter = chapterForLevel(levelNumber);
        progress.normalHighest = (levelNumber + 1).clamp(1, maxLevelCount + 1);
        final nextChapter = chapterForLevel(progress.normalHighest);
        if (nextChapter != null) {
          _unlockChapterOnly(progress, nextChapter);
        }
        if (completedChapter != null &&
            levelNumber == completedChapter.endLevel) {
          _grantCompletionRewardOn(progress, completedChapter);
        }
      }
    } else if (track == PuzzleTrack.hard) {
      if (levelNumber >= progress.hardHighest) {
        progress.hardHighest = (levelNumber + 1).clamp(1, maxLevelCount + 1);
      }
    } else if (track == PuzzleTrack.ultraHard) {
      if (levelNumber >= progress.ultraHighest) {
        progress.ultraHighest = (levelNumber + 1).clamp(1, maxLevelCount + 1);
      }
    }

    saveProgress(progress);
  }

  bool isLevelUnlocked(int levelNumber, PuzzleTrack track) {
    if (levelNumber < 1 || levelNumber > maxLevelCount) return false;

    final progress = getProgress();
    return levelNumber <=
        switch (track) {
          PuzzleTrack.normal => progress.normalHighest,
          PuzzleTrack.hard => progress.hardHighest,
          PuzzleTrack.ultraHard => progress.ultraHighest,
        };
  }

  bool isCurrentPlayableLevel(int levelNumber, PuzzleTrack track) {
    if (levelNumber < 1 || levelNumber > maxLevelCount) return false;

    final progress = getProgress();
    return levelNumber ==
        switch (track) {
          PuzzleTrack.normal => progress.normalHighest,
          PuzzleTrack.hard => progress.hardHighest,
          PuzzleTrack.ultraHard => progress.ultraHighest,
        };
  }

  /// Adds consumable items to inventory.
  void addHints(int count) {
    final progress = getProgress();
    progress.hints += count;
    saveProgress(progress);
  }

  void addExtraLives(int count) {
    final progress = getProgress();
    progress.extraLives += count;
    saveProgress(progress);
  }

  void addUndos(int count) {
    final progress = getProgress();
    progress.undos += count;
    saveProgress(progress);
  }

  void addBulbs(int count) {
    final progress = getProgress();
    progress.bulbs += count;
    saveProgress(progress);
  }

  void addAutoMarks(int count) {
    final progress = getProgress();
    progress.autoMarks += count;
    saveProgress(progress);
  }

  void addStreakFreezes(int count) {
    final progress = getProgress();
    progress.streakFreezes += count;
    saveProgress(progress);
  }

  void addCosmeticCurrency(int count) {
    final progress = getProgress();
    progress.cosmeticCurrency += count;
    saveProgress(progress);
  }

  /// Consumes one of each item. Returns false if not enough inventory.
  bool useHint() {
    final progress = getProgress();
    if (progress.hints > 0) {
      progress.hints -= 1;
      saveProgress(progress);
      return true;
    }
    return false;
  }

  bool useExtraLife() {
    final progress = getProgress();
    if (progress.extraLives > 0) {
      progress.extraLives -= 1;
      saveProgress(progress);
      return true;
    }
    return false;
  }

  bool useUndo() {
    final progress = getProgress();
    if (progress.undos > 0) {
      progress.undos -= 1;
      saveProgress(progress);
      return true;
    }
    return false;
  }

  bool useBulb() {
    final progress = getProgress();
    if (progress.bulbs > 0) {
      progress.bulbs -= 1;
      saveProgress(progress);
      return true;
    }
    return false;
  }

  bool useAutoMark() {
    final progress = getProgress();
    if (progress.autoMarks <= 0) return false;
    progress.autoMarks -= 1;
    saveProgress(progress);
    return true;
  }

  bool useStreakFreeze() {
    final progress = getProgress();
    if (progress.streakFreezes <= 0) return false;
    progress.streakFreezes -= 1;
    saveProgress(progress);
    return true;
  }

  Set<String> unlockedChapterIds() =>
      _decodeIds(getProgress().unlockedChapterIdsJson);
  Set<String> unlockedThemeIds() =>
      _decodeIds(getProgress().unlockedThemeIdsJson);
  Set<String> unlockedBoardSkinIds() =>
      _decodeIds(getProgress().unlockedBoardSkinIdsJson);
  Set<String> unlockedObjectIds() =>
      _decodeIds(getProgress().unlockedObjectIdsJson);
  Set<String> unlockedMusicTrackIds() =>
      _decodeIds(getProgress().unlockedMusicTrackIdsJson);

  void unlockChapter(CampaignChapter chapter) {
    final progress = getProgress();
    _unlockChapterOnly(progress, chapter);
    saveProgress(progress);
  }

  void grantChapterCompletionReward(ChapterDefinition chapter) {
    final progress = getProgress();
    _grantCompletionRewardOn(progress, chapter);
    saveProgress(progress);
  }

  bool isThemeUnlocked(String themeId) => unlockedThemeIds().contains(themeId);

  void _unlockChapterOnly(
    PlayerProgress progress,
    ChapterDefinition chapter,
  ) {
    progress.unlockedChapterIdsJson =
        _addId(progress.unlockedChapterIdsJson, chapter.id);
  }

  void _grantCompletionRewardOn(
    PlayerProgress progress,
    ChapterDefinition chapter,
  ) {
    final reward = chapter.completionReward;
    if (reward.themeId != null) {
      progress.unlockedThemeIdsJson =
          _addId(progress.unlockedThemeIdsJson, reward.themeId!);
    }
    if (reward.boardSkinId != null) {
      progress.unlockedBoardSkinIdsJson =
          _addId(progress.unlockedBoardSkinIdsJson, reward.boardSkinId!);
    }
    if (reward.objectId != null) {
      progress.unlockedObjectIdsJson =
          _addId(progress.unlockedObjectIdsJson, reward.objectId!);
    }
    if (reward.musicTrackId != null) {
      progress.unlockedMusicTrackIdsJson =
          _addId(progress.unlockedMusicTrackIdsJson, reward.musicTrackId!);
    }
  }

  void unlockObject(String objectId) {
    final progress = getProgress();
    progress.unlockedObjectIdsJson =
        _addId(progress.unlockedObjectIdsJson, objectId);
    saveProgress(progress);
  }

  void markTutorialBoardCompleted(int boardNumber) {
    if (boardNumber < 1 || boardNumber > tutorialBoardCount) return;
    final progress = getProgress();
    if (boardNumber > progress.tutorialBoardsCompleted) {
      progress.tutorialBoardsCompleted = boardNumber;
      saveProgress(progress);
    }
  }

  bool isTutorialRewardClaimed(int boardNumber) {
    if (boardNumber < 1 || boardNumber > tutorialBoardCount) return false;
    return getProgress().tutorialRewardClaimsMask & (1 << (boardNumber - 1)) !=
        0;
  }

  bool claimTutorialReward(int boardNumber) {
    if (boardNumber < 1 || boardNumber > tutorialBoardCount) return false;
    final progress = getProgress();
    if (progress.tutorialBoardsCompleted < boardNumber) return false;
    final bit = 1 << (boardNumber - 1);
    if (progress.tutorialRewardClaimsMask & bit != 0) return false;
    progress.tutorialRewardClaimsMask |= bit;
    saveProgress(progress);
    return true;
  }

  Set<String> _decodeIds(String value) {
    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>().toSet();
    } on FormatException {
      return <String>{};
    } on TypeError {
      return <String>{};
    }
  }

  String _addId(String value, String id) {
    final ids = _decodeIds(value)..add(id);
    final sorted = ids.toList()..sort();
    return jsonEncode(sorted);
  }

  /// Marks the main tutorial as seen.
  void markTutorialSeen() {
    final progress = getProgress();
    progress.tutorialSeen = true;
    saveProgress(progress);
  }

  void resetTutorialSeen() {
    final progress = getProgress();
    progress.tutorialSeen = false;
    progress.guidedTutorialSeen = false;
    progress.tutorialBoardsCompleted = 0;
    saveProgress(progress);
  }

  bool hasSeenGuidedTutorial() => getProgress().guidedTutorialSeen;

  void markGuidedTutorialSeen() {
    final progress = getProgress();
    progress.guidedTutorialSeen = true;
    saveProgress(progress);
  }

  void resetGuidedTutorial() {
    final progress = getProgress();
    progress.guidedTutorialSeen = false;
    saveProgress(progress);
  }

  /// Records that a rule tutorial was shown at this level.
  void markRuleTutorialSeen(int levelNumber) {
    final progress = getProgress();
    progress.lastRuleTutorialLevel = levelNumber;
    saveProgress(progress);
  }

  /// Returns true if the rule tutorial for this level has been shown before.
  bool hasSeenRuleTutorial(int levelNumber) {
    final progress = getProgress();
    return progress.lastRuleTutorialLevel >= levelNumber;
  }

  // ── Per-rule tutorial tracking ──────────────────────────

  bool hasSeenDiagonalRule() => getProgress().diagonalRuleSeen;
  void markDiagonalRuleSeen() {
    final progress = getProgress();
    progress.diagonalRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenMinDistanceRule() => getProgress().minDistanceRuleSeen;
  void markMinDistanceRuleSeen() {
    final progress = getProgress();
    progress.minDistanceRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenKnightMoveRule() => getProgress().knightMoveRuleSeen;
  void markKnightMoveRuleSeen() {
    final progress = getProgress();
    progress.knightMoveRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenMineRule() => getProgress().mineRuleSeen;
  void markMineRuleSeen() {
    final progress = getProgress();
    progress.mineRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenRowColumnRule() => getProgress().rowColumnRuleSeen;
  void markRowColumnRuleSeen() {
    final progress = getProgress();
    progress.rowColumnRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenColorRegionRule() => getProgress().colorRegionRuleSeen;
  void markColorRegionRuleSeen() {
    final progress = getProgress();
    progress.colorRegionRuleSeen = true;
    saveProgress(progress);
  }

  bool hasSeenNoTouchRule() => getProgress().noTouchRuleSeen;
  void markNoTouchRuleSeen() {
    final progress = getProgress();
    progress.noTouchRuleSeen = true;
    saveProgress(progress);
  }
}
