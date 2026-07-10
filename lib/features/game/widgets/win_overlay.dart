import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_model.dart';
import '../cubit/game_state.dart';

class WinOverlay extends StatefulWidget {
  final GameState state;
  final VoidCallback onNextLevel;
  final VoidCallback onMenu;

  const WinOverlay({
    super.key,
    required this.state,
    required this.onNextLevel,
    required this.onMenu,
  });

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final wrongPlacements = widget.state.maxLives - widget.state.livesRemaining;
    int stars = 3;
    if (wrongPlacements >= 3) {
      stars = 1;
    } else if (wrongPlacements >= 1) {
      stars = 2;
    }

    final minutes = widget.state.elapsed.inMinutes;
    final seconds = (widget.state.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final timeStr = "$minutes:$seconds";

    String trackName = 'Normal';
    if (widget.state.activeTrack == PuzzleTrack.hard) trackName = 'Hard ×1.5';
    if (widget.state.activeTrack == PuzzleTrack.ultraHard) trackName = 'Ultra ×2.5';
    final completedAllLevels = widget.state.levelNumber >= maxLevelCount;

    return Stack(
      children: [
        // Semi-transparent dark overlay
        Container(
          color: Colors.black.withValues(alpha: 0.6),
        ).animate().fadeIn(duration: 300.ms),

        // Card
        Center(
          child: Container(
            width: 360,
            height: 460,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Puzzle Solved! 🎉",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trackName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "${widget.state.score}",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Time: $timeStr",
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final earned = index < stars;
                    return Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
                      color: earned
                          ? Colors.amber
                          : theme.textPrimary.withValues(alpha: 0.3),
                    ).animate(delay: (400 + index * 200).ms).scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        );
                  }),
                ),
                const SizedBox(height: 32),
                if (completedAllLevels) ...[
                  Text(
                    "You've completed all levels!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textPrimary,
                          elevation: 0,
                          side: BorderSide(
                              color: theme.textPrimary.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Menu",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (!completedAllLevels) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onNextLevel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Next Level",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 400.ms,
              ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // blast downwards
            maxBlastForce: 25,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: [
              theme.accentColor,
              ...kBloomkuTileColors.take(3), // Use a few tile colors
            ],
          ),
        ),
      ],
    );
  }
}
