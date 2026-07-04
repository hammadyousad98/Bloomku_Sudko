import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class DailyChallengesScreen extends StatelessWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.backgroundTop, theme.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Material(
                      color: theme.textPrimary.withValues(alpha: 0.05),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => context.pop(),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: theme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Daily Challenges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44), // balance back button
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Centered Card
              Center(
                child: Container(
                  width: 300,
                  height: 400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy Emoji with bounce animation
                      const Text('🏆', style: TextStyle(fontSize: 120))
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .moveY(
                            begin: 0,
                            end: -6,
                            duration: 1.seconds,
                            curve: Curves.easeInOutSine,
                          ),

                      const SizedBox(height: 16),

                      Text(
                        'Coming Soon!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Daily challenges are on their way. A new puzzle every day, for every player, at the same time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: theme.textSecondary,
                        ),
                      ),

                      const Spacer(),

                      // Notify Me Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "We'll let you know when Daily Challenges launch!",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Notify Me',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Available in a future update',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
