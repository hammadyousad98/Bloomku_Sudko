import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../tutorial/tutorial_cubit.dart';
import '../../tutorial/tutorial_screen.dart';

class RulesPanel extends StatelessWidget {
  final bool blockFullDiagonal;
  final bool blockMinDistance;
  final int minDistance;
  final bool blockKnightMove;

  const RulesPanel({
    super.key,
    required this.blockFullDiagonal,
    required this.blockMinDistance,
    this.minDistance = 2,
    required this.blockKnightMove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    final List<_RuleChipData> rules = [
      _RuleChipData(
        icon: Icons.palette,
        label: "1 per color",
        onTap: () => _showRuleSnack(context, "Each color region contains exactly one piece."),
      ),
      _RuleChipData(
        icon: Icons.grid_on,
        label: "1 per row & col",
        onTap: () => _showRuleSnack(context, "Every row and column contains exactly one piece."),
      ),
      _RuleChipData(
        icon: Icons.block,
        label: "No touching",
        onTap: () => _showRuleSnack(context, "No two pieces can be adjacent — including diagonally adjacent."),
      ),
    ];

    if (blockFullDiagonal) {
      rules.add(_RuleChipData(
        icon: Icons.close_fullscreen,
        label: "No diagonal",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getFullDiagonalRule()),
      ));
    }
    if (blockMinDistance) {
      rules.add(_RuleChipData(
        icon: Icons.open_in_full,
        label: "Spread $minDistance+",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getMinDistanceRule(minDistance)),
      ));
    }
    if (blockKnightMove) {
      rules.add(_RuleChipData(
        icon: Icons.extension,
        label: "No ♞",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getKnightsMoveRule()),
      ));
    }

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: rules.length,
        itemBuilder: (context, index) {
          final rule = rules[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              avatar: Icon(rule.icon, size: 16, color: theme.accentColor),
              label: Text(rule.label, style: TextStyle(color: theme.textPrimary)),
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              onPressed: rule.onTap,
            ),
          );
        },
      ),
    );
  }

  void _showRuleSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _RuleChipData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _RuleChipData({required this.icon, required this.label, required this.onTap});
}
