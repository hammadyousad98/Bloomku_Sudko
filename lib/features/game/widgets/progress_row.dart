import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/common/themed_icon.dart';

class ProgressRow extends StatelessWidget {
  final int placedCount;
  final int totalCount;
  final int lives;
  final int score;
  final String timerText;

  const ProgressRow({
    super.key,
    required this.placedCount,
    required this.totalCount,
    required this.lives,
    required this.score,
    required this.timerText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final progress = totalCount > 0 ? placedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const ThemedIcon(size: 28),
          const SizedBox(width: 8),
          Text(
            "$placedCount/$totalCount",
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.textSecondary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: List.generate(3, (index) {
              return Icon(
                index < lives ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 20,
              );
            }),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Score $score",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textPrimary),
              ),
              Text(
                timerText,
                style: TextStyle(fontSize: 12, color: theme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
