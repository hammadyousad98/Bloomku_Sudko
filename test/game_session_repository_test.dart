import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/data/repositories/game_session_repository.dart';

void main() {
  test('saved game session round-trips all resumable state', () {
    const session = SavedGameSession(
      levelNumber: 12,
      tileStates: [TileState.object, TileState.marker, TileState.empty],
      placedCount: 1,
      moveHistory: [0],
      livesRemaining: 2,
      elapsedSeconds: 47,
      mistakeCount: 1,
      autoMarksUsed: 2,
      autoMarkHistory: [
        [4, 5, 6]
      ],
      actionHistory: ['object:0', 'autoMark:0'],
    );

    final restored = SavedGameSession.fromJson(session.toJson());

    expect(restored, isNotNull);
    expect(restored!.levelNumber, 12);
    expect(restored.tileStates, session.tileStates);
    expect(restored.moveHistory, session.moveHistory);
    expect(restored.livesRemaining, 2);
    expect(restored.elapsedSeconds, 47);
    expect(restored.mistakeCount, 1);
    expect(restored.autoMarksUsed, 2);
    expect(restored.autoMarkHistory, [
      [4, 5, 6]
    ]);
    expect(restored.actionHistory, ['object:0', 'autoMark:0']);
  });

  test('legacy saved sessions receive additive AutoMark defaults', () {
    final restored = SavedGameSession.fromJson({
      'levelNumber': 3,
      'tileStates': ['lockedObject', 'empty'],
      'placedCount': 1,
      'moveHistory': <int>[],
      'livesRemaining': 3,
      'elapsedSeconds': 10,
      'mistakeCount': 0,
    });

    expect(restored, isNotNull);
    expect(restored!.tileStates.first, TileState.lockedObject);
    expect(restored.autoMarksUsed, 0);
    expect(restored.autoMarkHistory, isEmpty);
    expect(restored.actionHistory, isEmpty);
  });
}
