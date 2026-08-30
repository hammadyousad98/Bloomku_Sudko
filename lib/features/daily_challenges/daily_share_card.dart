import 'package:intl/intl.dart';

import '../../core/utils/daily_challenge_config.dart';
import '../../core/utils/puzzle_generator.dart';
import '../../data/models/daily_challenge_history.dart';

/// Produces an achievement grid, never the puzzle's solution or mine layout.
String buildSpoilerFreeDailyGrid({
  required int stars,
  required int mistakes,
  required int powersUsed,
}) {
  final earned = (stars * 4 - mistakes - powersUsed).clamp(4, 16);
  return List.generate(4, (row) {
    return List.generate(4, (column) {
      final index = row * 4 + column;
      return index < earned ? '🟩' : '⬜';
    }).join();
  }).join('\n');
}

String buildDailyShareText({
  required DateTime date,
  required DailyChallengeDay challenge,
  required DailyChallengeHistory result,
}) {
  final time = Duration(milliseconds: result.bestTimeMs);
  final minutes = time.inMinutes;
  final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
  final difficulty = switch (challenge.track) {
    PuzzleTrack.normal => 'Normal',
    PuzzleTrack.hard => 'Hard',
    PuzzleTrack.ultraHard => 'Ultra Hard',
  };
  return 'Zendoku Daily · ${DateFormat('yyyy-MM-dd').format(date)}\n'
      '$difficulty · $minutes:$seconds · ${result.lowestMistakes} mistakes\n'
      '${result.shareGridData}\n'
      '🔥 ${result.streakAtCompletion} day streak';
}
