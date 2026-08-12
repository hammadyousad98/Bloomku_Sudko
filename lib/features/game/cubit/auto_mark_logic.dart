import '../../../core/utils/puzzle_generator.dart';

List<int> findAutoMarkTargets(
  List<TileState> states,
  int gridSize,
  Set<int> mineIndexes,
) {
  final targets = <int>{};
  for (var index = 0; index < states.length; index++) {
    if (states[index] != TileState.object &&
        states[index] != TileState.lockedObject) {
      continue;
    }
    final row = index ~/ gridSize;
    final col = index % gridSize;
    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (var colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue;
        final neighborRow = row + rowOffset;
        final neighborCol = col + colOffset;
        if (neighborRow < 0 ||
            neighborRow >= gridSize ||
            neighborCol < 0 ||
            neighborCol >= gridSize) {
          continue;
        }
        final neighbor = neighborRow * gridSize + neighborCol;
        if (states[neighbor] == TileState.empty &&
            !mineIndexes.contains(neighbor)) {
          targets.add(neighbor);
        }
      }
    }
  }
  return targets.toList()..sort();
}

int revertAutoMarkTransaction(
  List<TileState> states,
  Iterable<int> transactionIndexes,
) {
  var reverted = 0;
  for (final index in transactionIndexes) {
    if (index >= 0 &&
        index < states.length &&
        states[index] == TileState.autoMarker) {
      states[index] = TileState.empty;
      reverted += 1;
    }
  }
  return reverted;
}
