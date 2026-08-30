import 'dart:convert';
import 'dart:math';

import 'package:objectbox/objectbox.dart';

import '../models/level_result.dart';
import '../models/session_goal_state.dart';

class SessionGoalDefinition {
  const SessionGoalDefinition({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardType,
    required this.rewardAmount,
  });

  final String id;
  final String title;
  final int target;
  final String rewardType;
  final int rewardAmount;
}

const sessionGoalDefinitions = [
  SessionGoalDefinition(
    id: 'complete_three',
    title: 'Complete three different puzzles',
    target: 3,
    rewardType: 'collection_progress',
    rewardAmount: 1,
  ),
  SessionGoalDefinition(
    id: 'flawless',
    title: 'Finish without a mistake',
    target: 1,
    rewardType: 'cosmetic_currency',
    rewardAmount: 2,
  ),
  SessionGoalDefinition(
    id: 'hard_puzzle',
    title: 'Solve one Hard puzzle',
    target: 1,
    rewardType: 'streak_freeze',
    rewardAmount: 1,
  ),
  SessionGoalDefinition(
    id: 'no_powerups',
    title: 'Win without using a power-up',
    target: 1,
    rewardType: 'collection_progress',
    rewardAmount: 1,
  ),
  SessionGoalDefinition(
    id: 'personal_best',
    title: 'Beat a personal best',
    target: 1,
    rewardType: 'cosmetic_currency',
    rewardAmount: 2,
  ),
];

class SessionGoalUpdate {
  const SessionGoalUpdate({
    required this.goal,
    required this.changed,
    required this.newlyCompleted,
  });

  final SessionGoalState goal;
  final bool changed;
  final bool newlyCompleted;
}

class SessionGoalRepository {
  SessionGoalRepository(this._box);

  static const sessionDuration = Duration(hours: 6);
  final Box<SessionGoalState> _box;

  SessionGoalState? get current {
    final all = _box.getAll();
    return all.isEmpty ? null : all.first;
  }

  SessionGoalState ensureActive({DateTime? now, int? seed}) {
    final instant = now ?? DateTime.now();
    final existing = current;
    if (existing != null && instant.millisecondsSinceEpoch < existing.expiresAtMs) {
      return existing;
    }

    final selected = sessionGoalDefinitions[
        Random(seed ?? instant.millisecondsSinceEpoch).nextInt(
      sessionGoalDefinitions.length,
    )];
    final goal = SessionGoalState()
      ..goalId = 'session:${instant.millisecondsSinceEpoch}:${selected.id}'
      ..goalType = selected.id
      ..target = selected.target
      ..rewardType = selected.rewardType
      ..rewardAmount = selected.rewardAmount
      ..startedAtMs = instant.millisecondsSinceEpoch
      ..expiresAtMs = instant.add(sessionDuration).millisecondsSinceEpoch;
    setGoal(goal);
    return goal;
  }

  SessionGoalDefinition definitionFor(SessionGoalState goal) =>
      sessionGoalDefinitions.firstWhere(
        (definition) => definition.id == goal.goalType,
        orElse: () => sessionGoalDefinitions.first,
      );

  SessionGoalUpdate applyPuzzleResult(PuzzleResult puzzle) {
    final goal = ensureActive();
    if (goal.completed || !puzzle.completed || !_qualifies(goal, puzzle)) {
      return SessionGoalUpdate(
        goal: goal,
        changed: false,
        newlyCompleted: false,
      );
    }

    final identity = puzzle.mode == 'dailyChallenge'
        ? 'daily:${puzzle.puzzleKey}'
        : '${puzzle.track}:${puzzle.levelNumber}';
    final qualifying = _decodeIds(goal.qualifyingPuzzleIdsJson);
    if (!qualifying.add(identity)) {
      return SessionGoalUpdate(
        goal: goal,
        changed: false,
        newlyCompleted: false,
      );
    }

    goal.qualifyingPuzzleIdsJson = jsonEncode(qualifying.toList()..sort());
    goal.progress = (goal.progress + 1).clamp(0, goal.target);
    final wasComplete = goal.completed;
    goal.completed = goal.progress >= goal.target;
    _box.put(goal);
    return SessionGoalUpdate(
      goal: goal,
      changed: true,
      newlyCompleted: !wasComplete && goal.completed,
    );
  }

  bool _qualifies(SessionGoalState goal, PuzzleResult puzzle) =>
      switch (goal.goalType) {
        'complete_three' => true,
        'flawless' => puzzle.mistakes == 0,
        'hard_puzzle' => puzzle.track == 'hard',
        'no_powerups' => puzzle.hintsUsed == 0 &&
            puzzle.solveRowsUsed == 0 &&
            puzzle.autoMarksUsed == 0,
        'personal_best' => puzzle.beatPersonalBest,
        _ => false,
      };

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

  Set<String> _decodeIds(String value) {
    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }
}
