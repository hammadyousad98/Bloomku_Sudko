import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';

class MainMenuState extends Equatable {
  final int hints;
  final int extraLives;
  final int undos;
  final int bulbs;
  final int streakDay;
  final bool canClaimToday;

  const MainMenuState({
    required this.hints,
    required this.extraLives,
    required this.undos,
    required this.bulbs,
    required this.streakDay,
    required this.canClaimToday,
  });

  @override
  List<Object> get props => [hints, extraLives, undos, bulbs, streakDay, canClaimToday];
}

class MainMenuCubit extends Cubit<MainMenuState> {
  MainMenuCubit(this._progressRepo, this._rewardRepo)
      : super(const MainMenuState(
          hints: 0,
          extraLives: 0,
          undos: 0,
          bulbs: 0,
          streakDay: 0,
          canClaimToday: false,
        )) {
    loadData();
  }

  final ProgressRepository _progressRepo;
  final RewardRepository _rewardRepo;

  void loadData() {
    _rewardRepo.checkAndUpdateStreak();
    final progress = _progressRepo.getProgress();
    final rewardState = _rewardRepo.getState();

    emit(MainMenuState(
      hints: progress.hints,
      extraLives: progress.extraLives,
      undos: progress.undos,
      bulbs: progress.bulbs,
      streakDay: rewardState.currentStreakDay,
      canClaimToday: _rewardRepo.canClaimToday(),
    ));
  }
}
