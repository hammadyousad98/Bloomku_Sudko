import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/features/tutorial/onboarding_cubit.dart';

void main() {
  test('three scripted boards teach placement, X marks, and no-touch', () {
    final cubit = OnboardingCubit();

    expect(cubit.state.boardIndex, 0);
    expect(cubit.state.highlightedIndex, 0);
    for (final index in tutorialBoards[0].solutionIndexes) {
      cubit.tapCell(index);
    }
    expect(cubit.state.boardComplete, isTrue);

    cubit.continueAfterReward();
    expect(cubit.state.boardIndex, 1);
    cubit.tapCell(0);
    expect(cubit.state.expectsMarker, isTrue);
    cubit.tapCell(1);
    expect(cubit.state.tileStates[1], TileState.empty);
    cubit.longPressCell(1);
    expect(cubit.state.tileStates[1], TileState.marker);
    expect(cubit.state.markerTaught, isTrue);
    for (final index in tutorialBoards[1].solutionIndexes.skip(1)) {
      cubit.tapCell(index);
    }
    expect(cubit.state.boardComplete, isTrue);
    expect(cubit.state.tileStates[1], TileState.marker);

    cubit.continueAfterReward();
    expect(cubit.state.boardIndex, 2);
    for (final index in tutorialBoards[2].solutionIndexes) {
      cubit.tapCell(index);
    }
    expect(cubit.state.boardComplete, isTrue);
    cubit.continueAfterReward();
    expect(cubit.state.showPath, isTrue);

    cubit.close();
  });

  test('scripted solutions satisfy the rules introduced by each board', () {
    for (var boardIndex = 0; boardIndex < tutorialBoards.length; boardIndex++) {
      final board = tutorialBoards[boardIndex];
      expect(
          board.solutionIndexes.map((index) => index ~/ 4).toSet().length, 4);
      expect(board.solutionIndexes.map((index) => index % 4).toSet().length, 4);

      if (boardIndex >= 1) {
        expect(
          board.solutionIndexes
              .map((index) => board.colorMap[index])
              .toSet()
              .length,
          4,
        );
      }
      if (boardIndex >= 2) {
        for (var first = 0; first < board.solutionIndexes.length; first++) {
          for (var second = first + 1;
              second < board.solutionIndexes.length;
              second++) {
            final firstIndex = board.solutionIndexes[first];
            final secondIndex = board.solutionIndexes[second];
            final rowDistance = (firstIndex ~/ 4 - secondIndex ~/ 4).abs();
            final columnDistance = (firstIndex % 4 - secondIndex % 4).abs();
            expect(rowDistance <= 1 && columnDistance <= 1, isFalse);
          }
        }
      }
    }
  });

  test('completed tutorial progress resumes at the next board or path', () {
    final boardTwo = OnboardingCubit(completedBoards: 1);
    expect(boardTwo.state.boardIndex, 1);
    boardTwo.close();

    final finished = OnboardingCubit(completedBoards: 3);
    expect(finished.state.showPath, isTrue);
    finished.close();
  });
}
