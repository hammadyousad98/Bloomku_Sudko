import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zendoku/core/theme/app_theme.dart';
import 'package:zendoku/core/theme/theme_cubit.dart';
import 'package:zendoku/core/theme/theme_model.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/features/game/cubit/game_state.dart';
import 'package:zendoku/features/game/domain/star_calculation.dart';
import 'package:zendoku/features/game/game_screen.dart';
import 'package:zendoku/features/game/widgets/bottom_buttons.dart';
import 'package:zendoku/features/game/widgets/win_overlay.dart';

void main() {
  Widget themed(Widget child) => BlocProvider(
        create: (_) => ThemeCubit.preview(BloomkuThemes.blossom),
        child: MaterialApp(
          theme: bloomkuFlutterTheme(BloomkuThemes.blossom),
          home: Scaffold(body: child),
        ),
      );

  testWidgets('four power buttons fit narrow and regular phone widths',
      (tester) async {
    for (final size in [const Size(320, 640), const Size(430, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(themed(BottomButtons(
        hintCount: 2,
        bulbCount: 2,
        undoCount: 2,
        autoMarkCount: 0,
        onHintTap: () {},
        onBulbTap: () {},
        onUndoTap: () {},
        onAutoMarkTap: () {},
      )));
      expect(find.byType(PowerButtonIcon), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('zero-inventory power remains playable through its ad action',
      (tester) async {
    var autoMarkOffers = 0;
    await tester.pumpWidget(themed(BottomButtons(
      hintCount: 1,
      bulbCount: 1,
      undoCount: 1,
      autoMarkCount: 0,
      onHintTap: () {},
      onBulbTap: () {},
      onUndoTap: () {},
      onAutoMarkTap: () => autoMarkOffers++,
    )));
    await tester.tap(find.text('AutoMark'));
    expect(autoMarkOffers, 1);
    expect(find.text('AD'), findsOneWidget);
  });

  testWidgets('pinch zoom blocks input and does not trigger a tile tap',
      (tester) async {
    var taps = 0;
    final blocked = <bool>[];
    await tester.pumpWidget(themed(Center(
      child: SizedBox.square(
        dimension: 300,
        child: ZoomablePuzzleBoard(
          onInputBlockedChanged: blocked.add,
          child: GestureDetector(
            key: const Key('board-tile'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const ColoredBox(color: Colors.green),
          ),
        ),
      ),
    )));

    final center = tester.getCenter(find.byKey(const Key('board-tile')));
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(center - const Offset(15, 0));
    await second.down(center + const Offset(15, 0));
    await first.moveTo(center - const Offset(70, 0));
    await second.moveTo(center + const Offset(70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    final state = tester.state<ZoomablePuzzleBoardState>(
      find.byType(ZoomablePuzzleBoard),
    );
    expect(state.transformation.getMaxScaleOnAxis(), greaterThan(1));
    expect(blocked, contains(true));
    expect(taps, 0);
  });

  testWidgets('win overlay shows every statistic and Next Puzzle',
      (tester) async {
    const puzzle = GeneratedPuzzle(
      gridSize: 4,
      colorMap: [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3],
      solutionIndexes: [0, 6, 9, 15],
      lockedIndexes: [0],
      mineIndexes: [],
      isValid: true,
    );
    const calculation = StarCalculation(
      stars: 2,
      mistakeStarEarned: true,
      masteryStarEarned: false,
      parTime: Duration(seconds: 60),
    );
    const summary = WinSummary(
      starCalculation: calculation,
      personalBest: Duration(seconds: 42),
      isNewBest: true,
      chapterName: 'Blossom Garden',
      collectibleCount: 2,
      collectibleTarget: 10,
      nextCollectible: 'Rose',
      nextUnlock: 'Ocean Cove',
      levelsToUnlock: 13,
      chapterCompletedNow: false,
    );
    const state = GameState(
      phase: GamePhase.levelComplete,
      puzzle: puzzle,
      tileStates: [],
      placedCount: 4,
      targetCount: 4,
      livesRemaining: 2,
      maxLives: 3,
      score: 1200,
      mistakeCount: 1,
      elapsed: Duration(seconds: 42),
      hintCount: 2,
      undoCount: 2,
      bulbCount: 2,
      autoMarkCount: 2,
      hintsUsed: 1,
      solveRowsUsed: 1,
      autoMarksUsed: 1,
      undosUsed: 2,
      extraLiveCount: 0,
      activeTrack: PuzzleTrack.hard,
      levelNumber: 2,
      showDifficultyBar: false,
      showUltraTab: false,
      moveHistory: [],
      winSummary: summary,
    );

    await tester.pumpWidget(themed(WinOverlay(
      state: state,
      onNextLevel: () {},
      onMenu: () {},
    )));
    for (final label in [
      'Time',
      'Mistakes',
      'Hint',
      'Solve Row',
      'AutoMark',
      'Undo',
      'Next Puzzle  →',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }
    await tester.pumpWidget(themed(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 4));
  });
}
