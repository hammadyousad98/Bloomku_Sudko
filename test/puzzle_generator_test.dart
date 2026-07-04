import 'package:flutter_test/flutter_test.dart';
import 'package:bloomku/core/utils/puzzle_generator.dart';

void main() {
  group('PuzzleGenerator', () {
    test('gridSizeForLevel returns correct values for levels 1, 9, 16, 31, 50', () {
      expect(PuzzleGenerator.gridSizeForLevel(1, PuzzleTrack.normal), 2);
      expect(PuzzleGenerator.gridSizeForLevel(9, PuzzleTrack.normal), 6);
      expect(PuzzleGenerator.gridSizeForLevel(16, PuzzleTrack.normal), 7);
      expect(PuzzleGenerator.gridSizeForLevel(31, PuzzleTrack.normal), 10);
      expect(PuzzleGenerator.gridSizeForLevel(50, PuzzleTrack.normal), 13);
    });

    test('generate() returns isValid=true for all grid sizes 2-15 and checks rules', () {
      for (int size = 2; size <= 15; size++) {
        final config = PuzzleConfig(
          gridSize: size,
          levelNumber: 1, // Any valid level
          track: PuzzleTrack.normal,
        );

        final puzzle = PuzzleGenerator.generate(config);

        expect(puzzle.isValid, true, reason: 'Failed generation for grid size $size');
        expect(puzzle.solutionIndexes.length, size, reason: 'solutionIndexes length should match gridSize $size');
        expect(puzzle.colorMap.length, size * size, reason: 'colorMap length should match gridSize * gridSize');

        final rows = <int>{};
        final cols = <int>{};
        final colors = <int>{};

        for (int index in puzzle.solutionIndexes) {
          rows.add(index ~/ size);
          cols.add(index % size);
          colors.add(puzzle.colorMap[index]);
        }

        expect(rows.length, size, reason: 'No two solution indexes can share a row on grid size $size');
        expect(cols.length, size, reason: 'No two solution indexes can share a column on grid size $size');
        expect(colors.length, size, reason: 'No two solution indexes can share a color region on grid size $size');
      }
    });

    test('With blockFullDiagonal=true: no two solutions share a full diagonal', () {
      final config = PuzzleConfig(
        gridSize: 8,
        levelNumber: 16,
        track: PuzzleTrack.hard,
        blockFullDiagonal: true,
      );

      final puzzle = PuzzleGenerator.generate(config);
      expect(puzzle.isValid, true);

      for (int i = 0; i < puzzle.solutionIndexes.length; i++) {
        for (int j = i + 1; j < puzzle.solutionIndexes.length; j++) {
          int a = puzzle.solutionIndexes[i];
          int b = puzzle.solutionIndexes[j];
          int r1 = a ~/ config.gridSize;
          int c1 = a % config.gridSize;
          int r2 = b ~/ config.gridSize;
          int c2 = b % config.gridSize;
          expect((r1 - r2).abs() == (c1 - c2).abs(), false,
              reason: 'Shared full diagonal between $a and $b');
        }
      }
    });

    // ── Rule 3: Min Distance ──────────────────────────────

    test('minDistanceForGrid returns correct values per spec', () {
      // <= 9 → 2
      expect(PuzzleGenerator.minDistanceForGrid(6), 2);
      expect(PuzzleGenerator.minDistanceForGrid(9), 2);
      // 10-11 → 3
      expect(PuzzleGenerator.minDistanceForGrid(10), 3);
      expect(PuzzleGenerator.minDistanceForGrid(11), 3);
      // 12-13 → 4
      expect(PuzzleGenerator.minDistanceForGrid(12), 4);
      expect(PuzzleGenerator.minDistanceForGrid(13), 4);
      // 14+ → 5
      expect(PuzzleGenerator.minDistanceForGrid(14), 5);
      expect(PuzzleGenerator.minDistanceForGrid(15), 5);
    });

    test('isMinDistanceRuleActive only for Ultra Hard level >= 50', () {
      expect(PuzzleGenerator.isMinDistanceRuleActive(49, PuzzleTrack.ultraHard), false);
      expect(PuzzleGenerator.isMinDistanceRuleActive(50, PuzzleTrack.ultraHard), true);
      expect(PuzzleGenerator.isMinDistanceRuleActive(50, PuzzleTrack.hard), false);
      expect(PuzzleGenerator.isMinDistanceRuleActive(50, PuzzleTrack.normal), false);
    });

    test('With blockMinDistance=true: solution respects min distance', () {
      // Use a moderate grid so generation succeeds reliably
      final config = PuzzleConfig(
        gridSize: 10,
        levelNumber: 50,
        track: PuzzleTrack.ultraHard,
        blockMinDistance: true,
        minDistance: 3,
      );

      final puzzle = PuzzleGenerator.generate(config);
      expect(puzzle.isValid, true,
          reason: '10×10 with minDistance=3 should generate');

      for (int i = 0; i < puzzle.solutionIndexes.length; i++) {
        for (int j = i + 1; j < puzzle.solutionIndexes.length; j++) {
          int a = puzzle.solutionIndexes[i];
          int b = puzzle.solutionIndexes[j];
          int r1 = a ~/ config.gridSize;
          int c1 = a % config.gridSize;
          int r2 = b ~/ config.gridSize;
          int c2 = b % config.gridSize;
          int dist = (r1 - r2).abs() + (c1 - c2).abs();
          expect(dist >= config.minDistance, true,
              reason: 'Manhattan distance between $a and $b is $dist, '
                  'expected >= ${config.minDistance}');
        }
      }
    });

    // ── Rule 4: Knight's Move Exclusion ───────────────────

    test('isKnightMoveRuleActive from level 80 on all tracks', () {
      expect(PuzzleGenerator.isKnightMoveRuleActive(79), false);
      expect(PuzzleGenerator.isKnightMoveRuleActive(80), true);
      expect(PuzzleGenerator.isKnightMoveRuleActive(100), true);
    });

    test('With blockKnightMove=true: no two solutions are a knight move apart', () {
      final config = PuzzleConfig(
        gridSize: 8,
        levelNumber: 80,
        track: PuzzleTrack.normal,
        blockKnightMove: true,
      );

      final puzzle = PuzzleGenerator.generate(config);
      expect(puzzle.isValid, true);

      for (int i = 0; i < puzzle.solutionIndexes.length; i++) {
        for (int j = i + 1; j < puzzle.solutionIndexes.length; j++) {
          int a = puzzle.solutionIndexes[i];
          int b = puzzle.solutionIndexes[j];
          int dr = (a ~/ config.gridSize - b ~/ config.gridSize).abs();
          int dc = (a % config.gridSize - b % config.gridSize).abs();
          bool isKnight = (dr == 2 && dc == 1) || (dr == 1 && dc == 2);
          expect(isKnight, false,
              reason: 'Knight move between $a and $b');
        }
      }
    });

    // ── Combined rules stress test ────────────────────────

    test('configForLevel correctly activates rules at boundary levels', () {
      // Level 50 Ultra: should have diagonal + minDistance
      final config50ultra = PuzzleGenerator.configForLevel(50, PuzzleTrack.ultraHard);
      expect(config50ultra.blockFullDiagonal, true);
      expect(config50ultra.blockMinDistance, true);
      expect(config50ultra.blockKnightMove, false);

      // Level 80 Normal: should have knightMove only
      final config80normal = PuzzleGenerator.configForLevel(80, PuzzleTrack.normal);
      expect(config80normal.blockFullDiagonal, false);
      expect(config80normal.blockMinDistance, false);
      expect(config80normal.blockKnightMove, true);

      // Level 80 Ultra: all three rules
      final config80ultra = PuzzleGenerator.configForLevel(80, PuzzleTrack.ultraHard);
      expect(config80ultra.blockFullDiagonal, true);
      expect(config80ultra.blockMinDistance, true);
      expect(config80ultra.blockKnightMove, true);
    });

    test('generate() with fallback: Ultra config falls back to Hard on very constrained grids', () {
      // 14×14 Ultra grid with full diagonal + minDistance(5) — tough but should find or fallback
      final config = PuzzleGenerator.configForLevel(50, PuzzleTrack.ultraHard);
      final puzzle = PuzzleGenerator.generate(config);
      // Should either succeed or fall back to Hard — either way isValid should be true
      expect(puzzle.isValid, true,
          reason: 'Level 50 Ultra should produce valid puzzle (possibly via Hard fallback)');
    });
  });
}
