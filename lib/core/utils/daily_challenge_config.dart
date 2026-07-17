import 'puzzle_generator.dart';

class DailyChallengeDay {
  final int level;
  final PuzzleTrack track;

  const DailyChallengeDay(this.level, this.track);
}

DailyChallengeDay dailyChallengeConfigFor(DateTime date) {
  // date.weekday: 1=Mon..7=Sun
  const table = [
    DailyChallengeDay(5, PuzzleTrack.normal), // Mon
    DailyChallengeDay(10, PuzzleTrack.normal), // Tue
    DailyChallengeDay(18, PuzzleTrack.hard), // Wed
    DailyChallengeDay(24, PuzzleTrack.hard), // Thu
    DailyChallengeDay(30, PuzzleTrack.hard), // Fri
    DailyChallengeDay(38, PuzzleTrack.ultraHard), // Sat
    DailyChallengeDay(85, PuzzleTrack.ultraHard), // Sun
  ];
  return table[date.weekday - 1];
}
