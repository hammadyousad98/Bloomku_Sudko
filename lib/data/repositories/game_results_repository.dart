import 'package:objectbox/objectbox.dart';

import '../models/level_result.dart';

class GameResultsRepository {
  GameResultsRepository(this._levelBox, this._puzzleBox);

  final Box<LevelResult> _levelBox;
  final Box<PuzzleResult> _puzzleBox;

  LevelResult? levelResult(int levelNumber, String track) {
    final key = '$track:$levelNumber';
    for (final result in _levelBox.getAll()) {
      if (result.resultKey == key) return result;
    }
    return null;
  }

  List<LevelResult> allLevelResults() => _levelBox.getAll();

  List<PuzzleResult> puzzleHistory() =>
      _puzzleBox.getAll()..sort((a, b) => b.playedAtMs.compareTo(a.playedAtMs));

  int recordPuzzle(PuzzleResult result) {
    result.playedAtMs = result.playedAtMs == 0
        ? DateTime.now().millisecondsSinceEpoch
        : result.playedAtMs;
    final id = _puzzleBox.put(result);
    if (result.completed && result.mode == 'progression') {
      _mergeLevelResult(result);
    }
    return id;
  }

  void _mergeLevelResult(PuzzleResult puzzle) {
    final aggregate = levelResult(puzzle.levelNumber, puzzle.track) ??
        (LevelResult()
          ..resultKey = '${puzzle.track}:${puzzle.levelNumber}'
          ..levelNumber = puzzle.levelNumber
          ..track = puzzle.track);
    aggregate.completionCount += 1;
    if (puzzle.elapsedMs > 0 &&
        (aggregate.bestTimeMs == 0 ||
            puzzle.elapsedMs < aggregate.bestTimeMs)) {
      aggregate.bestTimeMs = puzzle.elapsedMs;
    }
    if (puzzle.score > aggregate.bestScore) aggregate.bestScore = puzzle.score;
    if (puzzle.stars > aggregate.highestStars) {
      aggregate.highestStars = puzzle.stars.clamp(0, 3);
    }
    if (aggregate.completionCount == 1 ||
        puzzle.mistakes < aggregate.bestMistakeCount) {
      aggregate.bestMistakeCount = puzzle.mistakes;
    }
    aggregate.lastCompletedAtMs = puzzle.playedAtMs;
    _levelBox.put(aggregate);
  }
}
