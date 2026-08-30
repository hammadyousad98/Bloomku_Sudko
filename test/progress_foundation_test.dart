import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zendoku/core/constants/app_constants.dart';
import 'package:zendoku/data/models/collection_progress.dart';
import 'package:zendoku/data/models/daily_challenge_history.dart';
import 'package:zendoku/data/models/level_result.dart';
import 'package:zendoku/data/models/player_progress.dart';
import 'package:zendoku/data/models/session_goal_state.dart';
import 'package:zendoku/data/models/daily_challenge_state.dart';
import 'package:zendoku/data/models/daily_reward_state.dart';
import 'package:zendoku/data/objectbox/objectbox.g.dart';
import 'package:zendoku/data/repositories/collection_repository.dart';
import 'package:zendoku/data/repositories/daily_history_repository.dart';
import 'package:zendoku/data/repositories/game_results_repository.dart';
import 'package:zendoku/data/repositories/progress_repository.dart';
import 'package:zendoku/data/repositories/session_goal_repository.dart';
import 'package:zendoku/data/repositories/daily_challenge_repository.dart';
import 'package:zendoku/data/repositories/reward_repository.dart';
import 'package:zendoku/features/main_menu/main_menu_cubit.dart';

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

  test('additive migration preserves existing inventory and progression', () {
    final box = store.box<PlayerProgress>();
    box.put(PlayerProgress()
      ..economyMigrationVersion = 0
      ..autoMarks = 3
      ..hints = 11
      ..extraLives = 4
      ..undos = 7
      ..normalHighest = 52
      ..hardHighest = 18
      ..ultraHighest = 9);

    final migrated = ProgressRepository(box).getProgress();
    expect(migrated.autoMarks, 3 + initialAutoMarkGrant);
    expect(migrated.hints, 11);
    expect(migrated.extraLives, 4);
    expect(migrated.undos, 7);
    expect(migrated.normalHighest, 52);
    expect(migrated.hardHighest, 18);
    expect(migrated.ultraHighest, 9);
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

    repository.markTutorialSeen();
    repository.markGuidedTutorialSeen();
    repository.resetTutorialSeen();
    expect(repository.getProgress().tutorialSeen, isFalse);
    expect(repository.getProgress().guidedTutorialSeen, isFalse);
    expect(repository.getProgress().tutorialBoardsCompleted, 0);
    expect(repository.isTutorialRewardClaimed(1), isTrue);

    repository.completeLevel(15, PuzzleTrack.normal);
    expect(repository.unlockedChapterIds(),
        containsAll({'blossom_garden', 'ocean_cove'}));
    expect(repository.unlockedThemeIds(), contains('theme_ocean_cove'));
    expect(repository.unlockedBoardSkinIds(), contains('board_ocean_cove'));
    expect(repository.unlockedMusicTrackIds(), contains('music_ocean_cove'));
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

  test('session goal progresses once per qualifying puzzle identity', () {
    final goals = SessionGoalRepository(store.box<SessionGoalState>());
    goals.setGoal(SessionGoalState()
      ..goalId = 'session:test:complete_three'
      ..goalType = 'complete_three'
      ..target = 3
      ..expiresAtMs = DateTime(2100).millisecondsSinceEpoch);

    PuzzleResult result(int level) => PuzzleResult()
      ..puzzleKey = 'normal:$level'
      ..mode = 'progression'
      ..track = 'normal'
      ..levelNumber = level
      ..completed = true;

    expect(goals.applyPuzzleResult(result(4)).changed, isTrue);
    expect(goals.applyPuzzleResult(result(4)).changed, isFalse);
    expect(goals.current!.progress, 1);
    goals.applyPuzzleResult(result(5));
    final finalUpdate = goals.applyPuzzleResult(result(6));
    expect(finalUpdate.newlyCompleted, isTrue);
    expect(goals.current!.progress, 3);
  });

  test('streak freeze covers exactly one missed day and is consumed once', () {
    final progress = ProgressRepository(store.box<PlayerProgress>());
    progress.getProgress();
    progress.addStreakFreezes(1);
    final challenges = DailyChallengeRepository(
      store.box<DailyChallengeState>(),
      DailyHistoryRepository(store.box<DailyChallengeHistory>()),
      progress,
    );
    final state = challenges.getState()
      ..lastCompletedDate = '2026-08-12'
      ..currentChallengeStreak = 4;
    store.box<DailyChallengeState>().put(state);

    final completion =
        challenges.markCompletedToday(date: DateTime(2026, 8, 14))!;
    expect(completion.usedStreakFreeze, isTrue);
    expect(completion.streak, 5);
    expect(progress.getProgress().streakFreezes, 0);
    expect(
      challenges.markCompletedToday(date: DateTime(2026, 8, 14)),
      isNull,
    );
  });

  test('login freeze preserves one missed-day streak without double use', () {
    final progress = ProgressRepository(store.box<PlayerProgress>());
    progress.getProgress();
    progress.addStreakFreezes(1);
    final rewards = RewardRepository(store.box<DailyRewardState>(), progress);
    final state = rewards.getState()
      ..lastClaimDate = '2026-08-12'
      ..currentStreakDay = 3
      ..claimedToday = true;
    store.box<DailyRewardState>().put(state);

    rewards.checkAndUpdateStreak(now: DateTime(2026, 8, 14));
    expect(rewards.getState().currentStreakDay, 3);
    expect(rewards.takeFreezeFeedback(), isTrue);
    expect(progress.getProgress().streakFreezes, 0);
    rewards.checkAndUpdateStreak(now: DateTime(2026, 8, 14));
    expect(rewards.takeFreezeFeedback(), isFalse);
    expect(rewards.getState().currentStreakDay, 3);
  });

  test('AutoMark inventory persists, consumes, and accepts ad replenishment', () {
    final repository = ProgressRepository(store.box<PlayerProgress>());
    final initial = repository.getProgress().autoMarks;
    expect(repository.useAutoMark(), isTrue);
    expect(repository.getProgress().autoMarks, initial - 1);

    // Rewarded-ad completion uses this same repository operation.
    repository.addAutoMarks(1);
    expect(repository.getProgress().autoMarks, initial);

    final reopened = ProgressRepository(store.box<PlayerProgress>());
    expect(reopened.getProgress().autoMarks, initial);
  });

  test('reward-ready badge refreshes after returning to the menu', () {
    final progress = ProgressRepository(store.box<PlayerProgress>());
    final history = DailyHistoryRepository(store.box<DailyChallengeHistory>());
    final rewards = RewardRepository(store.box<DailyRewardState>(), progress);
    final challenges = DailyChallengeRepository(
      store.box<DailyChallengeState>(),
      history,
      progress,
    );
    final cubit = MainMenuCubit(
      progress,
      rewards,
      CollectionRepository(store.box<CollectionProgress>()),
      GameResultsRepository(
        store.box<LevelResult>(),
        store.box<PuzzleResult>(),
      ),
      challenges,
      SessionGoalRepository(store.box<SessionGoalState>()),
    );
    expect(cubit.state.dailyReady, isTrue);

    final now = DateTime.now();
    history.recordCompletion(
      date: now,
      elapsedMs: 50000,
      score: 900,
      mistakes: 0,
      streak: 1,
      shareGridData: 'result',
    );
    rewards.claimTodayReward(now: now);
    cubit.loadData();
    expect(cubit.state.dailyReady, isFalse);
    cubit.close();
  });
}
