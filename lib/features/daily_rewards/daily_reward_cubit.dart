import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/models/daily_reward_state.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class DailyRewardCubitState extends Equatable {
  const DailyRewardCubitState();
  @override
  List<Object?> get props => [];
}

class DailyRewardLoading extends DailyRewardCubitState {
  const DailyRewardLoading();
}

class DailyRewardAvailable extends DailyRewardCubitState {
  final DailyRewardState rewardState;
  final List<DailyReward> schedule;

  const DailyRewardAvailable({required this.rewardState, required this.schedule});

  @override
  List<Object?> get props => [rewardState, schedule];
}

class DailyRewardAlreadyClaimed extends DailyRewardCubitState {
  final DailyRewardState rewardState;

  const DailyRewardAlreadyClaimed({required this.rewardState});

  @override
  List<Object?> get props => [rewardState];
}

class DailyRewardClaimed extends DailyRewardCubitState {
  final DailyReward reward;
  final DailyRewardState rewardState;

  const DailyRewardClaimed({required this.reward, required this.rewardState});

  @override
  List<Object?> get props => [reward, rewardState];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class DailyRewardCubit extends Cubit<DailyRewardCubitState> {
  DailyRewardCubit(this._rewardRepo, this._progressRepo)
      : super(const DailyRewardLoading());

  final RewardRepository _rewardRepo;
  final ProgressRepository _progressRepo;

  void loadState() {
    final state = _rewardRepo.getState();
    if (_rewardRepo.canClaimToday()) {
      emit(DailyRewardAvailable(
        rewardState: state,
        schedule: kDailyRewards,
      ));
    } else {
      emit(DailyRewardAlreadyClaimed(rewardState: state));
    }
  }

  void claimReward() {
    final reward = _rewardRepo.claimTodayReward();
    if (reward == null) return; // already claimed

    // Credit consumables to player progress
    if (reward.hints > 0) _progressRepo.addHints(reward.hints);
    if (reward.extraLives > 0) _progressRepo.addExtraLives(reward.extraLives);
    if (reward.undos > 0) _progressRepo.addUndos(reward.undos);
    if (reward.bulbs > 0) _progressRepo.addBulbs(reward.bulbs);
    if (reward.autoMarks > 0) _progressRepo.addAutoMarks(reward.autoMarks);
    if (reward.streakFreezes > 0) {
      _progressRepo.addStreakFreezes(reward.streakFreezes);
    }

    final updatedState = _rewardRepo.getState();
    emit(DailyRewardClaimed(reward: reward, rewardState: updatedState));
  }
}
