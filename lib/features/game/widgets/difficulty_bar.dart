import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/puzzle_generator.dart';

class DifficultyBar extends StatelessWidget {
  final bool showDifficultyBar;
  final bool showUltraTab;
  final PuzzleTrack currentTrack;
  final ValueChanged<PuzzleTrack> onTrackSelected;

  const DifficultyBar({
    super.key,
    required this.showDifficultyBar,
    required this.showUltraTab,
    required this.currentTrack,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDifficultyBar) {
      return const SizedBox.shrink();
    }

    final theme = context.bloomkuTheme;
    final tabs = [
      (label: 'Normal', track: PuzzleTrack.normal),
      (label: 'Hard', track: PuzzleTrack.hard),
      if (showUltraTab) (label: 'Ultra Hard', track: PuzzleTrack.ultraHard),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isActive = tab.track == currentTrack;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTrackSelected(tab.track),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isActive ? theme.accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      tab.label,
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
