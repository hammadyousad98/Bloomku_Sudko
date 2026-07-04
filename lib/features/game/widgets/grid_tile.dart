import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/themed_icon.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;

class GridTileWidget extends StatelessWidget {
  final Color backgroundColor;
  final TileState state;
  final VoidCallback onTap;
  final bool hasError;

  const GridTileWidget({
    super.key,
    required this.backgroundColor,
    required this.state,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch (state) {
      case TileState.empty:
        child = const SizedBox.expand();
        break;
      case TileState.marker:
        child = Center(
          child: const Text(
            "×",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black54),
          ).animate().fadeIn(duration: 150.ms),
        );
        break;
      case TileState.object:
        child = Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ThemedIcon(size: constraints.maxWidth * 0.6);
            },
          ),
        ).animate().scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0), duration: 200.ms, curve: Curves.elasticOut);
        break;
      case TileState.lockedObject:
        child = Stack(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ThemedIcon(size: constraints.maxWidth * 0.6);
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

    Widget tile = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasError ? Colors.red.withValues(alpha: 0.8) : backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );

    if (hasError) {
      tile = tile.animate(onComplete: (c) => c.reverse()).tint(color: Colors.red, duration: 150.ms).then(delay: 300.ms);
    }

    return tile;
  }
}
