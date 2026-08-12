import 'package:objectbox/objectbox.dart';

/// Best-known aggregate for one campaign level and difficulty track.
@Entity()
class LevelResult {
  @Id()
  int id = 0;

  /// Stable key in the form `<track>:<level>`, for example `normal:14`.
  @Unique()
  String resultKey = '';

  int levelNumber = 1;
  String track = 'normal';
  int bestTimeMs = 0;
  int bestScore = 0;
  int highestStars = 0;
  int completionCount = 0;
  int bestMistakeCount = 0;
  int lastCompletedAtMs = 0;
}

/// Immutable history row for a single puzzle attempt.
@Entity()
class PuzzleResult {
  @Id()
  int id = 0;

  String puzzleKey = '';
  String mode = 'progression';
  int levelNumber = 0;
  String track = 'normal';
  bool completed = false;
  int elapsedMs = 0;
  int score = 0;
  int stars = 0;
  int mistakes = 0;
  int hintsUsed = 0;
  int undosUsed = 0;
  int solveRowsUsed = 0;
  int autoMarksUsed = 0;
  int extraLivesUsed = 0;
  int playedAtMs = 0;
}
