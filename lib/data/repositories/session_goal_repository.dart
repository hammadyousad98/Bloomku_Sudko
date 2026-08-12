import 'package:objectbox/objectbox.dart';

import '../models/session_goal_state.dart';

class SessionGoalRepository {
  SessionGoalRepository(this._box);

  final Box<SessionGoalState> _box;

  SessionGoalState? get current {
    final all = _box.getAll();
    return all.isEmpty ? null : all.first;
  }

  void setGoal(SessionGoalState goal) {
    final existing = current;
    if (existing != null) goal.id = existing.id;
    _box.put(goal);
  }

  SessionGoalState? addProgress(int amount) {
    final goal = current;
    if (goal == null || goal.completed || amount <= 0) return goal;
    goal.progress = (goal.progress + amount).clamp(0, goal.target);
    goal.completed = goal.progress >= goal.target;
    _box.put(goal);
    return goal;
  }

  bool claimReward() {
    final goal = current;
    if (goal == null || !goal.completed || goal.rewardClaimed) return false;
    goal.rewardClaimed = true;
    _box.put(goal);
    return true;
  }

  void clear() {
    final goal = current;
    if (goal != null) _box.remove(goal.id);
  }
}
