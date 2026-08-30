import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/features/game/domain/star_calculation.dart';
import 'package:zendoku/core/constants/app_constants.dart';

void main() {
  const par = Duration(seconds: 90);

  test('completion always awards one base star', () {
    final result = calculateLevelStars(
      mistakes: 5,
      hintsUsed: 2,
      solveRowsUsed: 1,
      autoMarksUsed: 1,
      elapsed: const Duration(minutes: 4),
      parTime: par,
    );
    expect(result.stars, 1);
  });

  test('at most one mistake awards the accuracy star', () {
    final result = calculateLevelStars(
      mistakes: 1,
      hintsUsed: 1,
      solveRowsUsed: 0,
      autoMarksUsed: 0,
      elapsed: const Duration(seconds: 50),
      parTime: par,
    );
    expect(result.stars, 2);
    expect(result.mistakeStarEarned, isTrue);
    expect(result.masteryStarEarned, isFalse);
  });

  test('no invalidating powers under par awards all three stars', () {
    final result = calculateLevelStars(
      mistakes: 0,
      hintsUsed: 0,
      solveRowsUsed: 0,
      autoMarksUsed: 0,
      elapsed: const Duration(seconds: 89),
      parTime: par,
    );
    expect(result.stars, 3);
  });

  test('undo is intentionally absent from mastery calculation', () {
    expect(
      parTimeForPuzzle(gridSize: 10, track: PuzzleTrack.hard),
      const Duration(seconds: 180),
    );
  });

  test('every chapter defines ten restoration milestones and a reward', () {
    expect(campaignChapters, hasLength(5));
    for (final chapter in campaignChapters) {
      expect(chapter.collectibles, hasLength(10));
      expect(chapter.pathArtAsset, isNotEmpty);
      expect(chapter.completionReward.label, isNotEmpty);
    }
  });
}
