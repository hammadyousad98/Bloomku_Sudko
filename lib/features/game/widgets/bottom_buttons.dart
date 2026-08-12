import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

class BottomButtons extends StatelessWidget {
  const BottomButtons({
    super.key,
    required this.hintCount,
    required this.bulbCount,
    required this.undoCount,
    required this.autoMarkCount,
    required this.onHintTap,
    required this.onBulbTap,
    required this.onUndoTap,
    required this.onAutoMarkTap,
    this.enabled = true,
  });

  final int hintCount;
  final int bulbCount;
  final int undoCount;
  final int autoMarkCount;
  final VoidCallback onHintTap;
  final VoidCallback onBulbTap;
  final VoidCallback onUndoTap;
  final VoidCallback onAutoMarkTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _PowerAction(
        label: 'Hint',
        assetPath: 'assets/icons/powers/hint.svg',
        color: Colors.orange,
        count: hintCount,
        onTap: onHintTap,
      ),
      _PowerAction(
        label: 'Solve Row',
        assetPath: 'assets/icons/powers/solve_row.svg',
        color: Colors.purple,
        count: bulbCount,
        onTap: onBulbTap,
      ),
      _PowerAction(
        label: 'Undo',
        assetPath: 'assets/icons/powers/undo.svg',
        color: Colors.blueGrey,
        count: undoCount,
        onTap: onUndoTap,
      ),
      _PowerAction(
        label: 'AutoMark',
        assetPath: 'assets/icons/powers/auto_mark.svg',
        color: Colors.teal,
        count: autoMarkCount,
        onTap: onAutoMarkTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 430 ? 2 : 4;
          const spacing = 10.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final action in actions)
                SizedBox(
                  width: itemWidth,
                  child: _PowerButton(action: action, enabled: enabled),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PowerButtonIcon extends StatelessWidget {
  const PowerButtonIcon({
    super.key,
    required this.assetPath,
    required this.color,
    this.enabled = true,
    this.size = 28,
  });

  final String assetPath;
  final Color color;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        enabled ? color : color.withValues(alpha: 0.35),
        BlendMode.srcIn,
      ),
    );
  }
}

class _PowerAction {
  const _PowerAction({
    required this.label,
    required this.assetPath,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final Color color;
  final int count;
  final VoidCallback onTap;
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.action, required this.enabled});

  final _PowerAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final isAdReward = action.count <= 0;
    final foreground =
        enabled ? theme.textPrimary : theme.textPrimary.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${action.label}, ${isAdReward ? 'watch ad' : action.count}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: action.color.withValues(alpha: enabled ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: enabled ? action.onTap : null,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PowerButtonIcon(
                      assetPath: action.assetPath,
                      color: action.color,
                      enabled: enabled,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: enabled
                    ? (isAdReward ? Colors.blue : Colors.redAccent)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.backgroundTop, width: 2),
              ),
              child: Text(
                isAdReward ? 'AD' : action.count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
