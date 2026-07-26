import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/common/themed_icon.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;

class GridTileWidget extends StatelessWidget {
  final Color backgroundColor;
  final int colorRegionIndex;
  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final bool hasError;
  final bool hasHint;
  final bool isHintRowCol;
  final bool hasMineExplosion;

  const GridTileWidget({
    super.key,
    required this.backgroundColor,
    required this.colorRegionIndex,
    required this.state,
    required this.onTap,
    required this.onDoubleTap,
    this.hasError = false,
    this.hasHint = false,
    this.isHintRowCol = false,
    this.hasMineExplosion = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    final theme = context.bloomkuTheme;
    final iconPath =
        theme.objectIconPaths[colorRegionIndex % theme.objectIconPaths.length];

    switch (state) {
      case TileState.empty:
        child = const SizedBox.expand();
        break;
      case TileState.marker:
        child = Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Icon(
                Icons.close_rounded,
                size: constraints.maxWidth * 0.4,
                color: theme.textPrimary.withValues(alpha: 0.5),
              );
            },
          ),
        ).animate().fadeIn(duration: 150.ms);
        break;
      case TileState.object:
        child = Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ThemedIcon(
                size: constraints.maxWidth * 0.6,
                iconPath: iconPath,
              );
            },
          ),
        ).animate().scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
            curve: Curves.elasticOut);
        break;
      case TileState.lockedObject:
        child = Stack(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ThemedIcon(
                    size: constraints.maxWidth * 0.6,
                    iconPath: iconPath,
                  );
                },
              ),
            ),
            const Positioned(
              bottom: 2,
              right: 2,
              child: Icon(Icons.lock, size: 16, color: Colors.black87),
            ),
          ],
        );
        break;
      case TileState.revealedMine:
        child = Stack(
          children: [
            Container(color: Colors.grey.withValues(alpha: 0.5)),
            const Center(child: Text("💀", style: TextStyle(fontSize: 24))),
          ],
        );
        break;
    }

    final hintBaseColor = theme.textPrimary;
    Color bgColor = backgroundColor;
    
    if (hasHint) {
      bgColor = Color.alphaBlend(hintBaseColor.withValues(alpha: 0.25), bgColor);
    } else if (isHintRowCol) {
      bgColor = Color.alphaBlend(hintBaseColor.withValues(alpha: 0.15), bgColor);
    }

    Widget tile = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: (hasError || hasMineExplosion) ? Colors.red.withValues(alpha: 0.8) : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: hasHint
              ? Border.all(color: hintBaseColor, width: 3)
              : (isHintRowCol
                  ? Border.all(color: hintBaseColor.withValues(alpha: 0.4), width: 1.5)
                  : null),
          boxShadow: hasHint
              ? [
                  BoxShadow(
                    color: hintBaseColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );

    if (hasMineExplosion) {
      tile = tile
          .animate(onComplete: (c) => c.reverse())
          .tint(color: Colors.red, duration: 250.ms)
          .then(delay: 500.ms);
    } else if (hasError) {
      tile = tile
          .animate(onComplete: (c) => c.reverse())
          .tint(color: Colors.red, duration: 150.ms)
          .then(delay: 300.ms);
    }

    return tile;
  }
}
