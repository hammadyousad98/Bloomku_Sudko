import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/onboarding_analytics.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import '../../widgets/common/themed_icon.dart';
import '../game/widgets/puzzle_grid.dart';
import 'onboarding_cubit.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final ConfettiController _confettiController;
  final Set<int> _newlyClaimedRewards = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedBoards =
        sl<ProgressRepository>().getProgress().tutorialBoardsCompleted;
    return BlocProvider(
      create: (_) => OnboardingCubit(completedBoards: completedBoards),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: BlocConsumer<OnboardingCubit, OnboardingState>(
            listenWhen: (previous, current) =>
                previous.actionSerial != current.actionSerial,
            listener: (context, state) {
              final action = state.lastAction;
              if (action == null) return;
              sl<OnboardingAnalytics>().record(
                'tutorial_action',
                metadata: {
                  'board': state.boardIndex + 1,
                  'action': action,
                  'step': state.placementStep,
                },
              );
              if (action == 'board_completed') {
                _completeBoard(state.boardIndex);
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: state.showPath
                        ? const _BlossomPathView()
                        : _PlayableTutorialBoard(state: state),
                  ),
                  if (state.boardComplete && !state.showPath)
                    Positioned.fill(
                      child: _TutorialRewardOverlay(
                        boardIndex: state.boardIndex,
                        rewardGranted:
                            _newlyClaimedRewards.contains(state.boardIndex + 1),
                        onContinue: () => _continueAfterReward(context, state),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      emissionFrequency: 0.035,
                      numberOfParticles: 24,
                      gravity: 0.18,
                      colors: const [
                        Color(0xFFE8829A),
                        Color(0xFFFFC857),
                        Color(0xFF52D294),
                        Color(0xFF57A8FB),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _completeBoard(int boardIndex) {
    final boardNumber = boardIndex + 1;
    final progress = sl<ProgressRepository>();
    progress.markTutorialBoardCompleted(boardNumber);
    if (progress.claimTutorialReward(boardNumber)) {
      _newlyClaimedRewards.add(boardNumber);
      switch (boardNumber) {
        case 1:
          progress.addHints(1);
          progress.unlockObject('tutorial_seedling');
          break;
        case 2:
          progress.addAutoMarks(1);
          progress.unlockObject('tutorial_daisy_badge');
          break;
        case 3:
          progress.unlockObject('tutorial_garden_gate');
          break;
      }
    }
    sl<OnboardingAnalytics>().record(
      'tutorial_board_completed',
      metadata: {'board': boardNumber},
    );
    if (boardNumber == 3) {
      _confettiController.play();
    }
  }

  void _continueAfterReward(BuildContext context, OnboardingState state) {
    if (state.boardIndex == tutorialBoards.length - 1) {
      _finishOnboarding();
    }
    context.read<OnboardingCubit>().continueAfterReward();
  }

  void _finishOnboarding() {
    final progress = sl<ProgressRepository>();
    progress.markTutorialSeen();
    progress.markGuidedTutorialSeen();
    sl<OnboardingAnalytics>().recordOnce('onboarding_completed');
  }
}

class _PlayableTutorialBoard extends StatelessWidget {
  const _PlayableTutorialBoard({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final cubit = context.read<OnboardingCubit>();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.backgroundTop, theme.backgroundBottom],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              _BoardProgress(boardIndex: state.boardIndex),
              const SizedBox(height: 18),
              Text(
                state.board.title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.board.shortRule,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.expectsMarker
                          ? Icons.touch_app_rounded
                          : Icons.ads_click_rounded,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.feedback ?? state.instruction,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: PuzzleGrid(
                      gridKey: GlobalKey(),
                      gridSize: 4,
                      states: state.tileStates,
                      colorRegions: state.board.colorMap,
                      colorMap: [
                        for (final colorIndex in state.board.colorMap)
                          state.boardIndex == 0
                              ? theme.tileColors.first
                              : theme.tileColors[
                                  colorIndex % theme.tileColors.length],
                      ],
                      hintTileIndex: state.highlightedIndex,
                      onTileTap: cubit.tapCell,
                      onTileLongPress: cubit.longPressCell,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlHint(
                    icon: Icons.ads_click,
                    label: 'Tap: flower',
                    color: theme.accentColor,
                  ),
                  if (state.boardIndex >= 1) ...[
                    const SizedBox(width: 16),
                    _ControlHint(
                      icon: Icons.touch_app,
                      label: 'Long-press: X',
                      color: theme.textSecondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardProgress extends StatelessWidget {
  const _BoardProgress({required this.boardIndex});

  final int boardIndex;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Row(
      children: [
        Text(
          'BLOOM SCHOOL',
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        for (var index = 0; index < tutorialBoards.length; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: index == boardIndex ? 28 : 9,
            height: 9,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: index <= boardIndex
                  ? theme.accentColor
                  : theme.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TutorialRewardOverlay extends StatelessWidget {
  const _TutorialRewardOverlay({
    required this.boardIndex,
    required this.rewardGranted,
    required this.onContinue,
  });

  final int boardIndex;
  final bool rewardGranted;
  final VoidCallback onContinue;

  static const rewards = [
    ('🌱', 'Garden Seed', '+1 Hint'),
    ('🌼', 'Daisy Badge', '+1 AutoMark'),
    ('🏡', 'Blossom Garden', 'Chapter Unlocked'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final reward = rewards[boardIndex];
    final isFinal = boardIndex == tutorialBoards.length - 1;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFinal ? 'Your First Victory!' : 'Board Cleared!',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Text(reward.$1, style: const TextStyle(fontSize: 72))
                  .animate()
                  .scale(curve: Curves.elasticOut, duration: 700.ms),
              Text(
                reward.$2,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                rewardGranted ? reward.$3 : 'Collectible already owned',
                style: TextStyle(
                  color: theme.accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(isFinal ? 'Open Blossom Garden' : 'Next Board'),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.82, 0.82)),
      ),
    );
  }
}

class _BlossomPathView extends StatelessWidget {
  const _BlossomPathView();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.backgroundTop, theme.backgroundBottom],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const ThemedIcon(size: 72),
              const SizedBox(height: 16),
              Text(
                'Blossom Garden Unlocked!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your garden journey begins here.',
                style: TextStyle(color: theme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 100,
                      left: 30,
                      right: 30,
                      child: Container(height: 8, color: theme.panelColor),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var level = 1; level <= 5; level++)
                          _PathNode(level: level, active: level == 1),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final progress = sl<ProgressRepository>();
                    progress.markTutorialSeen();
                    progress.markGuidedTutorialSeen();
                    sl<OnboardingAnalytics>()
                        .record('continue_to_first_real_level');
                    context.go('/game', extra: {
                      'level': 1,
                      'track': 'normal',
                      'isDailyChallenge': false,
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue · Level 1'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.level, required this.active});

  final int level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    Widget node = Container(
      width: active ? 58 : 46,
      height: active ? 58 : 46,
      decoration: BoxDecoration(
        color: active ? theme.accentColor : theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.accentColor, width: 3),
        boxShadow: active
            ? [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          color: active ? Colors.white : theme.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (active) {
      node = node
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08));
    }
    return node;
  }
}
