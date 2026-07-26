import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BottomButtons extends StatelessWidget {
  final int hintCount;
  final int bulbCount;
  final int undoCount;
  final VoidCallback onHintTap;
  final VoidCallback onBulbTap;
  final VoidCallback onUndoTap;

  const BottomButtons({
    super.key,
    required this.hintCount,
    required this.bulbCount,
    required this.undoCount,
    required this.onHintTap,
    required this.onBulbTap,
    required this.onUndoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            label: "Hint",
            icon: Icons.lightbulb,
            color: Colors.orange,
            count: hintCount,
            onTap: onHintTap,
          ),
          _ActionButton(
            label: "Solve Row",
            icon: Icons.auto_fix_high,
            color: Colors.purple,
            count: bulbCount,
            onTap: onBulbTap,
          ),
          _ActionButton(
            label: "Undo",
            icon: Icons.undo,
            color: Colors.grey,
            count: undoCount,
            onTap: onUndoTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final badgeText = count > 0 ? count.toString() : "AD";
    final badgeColor = count > 0 ? Colors.red : Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
