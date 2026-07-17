import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/daily_challenge_config.dart';
import '../../data/repositories/daily_challenge_repository.dart';

sealed class DailyChallengeCubitState extends Equatable {
  const DailyChallengeCubitState();

  @override
  List<Object?> get props => [];
}

final class DailyChallengeLoading extends DailyChallengeCubitState {
  const DailyChallengeLoading();
}

final class DailyChallengeNotPlayed extends DailyChallengeCubitState {
  final DailyChallengeDay challenge;
  final int currentChallengeStreak;

  const DailyChallengeNotPlayed({
    required this.challenge,
    required this.currentChallengeStreak,
  });

  @override
  List<Object?> get props => [
        challenge.level,
        challenge.track,
        currentChallengeStreak,
      ];
}

final class DailyChallengeCompleted extends DailyChallengeCubitState {
  final int currentChallengeStreak;
  final int longestChallengeStreak;
  final Duration timeUntilNextChallenge;

  const DailyChallengeCompleted({
    required this.currentChallengeStreak,
    required this.longestChallengeStreak,
    required this.timeUntilNextChallenge,
  });

  @override
  List<Object?> get props => [
        currentChallengeStreak,
        longestChallengeStreak,
        timeUntilNextChallenge,
      ];
}

class DailyChallengeCubit extends Cubit<DailyChallengeCubitState> {
  DailyChallengeCubit(this._challengeRepo)
      : super(const DailyChallengeLoading());

  final DailyChallengeRepository _challengeRepo;
  Timer? _countdownTimer;
  DateTime? _nextChallengeAt;

  void loadState() {
    _countdownTimer?.cancel();
    final challengeState = _challengeRepo.getState();

    if (_challengeRepo.hasCompletedToday()) {
      _nextChallengeAt = _nextLocalMidnight();
      _emitCompletedState();
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateCountdown(),
      );
      return;
    }

    _nextChallengeAt = null;
    emit(
      DailyChallengeNotPlayed(
        challenge: dailyChallengeConfigFor(DateTime.now()),
        currentChallengeStreak: challengeState.currentChallengeStreak,
      ),
    );
  }

  void _updateCountdown() {
    if (_remainingUntilNextChallenge() <= Duration.zero) {
      loadState();
      return;
    }
    _emitCompletedState();
  }

  void _emitCompletedState() {
    final challengeState = _challengeRepo.getState();
    emit(
      DailyChallengeCompleted(
        currentChallengeStreak: challengeState.currentChallengeStreak,
        longestChallengeStreak: challengeState.longestChallengeStreak,
        timeUntilNextChallenge: _remainingUntilNextChallenge(),
      ),
    );
  }

  DateTime _nextLocalMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Duration _remainingUntilNextChallenge() {
    final target = _nextChallengeAt ?? _nextLocalMidnight();
    return target.difference(DateTime.now());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _nextChallengeAt = null;
    return super.close();
  }
}
