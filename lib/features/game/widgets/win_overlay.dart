import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_model.dart';
import '../cubit/game_scoring.dart';
import '../cubit/game_state.dart';
import '../domain/star_calculation.dart';

class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.state,
    required this.onNextLevel,
    required this.onMenu,
  });

  final GameState state;
  final VoidCallback onNextLevel;
  final VoidCallback onMenu;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final isDaily = widget.state.mode == GameMode.dailyChallenge;
    final completedCampaign =
        !isDaily && widget.state.levelNumber >= maxLevelCount;
    final summary = widget.state.winSummary ?? _fallbackSummary();
    final calculation = summary.starCalculation;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.66))
              .animate()
              .fadeIn(duration: 250.ms),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410, maxHeight: 720),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (summary.chapterCompletedNow)
                        _ChapterCompleteBanner(summary: summary)
                            .animate()
                            .scale(
                              begin: const Offset(0.75, 0.75),
                              curve: Curves.elasticOut,
                              duration: 700.ms,
                            ),
                      Text(
                        summary.chapterCompletedNow
                            ? 'Chapter Restored!'
                            : 'Puzzle Solved!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.chapterName} · Level ${widget.state.levelNumber}',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _StarRow(stars: calculation.stars),
                      const SizedBox(height: 12),
                      _ScoreChip(
                        score: widget.state.score,
                        multiplier:
                            difficultyMultiplier(widget.state.activeTrack),
                      ),
                      const SizedBox(height: 14),
                      _StatsGrid(state: widget.state, summary: summary),
                      const SizedBox(height: 14),
                      _StarBreakdown(
                        state: widget.state,
                        calculation: calculation,
                      ),
                      if (!isDaily) ...[
                        const SizedBox(height: 14),
                        _ChapterProgress(summary: summary),
                      ],
                      if (summary.sessionGoalMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            summary.sessionGoalMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (!completedCampaign && !isDaily)
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: widget.onNextLevel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Next Puzzle  →',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onMenu,
                        child: Text(
                          completedCampaign ? 'View Journey' : 'Back to Menu',
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms).scale(
                    begin: const Offset(0.88, 0.88),
                    curve: Curves.easeOutBack,
                    duration: 450.ms,
                  ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            maxBlastForce: summary.chapterCompletedNow ? 32 : 22,
            minBlastForce: 8,
            emissionFrequency: summary.chapterCompletedNow ? 0.04 : 0.07,
            numberOfParticles: summary.chapterCompletedNow ? 45 : 25,
            gravity: 0.12,
            colors: [theme.accentColor, ...kBloomkuTileColors.take(4)],
          ),
        ),
      ],
    );
  }

  WinSummary _fallbackSummary() {
    final par = parTimeForPuzzle(
      gridSize: widget.state.puzzle.gridSize,
      track: widget.state.activeTrack,
    );
    return WinSummary(
      starCalculation: calculateLevelStars(
        mistakes: widget.state.mistakeCount,
        hintsUsed: widget.state.hintsUsed,
        solveRowsUsed: widget.state.solveRowsUsed,
        autoMarksUsed: widget.state.autoMarksUsed,
        elapsed: widget.state.elapsed,
        parTime: par,
      ),
      personalBest: widget.state.elapsed,
      isNewBest: false,
      chapterName:
          chapterForLevel(widget.state.levelNumber)?.name ?? 'Daily Challenge',
      collectibleCount: 0,
      collectibleTarget: 10,
      nextCollectible: null,
      nextUnlock: null,
      levelsToUnlock: 0,
      chapterCompletedNow: false,
    );
  }
}

class _ChapterCompleteBanner extends StatelessWidget {
  const _ChapterCompleteBanner({required this.summary});
  final WinSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accentColor,
            theme.accentColor.withValues(alpha: 0.65)
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '✨ ${summary.nextUnlock ?? 'New chapter unlocked'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Icon(
            index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 46,
            color: index < stars ? Colors.amber : Colors.grey.shade400,
          ).animate(delay: (180 * index).ms).scale(
                begin: const Offset(0, 0),
                curve: Curves.elasticOut,
              ),
        ),
      );
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score, required this.multiplier});
  final int score;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$score points  ·  ×${multiplier.toStringAsFixed(1)} difficulty',
        style: TextStyle(
          color: theme.accentColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.state, required this.summary});
  final GameState state;
  final WinSummary summary;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Stat(label: 'Time', value: _formatDuration(state.elapsed)),
          _Stat(
            label: summary.isNewBest ? 'New best!' : 'Personal best',
            value: _formatDuration(summary.personalBest),
          ),
          _Stat(label: 'Mistakes', value: '${state.mistakeCount}'),
          _Stat(label: 'Hint', value: '${state.hintsUsed}'),
          _Stat(label: 'Solve Row', value: '${state.solveRowsUsed}'),
          _Stat(label: 'AutoMark', value: '${state.autoMarksUsed}'),
          _Stat(label: 'Undo', value: '${state.undosUsed}'),
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: theme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StarBreakdown extends StatelessWidget {
  const _StarBreakdown({required this.state, required this.calculation});
  final GameState state;
  final StarCalculation calculation;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.textSecondary.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _Criterion(label: 'Complete the puzzle', earned: true),
          _Criterion(
            label: 'One mistake or fewer',
            earned: calculation.mistakeStarEarned,
          ),
          _Criterion(
            label:
                'No Hint, Solve Row or AutoMark · under ${_formatDuration(calculation.parTime)}',
            earned: calculation.masteryStarEarned,
          ),
          if (state.undosUsed > 0)
            Text(
              'Undo is tracked, but does not remove a star.',
              style: TextStyle(color: theme.textSecondary, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _Criterion extends StatelessWidget {
  const _Criterion({required this.label, required this.earned});
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            earned ? Icons.star_rounded : Icons.star_outline_rounded,
            color: earned ? Colors.amber : theme.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.summary});
  final WinSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final target = summary.collectibleTarget;
    final progress = target == 0 ? 0.0 : summary.collectibleCount / target;
    final unlockText = summary.chapterCompletedNow
        ? 'Unlocked: ${summary.nextUnlock}'
        : summary.levelsToUnlock == 0
            ? 'Chapter reward ready'
            : '${summary.levelsToUnlock} puzzle${summary.levelsToUnlock == 1 ? '' : 's'} to ${summary.nextUnlock}';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.panelColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.chapterName} restoration',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${summary.collectibleCount}/$target',
                style: TextStyle(color: theme.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 7,
              color: theme.accentColor,
              backgroundColor: theme.cardColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            summary.nextCollectible == null
                ? unlockText
                : 'Next collectible: ${summary.nextCollectible} · $unlockText',
            style: TextStyle(color: theme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
