import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/daily_challenge_config.dart';

void main() {
  test('challenge identity uses the complete local calendar date', () {
    final mondayOne = dailyChallengeConfigFor(DateTime(2026, 8, 3));
    final mondayTwo = dailyChallengeConfigFor(DateTime(2026, 8, 10));

    expect(mondayOne.seed, 20260803);
    expect(mondayTwo.seed, 20260810);
    expect(mondayOne.seed, isNot(mondayTwo.seed));
  });

  test('the same date always returns the same deterministic challenge', () {
    final first = dailyChallengeConfigFor(DateTime(2026, 8, 14, 1));
    final second = dailyChallengeConfigFor(DateTime(2026, 8, 14, 23, 59));

    expect(second.seed, first.seed);
    expect(second.level, first.level);
    expect(second.track, first.track);
    expect(second.autoMarkReward, greaterThan(0));
  });

  test('consecutive dates always use different seeds', () {
    final first = dailyChallengeConfigFor(DateTime(2026, 12, 31));
    final second = dailyChallengeConfigFor(DateTime(2027, 1, 1));
    expect(first.seed, 20261231);
    expect(second.seed, 20270101);
    expect(second.seed, isNot(first.seed));
  });
}
