import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/game_results_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/session_goal_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/puzzle_generator.dart';
import '../../core/config/feature_flags.dart';

class MainMenuState extends Equatable {
  final int hints;
  final int extraLives;
  final int undos;
  final int bulbs;
  final int autoMarks;
  final int cosmeticCurrency;
  final int streakDay;
  final bool canClaimToday;
  final int campaignLevel;
  final String chapterName;
  final int gridSize;
  final int collectibleCount;
  final int collectibleTarget;
  final String nextMilestone;
  final int chapterStars;
  final bool dailyReady;
  final bool streakFreezeUsed;
  final String sessionGoalTitle;
  final int sessionGoalProgress;
  final int sessionGoalTarget;
  final bool sessionGoalCompleted;
  final String sessionGoalReward;

  const MainMenuState({
    required this.hints,
    required this.extraLives,
    required this.undos,
    required this.bulbs,
    required this.autoMarks,
    required this.cosmeticCurrency,
    required this.streakDay,
    required this.canClaimToday,
    required this.campaignLevel,
    required this.chapterName,
    required this.gridSize,
    required this.collectibleCount,
    required this.collectibleTarget,
    required this.nextMilestone,
    required this.chapterStars,
    required this.dailyReady,
    required this.streakFreezeUsed,
    required this.sessionGoalTitle,
    required this.sessionGoalProgress,
    required this.sessionGoalTarget,
    required this.sessionGoalCompleted,
    required this.sessionGoalReward,
  });

  @override
  List<Object> get props => [
        hints,
        extraLives,
        undos,
        bulbs,
        autoMarks,
        cosmeticCurrency,
        streakDay,
        canClaimToday,
        campaignLevel,
        chapterName,
        gridSize,
        collectibleCount,
        collectibleTarget,
        nextMilestone,
        chapterStars,
        dailyReady,
        streakFreezeUsed,
        sessionGoalTitle,
        sessionGoalProgress,
        sessionGoalTarget,
        sessionGoalCompleted,
        sessionGoalReward,
      ];
}

class MainMenuCubit extends Cubit<MainMenuState> {
  MainMenuCubit(
    this._progressRepo,
    this._rewardRepo,
    this._collectionRepo,
    this._resultsRepo,
    this._dailyChallengeRepo,
    this._sessionGoalRepo,
  ) : super(const MainMenuState(
          hints: 0,
          extraLives: 0,
          undos: 0,
          bulbs: 0,
          autoMarks: 0,
          cosmeticCurrency: 0,
          streakDay: 0,
          canClaimToday: false,
          campaignLevel: 1,
          chapterName: 'Blossom Garden',
          gridSize: 4,
          collectibleCount: 0,
          collectibleTarget: 10,
          nextMilestone: 'Rose',
          chapterStars: 0,
          dailyReady: false,
          streakFreezeUsed: false,
          sessionGoalTitle: 'Preparing a session goal',
          sessionGoalProgress: 0,
          sessionGoalTarget: 1,
          sessionGoalCompleted: false,
          sessionGoalReward: '',
        )) {
    loadData();
  }

  final ProgressRepository _progressRepo;
  final RewardRepository _rewardRepo;
  final CollectionRepository _collectionRepo;
  final GameResultsRepository _resultsRepo;
  final DailyChallengeRepository _dailyChallengeRepo;
  final SessionGoalRepository _sessionGoalRepo;

  void loadData() {
    _rewardRepo.checkAndUpdateStreak();
    final progress = _progressRepo.getProgress();
    final rewardState = _rewardRepo.getState();
    final campaignLevel = progress.normalHighest.clamp(
      1,
      FeatureFlags.current.campaignMaxLevel,
    );
    final chapter = chapterForLevel(campaignLevel)!;
    final collection = _collectionRepo.progressFor(chapter.id);
    final sessionGoal = _sessionGoalRepo.ensureActive();
    final sessionDefinition = _sessionGoalRepo.definitionFor(sessionGoal);
    final nextMilestone =
        collection.collectedCount < chapter.collectibles.length
            ? chapter.collectibles[collection.collectedCount].name
            : chapter.completionReward.label;

    emit(MainMenuState(
      hints: progress.hints,
      extraLives: progress.extraLives,
      undos: progress.undos,
      bulbs: progress.bulbs,
      autoMarks: progress.autoMarks,
      cosmeticCurrency: progress.cosmeticCurrency,
      streakDay: rewardState.currentStreakDay,
      canClaimToday: _rewardRepo.canClaimToday(),
      campaignLevel: campaignLevel,
      chapterName: chapter.name,
      gridSize: PuzzleGenerator.gridSizeForLevel(
        campaignLevel,
        PuzzleTrack.normal,
      ),
      collectibleCount: collection.collectedCount,
      collectibleTarget: collection.targetCount,
      nextMilestone: nextMilestone,
      chapterStars: _resultsRepo.totalStarsForChapter(chapter),
      dailyReady: !_dailyChallengeRepo.hasCompletedToday() ||
          _rewardRepo.canClaimToday(),
      streakFreezeUsed: _rewardRepo.takeFreezeFeedback(),
      sessionGoalTitle: sessionDefinition.title,
      sessionGoalProgress: sessionGoal.progress,
      sessionGoalTarget: sessionGoal.target,
      sessionGoalCompleted: sessionGoal.completed,
      sessionGoalReward: _rewardLabel(
        sessionGoal.rewardType,
        sessionGoal.rewardAmount,
      ),
    ));
  }

  String _rewardLabel(String type, int amount) => switch (type) {
        'collection_progress' => '+$amount collection progress',
        'cosmetic_currency' => '+$amount cosmetic petals',
        'streak_freeze' => '+$amount streak freeze',
        'auto_mark' => '+$amount AutoMark',
        _ => '+$amount reward',
      };
}
