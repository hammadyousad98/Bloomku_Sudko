import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import 'level_select_cubit.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LevelSelectCubit(sl<ProgressRepository>()),
      child: const _LevelSelectScreenView(),
    );
  }
}

class _LevelSelectScreenView extends StatefulWidget {
  const _LevelSelectScreenView();

  @override
  State<_LevelSelectScreenView> createState() => _LevelSelectScreenViewState();
}

class _LevelSelectScreenViewState extends State<_LevelSelectScreenView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      "Levels",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 48), // Empty space to center the title
                  ],
                ),
              ),

              // GridView
              Expanded(
                child: BlocBuilder<LevelSelectCubit, LevelSelectState>(
                  builder: (context, state) {
                    return GridView.builder(
                      key: const PageStorageKey('level_select_grid'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: state.levels.length,
                      itemBuilder: (context, index) {
                        final levelData = state.levels[index];
                        final isHighest = levelData.levelNumber == state.highestUnlocked;

                        return _LevelButton(
                          data: levelData,
                          isHighest: isHighest,
                          onTap: () {
                            context.read<LevelSelectCubit>().onLevelTap(levelData.levelNumber, context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Banner Ad
              BlocBuilder<LevelSelectCubit, LevelSelectState>(
                builder: (context, state) {
                  if (!state.adsRemoved) {
                    return const BannerAdWidget();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final LevelButtonData data;
  final bool isHighest;
  final VoidCallback onTap;

  const _LevelButton({
    required this.data,
    required this.isHighest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    final boxDecoration = data.isUnlocked
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHighest
                ? [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          )
        : BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12),
          );

    return GestureDetector(
      onTap: data.isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: boxDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (data.isUnlocked) ...[
              Text(
                '${data.levelNumber}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.normalGridSize}×${data.normalGridSize}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ] else ...[
              const Text('🔒', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              const Text(
                'Locked',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      color: Colors.black12,
      child: const Center(
        child: Text(
          'Banner Ad',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
