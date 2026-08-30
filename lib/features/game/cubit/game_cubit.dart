import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/daily_challenge_config.dart';
import '../../../core/utils/puzzle_generator.dart';
import '../../../data/repositories/daily_challenge_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/game_session_repository.dart';
import '../../../data/repositories/game_results_repository.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../data/repositories/daily_history_repository.dart';
import '../../../data/repositories/session_goal_repository.dart';
import '../../../data/models/level_result.dart';
import '../../../data/models/session_goal_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/analytics/onboarding_analytics.dart';
import '../../../core/config/feature_flags.dart';
import 'game_state.dart';
import 'game_scoring.dart';
import 'auto_mark_logic.dart';
import '../domain/star_calculation.dart';
import '../../daily_challenges/daily_share_card.dart';

import '../../../services/ad_service.dart';
import '../../../services/audio_service.dart';

GeneratedPuzzle _generatePuzzleIsolate(PuzzleConfig config) {
  var puzzle = PuzzleGenerator.generate(config);
  if (!puzzle.isValid) {
    puzzle = PuzzleGenerator.generate(config);
  }
  return puzzle;
}

class GameCubit extends Cubit<GameState> {
  final ProgressRepository _progressRepo;
  final SettingsRepository _settingsRepo;
  final DailyChallengeRepository _dailyChallengeRepo;
  final GameSessionRepository _sessionRepo;
  final OnboardingAnalytics _onboardingAnalytics;
  final GameResultsRepository _gameResultsRepo;
  final CollectionRepository _collectionRepo;
  final DailyHistoryRepository _dailyHistoryRepo;
  final SessionGoalRepository _sessionGoalRepo;

  final Map<PuzzleTrack, _InProgressSnapshot> _trackSnapshots = {};

  static const Duration _generationTimeout = Duration(seconds: 5);

  Timer? _timer;
  int _generationToken = 0;

  GameCubit(
    this._progressRepo,
    this._settingsRepo,
    this._dailyChallengeRepo,
    this._sessionRepo,
    this._onboardingAnalytics,
    this._gameResultsRepo,
    this._collectionRepo,
    this._dailyHistoryRepo,
    this._sessionGoalRepo,
  ) : super(
          const GameState(
            phase: GamePhase.loading,
            puzzle: GeneratedPuzzle.invalid,
            tileStates: [],
            placedCount: 0,
            targetCount: 0,
            livesRemaining: 3,
            maxLives: 3,
            score: 0,
            mistakeCount: 0,
            elapsed: Duration.zero,
            hintCount: 0,
            undoCount: 0,
            bulbCount: 0,
            autoMarkCount: 0,
            extraLiveCount: 0,
            activeTrack: PuzzleTrack.normal,
            levelNumber: 1,
            showDifficultyBar: false,
            showUltraTab: false,
            moveHistory: [],
          ),
        );

  @override
  Future<void> close() {
    _timer?.cancel();
    _persistCurrentGame();
    return super.close();
  }

  Future<void> startLevel(int levelNumber, PuzzleTrack track,
      {bool forceRestart = false}) async {
    if (forceRestart) {
      _trackSnapshots.remove(track);
      unawaited(_sessionRepo.clear(track));
    }
    await _startLevelInternal(levelNumber, track, forceRestart: forceRestart);
  }

  Future<void> startGuidedTutorial() async {
    emit(state.copyWith(
      guidedModeActive: true,
      guidedStepIndex: 0,
    ));
    await _startLevelInternal(
      1,
      PuzzleTrack.normal,
      forceRestart: true,
      includeLockedFlower: false,
    );
  }

  void _beginGuidedLevel() {
    emit(state.copyWith(
      guidedStepIndex: 0,
      guidedGotchaTriggered: false,
      guidedGotchaActive: false,
      guidedPreviewActive: true,
      guidedPreviewRule: state.levelNumber == 1
          ? 'rowColumn'
          : (state.levelNumber == 2 ? 'colorRegion' : 'noTouch'),
    ));
  }

  void finishGuidedPreview() {
    emit(state.copyWith(
        guidedPreviewActive: false, clearGuidedPreviewRule: true));
    if (state.levelNumber == 1) {
      _teachMarkerStep();
    } else {
      _guideCurrentStep();
    }
  }

  int _findMarkerDemoTileIndex() {
    for (int i = 0; i < state.puzzle.gridSize * state.puzzle.gridSize; i++) {
      if (!state.puzzle.solutionIndexes.contains(i)) {
        return i;
      }
    }
    return 0; // fallback
  }

  void _teachMarkerStep() {
    emit(state.copyWith(
      guidedInteractableIndex: _findMarkerDemoTileIndex(),
      guidedTeachingMarker: true,
      guidedInstructionText: "Long-press this cell to mark it with an ×",
    ));
  }

  void _guideCurrentStep() {
    if (state.levelNumber == 3 &&
        state.guidedStepIndex == state.puzzle.solutionIndexes.length - 1 &&
        !state.guidedGotchaTriggered) {
      int? gotchaIndex;
      if (state.puzzle.solutionIndexes.isNotEmpty) {
        int placedIndex = state.puzzle.solutionIndexes[0];
        int gridSize = state.puzzle.gridSize;
        int r = placedIndex ~/ gridSize;
        int c = placedIndex % gridSize;
        for (int dr in [-1, 1]) {
          for (int dc in [-1, 1]) {
            int nr = r + dr;
            int nc = c + dc;
            if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
              int idx = nr * gridSize + nc;
              if (state.tileStates[idx] == TileState.empty &&
                  !state.puzzle.lockedIndexes.contains(idx)) {
                gotchaIndex = idx;
                break;
              }
            }
          }
          if (gotchaIndex != null) break;
        }
      }

      if (gotchaIndex != null) {
        emit(state.copyWith(
            guidedGotchaActive: true,
            guidedInteractableIndex: gotchaIndex,
            guidedTeachingMarker: false,
            guidedInstructionText: "Try tapping here — see what happens"));
        return;
      }
    }

    if (state.guidedStepIndex >= state.puzzle.solutionIndexes.length) {
      _finishGuidedLevelGuidance();
      return;
    }
    final expectedIndex = state.puzzle.solutionIndexes[state.guidedStepIndex];
    String instr;
    if (state.levelNumber == 1) {
      instr =
          "Tap the highlighted tile to place a flower — only one per row & column";
    } else if (state.levelNumber == 2) {
      instr = "Tap the highlighted tile — only one flower per color region";
    } else {
      instr =
          "Tap the highlighted tile — flowers can't touch, not even diagonally";
    }

    emit(state.copyWith(
      guidedInteractableIndex: expectedIndex,
      guidedTeachingMarker: false,
      guidedInstructionText: instr,
    ));
  }

  void _finishGuidedLevelGuidance() {
    emit(state.copyWith(
      clearGuidedInteractableIndex: true,
      clearGuidedInstructionText: true,
    ));
  }

  void advanceGuidedLevel() {
    if (state.levelNumber >= 3) {
      completeGuidedTutorial();
    } else {
      _startLevelInternal(
        state.levelNumber + 1,
        PuzzleTrack.normal,
        forceRestart: true,
        includeLockedFlower: false,
      );
    }
  }

  void completeGuidedTutorial() {
    emit(state.copyWith(
      guidedModeActive: false,
      clearGuidedInteractableIndex: true,
      clearGuidedInstructionText: true,
      showGuidedRecap: true,
    ));
    _progressRepo.markGuidedTutorialSeen();
  }

  void cancelGuidedRecap() {
    emit(state.copyWith(showGuidedRecap: false));
  }

  void cancelGuidedTutorial() {
    emit(state.copyWith(
      guidedModeActive: false,
      clearGuidedInteractableIndex: true,
      clearGuidedInstructionText: true,
    ));
    _progressRepo.markGuidedTutorialSeen();
  }

  Future<void> startDailyChallenge() async {
    final config = dailyChallengeConfigFor(DateTime.now());
    await _startLevelInternal(
      config.level,
      config.track,
      mode: GameMode.dailyChallenge,
      dailyDay: config,
      includeLockedFlower: false,
    );
  }

  Future<void> _startLevelInternal(
    int levelNumber,
    PuzzleTrack track, {
    GameMode mode = GameMode.progression,
    DailyChallengeDay? dailyDay,
    bool forceRestart = false,
    bool includeLockedFlower = true,
  }) async {
    _timer?.cancel();
    final token = ++_generationToken;

    var effectiveLevel = levelNumber;
    var effectiveTrack = track;
    var config = PuzzleGenerator.configForLevel(
      levelNumber,
      track,
      includeLockedFlower: includeLockedFlower &&
          FeatureFlags.current.lockedFlowerAutoMarkIconsAndZoom,
    );
    var resolvedDailyDay = dailyDay;
    String? fallbackStatusMessage;
    final isDailyChallenge = mode == GameMode.dailyChallenge;

    if (!isDailyChallenge &&
        !_progressRepo.isLevelUnlocked(levelNumber, track)) {
      emit(state.copyWith(
        statusMessage:
            'That difficulty is not unlocked for level $levelNumber yet.',
      ));
      return;
    }

    emit(
      state.copyWith(
        phase: GamePhase.loading,
        mode: mode,
        activeDailyDay: resolvedDailyDay,
        clearActiveDailyDay: !isDailyChallenge,
        activeTrack: track,
        levelNumber: levelNumber,
        showDifficultyBar: !isDailyChallenge && levelNumber >= 15,
        showUltraTab: !isDailyChallenge && levelNumber > 30,
        elapsed: Duration.zero,
        score: 0,
        mistakeCount: 0,
        moveHistory: [],
        autoMarkHistory: const [],
        actionHistory: const [],
        autoMarksUsed: 0,
        hintsUsed: 0,
        undosUsed: 0,
        solveRowsUsed: 0,
        clearWinSummary: true,
        isAdPresenting: false,
        pendingRuleTutorials: const [],
        showRuleTutorial: false,
        errorTileIndex: null,
        hintTileIndex: null,
      ),
    );

    GeneratedPuzzle puzzle;
    try {
      puzzle = await compute(
        _generatePuzzleIsolate,
        config,
      ).timeout(_generationTimeout);
    } on TimeoutException {
      if (!isClosed && token == _generationToken) {
        emit(
          state.copyWith(
            phase: GamePhase.generationError,
            statusMessage: "Couldn't generate this level. Please try again.",
          ),
        );
      }
      return;
    } catch (_) {
      if (!isClosed && token == _generationToken) {
        emit(
          state.copyWith(
            phase: GamePhase.generationError,
            statusMessage: "Couldn't generate this level. Please try again.",
          ),
        );
      }
      return;
    }

    if (isClosed || token != _generationToken) {
      return;
    }

    if (!puzzle.isValid && isDailyChallenge) {
      const fallbackDay = DailyChallengeDay(
        38,
        PuzzleTrack.ultraHard,
        hintReward: 3,
        bulbReward: 2,
        undoReward: 2,
      );
      final fallbackConfig = PuzzleGenerator.configForLevel(
        fallbackDay.level,
        fallbackDay.track,
        includeLockedFlower: false,
      );

      try {
        puzzle = await compute(
          _generatePuzzleIsolate,
          fallbackConfig,
        ).timeout(_generationTimeout);
      } on TimeoutException {
        puzzle = GeneratedPuzzle.invalid;
      } catch (_) {
        puzzle = GeneratedPuzzle.invalid;
      }

      if (isClosed || token != _generationToken) {
        return;
      }

      if (puzzle.isValid) {
        effectiveLevel = fallbackDay.level;
        effectiveTrack = fallbackDay.track;
        resolvedDailyDay = fallbackDay;
        config = fallbackConfig;
        fallbackStatusMessage =
            "Today's puzzle needed a smaller board on this device — "
            "here's a slightly easier version.";
      }
    }

    if (!puzzle.isValid) {
      emit(
        state.copyWith(
          phase: GamePhase.generationError,
          statusMessage: "Couldn't generate this level. Please try again.",
        ),
      );
      return;
    }

    final gridSize = puzzle.gridSize;
    List<TileState> states = List.filled(
      gridSize * gridSize,
      TileState.empty,
    );
    for (int index in puzzle.lockedIndexes) {
      states[index] = TileState.lockedObject;
    }

    int currentPlacedCount = puzzle.lockedIndexes.length;
    int currentLives = 3;
    Duration currentElapsed = Duration.zero;
    List<int> currentMoveHistory = [];
    List<List<int>> currentAutoMarkHistory = [];
    List<String> currentActionHistory = [];
    int currentAutoMarksUsed = 0;
    int currentHintsUsed = 0;
    int currentUndosUsed = 0;
    int currentSolveRowsUsed = 0;
    int currentMistakeCount = 0;

    if (!forceRestart && !isDailyChallenge) {
      final persisted = _sessionRepo.load(effectiveTrack);
      final snapshot = _trackSnapshots[effectiveTrack] ??
          (persisted == null
              ? null
              : _InProgressSnapshot.fromSavedSession(persisted));
      if (snapshot != null && snapshot.levelNumber == effectiveLevel) {
        if (snapshot.tileStates.length == states.length) {
          states = List.from(snapshot.tileStates);
          currentPlacedCount = snapshot.placedCount;
          currentMoveHistory = List.from(snapshot.moveHistory);
          currentAutoMarkHistory = snapshot.autoMarkHistory
              .map((batch) => List<int>.from(batch))
              .toList();
          currentActionHistory = List.from(snapshot.actionHistory);
          if (currentActionHistory.isEmpty && currentMoveHistory.isNotEmpty) {
            currentActionHistory =
                currentMoveHistory.map((index) => 'object:$index').toList();
          }
          currentAutoMarksUsed = snapshot.autoMarksUsed;
          currentHintsUsed = snapshot.hintsUsed;
          currentUndosUsed = snapshot.undosUsed;
          currentSolveRowsUsed = snapshot.solveRowsUsed;
          currentLives = snapshot.livesRemaining;
          currentElapsed = snapshot.elapsed;
          currentMistakeCount = snapshot.mistakeCount;
        }
      }
    }

    final progress = _progressRepo.getProgress();
    if (!isDailyChallenge) {
      unawaited(_sessionRepo.setLastTrack(effectiveTrack));
    }
    // Detailed rule explanations now live in the expandable in-game Rules panel.
    const pending = <String>[];

    emit(
      state.copyWith(
        phase: currentLives <= 0 ? GamePhase.reviveOffer : GamePhase.playing,
        puzzle: puzzle,
        tileStates: states,
        placedCount: currentPlacedCount,
        targetCount: gridSize,
        livesRemaining: currentLives,
        maxLives: 3,
        score: calculateGameScore(
          track: effectiveTrack,
          playerPlacedCount: currentPlacedCount - puzzle.lockedIndexes.length,
          mistakeCount: currentMistakeCount,
          elapsed: currentElapsed,
        ),
        mistakeCount: currentMistakeCount,
        elapsed: currentElapsed,
        hintCount: progress.hints,
        undoCount: progress.undos,
        bulbCount: progress.bulbs,
        autoMarkCount: progress.autoMarks,
        autoMarksUsed: currentAutoMarksUsed,
        hintsUsed: currentHintsUsed,
        undosUsed: currentUndosUsed,
        solveRowsUsed: currentSolveRowsUsed,
        extraLiveCount: progress.extraLives,
        mode: mode,
        activeDailyDay: resolvedDailyDay,
        clearActiveDailyDay: !isDailyChallenge,
        activeTrack: effectiveTrack,
        levelNumber: effectiveLevel,
        showDifficultyBar: !isDailyChallenge && effectiveLevel >= 15,
        showUltraTab: !isDailyChallenge && effectiveLevel > 30,
        moveHistory: currentMoveHistory,
        autoMarkHistory: currentAutoMarkHistory,
        actionHistory: currentActionHistory,
        statusMessage: fallbackStatusMessage,
        showRuleTutorial: false,
        pendingRuleTutorials: pending,
        errorTileIndex: null,
        hintTileIndex: null,
        mineTileIndex: null,
        clearTutorialHighlightIndexes: true,
        lifeLostToken: 0,
        lifeLostTileIndex: null,
        lifeLostTargetHeartIndex: null,
      ),
    );

    if (state.guidedModeActive) {
      _beginGuidedLevel();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_shouldTimerRun) {
        final elapsed = state.elapsed + const Duration(seconds: 1);
        emit(
          state.copyWith(
            elapsed: elapsed,
            score: _scoreFor(elapsed: elapsed),
          ),
        );
        if (elapsed.inSeconds % 5 == 0) _persistCurrentGame();
      }
    });
  }

  bool get _shouldTimerRun =>
      state.phase == GamePhase.playing &&
      state.pendingRuleTutorials.isEmpty &&
      !state.guidedPreviewActive &&
      !state.showGuidedRecap;

  int _scoreFor({
    Duration? elapsed,
    int? placedCount,
    int? mistakeCount,
    bool completed = false,
  }) {
    return calculateGameScore(
      track: state.activeTrack,
      playerPlacedCount: (placedCount ?? state.placedCount) -
          state.puzzle.lockedIndexes.length,
      mistakeCount: mistakeCount ?? state.mistakeCount,
      elapsed: elapsed ?? state.elapsed,
      completed: completed,
    );
  }

  void pauseGame() {
    if (state.phase == GamePhase.playing) {
      emit(state.copyWith(phase: GamePhase.paused));
      _persistCurrentGame();
    }
  }

  void resumeGame() {
    if (state.phase == GamePhase.paused) {
      emit(state.copyWith(phase: GamePhase.playing));
    }
  }

  /// Called by the UI after showing a rule tutorial dialog.
  /// Removes the first pending tutorial; when list is empty the game starts.
  void dismissNextRuleTutorial(String completedRule) {
    final remaining = List<String>.from(state.pendingRuleTutorials);
    if (remaining.isNotEmpty) remaining.removeAt(0);

    List<int>? highlightIndexes;
    if (completedRule == 'rowColumn') {
      highlightIndexes = [];
      // Briefly outline row 0 and column 0 (which have an intersecting flower)
      for (int i = 0; i < state.puzzle.gridSize; i++) {
        highlightIndexes.add(i); // row 0
        highlightIndexes.add(i * state.puzzle.gridSize); // col 0
      }
    } else if (completedRule == 'colorRegion') {
      highlightIndexes = [];
      // Briefly pulse color 0
      for (int i = 0; i < state.tileStates.length; i++) {
        if (state.puzzle.colorMap[i] == 0) highlightIndexes.add(i);
      }
    } else if (completedRule == 'noTouch') {
      highlightIndexes = [];
      if (state.puzzle.lockedIndexes.isNotEmpty) {
        int locked = state.puzzle.lockedIndexes.first;
        int gridSize = state.puzzle.gridSize;
        int lr = locked ~/ gridSize;
        int lc = locked % gridSize;
        for (int r = lr - 1; r <= lr + 1; r++) {
          for (int c = lc - 1; c <= lc + 1; c++) {
            if (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
              if (!(r == lr && c == lc)) {
                highlightIndexes.add(r * gridSize + c);
              }
            }
          }
        }
      }
    }

    emit(
      state.copyWith(
        pendingRuleTutorials: remaining,
        showRuleTutorial: remaining.isNotEmpty,
        tutorialHighlightIndexes: highlightIndexes,
      ),
    );

    if (highlightIndexes != null && highlightIndexes.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isClosed) {
          emit(state.copyWith(clearTutorialHighlightIndexes: true));
        }
      });
    }
  }

  void onTileLongPress(int index) {
    if (state.phase != GamePhase.playing) return;

    if (state.guidedModeActive &&
        state.guidedInteractableIndex != null &&
        index != state.guidedInteractableIndex) {
      return;
    }

    final currentStates = List<TileState>.from(state.tileStates);
    final tile = currentStates[index];

    if (isImmutableTile(tile)) {
      return;
    }

    if (tile == TileState.empty) {
      currentStates[index] = TileState.marker;
    } else if (tile == TileState.marker || tile == TileState.autoMarker) {
      currentStates[index] = TileState.empty;
    } else {
      return;
    }

    emit(
      state.copyWith(
        tileStates: currentStates,
        errorTileIndex: null,
        hintTileIndex: null,
        mineTileIndex: null,
      ),
    );
    _persistCurrentGame();

    if (state.guidedModeActive &&
        state.guidedTeachingMarker &&
        index == state.guidedInteractableIndex) {
      emit(state.copyWith(guidedTeachingMarker: false));
      _guideCurrentStep();
    }
  }

  void onTileTap(int index) {
    if (state.phase != GamePhase.playing) return;

    if (state.guidedModeActive &&
        state.guidedInteractableIndex != null &&
        index != state.guidedInteractableIndex) {
      return;
    }

    final currentStates = List<TileState>.from(state.tileStates);
    final tile = currentStates[index];

    if (isImmutableTile(tile)) {
      return;
    }

    if (tile == TileState.empty ||
        tile == TileState.marker ||
        tile == TileState.autoMarker) {
      if (_canPlace(index, currentStates)) {
        currentStates[index] = TileState.object;
        final newHistory = List<int>.from(state.moveHistory)..add(index);
        final newActionHistory = List<String>.from(state.actionHistory)
          ..add('object:$index:${tile.name}');
        final newPlacedCount = state.placedCount + 1;

        AudioService.playPlaceObject();
        if (_settingsRepo.vibrationEnabled) {
          unawaited(HapticFeedback.lightImpact());
        }

        emit(
          state.copyWith(
            tileStates: currentStates,
            placedCount: newPlacedCount,
            score: _scoreFor(placedCount: newPlacedCount),
            moveHistory: newHistory,
            actionHistory: newActionHistory,
            errorTileIndex: null,
            hintTileIndex: null,
            mineTileIndex: null,
          ),
        );
        _persistCurrentGame();

        if (state.guidedModeActive &&
            state.guidedStepIndex < state.puzzle.solutionIndexes.length) {
          if (index == state.puzzle.solutionIndexes[state.guidedStepIndex]) {
            emit(state.copyWith(
                guidedStepIndex: state.guidedStepIndex + 1,
                clearGuidedInteractableIndex: true,
                clearGuidedInstructionText: true,
                guidedFeedbackText: state.levelNumber == 1
                    ? "✓ Nice! Only one flower per row & column"
                    : (state.levelNumber == 2
                        ? "✓ Correct! One per color region"
                        : "✓ Perfect — no flowers touching")));
            Future.delayed(const Duration(milliseconds: 900), () {
              if (!isClosed && state.guidedModeActive) {
                emit(state.copyWith(clearGuidedFeedbackText: true));
                _guideCurrentStep();
                if (_isBoardComplete(currentStates)) {
                  _onLevelComplete();
                }
              }
            });
          }
        } else {
          if (_isBoardComplete(currentStates)) {
            _onLevelComplete();
          }
        }
      } else {
        // Invalid placement
        if (state.guidedModeActive && state.guidedGotchaActive) {
          AudioService.playError();
          if (_settingsRepo.vibrationEnabled) {
            unawaited(HapticFeedback.heavyImpact());
          }
          emit(state.copyWith(
              errorTileIndex: index,
              guidedGotchaActive: false,
              guidedGotchaTriggered: true,
              clearGuidedInteractableIndex: true,
              clearGuidedInstructionText: true,
              guidedFeedbackText: "That's too close — not even diagonally!"));
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!isClosed && state.errorTileIndex == index) {
              emit(state.copyWith(errorTileIndex: null));
            }
            if (!isClosed && state.guidedModeActive) {
              emit(state.copyWith(clearGuidedFeedbackText: true));
              _guideCurrentStep();
            }
          });
          return;
        }

        if (state.puzzle.mineIndexes.contains(index)) {
          // Mine detonation
          AudioService.playMineExplosion();
          if (_settingsRepo.vibrationEnabled) {
            unawaited(HapticFeedback.heavyImpact());
            Future.delayed(const Duration(milliseconds: 120), () {
              if (!isClosed && _settingsRepo.vibrationEnabled) {
                unawaited(HapticFeedback.heavyImpact());
              }
            });
          }

          currentStates[index] = TileState.revealedMine;
          final lives = state.livesRemaining - 2;
          final mistakes = state.mistakeCount + 1;

          emit(
            state.copyWith(
              tileStates: currentStates,
              livesRemaining: lives,
              mistakeCount: mistakes,
              score: _scoreFor(mistakeCount: mistakes),
              mineTileIndex: index,
              errorTileIndex: null,
              hintTileIndex: null,
              lifeLostToken: state.lifeLostToken + 1,
              lifeLostTileIndex: index,
              lifeLostTargetHeartIndex: state.livesRemaining - 1,
            ),
          );
          _persistCurrentGame();

          Future.delayed(const Duration(milliseconds: 500), () {
            if (!isClosed && state.mineTileIndex == index) {
              emit(state.copyWith(mineTileIndex: null));
            }
          });

          if (lives <= 0) {
            onLivesExhausted();
          }
        } else {
          // Normal wrong placement
          AudioService.playError();
          if (_settingsRepo.vibrationEnabled) {
            unawaited(HapticFeedback.heavyImpact());
          }

          final lives = state.livesRemaining - 1;
          final mistakes = state.mistakeCount + 1;
          emit(
            state.copyWith(
              livesRemaining: lives,
              mistakeCount: mistakes,
              score: _scoreFor(mistakeCount: mistakes),
              errorTileIndex: index,
              mineTileIndex: null,
              hintTileIndex: null,
              lifeLostToken: state.lifeLostToken + 1,
              lifeLostTileIndex: index,
              lifeLostTargetHeartIndex: lives,
            ),
          );
          _persistCurrentGame();

          // Clear error highlight after short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!isClosed && state.errorTileIndex == index) {
              emit(state.copyWith(errorTileIndex: null));
            }
          });

          if (lives <= 0) {
            onLivesExhausted();
          }
        }
      }
    } else if (tile == TileState.object) {
      currentStates[index] = TileState.empty;
      final newHistory = List<int>.from(state.moveHistory)..remove(index);
      final newActionHistory = List<String>.from(state.actionHistory)
        ..removeWhere((action) =>
            action == 'object:$index' || action.startsWith('object:$index:'));
      emit(
        state.copyWith(
          tileStates: currentStates,
          placedCount: state.placedCount - 1,
          score: _scoreFor(placedCount: state.placedCount - 1),
          moveHistory: newHistory,
          actionHistory: newActionHistory,
          errorTileIndex: null,
          hintTileIndex: null,
          mineTileIndex: null,
        ),
      );
      _persistCurrentGame();
    }
  }

  bool _canPlace(int index, List<TileState> states) {
    final config = PuzzleGenerator.configForLevel(
      state.levelNumber,
      state.activeTrack,
    );
    final placed = <int>[];
    for (int i = 0; i < states.length; i++) {
      if (states[i] == TileState.object ||
          states[i] == TileState.lockedObject) {
        placed.add(i);
      }
    }

    return _canPlaceAgainst(index, placed, config);
  }

  bool _canPlaceAgainst(
    int index,
    List<int> placed,
    PuzzleConfig config,
  ) {
    final puzzle = state.puzzle;
    final gridSize = puzzle.gridSize;
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final myColor = puzzle.colorMap[index];

    if (puzzle.mineIndexes.contains(index)) return false;

    for (int i = 0; i < placed.length; i++) {
      int pIndex = placed[i];
      int pRow = pIndex ~/ gridSize;
      int pCol = pIndex % gridSize;

      if (pRow == row) return false;
      if (pCol == col) return false;
      if (puzzle.colorMap[pIndex] == myColor) return false;

      if (gridSize >= 4 && _isAdjacent(index, pIndex, gridSize)) return false;

      if (config.blockFullDiagonal &&
          _sharesFullDiagonal(index, pIndex, gridSize)) {
        return false;
      }

      if (config.blockMinDistance) {
        if (_manhattanDistance(index, pIndex, gridSize) < config.minDistance) {
          return false;
        }
      }

      if (config.blockKnightMove && _isKnightMove(index, pIndex, gridSize)) {
        return false;
      }
    }
    return true;
  }

  bool _isBoardComplete(List<TileState> states) {
    final placed = <int>[];
    for (var index = 0; index < states.length; index++) {
      if (states[index] == TileState.object ||
          states[index] == TileState.lockedObject) {
        placed.add(index);
      }
    }
    if (placed.length != state.targetCount) return false;

    final config = PuzzleGenerator.configForLevel(
      state.levelNumber,
      state.activeTrack,
    );
    for (var i = 0; i < placed.length; i++) {
      final others = List<int>.from(placed)..removeAt(i);
      if (!_canPlaceAgainst(placed[i], others, config)) return false;
    }
    return true;
  }

  bool _isAdjacent(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1;
  }

  bool _sharesFullDiagonal(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() == (c1 - c2).abs();
  }

  bool _isKnightMove(int a, int b, int gridSize) {
    int dr = (a ~/ gridSize - b ~/ gridSize).abs();
    int dc = (a % gridSize - b % gridSize).abs();
    return (dr == 2 && dc == 1) || (dr == 1 && dc == 2);
  }

  int _manhattanDistance(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() + (c1 - c2).abs();
  }

  void _onLevelComplete() {
    _timer?.cancel();
    _trackSnapshots.remove(state.activeTrack);
    unawaited(_sessionRepo.clear(state.activeTrack));

    if (_settingsRepo.vibrationEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }

    final finalScore = _scoreFor(completed: true);
    final starCalculation = calculateLevelStars(
      mistakes: state.mistakeCount,
      hintsUsed: state.hintsUsed,
      solveRowsUsed: state.solveRowsUsed,
      autoMarksUsed: state.autoMarksUsed,
      elapsed: state.elapsed,
      parTime: parTimeForPuzzle(
        gridSize: state.puzzle.gridSize,
        track: state.activeTrack,
      ),
    );
    late WinSummary winSummary;
    late PuzzleResult puzzleResult;

    if (state.mode == GameMode.dailyChallenge) {
      final now = DateTime.now();
      final dailyDay = state.activeDailyDay!;
      final previous = _dailyHistoryRepo.resultForDate(now);
      final isNewBest = previous == null ||
          previous.bestTimeMs == 0 ||
          state.elapsed.inMilliseconds < previous.bestTimeMs;
      var usedFreeze = false;

      if (!_dailyChallengeRepo.hasCompletedToday(now)) {
        _grantDailyReward(
          hints: dailyDay.hintReward,
          bulbs: dailyDay.bulbReward,
          undos: dailyDay.undoReward,
          extraLives: dailyDay.extraLifeReward,
          autoMarks: dailyDay.autoMarkReward,
        );
        final completion = _dailyChallengeRepo.markCompletedToday();
        usedFreeze = completion?.usedStreakFreeze ?? false;
        final streakReward = completion?.streakReward;
        if (streakReward != null) {
          _grantDailyReward(
            hints: streakReward.hints,
            bulbs: streakReward.bulbs,
            undos: streakReward.undos,
            extraLives: streakReward.extraLives,
            autoMarks: streakReward.autoMarks,
            streakFreezes: streakReward.streakFreezes,
          );
        }
      }

      final streak = _dailyChallengeRepo.getState().currentChallengeStreak;
      final shareGrid = buildSpoilerFreeDailyGrid(
        stars: starCalculation.stars,
        mistakes: state.mistakeCount,
        powersUsed:
            state.hintsUsed + state.solveRowsUsed + state.autoMarksUsed,
      );
      final history = _dailyHistoryRepo.recordCompletion(
        date: now,
        elapsedMs: state.elapsed.inMilliseconds,
        score: finalScore,
        mistakes: state.mistakeCount,
        streak: streak,
        shareGridData: shareGrid,
      );
      puzzleResult = _buildPuzzleResult(
        finalScore: finalScore,
        stars: starCalculation.stars,
        mode: 'dailyChallenge',
        puzzleKey: DailyHistoryRepository.dateKey(now),
        beatPersonalBest: isNewBest,
      );
      _gameResultsRepo.recordPuzzle(puzzleResult);
      winSummary = WinSummary(
        starCalculation: starCalculation,
        personalBest: Duration(milliseconds: history.bestTimeMs),
        isNewBest: isNewBest,
        chapterName: 'Daily Challenge',
        collectibleCount: 0,
        collectibleTarget: 0,
        nextCollectible: null,
        nextUnlock: null,
        levelsToUnlock: 0,
        chapterCompletedNow: false,
        sessionGoalMessage:
            usedFreeze ? '❄️ Streak Freeze saved your daily streak!' : null,
      );
    } else {
      final chapter = chapterForLevel(state.levelNumber)!;
      final progressBefore = _progressRepo.getProgress();
      final chapterCompletedNow = state.activeTrack == PuzzleTrack.normal &&
          state.levelNumber == chapter.endLevel &&
          progressBefore.normalHighest <= state.levelNumber;
      final previousResult = _gameResultsRepo.levelResult(
        state.levelNumber,
        state.activeTrack.name,
      );
      final isNewBest = previousResult == null ||
          previousResult.bestTimeMs == 0 ||
          state.elapsed.inMilliseconds < previousResult.bestTimeMs;

      _progressRepo.completeLevel(state.levelNumber, state.activeTrack);
      final collectionBefore = _collectionRepo.progressFor(chapter.id);
      final wasCollectionComplete = collectionBefore.chapterCompleted;
      final collection = _collectionRepo.collectForPuzzle(
        chapter: chapter,
        levelNumber: state.levelNumber,
        track: state.activeTrack,
      );
      var earnedFreeze = false;
      if (!wasCollectionComplete &&
          collection.chapterCompleted &&
          _collectionRepo.claimChapterReward(chapter.id)) {
        _progressRepo.addStreakFreezes(1);
        earnedFreeze = true;
      }
      puzzleResult = _buildPuzzleResult(
        finalScore: finalScore,
        stars: starCalculation.stars,
        mode: 'progression',
        puzzleKey: '${state.activeTrack.name}:${state.levelNumber}',
        beatPersonalBest: isNewBest,
      );
      _gameResultsRepo.recordPuzzle(puzzleResult);
      final best = _gameResultsRepo.levelResult(
        state.levelNumber,
        state.activeTrack.name,
      );
      final nextCollectible =
          collection.collectedCount < chapter.collectibles.length
              ? chapter.collectibles[collection.collectedCount].name
              : null;
      winSummary = WinSummary(
        starCalculation: starCalculation,
        personalBest: Duration(milliseconds: best?.bestTimeMs ?? 0),
        isNewBest: isNewBest,
        chapterName: chapter.name,
        collectibleCount: collection.collectedCount,
        collectibleTarget: collection.targetCount,
        nextCollectible: nextCollectible,
        nextUnlock: chapter.completionReward.label,
        levelsToUnlock: (chapter.endLevel - state.levelNumber).clamp(0, 80),
        chapterCompletedNow: chapterCompletedNow,
        sessionGoalMessage:
            earnedFreeze ? '❄️ Restoration milestone: +1 Streak Freeze' : null,
      );
      _onboardingAnalytics.recordOnce('first_real_win', metadata: {
        'level': state.levelNumber,
        'track': state.activeTrack.name,
        'elapsedMs': state.elapsed.inMilliseconds,
        'mistakes': state.mistakeCount,
      });

      final progress = _progressRepo.getProgress();
      if (!state.guidedModeActive &&
          progress.levelsCompletedCount >= 5 &&
          (progress.levelsCompletedCount - 5) % 2 == 0 &&
          !progress.adsRemoved) {
        AdService.showInterstitial(adsRemoved: progress.adsRemoved);
      }
    }

    if (!FeatureFlags.current.sessionGoalsAndEconomyBalancing) {
      emit(state.copyWith(
        phase: GamePhase.levelComplete,
        score: finalScore,
        winSummary: winSummary,
      ));
      return;
    }

    final goalUpdate = _sessionGoalRepo.applyPuzzleResult(puzzleResult);
    if (goalUpdate.newlyCompleted) {
      _grantSessionGoalReward(goalUpdate.goal);
    }
    if (goalUpdate.changed) {
      final definition = _sessionGoalRepo.definitionFor(goalUpdate.goal);
      final progressText = goalUpdate.newlyCompleted
          ? 'Session goal complete: ${definition.title}'
          : '${definition.title}: ${goalUpdate.goal.progress}/${goalUpdate.goal.target}';
      final existing = winSummary.sessionGoalMessage;
      winSummary = winSummary.copyWith(
        sessionGoalMessage:
            existing == null ? progressText : '$existing\n$progressText',
      );
    }

    emit(state.copyWith(
      phase: GamePhase.levelComplete,
      score: finalScore,
      winSummary: winSummary,
    ));
  }

  PuzzleResult _buildPuzzleResult({
    required int finalScore,
    required int stars,
    required String mode,
    required String puzzleKey,
    required bool beatPersonalBest,
  }) =>
      PuzzleResult()
        ..puzzleKey = puzzleKey
        ..mode = mode
        ..levelNumber = state.levelNumber
        ..track = state.activeTrack.name
        ..completed = true
        ..elapsedMs = state.elapsed.inMilliseconds
        ..score = finalScore
        ..stars = stars
        ..mistakes = state.mistakeCount
        ..hintsUsed = state.hintsUsed
        ..undosUsed = state.undosUsed
        ..solveRowsUsed = state.solveRowsUsed
        ..autoMarksUsed = state.autoMarksUsed
        ..beatPersonalBest = beatPersonalBest;

  void _grantDailyReward({
    int hints = 0,
    int bulbs = 0,
    int undos = 0,
    int extraLives = 0,
    int autoMarks = 0,
    int streakFreezes = 0,
  }) {
    if (hints > 0) _progressRepo.addHints(hints);
    if (bulbs > 0) _progressRepo.addBulbs(bulbs);
    if (undos > 0) _progressRepo.addUndos(undos);
    if (extraLives > 0) _progressRepo.addExtraLives(extraLives);
    if (autoMarks > 0) _progressRepo.addAutoMarks(autoMarks);
    if (streakFreezes > 0) _progressRepo.addStreakFreezes(streakFreezes);
  }

  void _grantSessionGoalReward(SessionGoalState goal) {
    if (!_sessionGoalRepo.claimReward()) return;
    switch (goal.rewardType) {
      case 'collection_progress':
        final level = _progressRepo
            .getProgress()
            .normalHighest
            .clamp(1, maxLevelCount);
        final chapter = chapterForLevel(level)!;
        _collectionRepo.collect(chapter.id, goal.goalId);
      case 'cosmetic_currency':
        _progressRepo.addCosmeticCurrency(goal.rewardAmount);
      case 'streak_freeze':
        _progressRepo.addStreakFreezes(goal.rewardAmount);
      case 'auto_mark':
        _progressRepo.addAutoMarks(goal.rewardAmount);
    }
  }

  void useHint() {
    if (!_canUsePowers) return;
    if (state.hintCount > 0) {
      final completion = _findCompatibleCompletion(state.tileStates);
      final target = completion?.where((index) {
        return state.tileStates[index] == TileState.empty ||
            state.tileStates[index] == TileState.marker ||
            state.tileStates[index] == TileState.autoMarker;
      }).firstOrNull;

      if (target == null) return;
      _progressRepo.useHint();

      emit(
        state.copyWith(
          hintCount: state.hintCount - 1,
          hintTileIndex: target,
          hintsUsed: state.hintsUsed + 1,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isClosed && state.hintTileIndex == target) {
          emit(state.copyWith(hintTileIndex: null));
        }
      });
    } else {
      _showRewardedPower(RewardType.hint);
    }
  }

  void useBulb() {
    if (!_canUsePowers) return;
    if (state.bulbCount > 0) {
      final currentStates = List<TileState>.from(state.tileStates);
      final completion = _findCompatibleCompletion(currentStates);
      final target = completion?.where((index) {
        final tile = currentStates[index];
        return tile != TileState.object && tile != TileState.lockedObject;
      }).firstOrNull;

      if (target == null) return;
      _progressRepo.useBulb();
      currentStates[target] = TileState.lockedObject;
      final newPlacedCount = state.placedCount + 1;
      emit(
        state.copyWith(
          bulbCount: state.bulbCount - 1,
          solveRowsUsed: state.solveRowsUsed + 1,
          tileStates: currentStates,
          placedCount: newPlacedCount,
          score: _scoreFor(placedCount: newPlacedCount),
        ),
      );
      _persistCurrentGame();
      if (_isBoardComplete(currentStates)) _onLevelComplete();
    } else {
      _showRewardedPower(RewardType.bulb);
    }
  }

  void useAutoMark() {
    if (!FeatureFlags.current.lockedFlowerAutoMarkIconsAndZoom ||
        !_canUsePowers) {
      return;
    }

    final plan = planAutoMark(
      state.tileStates,
      state.puzzle.gridSize,
      state.puzzle.mineIndexes.toSet(),
      inventory: state.autoMarkCount,
    );
    final targets = plan.targetIndexes;
    if (targets.isEmpty) {
      emit(state.copyWith(
        rewardMessage: 'No new touching cells can be marked yet.',
      ));
      return;
    }

    if (!plan.canApply) {
      _showRewardedPower(RewardType.autoMark);
      return;
    }
    if (!_progressRepo.useAutoMark()) return;

    final currentStates = List<TileState>.from(state.tileStates);
    for (final index in targets) {
      currentStates[index] = TileState.autoMarker;
    }
    final batches =
        state.autoMarkHistory.map((batch) => List<int>.from(batch)).toList();
    final batchIndex = batches.length;
    batches.add(targets);
    final actions = List<String>.from(state.actionHistory)
      ..add('autoMark:$batchIndex');

    emit(state.copyWith(
      tileStates: currentStates,
      autoMarkCount: state.autoMarkCount - 1,
      autoMarksUsed: state.autoMarksUsed + 1,
      autoMarkHistory: batches,
      actionHistory: actions,
    ));
    _persistCurrentGame();
  }

  void undoLast() {
    if (!_canUsePowers || state.actionHistory.isEmpty) return;
    if (state.undoCount <= 0) {
      _showRewardedPower(RewardType.undo);
      return;
    }

    final currentStates = List<TileState>.from(state.tileStates);
    final actions = List<String>.from(state.actionHistory);
    final action = actions.removeLast();
    final moveHistory = List<int>.from(state.moveHistory);
    final batches =
        state.autoMarkHistory.map((batch) => List<int>.from(batch)).toList();
    var placedCount = state.placedCount;
    var changed = false;

    if (action.startsWith('autoMark:')) {
      final batchIndex = int.tryParse(action.substring('autoMark:'.length));
      if (batchIndex != null &&
          batchIndex >= 0 &&
          batchIndex < batches.length) {
        changed =
            revertAutoMarkTransaction(currentStates, batches[batchIndex]) > 0;
        batches.removeAt(batchIndex);
      }
    } else if (action.startsWith('object:')) {
      final parts = action.split(':');
      final index = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      if (index != null &&
          index >= 0 &&
          index < currentStates.length &&
          currentStates[index] == TileState.object) {
        final previousState = parts.length >= 3
            ? TileState.values
                .where((value) => value.name == parts[2])
                .firstOrNull
            : null;
        currentStates[index] = previousState ?? TileState.empty;
        moveHistory.remove(index);
        placedCount -= 1;
        changed = true;
      }
    }

    if (!changed) {
      emit(state.copyWith(
        autoMarkHistory: batches,
        actionHistory: actions,
      ));
      _persistCurrentGame();
      return;
    }

    if (!_progressRepo.useUndo()) return;
    emit(state.copyWith(
      undoCount: state.undoCount - 1,
      undosUsed: state.undosUsed + 1,
      tileStates: currentStates,
      moveHistory: moveHistory,
      autoMarkHistory: batches,
      actionHistory: actions,
      placedCount: placedCount,
      score: _scoreFor(placedCount: placedCount),
    ));
    _persistCurrentGame();
  }

  bool get _canUsePowers =>
      state.phase == GamePhase.playing &&
      !state.guidedModeActive &&
      state.pendingRuleTutorials.isEmpty &&
      !state.guidedPreviewActive &&
      !state.showGuidedRecap &&
      !state.isAdPresenting &&
      !AdService.isPresentingFullScreenAd;

  void _showRewardedPower(RewardType type) {
    if (!_canUsePowers) return;
    if (!AdService.isInitialized) {
      emit(state.copyWith(
        rewardMessage: 'Rewarded ads are unavailable right now.',
      ));
      return;
    }
    emit(state.copyWith(isAdPresenting: true));
    try {
      final started = AdService.showRewarded(
        type,
        onRewarded: onRewardedAdCompleted,
        adsRemoved: _progressRepo.getProgress().adsRemoved,
        onClosed: () {
          if (!isClosed) emit(state.copyWith(isAdPresenting: false));
        },
      );
      if (!started && !isClosed) {
        emit(state.copyWith(
          isAdPresenting: false,
          rewardMessage: 'Rewarded ads are unavailable right now.',
        ));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isAdPresenting: false));
    }
  }

  void switchTrack(PuzzleTrack track) {
    if (state.mode == GameMode.dailyChallenge) return;
    if (track == state.activeTrack) return;
    if (!_progressRepo.isLevelUnlocked(state.levelNumber, track)) {
      emit(state.copyWith(
        rewardMessage:
            '${track == PuzzleTrack.ultraHard ? 'Ultra Hard' : 'Hard'} level ${state.levelNumber} is still locked.',
      ));
      return;
    }

    if (state.phase == GamePhase.playing) {
      final snapshot = _InProgressSnapshot(
        levelNumber: state.levelNumber,
        tileStates: List.from(state.tileStates),
        placedCount: state.placedCount,
        moveHistory: List.from(state.moveHistory),
        autoMarkHistory: state.autoMarkHistory
            .map((batch) => List<int>.from(batch))
            .toList(),
        actionHistory: List.from(state.actionHistory),
        autoMarksUsed: state.autoMarksUsed,
        hintsUsed: state.hintsUsed,
        undosUsed: state.undosUsed,
        solveRowsUsed: state.solveRowsUsed,
        livesRemaining: state.livesRemaining,
        elapsed: state.elapsed,
        mistakeCount: state.mistakeCount,
      );
      _trackSnapshots[state.activeTrack] = snapshot;
      unawaited(
          _sessionRepo.save(state.activeTrack, snapshot.toSavedSession()));
    }

    startLevel(state.levelNumber, track);
  }

  void onLivesExhausted() {
    emit(state.copyWith(phase: GamePhase.reviveOffer));
  }

  void onRewardedAdCompleted(RewardType type) {
    if (type == RewardType.hint) {
      _progressRepo.addHints(1);
      emit(state.copyWith(
          hintCount: state.hintCount + 1, rewardMessage: '+1 Hint added!'));
    } else if (type == RewardType.bulb) {
      _progressRepo.addBulbs(1);
      emit(state.copyWith(
          bulbCount: state.bulbCount + 1,
          rewardMessage: '+1 Solve Row added!'));
    } else if (type == RewardType.undo) {
      _progressRepo.addUndos(1);
      emit(state.copyWith(
          undoCount: state.undoCount + 1, rewardMessage: '+1 Undo added!'));
    } else if (type == RewardType.autoMark) {
      _progressRepo.addAutoMarks(1);
      emit(state.copyWith(
        autoMarkCount: state.autoMarkCount + 1,
        rewardMessage: '+1 AutoMark added!',
      ));
    } else if (type == RewardType.extraLife) {
      emit(
        state.copyWith(
          livesRemaining: 1,
          phase: GamePhase.playing,
          rewardMessage: '+1 life restored!',
        ),
      );
      _persistCurrentGame();
    }
  }

  void useInventoryExtraLife() {
    if (state.phase != GamePhase.reviveOffer || state.extraLiveCount <= 0) {
      return;
    }
    if (!_progressRepo.useExtraLife()) return;

    emit(state.copyWith(
      extraLiveCount: state.extraLiveCount - 1,
      livesRemaining: 1,
      phase: GamePhase.playing,
      rewardMessage: 'Extra life used: +1 heart',
    ));
    _persistCurrentGame();
  }

  void giveUp() {
    _trackSnapshots.remove(state.activeTrack);
    unawaited(_sessionRepo.clear(state.activeTrack));
    emit(state.copyWith(phase: GamePhase.gameOver));
  }

  void clearRewardMessage() {
    if (state.rewardMessage != null) {
      emit(state.copyWith(clearRewardMessage: true));
    }
  }

  List<int>? _findCompatibleCompletion(List<TileState> states) {
    final gridSize = state.puzzle.gridSize;
    final config = PuzzleGenerator.configForLevel(
      state.levelNumber,
      state.activeTrack,
    );
    final placed = <int>[];
    for (var index = 0; index < states.length; index++) {
      if (states[index] == TileState.object ||
          states[index] == TileState.lockedObject) {
        placed.add(index);
      }
    }

    List<int>? search(int row, List<int> candidate) {
      if (row == gridSize) return candidate;
      if (candidate.any((index) => index ~/ gridSize == row)) {
        return search(row + 1, candidate);
      }

      final preferred = state.puzzle.solutionIndexes
          .where((index) => index ~/ gridSize == row);
      final rowIndexes = {
        ...preferred,
        for (var col = 0; col < gridSize; col++) row * gridSize + col,
      };
      for (final index in rowIndexes) {
        if (_canPlaceAgainst(index, candidate, config)) {
          final result = search(row + 1, [...candidate, index]);
          if (result != null) return result;
        }
      }
      return null;
    }

    return search(0, placed);
  }

  void _persistCurrentGame() {
    if (state.mode != GameMode.progression ||
        state.puzzle == GeneratedPuzzle.invalid ||
        state.phase == GamePhase.levelComplete ||
        state.phase == GamePhase.gameOver) {
      return;
    }
    final snapshot = _InProgressSnapshot(
      levelNumber: state.levelNumber,
      tileStates: List.from(state.tileStates),
      placedCount: state.placedCount,
      moveHistory: List.from(state.moveHistory),
      autoMarkHistory:
          state.autoMarkHistory.map((batch) => List<int>.from(batch)).toList(),
      actionHistory: List.from(state.actionHistory),
      autoMarksUsed: state.autoMarksUsed,
      hintsUsed: state.hintsUsed,
      undosUsed: state.undosUsed,
      solveRowsUsed: state.solveRowsUsed,
      livesRemaining: state.livesRemaining,
      elapsed: state.elapsed,
      mistakeCount: state.mistakeCount,
    );
    _trackSnapshots[state.activeTrack] = snapshot;
    unawaited(_sessionRepo.save(state.activeTrack, snapshot.toSavedSession()));
  }
}

class _InProgressSnapshot {
  final int levelNumber;
  final List<TileState> tileStates;
  final int placedCount;
  final List<int> moveHistory;
  final List<List<int>> autoMarkHistory;
  final List<String> actionHistory;
  final int autoMarksUsed;
  final int hintsUsed;
  final int undosUsed;
  final int solveRowsUsed;
  final int livesRemaining;
  final Duration elapsed;
  final int mistakeCount;

  _InProgressSnapshot({
    required this.levelNumber,
    required this.tileStates,
    required this.placedCount,
    required this.moveHistory,
    required this.autoMarkHistory,
    required this.actionHistory,
    required this.autoMarksUsed,
    required this.hintsUsed,
    required this.undosUsed,
    required this.solveRowsUsed,
    required this.livesRemaining,
    required this.elapsed,
    required this.mistakeCount,
  });

  factory _InProgressSnapshot.fromSavedSession(SavedGameSession session) =>
      _InProgressSnapshot(
        levelNumber: session.levelNumber,
        tileStates: session.tileStates,
        placedCount: session.placedCount,
        moveHistory: session.moveHistory,
        autoMarkHistory: session.autoMarkHistory,
        actionHistory: session.actionHistory,
        autoMarksUsed: session.autoMarksUsed,
        hintsUsed: session.hintsUsed,
        undosUsed: session.undosUsed,
        solveRowsUsed: session.solveRowsUsed,
        livesRemaining: session.livesRemaining,
        elapsed: Duration(seconds: session.elapsedSeconds),
        mistakeCount: session.mistakeCount,
      );

  SavedGameSession toSavedSession() => SavedGameSession(
        levelNumber: levelNumber,
        tileStates: tileStates,
        placedCount: placedCount,
        moveHistory: moveHistory,
        autoMarkHistory: autoMarkHistory,
        actionHistory: actionHistory,
        autoMarksUsed: autoMarksUsed,
        hintsUsed: hintsUsed,
        undosUsed: undosUsed,
        solveRowsUsed: solveRowsUsed,
        livesRemaining: livesRemaining,
        elapsedSeconds: elapsed.inSeconds,
        mistakeCount: mistakeCount,
      );
}
