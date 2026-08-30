import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/daily_challenge_config.dart';
import 'package:zendoku/data/models/daily_challenge_history.dart';
import 'package:zendoku/features/daily_challenges/daily_share_card.dart';

void main() {
  test('share card includes results but not a board solution', () {
    final grid = buildSpoilerFreeDailyGrid(
      stars: 3,
      mistakes: 1,
      powersUsed: 0,
    );
    final result = DailyChallengeHistory()
      ..bestTimeMs = 65000
      ..lowestMistakes = 1
      ..streakAtCompletion = 4
      ..shareGridData = grid;
    final text = buildDailyShareText(
      date: DateTime(2026, 8, 14),
      challenge: dailyChallengeConfigFor(DateTime(2026, 8, 14)),
      result: result,
    );

    expect(text, contains('2026-08-14'));
    expect(text, contains('1:05'));
    expect(text, contains('1 mistakes'));
    expect(text, contains('🔥 4 day streak'));
    expect(text, isNot(contains('mine')));
  });
}
