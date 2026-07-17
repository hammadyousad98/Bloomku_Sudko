import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/theme/theme_model.dart';
import '../../widgets/common/themed_icon.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import 'main_menu_cubit.dart';

import '../../services/audio_service.dart';
import '../../services/ad_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.playMenuMusic();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MainMenuCubit(sl<ProgressRepository>(), sl<RewardRepository>()),
      child: const _MainMenuScreenView(),
    );
  }
}

class _MainMenuScreenView extends StatelessWidget {
  const _MainMenuScreenView();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundTop, theme.backgroundBottom],
              ),
            ),
          ),

          // Ambient Theme Background
          const _ThemeBackgroundLayer(),

          // Foreground UI
          SafeArea(
            child: Column(
              children: [
                // TOP ROW
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopIconButton(
                        icon: Icons.settings,
                        onTap: () => context.push('/settings'),
                      ),
                      _TopIconButton(
                        icon: Icons.palette,
                        onTap: () => _showThemeSelector(context),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // HERO SECTION
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThemedIcon(size: 120)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: 0,
                          end: -8,
                          duration: const Duration(milliseconds: 2500),
                          curve: Curves.easeInOut,
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: const Duration(milliseconds: 400),
                        ),
                    const SizedBox(height: 16),
                    Text(
                      'Zenduko',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: theme.textPrimary,
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 200))
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: const Duration(milliseconds: 300),
                        ),
                    const SizedBox(height: 4),
                    Text(
                      'Mindful Puzzle',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: theme.textSecondary,
                      ),
                    )
                        .animate(delay: const Duration(milliseconds: 300))
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: const Duration(milliseconds: 300),
                        ),
                  ],
                ),

                const Spacer(flex: 3),

                // BUTTONS SECTION
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Column(
                    children: [
                      _PrimaryButton(
                        label: "Play",
                        backgroundColor: theme.accentColor,
                        textColor: Colors.white,
                        onTap: () => _playCurrentLevel(context),
                      )
                          .animate(delay: const Duration(milliseconds: 400))
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                              begin: 1.0,
                              end: 1.04,
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeInOut),
                      const SizedBox(height: 16),
                      _PrimaryButton(
                        label: "Daily Challenges 🏆",
                        backgroundColor: theme.cardColor,
                        textColor: theme.accentColor,
                        onTap: () => context.push('/challenges'),
                      )
                          .animate(delay: const Duration(milliseconds: 500))
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                          ),
                      const SizedBox(height: 16),
                      BlocBuilder<MainMenuCubit, MainMenuState>(
                        builder: (context, state) {
                          return _GradientButton(
                            label: state.streakDay > 0
                                ? "🔥 Day ${state.streakDay}"
                                : "Start your streak!",
                            onTap: () => context.push('/rewards'),
                          );
                        },
                      )
                          .animate(delay: const Duration(milliseconds: 600))
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                          ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playCurrentLevel(BuildContext context) {
    final progress = sl<ProgressRepository>().getProgress();
    if (progress.normalHighest > maxLevelCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You completed every level!')),
      );
      return;
    }

    AdService.preloadGameBanners(adsRemoved: progress.adsRemoved);

    context.push(
      '/game',
      extra: {'level': progress.normalHighest, 'track': 'normal'},
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Material(
      color: theme.textPrimary.withValues(alpha: 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: theme.textPrimary),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFEB3B),
          ], // warm orange -> yellow
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.bloomkuTheme;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: activeTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: activeTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BloomkuThemes.all.length,
              itemBuilder: (context, index) {
                final themeData = BloomkuThemes.all[index];
                final isActive = activeTheme.id == themeData.id;

                return GestureDetector(
                  onTap: () {
                    context.read<ThemeCubit>().selectTheme(index);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeData.backgroundTop,
                          themeData.backgroundBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? Border.all(color: themeData.accentColor, width: 3)
                          : Border.all(color: Colors.transparent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PreviewIcon(themeData: themeData),
                              const SizedBox(height: 12),
                              Text(
                                themeData.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeData.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: themeData.accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PreviewIcon extends StatelessWidget {
  final AppThemeData themeData;
  const _PreviewIcon({required this.themeData});

  @override
  Widget build(BuildContext context) {
    return ThemedIcon(
      iconPath: themeData.objectIconPaths.first,
      size: 48,
      color: themeData.accentColor,
    );
  }
}

class _ThemeBackgroundLayer extends StatefulWidget {
  const _ThemeBackgroundLayer();

  @override
  State<_ThemeBackgroundLayer> createState() => _ThemeBackgroundLayerState();
}

class _ThemeBackgroundLayerState extends State<_ThemeBackgroundLayer> {
  final _random = Random();
  late List<_Particle> _particles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = context.bloomkuTheme;
    // Keep it lightweight (15 particles max)
    _particles = List.generate(15, (index) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 15 + _random.nextDouble() * 30,
        iconPath: theme
            .objectIconPaths[_random.nextInt(theme.objectIconPaths.length)],
        color: theme.accentColor,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final isOcean = theme.id == BloomkuTheme.ocean;
    final isCosmos = theme.id == BloomkuTheme.cosmos;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _particles.map((p) {
            Widget child;
            if (isCosmos) {
              // Twinkling stars
              child = Positioned(
                left: p.x * constraints.maxWidth,
                top: p.y * constraints.maxHeight,
                child: ThemedIcon(
                  iconPath: p.iconPath,
                  size: p.size * 0.6,
                  color: p.color.withValues(alpha: 0.25),
                )
                    .animate(
                      onPlay: (c) => c.loop(reverse: true),
                      delay: Duration(milliseconds: _random.nextInt(3000)),
                    )
                    .fadeIn(
                        duration: Duration(seconds: 2 + _random.nextInt(3))),
              );
            } else if (isOcean) {
              // Bubbles drifting up
              child = Positioned(
                left: p.x * constraints.maxWidth,
                bottom: p.y * constraints.maxHeight,
                child: ThemedIcon(
                  iconPath: p.iconPath,
                  size: p.size,
                  color: p.color.withValues(alpha: 0.15),
                )
                    .animate(
                      onPlay: (c) => c.loop(),
                      delay: Duration(milliseconds: _random.nextInt(6000)),
                    )
                    .slideY(
                      begin: 1,
                      end: -(constraints.maxHeight / p.size),
                      duration: Duration(seconds: 8 + _random.nextInt(10)),
                    )
                    .fadeIn(duration: 1.seconds),
              );
            } else {
              // Falling petals/leaves/fruit
              child = Positioned(
                left: p.x * constraints.maxWidth,
                top: p.y * constraints.maxHeight,
                child: ThemedIcon(
                  iconPath: p.iconPath,
                  size: p.size,
                  color: p.color.withValues(alpha: 0.15),
                )
                    .animate(
                      onPlay: (c) => c.loop(),
                      delay: Duration(milliseconds: _random.nextInt(6000)),
                    )
                    .slideY(
                      begin: -(constraints.maxHeight / p.size),
                      end: 1.5,
                      duration: Duration(seconds: 7 + _random.nextInt(12)),
                    )
                    .slideX(
                      begin: -0.3,
                      end: 0.3,
                      duration: Duration(seconds: 3 + _random.nextInt(4)),
                      curve: Curves.easeInOutSine,
                    )
                    .fadeIn(duration: 1.seconds),
              );
            }
            return child;
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final String iconPath;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.iconPath,
    required this.color,
  });
}
