import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/features/game/cubit/auto_mark_logic.dart';

void main() {
  test('AutoMark targets only the eight cells touching placed flowers', () {
    final states = List<TileState>.filled(25, TileState.empty);
    states[12] = TileState.lockedObject;
    states[0] = TileState.object;
    states[6] = TileState.marker;
    states[13] = TileState.revealedMine;

    final targets = findAutoMarkTargets(states, 5, {7});

    expect(targets, [1, 5, 8, 11, 16, 17, 18]);
    expect(targets, isNot(contains(2)), reason: 'distant row exclusion');
    expect(targets, isNot(contains(7)), reason: 'hidden mine is preserved');
    expect(targets, isNot(contains(6)), reason: 'player marker is preserved');
    expect(targets, isNot(contains(13)), reason: 'revealed mine is preserved');
  });

  test('one undo transaction removes only AutoMark-created markers', () {
    final states = <TileState>[
      TileState.lockedObject,
      TileState.autoMarker,
      TileState.marker,
      TileState.autoMarker,
      TileState.object,
      TileState.revealedMine,
    ];

    final reverted = revertAutoMarkTransaction(states, [1, 2, 3, 4, 5]);

    expect(reverted, 2);
    expect(states, [
      TileState.lockedObject,
      TileState.empty,
      TileState.marker,
      TileState.empty,
      TileState.object,
      TileState.revealedMine,
    ]);
  });
}
