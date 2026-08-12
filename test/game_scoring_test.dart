import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/features/game/cubit/game_scoring.dart';

void main() {
  test('score changes during play and penalizes mistakes', () {
    final clean = calculateGameScore(
      track: PuzzleTrack.normal,
      playerPlacedCount: 3,
      mistakeCount: 0,
      elapsed: const Duration(seconds: 20),
    );
    final mistaken = calculateGameScore(
      track: PuzzleTrack.normal,
      playerPlacedCount: 3,
      mistakeCount: 1,
      elapsed: const Duration(seconds: 20),
    );

    expect(clean, 300);
    expect(mistaken, 150);
  });

  test('completion rewards speed and applies displayed multipliers', () {
    int score(PuzzleTrack track, Duration elapsed) => calculateGameScore(
          track: track,
          playerPlacedCount: 4,
          mistakeCount: 0,
          elapsed: elapsed,
          completed: true,
        );

    final normal = score(PuzzleTrack.normal, const Duration(seconds: 30));
    expect(score(PuzzleTrack.hard, const Duration(seconds: 30)),
        (normal * 1.5).round());
    expect(score(PuzzleTrack.ultraHard, const Duration(seconds: 30)),
        (normal * 2.5).round());
    expect(score(PuzzleTrack.normal, const Duration(seconds: 10)),
        greaterThan(score(PuzzleTrack.normal, const Duration(minutes: 3))));
  });
}
