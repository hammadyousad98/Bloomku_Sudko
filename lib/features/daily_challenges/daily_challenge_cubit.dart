import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/daily_challenge_config.dart';
import '../../data/models/daily_challenge_history.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/daily_history_repository.dart';

enum DailyCalendarStatus { completed, missed, today, future }

class DailyCalendarDay extends Equatable {
  const DailyCalendarDay({
    required this.date,
    required this.status,
    this.bestTimeMs = 0,
  });

  final DateTime date;
  final DailyCalendarStatus status;
  final int bestTimeMs;

  @override
  List<Object> get props => [date, status, bestTimeMs];
}

sealed class DailyChallengeCubitState extends Equatable {
  const DailyChallengeCubitState();
  @override
  List<Object?> get props => [];
}

final class DailyChallengeLoading extends DailyChallengeCubitState {
  const DailyChallengeLoading();
}

final class DailyChallengeNotPlayed extends DailyChallengeCubitState {
  const DailyChallengeNotPlayed({
    required this.challenge,
    required this.currentChallengeStreak,
    required this.calendarDays,
  });

  final DailyChallengeDay challenge;
  final int currentChallengeStreak;
  final List<DailyCalendarDay> calendarDays;

  @override
  List<Object?> get props => [
        challenge.seed,
        currentChallengeStreak,
        calendarDays,
      ];
}

final class DailyChallengeCompleted extends DailyChallengeCubitState {
  const DailyChallengeCompleted({
    required this.currentChallengeStreak,
    required this.longestChallengeStreak,
    required this.timeUntilNextChallenge,
    required this.challenge,
    required this.result,
    required this.calendarDays,
  });

  final int currentChallengeStreak;
  final int longestChallengeStreak;
  final Duration timeUntilNextChallenge;
  final DailyChallengeDay challenge;
  final DailyChallengeHistory result;
  final List<DailyCalendarDay> calendarDays;

  @override
  List<Object?> get props => [
        currentChallengeStreak,
        longestChallengeStreak,
        timeUntilNextChallenge,
        challenge.seed,
        result.bestTimeMs,
        result.lowestMistakes,
        result.shareGridData,
        calendarDays,
      ];
}

class DailyChallengeCubit extends Cubit<DailyChallengeCubitState> {
  DailyChallengeCubit(this._challengeRepo, this._historyRepo)
      : super(const DailyChallengeLoading());

  final DailyChallengeRepository _challengeRepo;
  final DailyHistoryRepository _historyRepo;
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
        calendarDays: _calendarForCurrentMonth(),
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
    final now = DateTime.now();
    final result = _historyRepo.resultForDate(now);
    if (result == null) return;
    emit(
      DailyChallengeCompleted(
        currentChallengeStreak: challengeState.currentChallengeStreak,
        longestChallengeStreak: challengeState.longestChallengeStreak,
        timeUntilNextChallenge: _remainingUntilNextChallenge(),
        challenge: dailyChallengeConfigFor(now),
        result: result,
        calendarDays: _calendarForCurrentMonth(),
      ),
    );
  }

  List<DailyCalendarDay> _calendarForCurrentMonth() {
    final now = DateTime.now();
    final results = {
      for (final result in _historyRepo.resultsForMonth(now.year, now.month))
        result.dateKey: result,
    };
    final dayCount = DateTime(now.year, now.month + 1, 0).day;
    return List.generate(dayCount, (index) {
      final date = DateTime(now.year, now.month, index + 1);
      final result = results[DailyHistoryRepository.dateKey(date)];
      final status = result?.completed == true
          ? DailyCalendarStatus.completed
          : date.day == now.day
              ? DailyCalendarStatus.today
              : date.isAfter(DateTime(now.year, now.month, now.day))
                  ? DailyCalendarStatus.future
                  : DailyCalendarStatus.missed;
      return DailyCalendarDay(
        date: date,
        status: status,
        bestTimeMs: result?.bestTimeMs ?? 0,
      );
    });
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
    return super.close();
  }
}
