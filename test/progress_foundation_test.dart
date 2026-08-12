import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zendoku/core/constants/app_constants.dart';
import 'package:zendoku/data/models/collection_progress.dart';
import 'package:zendoku/data/models/daily_challenge_history.dart';
import 'package:zendoku/data/models/level_result.dart';
import 'package:zendoku/data/models/player_progress.dart';
import 'package:zendoku/data/models/session_goal_state.dart';
import 'package:zendoku/data/objectbox/objectbox.g.dart';
import 'package:zendoku/data/repositories/collection_repository.dart';
import 'package:zendoku/data/repositories/daily_history_repository.dart';
import 'package:zendoku/data/repositories/game_results_repository.dart';
import 'package:zendoku/data/repositories/progress_repository.dart';
import 'package:zendoku/data/repositories/session_goal_repository.dart';

void main() {
  late Directory directory;
  late Store store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('bloomku-progress-test-');
    store = Store(getObjectBoxModel(), directory: directory.path);
  });

  tearDown(() {
    store.close();
    directory.deleteSync(recursive: true);
  });

  test('campaign chapters cover levels 1 through 80 without overlap', () {
    expect(maxLevelCount, 80);
    for (var level = 1; level <= maxLevelCount; level++) {
      final matches =
          campaignChapters.where((chapter) => chapter.contains(level));
      expect(matches, hasLength(1),
          reason: 'level $level must have one chapter');
      expect(chapterForLevel(level), matches.single);
    }
    expect(campaignChapters.map((chapter) => chapter.startLevel),
        [1, 16, 31, 51, 66]);
    expect(campaignChapters.map((chapter) => chapter.endLevel),
        [15, 30, 50, 65, 80]);
  });

  test('economy migration grants five AutoMarks exactly once', () {
    final box = store.box<PlayerProgress>();
    final oldProgress = PlayerProgress()
      ..autoMarks = 0
      ..economyMigrationVersion = 0
      ..hints = 13
      ..undos = 9
      ..normalHighest = 27;
    box.put(oldProgress);

    final repository = ProgressRepository(box);
    final migrated = repository.getProgress();
    expect(migrated.autoMarks, initialAutoMarkGrant);
    expect(migrated.economyMigrationVersion, currentEconomyMigrationVersion);
    expect(migrated.hints, 13);
    expect(migrated.undos, 9);
    expect(migrated.normalHighest, 27);
    expect(repository.unlockedChapterIds(), {'blossom_garden', 'ocean_cove'});
    expect(repository.unlockedThemeIds(),
        {'theme_blossom_garden', 'theme_ocean_cove'});

    expect(repository.getProgress().autoMarks, initialAutoMarkGrant);
  });

  test('new progress has initial unlocks and supports tutorial claims', () {
    final repository = ProgressRepository(store.box<PlayerProgress>());
    final progress = repository.getProgress();
    expect(progress.autoMarks, initialAutoMarkGrant);
    expect(repository.unlockedChapterIds(), {'blossom_garden'});

    repository.markTutorialBoardCompleted(1);
    expect(repository.claimTutorialReward(1), isTrue);
    expect(repository.claimTutorialReward(1), isFalse);
    expect(repository.isTutorialRewardClaimed(1), isTrue);

    repository.completeLevel(15, PuzzleTrack.normal);
    expect(repository.unlockedChapterIds(),
        containsAll({'blossom_garden', 'ocean_cove'}));
    repository.completeLevel(80, PuzzleTrack.normal);
    expect(repository.getProgress().normalHighest, maxLevelCount + 1);
    expect(repository.isLevelUnlocked(81, PuzzleTrack.normal), isFalse);
  });

  test('puzzle history retains usage and updates best level result', () {
    final repository = GameResultsRepository(
      store.box<LevelResult>(),
      store.box<PuzzleResult>(),
    );
    repository.recordPuzzle(PuzzleResult()
      ..puzzleKey = 'normal:14:first'
      ..levelNumber = 14
      ..track = 'normal'
      ..completed = true
      ..elapsedMs = 90000
      ..score = 1000
      ..stars = 2
      ..mistakes = 2
      ..hintsUsed = 1
      ..autoMarksUsed = 2);
    repository.recordPuzzle(PuzzleResult()
      ..puzzleKey = 'normal:14:second'
      ..levelNumber = 14
      ..track = 'normal'
      ..completed = true
      ..elapsedMs = 70000
      ..score = 1300
      ..stars = 3
      ..mistakes = 0);

    final aggregate = repository.levelResult(14, 'normal')!;
    expect(aggregate.completionCount, 2);
    expect(aggregate.bestTimeMs, 70000);
    expect(aggregate.bestScore, 1300);
    expect(aggregate.highestStars, 3);
    expect(aggregate.bestMistakeCount, 0);
    expect(repository.puzzleHistory().first.autoMarksUsed, anyOf(0, 2));
    expect(repository.puzzleHistory().map((item) => item.autoMarksUsed),
        contains(2));
  });

  test('daily history is keyed by full date and keeps personal best', () {
    final repository =
        DailyHistoryRepository(store.box<DailyChallengeHistory>());
    final date = DateTime(2026, 8, 13);
    repository.recordCompletion(
      date: date,
      elapsedMs: 80000,
      score: 500,
      mistakes: 2,
      streak: 4,
      shareGridData: 'first',
    );
    repository.recordCompletion(
      date: date,
      elapsedMs: 60000,
      score: 700,
      mistakes: 0,
      streak: 4,
      shareGridData: 'best',
    );

    final result = repository.resultForDate(date)!;
    expect(result.dateKey, '2026-08-13');
    expect(result.completionCount, 2);
    expect(result.bestTimeMs, 60000);
    expect(result.lowestMistakes, 0);
    expect(result.shareGridData, 'best');
  });

  test('session goal and collection rewards can only be claimed once', () {
    final goals = SessionGoalRepository(store.box<SessionGoalState>());
    goals.setGoal(SessionGoalState()
      ..goalId = 'three_puzzles'
      ..target = 3
      ..rewardType = 'collection_progress');
    goals.addProgress(3);
    expect(goals.current!.completed, isTrue);
    expect(goals.claimReward(), isTrue);
    expect(goals.claimReward(), isFalse);

    final collections = CollectionRepository(store.box<CollectionProgress>());
    for (var index = 0; index < 10; index++) {
      collections.collect('blossom_garden', 'flower_$index');
    }
    expect(collections.progressFor('blossom_garden').chapterCompleted, isTrue);
    expect(collections.claimChapterReward('blossom_garden'), isTrue);
    expect(collections.claimChapterReward('blossom_garden'), isFalse);
  });
}
