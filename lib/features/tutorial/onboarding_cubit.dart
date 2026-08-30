import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/puzzle_generator.dart';

class TutorialBoardDefinition {
  const TutorialBoardDefinition({
    required this.title,
    required this.shortRule,
    required this.solutionIndexes,
    required this.colorMap,
    this.markerTarget,
  });

  final String title;
  final String shortRule;
  final List<int> solutionIndexes;
  final List<int> colorMap;
  final int? markerTarget;
}

const tutorialBoards = [
  TutorialBoardDefinition(
    title: 'Rows & Columns',
    shortRule: 'Place one flower in every row and every column.',
    solutionIndexes: [0, 6, 9, 15],
    colorMap: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ),
  TutorialBoardDefinition(
    title: 'Color Regions',
    shortRule: 'Each colored region also needs exactly one flower.',
    solutionIndexes: [0, 6, 9, 15],
    colorMap: [0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 3, 3, 2, 2, 3, 3],
    markerTarget: 1,
  ),
  TutorialBoardDefinition(
    title: 'No Touching',
    shortRule: 'Flowers cannot touch, even at the corners.',
    solutionIndexes: [1, 7, 8, 14],
    colorMap: [0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 3, 3, 2, 2, 3, 3],
  ),
];

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.boardIndex,
    required this.tileStates,
    this.placementStep = 0,
    this.markerTaught = false,
    this.boardComplete = false,
    this.showPath = false,
    this.feedback,
    this.actionSerial = 0,
    this.lastAction,
  });

  final int boardIndex;
  final List<TileState> tileStates;
  final int placementStep;
  final bool markerTaught;
  final bool boardComplete;
  final bool showPath;
  final String? feedback;
  final int actionSerial;
  final String? lastAction;

  TutorialBoardDefinition get board => tutorialBoards[boardIndex];

  bool get expectsMarker =>
      boardIndex == 1 && placementStep == 1 && !markerTaught;

  int? get highlightedIndex {
    if (boardComplete || showPath) return null;
    if (expectsMarker) return board.markerTarget;
    if (placementStep >= board.solutionIndexes.length) return null;
    return board.solutionIndexes[placementStep];
  }

  String get instruction {
    if (expectsMarker) {
      return 'This cell cannot hold a flower. Long-press it to add an X.';
    }
    if (boardIndex == 0 && placementStep == 0) {
      return 'Tap the highlighted cell to plant your first flower.';
    }
    if (boardIndex == 1) {
      return 'Tap the highlighted cell. Watch the colored regions too.';
    }
    if (boardIndex == 2) {
      return 'Tap the highlight and leave space around every flower.';
    }
    return 'Keep placing one flower in each row and column.';
  }

  @override
  List<Object?> get props => [
        boardIndex,
        tileStates,
        placementStep,
        markerTaught,
        boardComplete,
        showPath,
        feedback,
        actionSerial,
        lastAction,
      ];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({int completedBoards = 0})
      : super(
          completedBoards >= tutorialBoards.length
              ? OnboardingState(
                  boardIndex: tutorialBoards.length - 1,
                  tileStates: List.filled(16, TileState.empty),
                  boardComplete: true,
                  showPath: true,
                )
              : _initialState(completedBoards.clamp(0, 2)),
        );

  static OnboardingState _initialState(int boardIndex) => OnboardingState(
        boardIndex: boardIndex,
        tileStates: List.filled(16, TileState.empty),
      );

  void tapCell(int index) {
    if (state.boardComplete || state.showPath || index < 0 || index >= 16) {
      return;
    }
    final tiles = List<TileState>.from(state.tileStates);
    if (tiles[index] == TileState.object) {
      final solutionPosition = state.board.solutionIndexes.indexOf(index);
      if (solutionPosition < 0) return;
      for (var position = solutionPosition;
          position < state.board.solutionIndexes.length;
          position++) {
        final solutionIndex = state.board.solutionIndexes[position];
        if (tiles[solutionIndex] == TileState.object) {
          tiles[solutionIndex] = TileState.empty;
        }
      }
      _emitAction(
        tiles: tiles,
        placementStep: solutionPosition,
        action: 'remove_flower',
        feedback: 'Removed. Tap the highlight to place it again.',
      );
      return;
    }
    if (state.expectsMarker) {
      _emitAction(
        action: 'marker_prompt_tap',
        feedback: 'Long-press the highlighted cell to mark it with X.',
      );
      return;
    }

    final expected = state.highlightedIndex;
    if (index != expected) {
      _emitAction(
        action: 'invalid_tutorial_tap',
        feedback: _constraintFeedback(index),
      );
      return;
    }

    tiles[index] = TileState.object;
    final nextStep = state.placementStep + 1;
    final complete = nextStep == state.board.solutionIndexes.length;
    _emitAction(
      tiles: tiles,
      placementStep: nextStep,
      boardComplete: complete,
      action: complete ? 'board_completed' : 'place_flower',
      feedback: complete ? null : _successFeedback,
    );
  }

  void longPressCell(int index) {
    if (state.boardComplete || state.showPath || index < 0 || index >= 16) {
      return;
    }
    final tiles = List<TileState>.from(state.tileStates);
    final tile = tiles[index];
    if (tile == TileState.object || tile == TileState.lockedObject) return;

    final addingMarker = tile != TileState.marker;
    tiles[index] = addingMarker ? TileState.marker : TileState.empty;
    final taughtMarker = state.markerTaught ||
        (state.expectsMarker && index == state.board.markerTarget);
    _emitAction(
      tiles: tiles,
      markerTaught: taughtMarker,
      action: addingMarker ? 'add_x' : 'remove_x',
      feedback: taughtMarker && !state.markerTaught
          ? 'Great! X marks help remember eliminated cells.'
          : null,
    );
  }

  void continueAfterReward() {
    if (!state.boardComplete) return;
    if (state.boardIndex == tutorialBoards.length - 1) {
      emit(OnboardingState(
        boardIndex: state.boardIndex,
        tileStates: state.tileStates,
        placementStep: state.placementStep,
        markerTaught: state.markerTaught,
        boardComplete: true,
        showPath: true,
        actionSerial: state.actionSerial + 1,
        lastAction: 'show_blossom_path',
      ));
      return;
    }
    emit(_initialState(state.boardIndex + 1));
  }

  void _emitAction({
    List<TileState>? tiles,
    int? placementStep,
    bool? markerTaught,
    bool? boardComplete,
    required String action,
    String? feedback,
  }) {
    emit(OnboardingState(
      boardIndex: state.boardIndex,
      tileStates: tiles ?? state.tileStates,
      placementStep: placementStep ?? state.placementStep,
      markerTaught: markerTaught ?? state.markerTaught,
      boardComplete: boardComplete ?? state.boardComplete,
      feedback: feedback,
      actionSerial: state.actionSerial + 1,
      lastAction: action,
    ));
  }

  String _constraintFeedback(int index) {
    final expected = state.highlightedIndex;
    if (expected == null) return 'Follow the highlighted cell.';
    final row = index ~/ 4;
    final col = index % 4;
    for (var tileIndex = 0; tileIndex < state.tileStates.length; tileIndex++) {
      if (state.tileStates[tileIndex] != TileState.object) continue;
      if (tileIndex ~/ 4 == row) return 'That row already has a flower.';
      if (tileIndex % 4 == col) return 'That column already has a flower.';
      if (state.boardIndex >= 1 &&
          state.board.colorMap[tileIndex] == state.board.colorMap[index]) {
        return 'That colored region already has a flower.';
      }
      if (state.boardIndex >= 2 && _touches(tileIndex, index)) {
        return 'Too close—flowers cannot touch, even diagonally.';
      }
    }
    return 'Try the highlighted cell for this quick lesson.';
  }

  bool _touches(int first, int second) {
    final rowDistance = (first ~/ 4 - second ~/ 4).abs();
    final columnDistance = (first % 4 - second % 4).abs();
    return rowDistance <= 1 && columnDistance <= 1;
  }

  String get _successFeedback => switch (state.boardIndex) {
        0 => 'Nice—one flower in that row and column.',
        1 => 'Perfect—one flower for that colored region.',
        _ => 'Good spacing—no flowers are touching.',
      };
}
