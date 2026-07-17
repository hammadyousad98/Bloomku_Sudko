import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/daily_challenge_config.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';

void main() {
  test('maps each weekday to the fixed daily challenge config', () {
    final expected = <DailyChallengeDay>[
      const DailyChallengeDay(5, PuzzleTrack.normal),
      const DailyChallengeDay(10, PuzzleTrack.normal),
      const DailyChallengeDay(18, PuzzleTrack.hard),
      const DailyChallengeDay(24, PuzzleTrack.hard),
      const DailyChallengeDay(30, PuzzleTrack.hard),
      const DailyChallengeDay(38, PuzzleTrack.ultraHard),
      const DailyChallengeDay(85, PuzzleTrack.ultraHard),
    ];

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final date = DateTime(2026, 7, 13 + weekday - DateTime.monday);
      final config = dailyChallengeConfigFor(date);

      expect(config.level, expected[weekday - 1].level);
      expect(config.track, expected[weekday - 1].track);
    }
  });
}
