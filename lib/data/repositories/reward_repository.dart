import 'package:objectbox/objectbox.dart';
import '../models/daily_reward_state.dart';
import 'package:intl/intl.dart';

class DailyReward {
  final int day;
  final int hints;
  final int extraLives;
  final int undos;
  final int bulbs;

  const DailyReward({
    required this.day,
    this.hints = 0,
    this.extraLives = 0,
    this.undos = 0,
    this.bulbs = 0,
  });
}

const List<DailyReward> kDailyRewards = [
  DailyReward(day: 1, hints: 1),
  DailyReward(day: 2, extraLives: 1),
  DailyReward(day: 3, undos: 1),
  DailyReward(day: 4, bulbs: 1, hints: 1),
  DailyReward(day: 5, extraLives: 1, hints: 2),
  DailyReward(day: 6, bulbs: 1, undos: 1, hints: 1),
  DailyReward(day: 7, hints: 2, bulbs: 1, extraLives: 1, undos: 1),
];

/// Repository for handling daily rewards logic.
class RewardRepository {
  RewardRepository(this._box);
  final Box<DailyRewardState> _box;

  /// Returns the single DailyRewardState record, creating it if absent.
  DailyRewardState getState() {
    final existing = _box.getAll();
    if (existing.isNotEmpty) return existing.first;
    
    // New object MUST have id = 0 for ObjectBox to auto-assign
    final defaults = DailyRewardState(); // id defaults to 0
    _box.put(defaults);
    return defaults;
  }

  /// Call on app launch to check if streak should reset.
  /// If last claim was 2+ days ago, reset streak to 0.
  void checkAndUpdateStreak() {
    final state = getState();
    if (state.lastClaimDate.isEmpty) return;

    try {
      final lastClaim = DateFormat('yyyy-MM-dd').parse(state.lastClaimDate);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final today = DateFormat('yyyy-MM-dd').parse(todayStr);

      final difference = today.difference(lastClaim).inDays;
      if (difference == 0) {
        state.claimedToday = true;
      } else if (difference == 1) {
        state.claimedToday = false;
      } else {
        // Missed a day
        state.currentStreakDay = 0;
        state.claimedToday = false;
      }
      _box.put(state);
    } catch (e) {
      // Ignore parse errors, just reset
      state.currentStreakDay = 0;
      state.claimedToday = false;
      _box.put(state);
    }
  }

  /// Returns true if today's reward is available to claim.
  bool canClaimToday() {
    final state = getState();
    return !state.claimedToday;
  }

  /// Claims today's reward. Returns the DailyReward for today's day.
  /// Advances streak day. Returns null if already claimed today.
  DailyReward? claimTodayReward() {
    if (!canClaimToday()) return null;

    final state = getState();
    state.currentStreakDay = (state.currentStreakDay % 7) + 1;
    state.claimedToday = true;
    state.lastClaimDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    _box.put(state);

    return kDailyRewards[state.currentStreakDay - 1];
  }
}
