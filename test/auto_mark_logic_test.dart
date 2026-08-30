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

  test('AutoMark charges once only when at least one cell can change', () {
    final applicable = List.filled(9, TileState.empty)
      ..[4] = TileState.lockedObject;
    final plan = planAutoMark(applicable, 3, const {}, inventory: 2);
    expect(plan.canApply, isTrue);
    expect(plan.consumesInventory, isTrue);
    expect(plan.targetIndexes, hasLength(8));

    final noInventory = planAutoMark(applicable, 3, const {}, inventory: 0);
    expect(noInventory.canApply, isFalse);
    expect(noInventory.consumesInventory, isFalse);
    expect(noInventory.targetIndexes, isNotEmpty);

    final noOp = planAutoMark(
      List.filled(9, TileState.marker)..[4] = TileState.lockedObject,
      3,
      const {},
      inventory: 2,
    );
    expect(noOp.targetIndexes, isEmpty);
    expect(noOp.consumesInventory, isFalse);
  });

  test('locked flowers are immutable and never reverted by AutoMark undo', () {
    expect(isImmutableTile(TileState.lockedObject), isTrue);
    expect(isImmutableTile(TileState.object), isFalse);
    final states = [TileState.lockedObject, TileState.autoMarker];
    expect(revertAutoMarkTransaction(states, [0, 1]), 1);
    expect(states, [TileState.lockedObject, TileState.empty]);
  });
}
