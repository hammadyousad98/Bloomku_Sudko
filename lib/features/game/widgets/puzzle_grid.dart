import 'package:flutter/material.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;
import 'grid_tile.dart';

class PuzzleGrid extends StatelessWidget {
  final int gridSize;
  final List<TileState> states;
  final List<Color> colorMap;
  final Function(int index) onTileTap;

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.states,
    required this.colorMap,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          return GridTileWidget(
            backgroundColor: colorMap[index],
            state: states[index],
            onTap: () => onTileTap(index),
          );
        },
      ),
    );
  }
}
