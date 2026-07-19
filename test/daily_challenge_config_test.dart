import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/daily_challenge_config.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';

void main() {
  test('maps each weekday to the fixed daily challenge config', () {
    final expected = <DailyChallengeDay>[
      const DailyChallengeDay(5, PuzzleTrack.normal, hintReward: 1),
      const DailyChallengeDay(10, PuzzleTrack.normal, bulbReward: 1),
      const DailyChallengeDay(
        18,
        PuzzleTrack.hard,
        hintReward: 1,
        bulbReward: 1,
      ),
      const DailyChallengeDay(
        24,
        PuzzleTrack.hard,
        hintReward: 2,
        bulbReward: 2,
      ),
      const DailyChallengeDay(
        30,
        PuzzleTrack.hard,
        hintReward: 2,
        bulbReward: 2,
        undoReward: 2,
      ),
      const DailyChallengeDay(
        38,
        PuzzleTrack.ultraHard,
        hintReward: 3,
        bulbReward: 2,
        undoReward: 2,
      ),
      const DailyChallengeDay(
        85,
        PuzzleTrack.ultraHard,
        hintReward: 3,
        bulbReward: 3,
        undoReward: 3,
        extraLifeReward: 2,
      ),
    ];

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final date = DateTime(2026, 7, 13 + weekday - DateTime.monday);
      final config = dailyChallengeConfigFor(date);

      expect(config.level, expected[weekday - 1].level);
      expect(config.track, expected[weekday - 1].track);
      expect(config.hintReward, expected[weekday - 1].hintReward);
      expect(config.bulbReward, expected[weekday - 1].bulbReward);
      expect(config.undoReward, expected[weekday - 1].undoReward);
      expect(config.extraLifeReward, expected[weekday - 1].extraLifeReward);
    }
  });
}
