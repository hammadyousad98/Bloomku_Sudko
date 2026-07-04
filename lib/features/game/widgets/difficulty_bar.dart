import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DifficultyBar extends StatelessWidget {
  final int highestUnlockedLevel;
  final String currentTrack;
  final ValueChanged<String> onTrackSelected;

  const DifficultyBar({
    super.key,
    required this.highestUnlockedLevel,
    required this.currentTrack,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (highestUnlockedLevel < 16) {
      return const SizedBox.shrink(); // Hidden for levels 1-15
    }

    final theme = context.bloomkuTheme;
    final List<String> tabs = ['Normal', 'Hard'];
    if (highestUnlockedLevel >= 31) {
      tabs.add('Ultra');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isActive = tab.toLowerCase() == currentTrack.toLowerCase();
            return Expanded(
              child: GestureDetector(
                onTap: () => onTrackSelected(tab.toLowerCase()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isActive ? theme.accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isActive ? Colors.white : theme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
