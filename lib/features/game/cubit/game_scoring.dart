import '../../../core/utils/puzzle_generator.dart';

double difficultyMultiplier(PuzzleTrack track) => switch (track) {
      PuzzleTrack.normal => 1,
      PuzzleTrack.hard => 1.5,
      PuzzleTrack.ultraHard => 2.5,
    };

int calculateGameScore({
  required PuzzleTrack track,
  required int playerPlacedCount,
  required int mistakeCount,
  required Duration elapsed,
  bool completed = false,
}) {
  final placementPoints = playerPlacedCount * 100;
  final mistakePenalty = mistakeCount * 150;
  final completionPoints = completed ? 1000 : 0;
  final timeBonus = completed ? (600 - elapsed.inSeconds * 5).clamp(0, 600) : 0;
  final flawlessBonus = completed && mistakeCount == 0 ? 250 : 0;
  final rawScore = (placementPoints +
          completionPoints +
          timeBonus +
          flawlessBonus -
          mistakePenalty)
      .clamp(0, 1 << 30);

  return (rawScore * difficultyMultiplier(track)).round();
}
