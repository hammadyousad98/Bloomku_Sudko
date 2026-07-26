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
    if (existing.isNotEmpty) return existing.first;

    // New object MUST have id = 0 for ObjectBox to auto-assign
    final defaults = PlayerProgress(); // id defaults to 0
    _box.put(defaults);
    return defaults;
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
        progress.normalHighest = levelNumber + 1;
      }
    } else if (track == PuzzleTrack.hard) {
      if (levelNumber >= progress.hardHighest) {
        progress.hardHighest = levelNumber + 1;
      }
    } else if (track == PuzzleTrack.ultraHard) {
      if (levelNumber >= progress.ultraHighest) {
        progress.ultraHighest = levelNumber + 1;
      }
    }

    saveProgress(progress);
  }

  bool isLevelUnlocked(int levelNumber, PuzzleTrack track) {
    if (levelNumber < 1) return false;

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

  /// Marks the main tutorial as seen.
  void markTutorialSeen() {
    final progress = getProgress();
    progress.tutorialSeen = true;
    saveProgress(progress);
  }

  void resetTutorialSeen() {
    final progress = getProgress();
    progress.tutorialSeen = false;
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
