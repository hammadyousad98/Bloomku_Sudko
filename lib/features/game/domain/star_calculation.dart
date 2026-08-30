import '../../../core/utils/puzzle_generator.dart';

class StarCalculation {
  const StarCalculation({
    required this.stars,
    required this.mistakeStarEarned,
    required this.masteryStarEarned,
    required this.parTime,
  });

  final int stars;
  final bool mistakeStarEarned;
  final bool masteryStarEarned;
  final Duration parTime;
}

Duration parTimeForPuzzle({
  required int gridSize,
  required PuzzleTrack track,
}) {
  final baseSeconds = gridSize * 15;
  final multiplier = switch (track) {
    PuzzleTrack.normal => 1.0,
    PuzzleTrack.hard => 1.2,
    PuzzleTrack.ultraHard => 1.4,
  };
  return Duration(seconds: (baseSeconds * multiplier).round());
}

StarCalculation calculateLevelStars({
  required int mistakes,
  required int hintsUsed,
  required int solveRowsUsed,
  required int autoMarksUsed,
  required Duration elapsed,
  required Duration parTime,
}) {
  final mistakeStarEarned = mistakes <= 1;
  final masteryStarEarned = hintsUsed == 0 &&
      solveRowsUsed == 0 &&
      autoMarksUsed == 0 &&
      elapsed <= parTime;
  return StarCalculation(
    stars: 1 + (mistakeStarEarned ? 1 : 0) + (masteryStarEarned ? 1 : 0),
    mistakeStarEarned: mistakeStarEarned,
    masteryStarEarned: masteryStarEarned,
    parTime: parTime,
  );
}
