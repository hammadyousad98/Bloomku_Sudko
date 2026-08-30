import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/service_locator.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/themed_icon.dart';
import '../../core/analytics/onboarding_analytics.dart';
import '../../core/config/feature_flags.dart';

const mandatorySplashDuration = Duration(seconds: 4);
const splashFadeDuration = Duration(milliseconds: 300);

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = mandatorySplashDuration,
    this.onFinished,
  });

  final Duration duration;
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<OnboardingAnalytics>()) {
      sl<OnboardingAnalytics>().recordOnce('splash_started');
    }
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(widget.duration - splashFadeDuration);
    if (!mounted) return;

    setState(() {
      _fadeOut = true;
    });

    // Wait for the fade out to complete
    await Future.delayed(splashFadeDuration);
    if (!mounted) return;

    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    final progressRepo = sl<ProgressRepository>();
    final progress = progressRepo.getProgress();
    if (sl.isRegistered<OnboardingAnalytics>()) {
      sl<OnboardingAnalytics>().record('splash_completed', metadata: {
        'destination': progress.tutorialSeen ? 'menu' : 'tutorial',
      });
    }

    if (progress.tutorialSeen ||
        !FeatureFlags.current.nonBlockingStartupAndTutorial) {
      context.go('/menu');
    } else {
      context.go('/tutorial');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: AnimatedOpacity(
        opacity: _fadeOut ? 0.0 : 1.0,
        duration: splashFadeDuration,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundTop,
                theme.backgroundBottom,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ThemedIcon(size: 80)
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.08, 1.08),
                      duration: const Duration(milliseconds: 750), // 1.5s loop
                      curve: Curves.easeInOut,
                    )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 600)),
                const SizedBox(height: 24),
                Text(
                  'Zenduko',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 8),
                Text(
                  'A mindful puzzle',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: theme.textSecondary,
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 600))
                    .fadeIn(duration: const Duration(milliseconds: 300)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
