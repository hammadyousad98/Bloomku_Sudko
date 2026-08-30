import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/utils/puzzle_generator.dart';
import '../data/models/collection_progress.dart';
import '../data/models/daily_challenge_history.dart';
import '../data/models/daily_reward_state.dart';
import '../data/models/level_result.dart';
import '../data/models/player_progress.dart';
import '../data/models/session_goal_state.dart';
import '../data/models/settings_model.dart';
import '../data/objectbox/objectbox.dart';
import '../data/repositories/game_session_repository.dart';

/// Produces the neutral, versioned JSON payload consumed by the Unity build.
/// This exporter is intentionally read-only: it never changes ObjectBox data.
class UnityMigrationExportService {
  UnityMigrationExportService(this._objectBox, this._sessions);

  final ObjectBoxStore _objectBox;
  final GameSessionRepository _sessions;

  String buildJson({String? migrationId, DateTime? now}) {
    final progress = _objectBox.progressBox.getAll().firstOrNull ?? PlayerProgress();
    final settings = _objectBox.settingsBox.getAll().firstOrNull ?? SettingsModel();
    final reward = _objectBox.rewardBox.getAll().firstOrNull;
    final goal = _objectBox.sessionGoalBox.getAll().firstOrNull;
    final track = _sessions.lastTrack;
    final session = _sessions.load(track);
    final timestamp = now ?? DateTime.now().toUtc();

    final payload = UnityMigrationMapper.build(
      migrationId: migrationId ?? 'flutter-${timestamp.microsecondsSinceEpoch}',
      progress: progress,
      settings: settings,
      reward: reward,
      goal: goal,
      levels: _objectBox.levelResultBox.getAll(),
      dailyHistory: _objectBox.dailyHistoryBox.getAll(),
      collections: _objectBox.collectionBox.getAll(),
      activeTrack: track,
      activeSession: session,
    );
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<File> writeExportFile({String? migrationId}) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'zenduko-unity-migration.json'));
    return file.writeAsString(buildJson(migrationId: migrationId), flush: true);
  }
}

/// Public pure mapper so migration fixtures can be tested without opening a
/// database or touching the filesystem.
class UnityMigrationMapper {
  static Map<String, Object?> build({
    required String migrationId,
    required PlayerProgress progress,
    required SettingsModel settings,
    required List<LevelResult> levels,
    required List<DailyChallengeHistory> dailyHistory,
    required List<CollectionProgress> collections,
    required PuzzleTrack activeTrack,
    required SavedGameSession? activeSession,
    DailyRewardState? reward,
    SessionGoalState? goal,
  }) {
    return {
      'MigrationId': migrationId,
      'SourceSchemaVersion': 1,
      'Progress': _progress(progress, reward, goal, levels, dailyHistory, collections),
      'Settings': _settings(settings),
      'ActiveSession': _activeSession(activeTrack, activeSession),
    };
  }

  static Map<String, Object?> _progress(
    PlayerProgress value,
    DailyRewardState? reward,
    SessionGoalState? goal,
    List<LevelResult> levels,
    List<DailyChallengeHistory> dailyHistory,
    List<CollectionProgress> collections,
  ) {
    final unlocked = <String>{
      ..._decodeIds(value.unlockedChapterIdsJson).map((id) => 'chapter.$id'),
      ..._decodeIds(value.unlockedThemeIdsJson).map((id) => 'theme.$id'),
      ..._decodeIds(value.unlockedBoardSkinIdsJson).map((id) => 'board.$id'),
      ..._decodeIds(value.unlockedObjectIdsJson).map((id) => 'object.$id'),
      ..._decodeIds(value.unlockedMusicTrackIdsJson).map((id) => 'music.$id'),
    }.toList()
      ..sort();

    return {
      'EconomyMigrationVersion': value.economyMigrationVersion,
      'NormalHighest': value.normalHighest,
      'HardHighest': value.hardHighest,
      'UltraHardHighest': value.ultraHighest,
      'AutoMarks': value.autoMarks,
      'Hints': value.hints,
      'SolveRows': value.bulbs,
      'Undos': value.undos,
      'ExtraLives': value.extraLives,
      'StreakFreezes': value.streakFreezes,
      'CosmeticCurrency': value.cosmeticCurrency,
      'AdsRemoved': value.adsRemoved,
      'LevelsCompletedCount': value.levelsCompletedCount,
      'LastRuleTutorialLevel': value.lastRuleTutorialLevel,
      'GuidedTutorialSeen': value.guidedTutorialSeen,
      'RowColumnRuleSeen': value.rowColumnRuleSeen,
      'ColorRegionRuleSeen': value.colorRegionRuleSeen,
      'NoTouchRuleSeen': value.noTouchRuleSeen,
      'DiagonalRuleSeen': value.diagonalRuleSeen,
      'MinimumDistanceRuleSeen': value.minDistanceRuleSeen,
      'KnightMoveRuleSeen': value.knightMoveRuleSeen,
      'MineRuleSeen': value.mineRuleSeen,
      'UnlockedContent': unlocked,
      'Levels': levels.map(_level).toList(),
      'DailyHistory': dailyHistory.map(_daily).toList(),
      'Collections': collections.map(_collection).toList(),
      'DailyReward': {
        'CurrentStreakDay': reward?.currentStreakDay ?? 0,
        'LastClaimDate': reward?.lastClaimDate ?? '',
        'LastFreezeUsedDate': reward?.lastFreezeUsedDate ?? '',
      },
      'SessionGoal': _sessionGoal(goal),
      'Tutorial': {
        'BoardsCompleted': List.generate(3, (index) => value.tutorialBoardsCompleted > index),
        'RewardsClaimed': List.generate(
          3,
          (index) => value.tutorialRewardClaimsMask & (1 << index) != 0,
        ),
      },
      'ProcessedResultIds': <String>[],
    };
  }

  static Map<String, Object?> _settings(SettingsModel value) {
    const themes = [
      'theme_blossom_garden',
      'theme_ocean_cove',
      'theme_forest_trail',
      'theme_cosmic_garden',
      'theme_peach_orchard',
    ];
    final index = value.selectedThemeIndex.clamp(0, themes.length - 1);
    final theme = themes[index];
    return {
      'MusicEnabled': value.musicVolume > 0,
      'EffectsEnabled': value.sfxVolume > 0,
      'HapticsEnabled': value.vibrationEnabled,
      'ReminderNotificationsEnabled': false,
      'MusicVolume': value.musicVolume,
      'EffectsVolume': value.sfxVolume,
      'SelectedThemeId': theme,
      'SelectedBoardSkinId': theme.replaceFirst('theme_', 'board_'),
      'SelectedObjectId': 'tutorial_seedling',
      'SelectedMusicTrackId': theme.replaceFirst('theme_', 'music_'),
    };
  }

  static Map<String, Object?> _level(LevelResult value) => {
        'Level': value.levelNumber,
        'Difficulty': _trackIndex(value.track),
        'BestSeconds': value.bestTimeMs / 1000.0,
        'BestScore': value.bestScore,
        'Stars': value.highestStars,
        'CompletionCount': value.completionCount,
      };

  static Map<String, Object?> _daily(DailyChallengeHistory value) => {
        'Date': value.dateKey,
        'Completed': value.completed,
        'BestSeconds': value.bestTimeMs / 1000.0,
        'Mistakes': value.lowestMistakes,
        'Streak': value.streakAtCompletion,
        'ShareGrid': value.shareGridData,
      };

  static Map<String, Object?> _collection(CollectionProgress value) => {
        'ChapterId': value.chapterId,
        'CollectedIds': _decodeIds(value.collectedObjectIdsJson).toList()..sort(),
        'Target': value.targetCount,
        'RewardClaimed': value.completionRewardClaimed,
      };

  static Map<String, Object?> _sessionGoal(SessionGoalState? value) => {
        'GoalId': value?.goalId ?? '',
        'GoalType': value?.goalType ?? '',
        'Current': value?.progress ?? 0,
        'Target': value?.target ?? 0,
        'RewardType': value?.rewardType ?? '',
        'RewardAmount': value?.rewardAmount ?? 0,
        'Completed': value?.completed ?? false,
        'RewardClaimed': value?.rewardClaimed ?? false,
        'StartedAtUnixMs': value?.startedAtMs ?? 0,
        'ExpiresAtUnixMs': value?.expiresAtMs ?? 0,
        'QualifyingPuzzleIds': _decodeIds(value?.qualifyingPuzzleIdsJson ?? '[]').toList()..sort(),
        'SessionId': value?.goalId ?? '',
      };

  static Map<String, Object?>? _activeSession(
    PuzzleTrack track,
    SavedGameSession? saved,
  ) {
    if (saved == null) return null;
    final config = PuzzleGenerator.configForLevel(saved.levelNumber, track);
    final puzzle = PuzzleGenerator.generate(config);
    if (!puzzle.isValid || saved.tileStates.length != puzzle.gridSize * puzzle.gridSize) {
      return null;
    }
    return {
      'Puzzle': {
        'GridSize': puzzle.gridSize,
        'RegionMap': puzzle.colorMap,
        'SolutionIndexes': puzzle.solutionIndexes,
        'LockedIndexes': puzzle.lockedIndexes,
        'MineIndexes': puzzle.mineIndexes,
        'Config': {
          'GridSize': config.gridSize,
          'LevelNumber': config.levelNumber,
          'Difficulty': track.index,
          'BlockFullDiagonal': config.blockFullDiagonal,
          'BlockMinimumDistance': config.blockMinDistance,
          'MinimumDistance': config.minDistance,
          'BlockKnightMove': config.blockKnightMove,
          'IncludeLockedFlower': config.includeLockedFlower,
          'SeedOverride': 0,
        },
      },
      'Cells': saved.tileStates.map(_tileStateIndex).toList(),
      'Difficulty': track.index,
      'Mode': 0,
      'Phase': 1,
      'LevelNumber': saved.levelNumber,
      'LivesRemaining': saved.livesRemaining,
      'Mistakes': saved.mistakeCount,
      'Score': 0,
      'ElapsedSeconds': saved.elapsedSeconds.toDouble(),
      'Usage': {
        'Hints': saved.hintsUsed,
        'SolveRows': saved.solveRowsUsed,
        'AutoMarks': saved.autoMarksUsed,
        'Undos': saved.undosUsed,
      },
      'History': <Object>[],
    };
  }

  static int _trackIndex(String value) => switch (value) {
        'hard' => 1,
        'ultraHard' => 2,
        _ => 0,
      };

  static int _tileStateIndex(TileState value) => switch (value) {
        TileState.empty => 0,
        TileState.marker => 1,
        TileState.autoMarker => 2,
        TileState.object => 3,
        TileState.lockedObject => 4,
        TileState.revealedMine => 5,
      };

  static Set<String> _decodeIds(String value) {
    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }
}
