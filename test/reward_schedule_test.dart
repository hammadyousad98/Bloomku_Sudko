import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/data/repositories/reward_repository.dart';

void main() {
  test('reward schedule repeats without resetting the streak count', () {
    expect(rewardForStreakDay(1).day, 1);
    expect(rewardForStreakDay(7).day, 7);
    expect(rewardForStreakDay(8).day, 1);
    expect(rewardForStreakDay(15).day, 1);
  });
}
