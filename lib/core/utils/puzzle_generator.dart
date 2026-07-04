import 'dart:math';
import 'package:flutter/foundation.dart';

enum PuzzleTrack { normal, hard, ultraHard }

enum TileState { empty, marker, object, lockedObject, revealedMine }

class PuzzleConfig {
  final int gridSize;
  final int levelNumber;
  final PuzzleTrack track;
  final bool blockFullDiagonal;
  final bool blockMinDistance;
  final int minDistance;
  final bool blockKnightMove;

  const PuzzleConfig({
    required this.gridSize,
    required this.levelNumber,
    required this.track,
    this.blockFullDiagonal = false,
    this.blockMinDistance = false,
    this.minDistance = 3,
    this.blockKnightMove = false,
  });
}

class GeneratedPuzzle {
  final int gridSize;
  final List<int> colorMap;
  final List<int> solutionIndexes;
  final List<int> lockedIndexes;
  final List<int> mineIndexes;
  final bool isValid;

  const GeneratedPuzzle({
    required this.gridSize,
    required this.colorMap,
    required this.solutionIndexes,
    required this.lockedIndexes,
    required this.mineIndexes,
    required this.isValid,
  });

  static const GeneratedPuzzle invalid = GeneratedPuzzle(
    gridSize: 0,
    colorMap: [],
    solutionIndexes: [],
    lockedIndexes: [],
    mineIndexes: [],
    isValid: false,
  );
}

class _AttemptCounter {
  int count = 0;
}

class PuzzleGenerator {
  static const int _maxAttempts = 50000;
  static const int _maxMines = 3;
  static const int _minMines = 2;

  static GeneratedPuzzle generate(PuzzleConfig config) {
    final result = _tryGenerate(config);
    if (result.isValid) return result;

    // Fallback: if Ultra failed, try Hard config for the same level
    if (config.track == PuzzleTrack.ultraHard) {
      debugPrint(
        '[PuzzleGenerator] WARNING: Ultra generation failed for level '
        '${config.levelNumber} (grid ${config.gridSize}). '
        'Falling back to Hard config.',
      );
      final fallbackConfig = configForLevel(config.levelNumber, PuzzleTrack.hard);
      final fallback = _tryGenerate(fallbackConfig);
      if (fallback.isValid) return fallback;
    }

    return GeneratedPuzzle.invalid;
  }

  static GeneratedPuzzle _tryGenerate(PuzzleConfig config) {
    int seed = 0;
    final rng = Random();

    while (seed < 1000) {
      List<int> solutionCols = _getSolutionColumns(config.gridSize, seed);
      List<int> colorMap = _buildColorMap(config.gridSize, solutionCols);

      var counter = _AttemptCounter();
      List<int>? solution = _placePieces(0, [], config.gridSize, config, colorMap, rng, counter);

      if (solution != null) {
        List<int> lockedIndexes = [];
        List<int> mineIndexes = [];

        if (config.track == PuzzleTrack.hard) {
          lockedIndexes.add(solution[rng.nextInt(solution.length)]);
        } else if (config.track == PuzzleTrack.ultraHard) {
          int mineCount = _minMines + rng.nextInt(_maxMines - _minMines + 1);
          List<int> candidates = [];
          for (int i = 0; i < config.gridSize * config.gridSize; i++) {
            if (!solution.contains(i)) {
              candidates.add(i);
            }
          }
          candidates.shuffle(rng);
          for (int c in candidates) {
            if (mineIndexes.length >= mineCount) break;
            bool safe = true;
            for (int s in solution) {
              if (_isAdjacent(c, s, config.gridSize)) {
                safe = false;
                break;
              }
            }
            if (safe) {
              for (int m in mineIndexes) {
                if (_isAdjacent(c, m, config.gridSize)) {
                  safe = false;
                  break;
                }
              }
            }
            if (safe) mineIndexes.add(c);
          }
        }

        return GeneratedPuzzle(
          gridSize: config.gridSize,
          colorMap: colorMap,
          solutionIndexes: solution,
          lockedIndexes: lockedIndexes,
          mineIndexes: mineIndexes,
          isValid: true,
        );
      }
      seed++;
    }

    return GeneratedPuzzle.invalid;
  }

  static int gridSizeForLevel(int level, PuzzleTrack track) {
    int baseSize = 2;
    if (level == 1) {
      baseSize = 2;
    } else if (level == 2) {
      baseSize = 3;
    } else if (level <= 5) {
      baseSize = 4;
    } else if (level <= 8) {
      baseSize = 5;
    } else if (level <= 15) {
      baseSize = 6;
    } else if (level <= 20) {
      baseSize = 7;
    } else if (level <= 25) {
      baseSize = 8;
    } else if (level <= 30) {
      baseSize = 9;
    } else if (level <= 35) {
      baseSize = 10;
    } else if (level <= 40) {
      baseSize = 11;
    } else if (level <= 45) {
      baseSize = 12;
    } else {
      baseSize = 13;
    }

    if (track == PuzzleTrack.hard) {
      baseSize += 1;
    }
    if (track == PuzzleTrack.ultraHard) {
      baseSize += 2;
    }

    return baseSize;
  }

  static PuzzleConfig configForLevel(int level, PuzzleTrack track) {
    final gridSize = gridSizeForLevel(level, track);
    final blockFullDiagonal = isDiagonalRuleActive(level, track);
    final blockMinDistance = isMinDistanceRuleActive(level, track);
    final blockKnightMove = isKnightMoveRuleActive(level);
    final minDistance = minDistanceForGrid(gridSize);

    return PuzzleConfig(
      gridSize: gridSize,
      levelNumber: level,
      track: track,
      blockFullDiagonal: blockFullDiagonal,
      blockMinDistance: blockMinDistance,
      minDistance: minDistance,
      blockKnightMove: blockKnightMove,
    );
  }

  static bool isDiagonalRuleActive(int level, PuzzleTrack track) =>
      track != PuzzleTrack.normal && level >= 16;

  static bool isMinDistanceRuleActive(int level, PuzzleTrack track) =>
      track == PuzzleTrack.ultraHard && level >= 50;

  static bool isKnightMoveRuleActive(int level) => level >= 80;

  static int minDistanceForGrid(int gridSize) {
    if (gridSize <= 9) return 2;
    if (gridSize <= 11) return 3;
    if (gridSize <= 13) return 4;
    return 5;
  }

  static List<int> _getSolutionColumns(int size, int variantSeed) {
    final r = Random(variantSeed);
    final cols = List.generate(size, (i) => i);
    cols.shuffle(r);
    return cols;
  }

  static List<int> _buildColorMap(int gridSize, List<int> solutionCols) {
    List<int> colorMap = List.filled(gridSize * gridSize, 0);
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        int minDist = 999999;
        int bestColor = -1;
        for (int i = 0; i < solutionCols.length; i++) {
          int dist = _manhattanDistance(
              r * gridSize + c, i * gridSize + solutionCols[i], gridSize);
          if (dist < minDist) {
            minDist = dist;
            bestColor = i;
          } else if (dist == minDist) {
            if (i < bestColor) bestColor = i;
          }
        }
        colorMap[r * gridSize + c] = bestColor;
      }
    }
    return colorMap;
  }

  static List<int>? _placePieces(
      int row,
      List<int> placed,
      int gridSize,
      PuzzleConfig config,
      List<int> colorMap,
      Random rng,
      _AttemptCounter counter) {
    if (row == gridSize) return placed;
    if (counter.count >= _maxAttempts) return null;

    List<int> cols = List.generate(gridSize, (i) => i);
    cols.shuffle(rng);

    for (int col in cols) {
      int index = row * gridSize + col;
      if (_isValidPlacement(index, row, col, placed, gridSize, config, colorMap)) {
        counter.count++;
        var result = _placePieces(
            row + 1, [...placed, index], gridSize, config, colorMap, rng, counter);
        if (result != null) return result;
      }
    }
    return null;
  }

  static bool _isValidPlacement(int index, int row, int col, List<int> placed,
      int gridSize, PuzzleConfig config, List<int> colorMap) {
    int myColor = colorMap[index];

    for (int i = 0; i < placed.length; i++) {
      int pIndex = placed[i];
      int pCol = pIndex % gridSize;

      if (pCol == col) return false;
      if (colorMap[pIndex] == myColor) return false;
      if (gridSize >= 4 && _isAdjacent(index, pIndex, gridSize)) return false;
      if (config.blockFullDiagonal && _sharesFullDiagonal(index, pIndex, gridSize)) {
        return false;
      }
      if (config.blockMinDistance) {
        if (_manhattanDistance(index, pIndex, gridSize) < config.minDistance) {
          return false;
        }
      }
      if (config.blockKnightMove && _isKnightMove(index, pIndex, gridSize)) {
        return false;
      }
    }
    return true;
  }

  static bool _isAdjacent(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1;
  }

  static bool _sharesFullDiagonal(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() == (c1 - c2).abs();
  }

  static bool _isKnightMove(int a, int b, int gridSize) {
    int dr = (a ~/ gridSize - b ~/ gridSize).abs();
    int dc = (a % gridSize - b % gridSize).abs();
    return (dr == 2 && dc == 1) || (dr == 1 && dc == 2);
  }

  static int _manhattanDistance(int a, int b, int gridSize) {
    int r1 = a ~/ gridSize;
    int c1 = a % gridSize;
    int r2 = b ~/ gridSize;
    int c2 = b % gridSize;
    return (r1 - r2).abs() + (c1 - c2).abs();
  }
}
