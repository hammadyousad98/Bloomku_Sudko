import 'package:flutter/material.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;
import 'grid_tile.dart';

class PuzzleGrid extends StatelessWidget {
  final int gridSize;
  final List<TileState> states;
  final List<Color> colorMap;
  final List<int> colorRegions;
  final int? errorTileIndex;
  final int? hintTileIndex;
  final ValueChanged<int> onTileSingleTap;
  final ValueChanged<int> onTileDoubleTap;

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.states,
    required this.colorMap,
    required this.colorRegions,
    required this.onTileSingleTap,
    required this.onTileDoubleTap,
    this.errorTileIndex,
    this.hintTileIndex,
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
            colorRegionIndex: colorRegions[index],
            state: states[index],
            onTap: () => onTileSingleTap(index),
            onDoubleTap: () => onTileDoubleTap(index),
            hasError: errorTileIndex == index,
            hasHint: hintTileIndex == index,
          );
        },
      ),
    );
  }
}
