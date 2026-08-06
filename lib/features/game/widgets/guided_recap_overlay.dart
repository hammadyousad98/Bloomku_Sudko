import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class GuidedRecapOverlay extends StatelessWidget {
  final VoidCallback onLetPlay;

  const GuidedRecapOverlay({super.key, required this.onLetPlay});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.accentColor, width: 2),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You're ready! 🌸",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().slideY(begin: -0.5, end: 0).fadeIn(),
                const SizedBox(height: 32),
                _buildRuleRow(context, Icons.grid_on, "1 per row & col", 200),
                const SizedBox(height: 16),
                _buildRuleRow(context, Icons.palette, "1 per color", 400),
                const SizedBox(height: 16),
                _buildRuleRow(context, Icons.block, "No touching", 600),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onLetPlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("Let's Play!",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ).animate().scale(delay: 800.ms).fadeIn(),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
        ),
      ),
    );
  }

  Widget _buildRuleRow(
      BuildContext context, IconData icon, String text, int delayMs) {
    final theme = context.bloomkuTheme;
    return Row(
      children: [
        Icon(icon, color: theme.accentColor, size: 28),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(color: theme.textSecondary, fontSize: 18),
        ),
      ],
    ).animate().fadeIn(delay: delayMs.ms).slideX(begin: -0.2, end: 0);
  }
}
