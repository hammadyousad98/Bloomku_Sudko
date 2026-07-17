import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../utils/puzzle_generator.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../features/daily_challenges/daily_challenges_screen.dart';
import '../../features/daily_rewards/daily_reward_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/main_menu/main_menu_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tutorial/tutorial_screen.dart';

class AppRouter {
  AppRouter._();

  static bool _checkedLaunchRewards = false;

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final extra = state.extra;
          final level = extra is Map<String, Object?>
              ? extra['level'] as int? ?? 1
              : int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1;
          final track = extra is Map<String, Object?>
              ? extra['track'] as String? ?? 'normal'
              : state.uri.queryParameters['track'] ?? 'normal';
          final isDailyChallenge = extra is Map<String, Object?>
              ? extra['isDailyChallenge'] as bool? ?? false
              : state.uri.queryParameters['isDailyChallenge'] == 'true';

          return GameScreen(
            level: level,
            track: track,
            isDailyChallenge: isDailyChallenge,
          );
        },
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const DailyRewardScreen(),
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const DailyChallengesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;

    if (location == '/game') {
      final extra = state.extra;
      final isDailyChallenge = extra is Map<String, Object?>
          ? extra['isDailyChallenge'] as bool? ?? false
          : state.uri.queryParameters['isDailyChallenge'] == 'true';

      if (isDailyChallenge) return null;

      final level = extra is Map<String, Object?>
          ? extra['level'] as int?
          : int.tryParse(state.uri.queryParameters['level'] ?? '');
      final trackName = extra is Map<String, Object?>
          ? extra['track'] as String? ?? 'normal'
          : state.uri.queryParameters['track'] ?? 'normal';

      final isCurrentPlayable = level != null &&
          sl<ProgressRepository>().isCurrentPlayableLevel(
            level,
            _trackFromName(trackName),
          );

      if (!isCurrentPlayable) {
        return '/menu';
      }
    }

    if (location == '/rewards' && !_checkedLaunchRewards) {
      sl<RewardRepository>().checkAndUpdateStreak();
      _checkedLaunchRewards = true;
    }

    return null;
  }

  static PuzzleTrack _trackFromName(String track) {
    switch (track.toLowerCase()) {
      case 'hard':
        return PuzzleTrack.hard;
      case 'ultra':
      case 'ultrahard':
      case 'ultra-hard':
        return PuzzleTrack.ultraHard;
      default:
        return PuzzleTrack.normal;
    }
  }
}
