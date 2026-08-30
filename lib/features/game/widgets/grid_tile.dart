import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;

const _gameplaySprites = 'assets/images/sprites/gameplay';

class GridTileWidget extends StatelessWidget {
  const GridTileWidget({
    super.key,
    required this.backgroundColor,
    required this.colorRegionIndex,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    this.hasError = false,
    this.hasHint = false,
    this.isHintRowCol = false,
    this.hasMineExplosion = false,
    this.isGuidedLocked = false,
    this.isGuidedTarget = false,
  });

  final Color backgroundColor;
  final int colorRegionIndex;
  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hasError;
  final bool hasHint;
  final bool isHintRowCol;
  final bool hasMineExplosion;
  final bool isGuidedLocked;
  final bool isGuidedTarget;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final hintColor = theme.textPrimary;
    var tileColor = Color.lerp(backgroundColor, Colors.white, 0.48)!;

    if (hasHint || isGuidedTarget) {
      tileColor = Color.alphaBlend(
        hintColor.withValues(alpha: 0.25),
        tileColor,
      );
    } else if (isHintRowCol) {
      tileColor = Color.alphaBlend(
        hintColor.withValues(alpha: 0.15),
        tileColor,
      );
    }

    Widget tile = GestureDetector(
      onTap: onTap,
      onDoubleTap: () {},
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: (hasError || hasMineExplosion)
              ? Colors.red.withValues(alpha: 0.8)
              : tileColor,
          borderRadius: BorderRadius.circular(7),
          border: (hasHint || isGuidedTarget)
              ? Border.all(color: hintColor, width: 3)
              : Border.all(
                  color: const Color(0xFF8E662D).withValues(alpha: 0.55),
                  width: isHintRowCol ? 1.5 : 0.8,
                ),
          boxShadow: (hasHint || isGuidedTarget)
              ? [
                  BoxShadow(
                    color: hintColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: _TileContent(state: state),
      ),
    );

    if (isGuidedTarget) {
      tile = tile
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 600.ms,
          );
    }
    if (isGuidedLocked) {
      tile = IgnorePointer(child: Opacity(opacity: 0.35, child: tile));
    }
    if (hasMineExplosion) {
      tile = tile
          .animate(onComplete: (controller) => controller.reverse())
          .tint(color: Colors.red, duration: 250.ms)
          .then(delay: 500.ms);
    } else if (hasError) {
      tile = tile
          .animate(onComplete: (controller) => controller.reverse())
          .tint(color: Colors.red, duration: 150.ms)
          .then(delay: 300.ms);
    }
    return tile;
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({required this.state});

  final TileState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case TileState.empty:
        return const SizedBox.expand();
      case TileState.marker:
      case TileState.autoMarker:
        return LayoutBuilder(
          builder: (context, constraints) => Center(
            child: Icon(
              Icons.close_rounded,
              size: constraints.maxWidth * 0.43,
              color: const Color(0xFF58721F),
            ),
          ),
        ).animate().fadeIn(duration: 150.ms);
      case TileState.object:
        return _flower().animate().scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
              duration: 200.ms,
              curve: Curves.elasticOut,
            );
      case TileState.lockedObject:
        return Stack(
          children: [
            _flower(),
            Positioned(
              right: 0,
              bottom: 0,
              width: 25,
              height: 25,
              child: Image.asset(
                '$_gameplaySprites/lock_badge.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        );
      case TileState.revealedMine:
        return const Center(
          child: Icon(Icons.warning_rounded, color: Color(0xFF4A2614)),
        );
    }
  }

  Widget _flower() => LayoutBuilder(
        builder: (context, constraints) => Center(
          child: Image.asset(
            '$_gameplaySprites/flower_piece.png',
            width: constraints.maxWidth * 0.78,
            height: constraints.maxWidth * 0.78,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}
