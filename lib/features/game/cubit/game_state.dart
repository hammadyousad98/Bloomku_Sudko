import 'package:equatable/equatable.dart';
import '../../../core/utils/puzzle_generator.dart';

enum GamePhase {
  loading,
  playing,
  paused,
  levelComplete,
  gameOver,
  reviveOffer,
  generationError,
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
  final Duration elapsed;
  final int hintCount;
  final int undoCount;
  final int bulbCount;
  final int extraLiveCount;
  final PuzzleTrack activeTrack;
  final int levelNumber;
  final bool showDifficultyBar;
  final bool showUltraTab;
  final List<int> moveHistory;
  final String? statusMessage;
  final bool showRuleTutorial;
  final int? errorTileIndex;
  final int? hintTileIndex;
  final List<String> pendingRuleTutorials;

  const GameState({
    required this.phase,
    required this.puzzle,
    required this.tileStates,
    required this.placedCount,
    required this.targetCount,
    required this.livesRemaining,
    required this.maxLives,
    required this.score,
    required this.elapsed,
    required this.hintCount,
    required this.undoCount,
    required this.bulbCount,
    required this.extraLiveCount,
    required this.activeTrack,
    required this.levelNumber,
    required this.showDifficultyBar,
    required this.showUltraTab,
    required this.moveHistory,
    this.statusMessage,
    this.showRuleTutorial = false,
    this.errorTileIndex,
    this.hintTileIndex,
    this.pendingRuleTutorials = const [],
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
    Duration? elapsed,
    int? hintCount,
    int? undoCount,
    int? bulbCount,
    int? extraLiveCount,
    PuzzleTrack? activeTrack,
    int? levelNumber,
    bool? showDifficultyBar,
    bool? showUltraTab,
    List<int>? moveHistory,
    String? statusMessage,
    bool? showRuleTutorial,
    int? errorTileIndex,
    int? hintTileIndex,
    List<String>? pendingRuleTutorials,
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
      elapsed: elapsed ?? this.elapsed,
      hintCount: hintCount ?? this.hintCount,
      undoCount: undoCount ?? this.undoCount,
      bulbCount: bulbCount ?? this.bulbCount,
      extraLiveCount: extraLiveCount ?? this.extraLiveCount,
      activeTrack: activeTrack ?? this.activeTrack,
      levelNumber: levelNumber ?? this.levelNumber,
      showDifficultyBar: showDifficultyBar ?? this.showDifficultyBar,
      showUltraTab: showUltraTab ?? this.showUltraTab,
      moveHistory: moveHistory ?? this.moveHistory,
      statusMessage: statusMessage ?? this.statusMessage,
      showRuleTutorial: showRuleTutorial ?? this.showRuleTutorial,
      errorTileIndex:
          errorTileIndex, // Allow clearing by not defaulting to this.
      hintTileIndex: hintTileIndex, // Allow clearing by not defaulting to this.
      pendingRuleTutorials: pendingRuleTutorials ?? this.pendingRuleTutorials,
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
        elapsed,
        hintCount,
        undoCount,
        bulbCount,
        extraLiveCount,
        activeTrack,
        levelNumber,
        showDifficultyBar,
        showUltraTab,
        moveHistory,
        statusMessage,
        showRuleTutorial,
        errorTileIndex,
        hintTileIndex,
        pendingRuleTutorials,
      ];
}
