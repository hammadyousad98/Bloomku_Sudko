import 'dart:math';

import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import '../models/daily_challenge_state.dart';
import 'reward_repository.dart';

const List<DailyReward> kDailyChallengeStreakRewards = [
  DailyReward(day: 1, hints: 1),
  DailyReward(day: 2, undos: 1),
  DailyReward(day: 3, hints: 1, undos: 1),
  DailyReward(day: 4, bulbs: 1),
  DailyReward(day: 5, extraLives: 1, hints: 1),
  DailyReward(day: 6, bulbs: 1, undos: 1, hints: 1),
  DailyReward(day: 7, hints: 3, bulbs: 1, extraLives: 1, undos: 2),
];

/// Repository for handling daily challenge streak state.
class DailyChallengeRepository {
  DailyChallengeRepository(this._box);
  final Box<DailyChallengeState> _box;

  /// Returns the single DailyChallengeState record, creating it if absent.
  DailyChallengeState getState() {
    final existing = _box.getAll();
    if (existing.isNotEmpty) return existing.first;

    // New object MUST have id = 0 for ObjectBox to auto-assign
    final defaults = DailyChallengeState(); // id defaults to 0
    _box.put(defaults);
    return defaults;
  }

  /// Returns true if today's challenge has already been completed.
  bool hasCompletedToday() {
    final state = getState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return state.lastCompletedDate == today;
  }

  /// Records today's completion and returns its repeating seven-day bonus.
  /// Returns null when today was already completed or no bonus is configured.
  DailyReward? markCompletedToday() {
    final state = getState();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Replays on the same local calendar day must not affect counters.
    if (state.lastCompletedDate == today) return null;

    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    if (state.lastCompletedDate == yesterday) {
      state.currentChallengeStreak += 1;
    } else {
      state.currentChallengeStreak = 1;
    }

    state.longestChallengeStreak = max(
      state.longestChallengeStreak,
      state.currentChallengeStreak,
    );
    state.totalChallengesCompleted += 1;
    state.lastCompletedDate = today;

    _box.put(state);

    final rewardDay = ((state.currentChallengeStreak - 1) % 7) + 1;
    for (final reward in kDailyChallengeStreakRewards) {
      if (reward.day == rewardDay) return reward;
    }
    return null;
  }
}
