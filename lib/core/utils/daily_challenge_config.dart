import 'dart:math';

import 'puzzle_generator.dart';

class DailyChallengeDay {
  final int level;
  final PuzzleTrack track;
  final int hintReward;
  final int bulbReward;
  final int undoReward;
  final int extraLifeReward;
  final int autoMarkReward;
  final int seed;

  const DailyChallengeDay(
    this.level,
    this.track, {
    this.hintReward = 0,
    this.bulbReward = 0,
    this.undoReward = 0,
    this.extraLifeReward = 0,
    this.autoMarkReward = 1,
    this.seed = 0,
  });
}

DailyChallengeDay dailyChallengeConfigFor(DateTime date) {
  final local = date.toLocal();
  final seed = local.year * 10000 + local.month * 100 + local.day;
  final random = Random(seed);
  final difficultyRoll = random.nextInt(100);

  if (difficultyRoll < 45) {
    return DailyChallengeDay(
      5 + random.nextInt(11),
      PuzzleTrack.normal,
      hintReward: 1,
      autoMarkReward: 1,
      seed: seed,
    );
  }
  if (difficultyRoll < 80) {
    return DailyChallengeDay(
      16 + random.nextInt(20),
      PuzzleTrack.hard,
      hintReward: 1 + random.nextInt(2),
      bulbReward: 1,
      undoReward: 1,
      autoMarkReward: 1,
      seed: seed,
    );
  }
  return DailyChallengeDay(
    31 + random.nextInt(20),
    PuzzleTrack.ultraHard,
    hintReward: 2,
    bulbReward: 1 + random.nextInt(2),
    undoReward: 2,
    extraLifeReward: 1,
    autoMarkReward: 2,
    seed: seed,
  );
}
