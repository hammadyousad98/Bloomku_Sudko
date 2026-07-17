import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_model.dart';
import '../cubit/game_state.dart';

class GameOverOverlay extends StatelessWidget {
  final GameState state;
  final VoidCallback onWatchAdForLife;
  final VoidCallback onGiveUp;
  final VoidCallback onTryAgain;
  final VoidCallback onMenu;

  const GameOverOverlay({
    super.key,
    required this.state,
    required this.onWatchAdForLife,
    required this.onGiveUp,
    required this.onTryAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.phase == GamePhase.reviveOffer
                  ? _buildReviveCard(context, theme)
                  : _buildGameOverCard(context, theme),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 400.ms,
              ),
        ),
      ],
    );
  }

  Widget _buildReviveCard(BuildContext context, AppThemeData theme) {
    return Column(
      key: const ValueKey('revive'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Out of Lives! 💔",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Watch a short ad to get +1 life and continue?",
          style: TextStyle(
            fontSize: 16,
            color: theme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onWatchAdForLife,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Watch Ad ▶",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onGiveUp,
          style: TextButton.styleFrom(
            foregroundColor: theme.textSecondary,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text("Give Up", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildGameOverCard(BuildContext context, AppThemeData theme) {
    final minutes = state.elapsed.inMinutes;
    final seconds = (state.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final timeStr = "$minutes:$seconds";

    return Column(
      key: const ValueKey('gameover'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Game Over",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          "${state.score}",
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
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onMenu,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: onTryAgain,
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
                  "Try Again",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
