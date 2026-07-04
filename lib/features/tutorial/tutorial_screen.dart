import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import 'tutorial_cubit.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TutorialCubit(
        slides: TutorialCubit.getMainSlides(),
        onComplete: () {
          final progressRepo = sl<ProgressRepository>();
          progressRepo.markTutorialSeen();
          context.go('/menu');
        },
      ),
      child: const _TutorialScreenView(),
    );
  }
}

class _TutorialScreenView extends StatelessWidget {
  const _TutorialScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => context.read<TutorialCubit>().skip(),
                      child: Text(
                        "Skip →",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.bloomkuTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _TutorialCard(isRuleTutorial: false),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RuleTutorialDialog extends StatelessWidget {
  final TutorialSlide slide;
  final VoidCallback onDismiss;

  const RuleTutorialDialog({
    super.key,
    required this.slide,
    required this.onDismiss,
    required this.minDistance,
  });

  // dummy constructor to pass flutter analyze
  final int minDistance;

  static Future<void> show(BuildContext context, TutorialSlide slide) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => RuleTutorialDialog(
        slide: slide,
        minDistance: 0,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TutorialCubit(
        slides: [slide],
        onComplete: onDismiss,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _TutorialCard(isRuleTutorial: true),
          ),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final bool isRuleTutorial;

  const _TutorialCard({required this.isRuleTutorial});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: BlocBuilder<TutorialCubit, TutorialState>(
        builder: (context, state) {
          final cubit = context.read<TutorialCubit>();
          final slide = state.slides[state.currentSlide];
          final isLastSlide = state.currentSlide == state.totalSlides - 1;

          final titleText = slide.title.replaceAll('[objectName]', theme.objectName);
          final bodyText = slide.body.replaceAll('[objectName]', theme.objectName);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isRuleTutorial 
                          ? [theme.accentColor.withValues(alpha: 0.2), theme.accentColor.withValues(alpha: 0.4)]
                          : [theme.backgroundTop, theme.backgroundBottom],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isRuleTutorial ? Icons.lightbulb_outline : Icons.extension,
                      size: 64,
                      color: theme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  bodyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                if (isRuleTutorial)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cubit.nextSlide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Got it!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: state.currentSlide > 0 ? cubit.prevSlide : null,
                        child: Text(
                          "Prev",
                          style: TextStyle(
                            color: state.currentSlide > 0 
                                ? theme.textSecondary 
                                : Colors.transparent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(state.totalSlides, (index) {
                          final isActive = index == state.currentSlide;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isActive ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isActive ? theme.accentColor : theme.accentColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      ElevatedButton(
                        onPressed: cubit.nextSlide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLastSlide ? theme.accentColor : theme.backgroundBottom,
                          foregroundColor: isLastSlide ? Colors.white : theme.textPrimary,
                          elevation: isLastSlide ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isLastSlide ? "Let's Play!" : "Next",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
