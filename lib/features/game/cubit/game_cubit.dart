import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/daily_challenge_config.dart';
import '../../../core/utils/puzzle_generator.dart';
import '../../../data/repositories/daily_challenge_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import 'game_state.dart';

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

  final Map<PuzzleTrack, _InProgressSnapshot> _trackSnapshots = {};

  static const Duration _generationTimeout = Duration(seconds: 5);

  Timer? _timer;
  int _generationToken = 0;

  GameCubit(
    this._progressRepo,
    this._settingsRepo,
    this._dailyChallengeRepo,
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
            elapsed: Duration.zero,
            hintCount: 0,
            undoCount: 0,
            bulbCount: 0,
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
    return super.close();
  }

  Future<void> startLevel(int levelNumber, PuzzleTrack track, {bool forceRestart = false}) async {
    if (forceRestart) {
      _trackSnapshots.remove(track);
    }
    await _startLevelInternal(levelNumber, track, forceRestart: forceRestart);
  }

  Future<void> startGuidedTutorial() async {
    emit(state.copyWith(
      guidedModeActive: true,
      guidedStepIndex: 0,
    ));
    await _startLevelInternal(1, PuzzleTrack.normal, forceRestart: true);
  }

  void _beginGuidedLevel() {
    emit(state.copyWith(
      guidedStepIndex: 0,
      guidedGotchaTriggered: false,
      guidedGotchaActive: false,
      guidedPreviewActive: true,
      guidedPreviewRule: state.levelNumber == 1 ? 'rowColumn' : (state.levelNumber == 2 ? 'colorRegion' : 'noTouch'),
    ));
  }

  void finishGuidedPreview() {
    emit(state.copyWith(guidedPreviewActive: false, clearGuidedPreviewRule: true));
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
      guidedInstructionText: "Tap once to mark this cell with an ×",
    ));
  }

  void _guideCurrentStep() {
    if (state.levelNumber == 3 && state.guidedStepIndex == state.puzzle.solutionIndexes.length - 1 && !state.guidedGotchaTriggered) {
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
                if (state.tileStates[idx] == TileState.empty && !state.puzzle.lockedIndexes.contains(idx)) {
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
              guidedInstructionText: "Try tapping here — see what happens"
          ));
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
      instr = "Double-tap the highlighted tile to place a flower — only one per row & column";
    } else if (state.levelNumber == 2) {
      instr = "Double-tap the highlighted tile — only one flower per color region";
    } else {
      instr = "Double-tap the highlighted tile — flowers can't touch, not even diagonally";
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
      startLevel(state.levelNumber + 1, PuzzleTrack.normal);
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
    );
  }

  Future<void> _startLevelInternal(
    int levelNumber,
    PuzzleTrack track, {
    GameMode mode = GameMode.progression,
    DailyChallengeDay? dailyDay,
    bool forceRestart = false,
  }) async {
    _timer?.cancel();
    final token = ++_generationToken;

    var effectiveLevel = levelNumber;
    var effectiveTrack = track;
    var config = PuzzleGenerator.configForLevel(levelNumber, track);
    var resolvedDailyDay = dailyDay;
    String? fallbackStatusMessage;
    final isDailyChallenge = mode == GameMode.dailyChallenge;

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
        moveHistory: [],
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

    if (!forceRestart && !isDailyChallenge) {
      final snapshot = _trackSnapshots[effectiveTrack];
      if (snapshot != null && snapshot.levelNumber == effectiveLevel) {
        if (snapshot.tileStates.length == states.length) {
          states = List.from(snapshot.tileStates);
          currentPlacedCount = snapshot.placedCount;
          currentMoveHistory = List.from(snapshot.moveHistory);
          currentLives = snapshot.livesRemaining;
          currentElapsed = snapshot.elapsed;
        }
      }
    }

    final progress = _progressRepo.getProgress();
    final bool showRuleTutorial = !_progressRepo.hasSeenRuleTutorial(
      effectiveLevel,
    );
    if (showRuleTutorial) {
      _progressRepo.markRuleTutorialSeen(effectiveLevel);
    }

    // Build list of new rule tutorials to show
    final List<String> pending = [];
    if (config.blockFullDiagonal && !_progressRepo.hasSeenDiagonalRule()) {
      _progressRepo.markDiagonalRuleSeen();
      pending.add('diagonal');
    }
    if (config.blockMinDistance && !_progressRepo.hasSeenMinDistanceRule()) {
      _progressRepo.markMinDistanceRuleSeen();
      pending.add('minDistance');
    }
    if (config.blockKnightMove && !_progressRepo.hasSeenKnightMoveRule()) {
      _progressRepo.markKnightMoveRuleSeen();
      pending.add('knightMove');
    }
    if (puzzle.mineIndexes.isNotEmpty && !_progressRepo.hasSeenMineRule()) {
      _progressRepo.markMineRuleSeen();
      pending.add('mine');
    }

    // The old rule-popup tutorial system for row/column, color-region, and no-touch
    // on levels 1-3 of Normal track has been superseded by the guided walkthrough.

    emit(
      state.copyWith(
        phase: GamePhase.playing,
        puzzle: puzzle,
        tileStates: states,
        placedCount: currentPlacedCount,
        targetCount: gridSize,
        livesRemaining: currentLives,
        maxLives: 3,
        elapsed: currentElapsed,
        hintCount: progress.hints,
        undoCount: progress.undos,
        bulbCount: progress.bulbs,
        extraLiveCount: progress.extraLives,
        mode: mode,
        activeDailyDay: resolvedDailyDay,
        clearActiveDailyDay: !isDailyChallenge,
        activeTrack: effectiveTrack,
        levelNumber: effectiveLevel,
        showDifficultyBar: !isDailyChallenge && effectiveLevel >= 15,
        showUltraTab: !isDailyChallenge && effectiveLevel > 30,
        moveHistory: currentMoveHistory,
        statusMessage: fallbackStatusMessage,
        showRuleTutorial: showRuleTutorial || pending.isNotEmpty,
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
      if (state.phase == GamePhase.playing) {
        emit(
          state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1)),
        );
      }
    });
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

  void onTileSingleTap(int index) {
    if (state.phase != GamePhase.playing) return;

    if (state.guidedModeActive && state.guidedInteractableIndex != null && index != state.guidedInteractableIndex) {
      return;
    }

    final currentStates = List<TileState>.from(state.tileStates);
    final tile = currentStates[index];

    if (tile == TileState.lockedObject || tile == TileState.revealedMine) {
      return;
    }

    if (tile == TileState.empty) {
      currentStates[index] = TileState.marker;
    } else if (tile == TileState.marker) {
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

    if (state.guidedModeActive && state.guidedTeachingMarker && index == state.guidedInteractableIndex) {
      emit(state.copyWith(guidedTeachingMarker: false));
      _guideCurrentStep();
    }
  }

  void onTileDoubleTap(int index) {
    if (state.phase != GamePhase.playing) return;

    if (state.guidedModeActive && state.guidedInteractableIndex != null && index != state.guidedInteractableIndex) {
      return;
    }

    final currentStates = List<TileState>.from(state.tileStates);
    final tile = currentStates[index];

    if (tile == TileState.lockedObject || tile == TileState.revealedMine) {
      return;
    }

    if (tile == TileState.empty || tile == TileState.marker) {
      if (_canPlace(index, currentStates)) {
        currentStates[index] = TileState.object;
        final newHistory = List<int>.from(state.moveHistory)..add(index);
        final newPlacedCount = state.placedCount + 1;

        AudioService.playPlaceObject();
        if (_settingsRepo.vibrationEnabled) {
          unawaited(HapticFeedback.lightImpact());
        }

        emit(
          state.copyWith(
            tileStates: currentStates,
            placedCount: newPlacedCount,
            moveHistory: newHistory,
            errorTileIndex: null,
            hintTileIndex: null,
            mineTileIndex: null,
          ),
        );

        if (state.guidedModeActive &&
            state.guidedStepIndex < state.puzzle.solutionIndexes.length) {
          if (index == state.puzzle.solutionIndexes[state.guidedStepIndex]) {
            emit(state.copyWith(
              guidedStepIndex: state.guidedStepIndex + 1,
              clearGuidedInteractableIndex: true,
              clearGuidedInstructionText: true,
              guidedFeedbackText: state.levelNumber == 1 ? "✓ Nice! Only one flower per row & column" : (state.levelNumber == 2 ? "✓ Correct! One per color region" : "✓ Perfect — no flowers touching")
            ));
            Future.delayed(const Duration(milliseconds: 900), () {
              if (!isClosed && state.guidedModeActive) {
                emit(state.copyWith(clearGuidedFeedbackText: true));
                _guideCurrentStep();
                if (newPlacedCount == state.targetCount) {
                  _onLevelComplete();
                }
              }
            });
          }
        } else {
          if (newPlacedCount == state.targetCount) {
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
            guidedFeedbackText: "That's too close — not even diagonally!"
          ));
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
          
          emit(
            state.copyWith(
              tileStates: currentStates,
              livesRemaining: lives,
              mineTileIndex: index,
              errorTileIndex: null,
              hintTileIndex: null,
              lifeLostToken: state.lifeLostToken + 1,
              lifeLostTileIndex: index,
              lifeLostTargetHeartIndex: state.livesRemaining - 1,
            ),
          );

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
          emit(
            state.copyWith(
              livesRemaining: lives,
              errorTileIndex: index,
              mineTileIndex: null,
              hintTileIndex: null,
              lifeLostToken: state.lifeLostToken + 1,
              lifeLostTileIndex: index,
              lifeLostTargetHeartIndex: lives,
            ),
          );

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
      emit(
        state.copyWith(
          tileStates: currentStates,
          placedCount: state.placedCount - 1,
          moveHistory: newHistory,
          errorTileIndex: null,
          hintTileIndex: null,
          mineTileIndex: null,
        ),
      );
    }
  }

  bool _canPlace(int index, List<TileState> states) {
    final puzzle = state.puzzle;
    final config = PuzzleGenerator.configForLevel(
      state.levelNumber,
      state.activeTrack,
    );
    final int gridSize = puzzle.gridSize;
    final int row = index ~/ gridSize;
    final int col = index % gridSize;
    final int myColor = puzzle.colorMap[index];

    if (puzzle.mineIndexes.contains(index)) return false;

    final placed = <int>[];
    for (int i = 0; i < states.length; i++) {
      if (states[i] == TileState.object ||
          states[i] == TileState.lockedObject) {
        placed.add(i);
      }
    }

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

    if (_settingsRepo.vibrationEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }

    int wrongPlacements = (state.maxLives - state.livesRemaining);
    int baseScore = 1000;
    int errorsPenalty = wrongPlacements * 10;
    int flawlessBonus = wrongPlacements == 0 ? 50 : 0;
    int finalScore = state.score + baseScore - errorsPenalty + flawlessBonus;

    if (state.mode == GameMode.dailyChallenge) {
      if (!_dailyChallengeRepo.hasCompletedToday()) {
        final dailyDay = state.activeDailyDay!;
        if (dailyDay.hintReward > 0) {
          _progressRepo.addHints(dailyDay.hintReward);
        }
        if (dailyDay.bulbReward > 0) {
          _progressRepo.addBulbs(dailyDay.bulbReward);
        }
        if (dailyDay.undoReward > 0) {
          _progressRepo.addUndos(dailyDay.undoReward);
        }
        if (dailyDay.extraLifeReward > 0) {
          _progressRepo.addExtraLives(dailyDay.extraLifeReward);
        }

        final streakReward = _dailyChallengeRepo.markCompletedToday();
        if (streakReward != null) {
          if (streakReward.hints > 0) {
            _progressRepo.addHints(streakReward.hints);
          }
          if (streakReward.bulbs > 0) {
            _progressRepo.addBulbs(streakReward.bulbs);
          }
          if (streakReward.undos > 0) {
            _progressRepo.addUndos(streakReward.undos);
          }
          if (streakReward.extraLives > 0) {
            _progressRepo.addExtraLives(streakReward.extraLives);
          }
        }
      }
    } else {
      _progressRepo.completeLevel(state.levelNumber, state.activeTrack);

      final progress = _progressRepo.getProgress();
      if (!state.guidedModeActive &&
          progress.levelsCompletedCount >= 5 &&
          (progress.levelsCompletedCount - 5) % 2 == 0 &&
          !progress.adsRemoved) {
        AdService.showInterstitial(adsRemoved: progress.adsRemoved);
      }
    }

    emit(state.copyWith(phase: GamePhase.levelComplete, score: finalScore));
  }

  void useHint() {
    if (state.hintCount > 0) {
      _progressRepo.useHint();

      // Find a valid empty tile
      int? target;
      for (int i = 0; i < state.puzzle.solutionIndexes.length; i++) {
        int index = state.puzzle.solutionIndexes[i];
        if (state.tileStates[index] == TileState.empty ||
            state.tileStates[index] == TileState.marker) {
          target = index;
          break;
        }
      }

      emit(
        state.copyWith(hintCount: state.hintCount - 1, hintTileIndex: target),
      );

      if (target != null) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!isClosed && state.hintTileIndex == target) {
            emit(state.copyWith(hintTileIndex: null));
          }
        });
      }
    } else {
      try {
        AdService.showRewarded(
          RewardType.hint,
          onRewarded: onRewardedAdCompleted,
          adsRemoved: _progressRepo.getProgress().adsRemoved,
        );
      } catch (_) {}
    }
  }

  void useBulb() {
    if (state.bulbCount > 0) {
      _progressRepo.useBulb();

      final currentStates = List<TileState>.from(state.tileStates);
      final gridSize = state.puzzle.gridSize;

      for (int row = 0; row < gridSize; row++) {
        // Find if this row is already solved
        bool solved = false;
        for (int col = 0; col < gridSize; col++) {
          int index = row * gridSize + col;
          if (currentStates[index] == TileState.object ||
              currentStates[index] == TileState.lockedObject) {
            solved = true;
            break;
          }
        }

        if (!solved) {
          // Place the correct object for this row
          for (int index in state.puzzle.solutionIndexes) {
            if (index ~/ gridSize == row) {
              currentStates[index] =
                  TileState.lockedObject; // lock it so it can't be undone
              final newPlacedCount = state.placedCount + 1;
              emit(
                state.copyWith(
                  bulbCount: state.bulbCount - 1,
                  tileStates: currentStates,
                  placedCount: newPlacedCount,
                ),
              );
              if (newPlacedCount == state.targetCount) {
                _onLevelComplete();
              }
              return;
            }
          }
        }
      }
    } else {
      try {
        AdService.showRewarded(
          RewardType.bulb,
          onRewarded: onRewardedAdCompleted,
          adsRemoved: _progressRepo.getProgress().adsRemoved,
        );
      } catch (_) {}
    }
  }

  void undoLast() {
    if (state.moveHistory.isNotEmpty && state.undoCount > 0) {
      _progressRepo.useUndo();

      final currentStates = List<TileState>.from(state.tileStates);
      final newHistory = List<int>.from(state.moveHistory);
      final indexToUndo = newHistory.removeLast();

      if (currentStates[indexToUndo] == TileState.object) {
        currentStates[indexToUndo] = TileState.empty;
        emit(
          state.copyWith(
            undoCount: state.undoCount - 1,
            tileStates: currentStates,
            moveHistory: newHistory,
            placedCount: state.placedCount - 1,
          ),
        );
      }
    } else if (state.undoCount <= 0) {
      try {
        AdService.showRewarded(
          RewardType.undo,
          onRewarded: onRewardedAdCompleted,
          adsRemoved: _progressRepo.getProgress().adsRemoved,
        );
      } catch (_) {}
    }
  }

  void switchTrack(PuzzleTrack track) {
    if (state.mode == GameMode.dailyChallenge) return;

    if (state.phase == GamePhase.playing) {
      _trackSnapshots[state.activeTrack] = _InProgressSnapshot(
        levelNumber: state.levelNumber,
        tileStates: List.from(state.tileStates),
        placedCount: state.placedCount,
        moveHistory: List.from(state.moveHistory),
        livesRemaining: state.livesRemaining,
        elapsed: state.elapsed,
      );
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
    } else if (type == RewardType.extraLife) {
      _progressRepo.addExtraLives(1);
      emit(
        state.copyWith(
          extraLiveCount: state.extraLiveCount + 1,
          livesRemaining: 3,
          phase: GamePhase.playing,
        ),
      );
    }
  }

  void giveUp() {
    _trackSnapshots.remove(state.activeTrack);
    emit(state.copyWith(phase: GamePhase.gameOver));
  }

  void clearRewardMessage() {
    if (state.rewardMessage != null) {
      emit(state.copyWith(clearRewardMessage: true));
    }
  }
}

class _InProgressSnapshot {
  final int levelNumber;
  final List<TileState> tileStates;
  final int placedCount;
  final List<int> moveHistory;
  final int livesRemaining;
  final Duration elapsed;

  _InProgressSnapshot({
    required this.levelNumber,
    required this.tileStates,
    required this.placedCount,
    required this.moveHistory,
    required this.livesRemaining,
    required this.elapsed,
  });
}
