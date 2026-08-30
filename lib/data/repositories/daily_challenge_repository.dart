import 'dart:math';

import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import '../models/daily_challenge_state.dart';
import 'reward_repository.dart';
import 'progress_repository.dart';
import 'daily_history_repository.dart';

const List<DailyReward> kDailyChallengeStreakRewards = [
  DailyReward(day: 1, hints: 1, autoMarks: 1),
  DailyReward(day: 2, undos: 1, autoMarks: 1),
  DailyReward(day: 3, hints: 1, undos: 1, autoMarks: 1),
  DailyReward(day: 4, bulbs: 1, autoMarks: 1),
  DailyReward(day: 5, extraLives: 1, hints: 1, autoMarks: 1),
  DailyReward(day: 6, bulbs: 1, undos: 1, hints: 1, autoMarks: 1),
  DailyReward(
    day: 7,
    hints: 3,
    bulbs: 1,
    extraLives: 1,
    undos: 2,
    autoMarks: 2,
  ),
];

class DailyChallengeCompletion {
  const DailyChallengeCompletion({
    required this.streak,
    required this.streakReward,
    required this.usedStreakFreeze,
  });

  final int streak;
  final DailyReward? streakReward;
  final bool usedStreakFreeze;
}

/// Repository for handling daily challenge streak state.
class DailyChallengeRepository {
  DailyChallengeRepository(
    this._box,
    this._history,
    this._progress,
  );
  final Box<DailyChallengeState> _box;
  final DailyHistoryRepository _history;
  final ProgressRepository _progress;

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
  bool hasCompletedToday([DateTime? date]) =>
      _history.resultForDate(date ?? DateTime.now())?.completed ?? false;

  /// Records today's completion and returns its repeating seven-day bonus.
  /// Returns null when today was already completed or no bonus is configured.
  DailyChallengeCompletion? markCompletedToday({DateTime? date}) {
    final state = getState();
    final now = date ?? DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Replays on the same local calendar day must not affect counters.
    if (state.lastCompletedDate == today) return null;

    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    var usedFreeze = false;
    if (state.lastCompletedDate == yesterday) {
      state.currentChallengeStreak += 1;
    } else {
      final previous = DateTime.tryParse(state.lastCompletedDate);
      final missedExactlyOneDay = previous != null &&
          DateTime(now.year, now.month, now.day)
                  .difference(DateTime(previous.year, previous.month, previous.day))
                  .inDays ==
              2;
      if (missedExactlyOneDay &&
          state.lastFreezeUsedDate != today &&
          _progress.useStreakFreeze()) {
        usedFreeze = true;
        state.lastFreezeUsedDate = today;
        state.currentChallengeStreak += 1;
      } else {
        state.currentChallengeStreak = 1;
      }
    }

    state.longestChallengeStreak = max(
      state.longestChallengeStreak,
      state.currentChallengeStreak,
    );
    state.totalChallengesCompleted += 1;
    state.lastCompletedDate = today;

    _box.put(state);

    final rewardDay = ((state.currentChallengeStreak - 1) % 7) + 1;
    final streakReward = kDailyChallengeStreakRewards
        .where((reward) => reward.day == rewardDay)
        .firstOrNull;
    return DailyChallengeCompletion(
      streak: state.currentChallengeStreak,
      streakReward: streakReward,
      usedStreakFreeze: usedFreeze,
    );
  }
}
