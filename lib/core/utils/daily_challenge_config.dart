import 'puzzle_generator.dart';

class DailyChallengeDay {
  final int level;
  final PuzzleTrack track;
  final int hintReward;
  final int bulbReward;
  final int undoReward;
  final int extraLifeReward;

  const DailyChallengeDay(
    this.level,
    this.track, {
    this.hintReward = 0,
    this.bulbReward = 0,
    this.undoReward = 0,
    this.extraLifeReward = 0,
  });
}

DailyChallengeDay dailyChallengeConfigFor(DateTime date) {
  // date.weekday: 1=Mon..7=Sun
  const table = [
    DailyChallengeDay(5, PuzzleTrack.normal, hintReward: 1),
    DailyChallengeDay(10, PuzzleTrack.normal, bulbReward: 1),
    DailyChallengeDay(
      18,
      PuzzleTrack.hard,
      hintReward: 1,
      bulbReward: 1,
    ),
    DailyChallengeDay(
      24,
      PuzzleTrack.hard,
      hintReward: 2,
      bulbReward: 2,
    ),
    DailyChallengeDay(
      30,
      PuzzleTrack.hard,
      hintReward: 2,
      bulbReward: 2,
      undoReward: 2,
    ),
    DailyChallengeDay(
      38,
      PuzzleTrack.ultraHard,
      hintReward: 3,
      bulbReward: 2,
      undoReward: 2,
    ),
    DailyChallengeDay(
      85,
      PuzzleTrack.ultraHard,
      hintReward: 3,
      bulbReward: 3,
      undoReward: 3,
      extraLifeReward: 2,
    ),
  ];
  return table[date.weekday - 1];
}
