import 'package:equatable/equatable.dart';
import '../../../core/utils/daily_challenge_config.dart';
import '../../../core/utils/puzzle_generator.dart';
import '../domain/star_calculation.dart';

enum GamePhase {
  loading,
  playing,
  paused,
  levelComplete,
  gameOver,
  reviveOffer,
  generationError,
}

enum GameMode { progression, dailyChallenge }

class WinSummary extends Equatable {
  const WinSummary({
    required this.starCalculation,
    required this.personalBest,
    required this.isNewBest,
    required this.chapterName,
    required this.collectibleCount,
    required this.collectibleTarget,
    required this.nextCollectible,
    required this.nextUnlock,
    required this.levelsToUnlock,
    required this.chapterCompletedNow,
    this.sessionGoalMessage,
  });

  final StarCalculation starCalculation;
  final Duration personalBest;
  final bool isNewBest;
  final String chapterName;
  final int collectibleCount;
  final int collectibleTarget;
  final String? nextCollectible;
  final String? nextUnlock;
  final int levelsToUnlock;
  final bool chapterCompletedNow;
  final String? sessionGoalMessage;

  WinSummary copyWith({String? sessionGoalMessage}) => WinSummary(
        starCalculation: starCalculation,
        personalBest: personalBest,
        isNewBest: isNewBest,
        chapterName: chapterName,
        collectibleCount: collectibleCount,
        collectibleTarget: collectibleTarget,
        nextCollectible: nextCollectible,
        nextUnlock: nextUnlock,
        levelsToUnlock: levelsToUnlock,
        chapterCompletedNow: chapterCompletedNow,
        sessionGoalMessage: sessionGoalMessage ?? this.sessionGoalMessage,
      );

  @override
  List<Object?> get props => [
        starCalculation.stars,
        starCalculation.mistakeStarEarned,
        starCalculation.masteryStarEarned,
        starCalculation.parTime,
        personalBest,
        isNewBest,
        chapterName,
        collectibleCount,
        collectibleTarget,
        nextCollectible,
        nextUnlock,
        levelsToUnlock,
        chapterCompletedNow,
        sessionGoalMessage,
      ];
}

class GameState extends Equatable {
  final GamePhase phase;
  final GeneratedPuzzle puzzle;
  final List<TileState> tileStates;
  final int placedCount;
  final int targetCount;
  final int livesRemaining;
  final int maxLives;
  final int score;
  final int mistakeCount;
  final Duration elapsed;
  final int hintCount;
  final int undoCount;
  final int bulbCount;
  final int autoMarkCount;
  final int autoMarksUsed;
  final int hintsUsed;
  final int undosUsed;
  final int solveRowsUsed;
  final int extraLiveCount;
  final PuzzleTrack activeTrack;
  final int levelNumber;
  final GameMode mode;
  final DailyChallengeDay? activeDailyDay;
  final bool showDifficultyBar;
  final bool showUltraTab;
  final List<int> moveHistory;
  final List<List<int>> autoMarkHistory;
  final List<String> actionHistory;
  final bool isAdPresenting;
  final String? statusMessage;
  final bool showRuleTutorial;
  final int? errorTileIndex;
  final int? hintTileIndex;
  final List<String> pendingRuleTutorials;
  final String? rewardMessage;
  final int? mineTileIndex;
  final List<int>? tutorialHighlightIndexes;
  final int lifeLostToken;
  final int? lifeLostTileIndex;
  final int? lifeLostTargetHeartIndex;
  final bool guidedModeActive;
  final int guidedStepIndex;
  final int? guidedInteractableIndex;
  final bool guidedTeachingMarker;
  final String? guidedInstructionText;

  final bool guidedPreviewActive;
  final String? guidedPreviewRule;
  final String? guidedFeedbackText;
  final bool guidedGotchaActive;
  final bool guidedGotchaTriggered;
  final bool showGuidedRecap;
  final WinSummary? winSummary;

  bool get powersEnabled =>
      phase == GamePhase.playing &&
      !guidedModeActive &&
      pendingRuleTutorials.isEmpty &&
      !guidedPreviewActive &&
      !showGuidedRecap &&
      !isAdPresenting;

  const GameState({
    required this.phase,
    required this.puzzle,
    required this.tileStates,
    required this.placedCount,
    required this.targetCount,
    required this.livesRemaining,
    required this.maxLives,
    required this.score,
    required this.mistakeCount,
    required this.elapsed,
    required this.hintCount,
    required this.undoCount,
    required this.bulbCount,
    required this.autoMarkCount,
    this.autoMarksUsed = 0,
    this.hintsUsed = 0,
    this.undosUsed = 0,
    this.solveRowsUsed = 0,
    required this.extraLiveCount,
    required this.activeTrack,
    required this.levelNumber,
    this.mode = GameMode.progression,
    this.activeDailyDay,
    required this.showDifficultyBar,
    required this.showUltraTab,
    required this.moveHistory,
    this.autoMarkHistory = const [],
    this.actionHistory = const [],
    this.isAdPresenting = false,
    this.statusMessage,
    this.showRuleTutorial = false,
    this.errorTileIndex,
    this.hintTileIndex,
    this.pendingRuleTutorials = const [],
    this.rewardMessage,
    this.mineTileIndex,
    this.tutorialHighlightIndexes,
    this.lifeLostToken = 0,
    this.lifeLostTileIndex,
    this.lifeLostTargetHeartIndex,
    this.guidedModeActive = false,
    this.guidedStepIndex = 0,
    this.guidedInteractableIndex,
    this.guidedTeachingMarker = false,
    this.guidedInstructionText,
    this.guidedPreviewActive = false,
    this.guidedPreviewRule,
    this.guidedFeedbackText,
    this.guidedGotchaActive = false,
    this.guidedGotchaTriggered = false,
    this.showGuidedRecap = false,
    this.winSummary,
  });

  GameState copyWith({
    GamePhase? phase,
    GeneratedPuzzle? puzzle,
    List<TileState>? tileStates,
    int? placedCount,
    int? targetCount,
    int? livesRemaining,
    int? maxLives,
    int? score,
    int? mistakeCount,
    Duration? elapsed,
    int? hintCount,
    int? undoCount,
    int? bulbCount,
    int? autoMarkCount,
    int? autoMarksUsed,
    int? hintsUsed,
    int? undosUsed,
    int? solveRowsUsed,
    int? extraLiveCount,
    PuzzleTrack? activeTrack,
    int? levelNumber,
    GameMode? mode,
    DailyChallengeDay? activeDailyDay,
    bool clearActiveDailyDay = false,
    bool? showDifficultyBar,
    bool? showUltraTab,
    List<int>? moveHistory,
    List<List<int>>? autoMarkHistory,
    List<String>? actionHistory,
    bool? isAdPresenting,
    String? statusMessage,
    bool? showRuleTutorial,
    int? errorTileIndex,
    int? hintTileIndex,
    List<String>? pendingRuleTutorials,
    String? rewardMessage,
    bool clearRewardMessage = false,
    int? mineTileIndex,
    List<int>? tutorialHighlightIndexes,
    bool clearTutorialHighlightIndexes = false,
    int? lifeLostToken,
    int? lifeLostTileIndex,
    int? lifeLostTargetHeartIndex,
    bool? guidedModeActive,
    int? guidedStepIndex,
    int? guidedInteractableIndex,
    bool clearGuidedInteractableIndex = false,
    bool? guidedTeachingMarker,
    String? guidedInstructionText,
    bool clearGuidedInstructionText = false,
    bool? guidedPreviewActive,
    String? guidedPreviewRule,
    bool clearGuidedPreviewRule = false,
    String? guidedFeedbackText,
    bool clearGuidedFeedbackText = false,
    bool? guidedGotchaActive,
    bool? guidedGotchaTriggered,
    bool? showGuidedRecap,
    WinSummary? winSummary,
    bool clearWinSummary = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      puzzle: puzzle ?? this.puzzle,
      tileStates: tileStates ?? this.tileStates,
      placedCount: placedCount ?? this.placedCount,
      targetCount: targetCount ?? this.targetCount,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      maxLives: maxLives ?? this.maxLives,
      score: score ?? this.score,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      elapsed: elapsed ?? this.elapsed,
      hintCount: hintCount ?? this.hintCount,
      undoCount: undoCount ?? this.undoCount,
      bulbCount: bulbCount ?? this.bulbCount,
      autoMarkCount: autoMarkCount ?? this.autoMarkCount,
      autoMarksUsed: autoMarksUsed ?? this.autoMarksUsed,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      undosUsed: undosUsed ?? this.undosUsed,
      solveRowsUsed: solveRowsUsed ?? this.solveRowsUsed,
      extraLiveCount: extraLiveCount ?? this.extraLiveCount,
      activeTrack: activeTrack ?? this.activeTrack,
      levelNumber: levelNumber ?? this.levelNumber,
      mode: mode ?? this.mode,
      activeDailyDay:
          clearActiveDailyDay ? null : activeDailyDay ?? this.activeDailyDay,
      showDifficultyBar: showDifficultyBar ?? this.showDifficultyBar,
      showUltraTab: showUltraTab ?? this.showUltraTab,
      moveHistory: moveHistory ?? this.moveHistory,
      autoMarkHistory: autoMarkHistory ?? this.autoMarkHistory,
      actionHistory: actionHistory ?? this.actionHistory,
      isAdPresenting: isAdPresenting ?? this.isAdPresenting,
      statusMessage: statusMessage ?? this.statusMessage,
      showRuleTutorial: showRuleTutorial ?? this.showRuleTutorial,
      errorTileIndex:
          errorTileIndex, // Allow clearing by not defaulting to this.
      hintTileIndex: hintTileIndex, // Allow clearing by not defaulting to this.
      pendingRuleTutorials: pendingRuleTutorials ?? this.pendingRuleTutorials,
      rewardMessage:
          clearRewardMessage ? null : rewardMessage ?? this.rewardMessage,
      mineTileIndex: mineTileIndex, // Allow clearing by not defaulting
      tutorialHighlightIndexes: clearTutorialHighlightIndexes
          ? null
          : tutorialHighlightIndexes ?? this.tutorialHighlightIndexes,
      lifeLostToken: lifeLostToken ?? this.lifeLostToken,
      lifeLostTileIndex: lifeLostTileIndex, // Allow clearing
      lifeLostTargetHeartIndex: lifeLostTargetHeartIndex, // Allow clearing
      guidedModeActive: guidedModeActive ?? this.guidedModeActive,
      guidedStepIndex: guidedStepIndex ?? this.guidedStepIndex,
      guidedInteractableIndex: clearGuidedInteractableIndex
          ? null
          : (guidedInteractableIndex ?? this.guidedInteractableIndex),
      guidedTeachingMarker: guidedTeachingMarker ?? this.guidedTeachingMarker,
      guidedInstructionText: clearGuidedInstructionText
          ? null
          : (guidedInstructionText ?? this.guidedInstructionText),
      guidedPreviewActive: guidedPreviewActive ?? this.guidedPreviewActive,
      guidedPreviewRule: clearGuidedPreviewRule
          ? null
          : (guidedPreviewRule ?? this.guidedPreviewRule),
      guidedFeedbackText: clearGuidedFeedbackText
          ? null
          : (guidedFeedbackText ?? this.guidedFeedbackText),
      guidedGotchaActive: guidedGotchaActive ?? this.guidedGotchaActive,
      guidedGotchaTriggered:
          guidedGotchaTriggered ?? this.guidedGotchaTriggered,
      showGuidedRecap: showGuidedRecap ?? this.showGuidedRecap,
      winSummary: clearWinSummary ? null : winSummary ?? this.winSummary,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        puzzle,
        tileStates,
        placedCount,
        targetCount,
        livesRemaining,
        maxLives,
        score,
        mistakeCount,
        elapsed,
        hintCount,
        undoCount,
        bulbCount,
        autoMarkCount,
        autoMarksUsed,
        hintsUsed,
        undosUsed,
        solveRowsUsed,
        extraLiveCount,
        activeTrack,
        levelNumber,
        mode,
        activeDailyDay,
        showDifficultyBar,
        showUltraTab,
        moveHistory,
        autoMarkHistory,
        actionHistory,
        isAdPresenting,
        statusMessage,
        showRuleTutorial,
        errorTileIndex,
        hintTileIndex,
        pendingRuleTutorials,
        rewardMessage,
        mineTileIndex,
        tutorialHighlightIndexes,
        lifeLostToken,
        lifeLostTileIndex,
        lifeLostTargetHeartIndex,
        guidedModeActive,
        guidedStepIndex,
        guidedInteractableIndex,
        guidedTeachingMarker,
        guidedInstructionText,
        guidedPreviewActive,
        guidedPreviewRule,
        guidedFeedbackText,
        guidedGotchaActive,
        guidedGotchaTriggered,
        showGuidedRecap,
        winSummary,
      ];
}
