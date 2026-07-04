import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/progress_repository.dart';
import '../../core/utils/puzzle_generator.dart';

class LevelButtonData extends Equatable {
  final int levelNumber;
  final int normalGridSize;
  final bool isUnlocked;

  const LevelButtonData({
    required this.levelNumber,
    required this.normalGridSize,
    required this.isUnlocked,
  });

  @override
  List<Object> get props => [levelNumber, normalGridSize, isUnlocked];
}

class LevelSelectState extends Equatable {
  final int highestUnlocked;
  final List<LevelButtonData> levels;
  final bool adsRemoved;

  const LevelSelectState({
    required this.highestUnlocked,
    required this.levels,
    required this.adsRemoved,
  });

  @override
  List<Object> get props => [highestUnlocked, levels, adsRemoved];
}

class LevelSelectCubit extends Cubit<LevelSelectState> {
  LevelSelectCubit(this._progressRepo)
      : super(const LevelSelectState(
          highestUnlocked: 1,
          levels: [],
          adsRemoved: false,
        )) {
    loadLevels();
  }

  final ProgressRepository _progressRepo;

  void loadLevels() {
    final progress = _progressRepo.getProgress();
    final highestUnlocked = progress.normalHighest;
    final maxLevels = 50; 

    final List<LevelButtonData> loadedLevels = [];
    for (int i = 1; i <= maxLevels; i++) {
      loadedLevels.add(
        LevelButtonData(
          levelNumber: i,
          normalGridSize: PuzzleGenerator.gridSizeForLevel(i, PuzzleTrack.normal),
          isUnlocked: i <= highestUnlocked,
        ),
      );
    }

    emit(LevelSelectState(
      highestUnlocked: highestUnlocked,
      levels: loadedLevels,
      adsRemoved: progress.adsRemoved,
    ));
  }

  void onLevelTap(int levelNumber, BuildContext context) {
    if (levelNumber <= state.highestUnlocked) {
      context.go('/game', extra: {'level': levelNumber, 'track': 'normal'});
    }
  }
}
