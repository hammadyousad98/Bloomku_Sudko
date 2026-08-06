import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../tutorial/tutorial_cubit.dart';
import '../../tutorial/tutorial_screen.dart';

class RulesPanel extends StatelessWidget {
  final bool blockFullDiagonal;
  final bool blockMinDistance;
  final int minDistance;
  final bool blockKnightMove;
  final bool hasMines;
  final String? highlightedRule;

  const RulesPanel({
    super.key,
    required this.blockFullDiagonal,
    required this.blockMinDistance,
    this.minDistance = 2,
    required this.blockKnightMove,
    this.hasMines = false,
    this.highlightedRule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    final List<_RuleChipData> rules = [
      _RuleChipData(
        ruleKey: 'colorRegion',
        icon: Icons.palette,
        label: "1 per color",
        onTap: () => _showRuleSnack(context, "Each color region contains exactly one piece."),
      ),
      _RuleChipData(
        ruleKey: 'rowColumn',
        icon: Icons.grid_on,
        label: "1 per row & col",
        onTap: () => _showRuleSnack(context, "Every row and column contains exactly one piece."),
      ),
      _RuleChipData(
        ruleKey: 'noTouch',
        icon: Icons.block,
        label: "No touching",
        onTap: () => _showRuleSnack(context, "No two pieces can be adjacent — including diagonally adjacent."),
      ),
    ];

    if (blockFullDiagonal) {
      rules.add(_RuleChipData(
        ruleKey: 'diagonal',
        icon: Icons.close_fullscreen,
        label: "No diagonal",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getFullDiagonalRule()),
      ));
    }
    if (blockMinDistance) {
      rules.add(_RuleChipData(
        ruleKey: 'minDistance',
        icon: Icons.open_in_full,
        label: "Spread $minDistance+",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getMinDistanceRule(minDistance)),
      ));
    }
    if (blockKnightMove) {
      rules.add(_RuleChipData(
        ruleKey: 'knightMove',
        icon: Icons.extension,
        label: "No ♞",
        onTap: () => RuleTutorialDialog.show(context, TutorialCubit.getKnightsMoveRule()),
      ));
    }
    if (hasMines) {
      rules.add(_RuleChipData(
        ruleKey: 'mine',
        icon: Icons.warning_amber_rounded,
        label: "Hidden mines",
        onTap: () => _showRuleSnack(context, "⚠️ Hidden mines — one wrong step costs double."),
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
          final isHighlighted = highlightedRule == rule.ruleKey;

          Widget chip = ActionChip(
            avatar: Icon(rule.icon, size: 16, color: isHighlighted ? Colors.white : theme.accentColor),
            label: Text(rule.label, style: TextStyle(color: isHighlighted ? Colors.white : theme.textPrimary)),
            backgroundColor: isHighlighted ? Colors.amber : theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isHighlighted ? const BorderSide(color: Colors.amberAccent, width: 2) : BorderSide.none,
            ),
            onPressed: rule.onTap,
          );

          if (isHighlighted) {
            chip = chip
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .boxShadow(
                begin: const BoxShadow(color: Colors.transparent),
                end: BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 8, spreadRadius: 2),
                duration: const Duration(milliseconds: 800),
              );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: chip,
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
  final String ruleKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _RuleChipData({required this.ruleKey, required this.icon, required this.label, required this.onTap});
}
