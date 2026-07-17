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

  Future<void> startLevel(int levelNumber, PuzzleTrack track) async {
    await _startLevelInternal(levelNumber, track);
  }

  Future<void> startDailyChallenge() async {
    final config = dailyChallengeConfigFor(DateTime.now());
    await _startLevelInternal(
      config.level,
      config.track,
      mode: GameMode.dailyChallenge,
    );
  }

  Future<void> _startLevelInternal(
    int levelNumber,
    PuzzleTrack track, {
    GameMode mode = GameMode.progression,
  }) async {
    _timer?.cancel();
    final token = ++_generationToken;

    var effectiveLevel = levelNumber;
    var effectiveTrack = track;
    var config = PuzzleGenerator.configForLevel(levelNumber, track);
    String? fallbackStatusMessage;
    final isDailyChallenge = mode == GameMode.dailyChallenge;

    emit(
      state.copyWith(
        phase: GamePhase.loading,
        mode: mode,
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
      const fallbackDay = DailyChallengeDay(38, PuzzleTrack.ultraHard);
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
    final List<TileState> states = List.filled(
      gridSize * gridSize,
      TileState.empty,
    );
    for (int index in puzzle.lockedIndexes) {
      states[index] = TileState.lockedObject;
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

    emit(
      state.copyWith(
        phase: GamePhase.playing,
        puzzle: puzzle,
        tileStates: states,
        placedCount: puzzle.lockedIndexes.length,
        targetCount: gridSize,
        livesRemaining: 3,
        maxLives: 3,
        elapsed: Duration.zero,
        hintCount: progress.hints,
        undoCount: progress.undos,
        bulbCount: progress.bulbs,
        extraLiveCount: progress.extraLives,
        mode: mode,
        activeTrack: effectiveTrack,
        levelNumber: effectiveLevel,
        showDifficultyBar: !isDailyChallenge && effectiveLevel >= 15,
        showUltraTab: !isDailyChallenge && effectiveLevel > 30,
        moveHistory: [],
        statusMessage: fallbackStatusMessage,
        showRuleTutorial: showRuleTutorial || pending.isNotEmpty,
        pendingRuleTutorials: pending,
        errorTileIndex: null,
        hintTileIndex: null,
      ),
    );

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
  void dismissNextRuleTutorial() {
    final remaining = List<String>.from(state.pendingRuleTutorials);
    if (remaining.isNotEmpty) remaining.removeAt(0);
    emit(
      state.copyWith(
        pendingRuleTutorials: remaining,
        showRuleTutorial: remaining.isNotEmpty,
      ),
    );
  }

  void onTileSingleTap(int index) {
    if (state.phase != GamePhase.playing) return;

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
      ),
    );
  }

  void onTileDoubleTap(int index) {
    if (state.phase != GamePhase.playing) return;

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
          ),
        );

        if (newPlacedCount == state.targetCount) {
          _onLevelComplete();
        }
      } else {
        // Invalid placement
        AudioService.playError();
        if (_settingsRepo.vibrationEnabled) {
          unawaited(HapticFeedback.heavyImpact());
        }

        final lives = state.livesRemaining - 1;
        emit(
          state.copyWith(
            livesRemaining: lives,
            errorTileIndex: index,
            hintTileIndex: null,
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
        _dailyChallengeRepo.markCompletedToday();
        _progressRepo.addHints(1);
        _progressRepo.addUndos(1);
      }
    } else {
      _progressRepo.completeLevel(state.levelNumber, state.activeTrack);

      final progress = _progressRepo.getProgress();
      if (progress.levelsCompletedCount % 2 == 0 && !progress.adsRemoved) {
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
    startLevel(state.levelNumber, track);
  }

  void onLivesExhausted() {
    emit(state.copyWith(phase: GamePhase.reviveOffer));
  }

  void onRewardedAdCompleted(RewardType type) {
    if (type == RewardType.hint) {
      _progressRepo.addHints(1);
      emit(state.copyWith(hintCount: state.hintCount + 1));
      useHint();
    } else if (type == RewardType.bulb) {
      _progressRepo.addBulbs(1);
      emit(state.copyWith(bulbCount: state.bulbCount + 1));
      useBulb();
    } else if (type == RewardType.undo) {
      _progressRepo.addUndos(1);
      emit(state.copyWith(undoCount: state.undoCount + 1));
      undoLast();
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
    emit(state.copyWith(phase: GamePhase.gameOver));
  }
}
