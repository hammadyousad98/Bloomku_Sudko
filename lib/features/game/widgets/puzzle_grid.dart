import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/puzzle_generator.dart' show TileState;
import 'grid_tile.dart';

class PuzzleGrid extends StatelessWidget {
  final int gridSize;
  final List<TileState> states;
  final List<Color> colorMap;
  final List<int> colorRegions;
  final int? errorTileIndex;
  final int? hintTileIndex;
  final int? mineTileIndex;
  final List<int>? tutorialHighlightIndexes;
  final ValueChanged<int> onTileSingleTap;
  final ValueChanged<int> onTileDoubleTap;
  final GlobalKey gridKey;

  const PuzzleGrid({
    super.key,
    required this.gridSize,
    required this.states,
    required this.colorMap,
    required this.colorRegions,
    required this.onTileSingleTap,
    required this.onTileDoubleTap,
    required this.gridKey,
    this.errorTileIndex,
    this.hintTileIndex,
    this.mineTileIndex,
    this.tutorialHighlightIndexes,
  });

  @override
  Widget build(BuildContext context) {
    Widget grid = GridView.builder(
      key: gridKey,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, index) {
        bool isHintRowCol = false;
        if (hintTileIndex != null) {
          int hintRow = hintTileIndex! ~/ gridSize;
          int hintCol = hintTileIndex! % gridSize;
          int myRow = index ~/ gridSize;
          int myCol = index % gridSize;
          if (myRow == hintRow || myCol == hintCol) {
            isHintRowCol = true;
          }
        }
        
        if (tutorialHighlightIndexes != null && tutorialHighlightIndexes!.contains(index)) {
          isHintRowCol = true;
        }

        return GridTileWidget(
          backgroundColor: colorMap[index],
          colorRegionIndex: colorRegions[index],
          state: states[index],
          onTap: () => onTileSingleTap(index),
          onDoubleTap: () => onTileDoubleTap(index),
          hasError: errorTileIndex == index,
          hasHint: hintTileIndex == index,
          isHintRowCol: isHintRowCol,
          hasMineExplosion: mineTileIndex == index,
        );
      },
    );

    if (mineTileIndex != null) {
      grid = grid.animate(onComplete: (c) => c.reverse())
          .shimmer(duration: 200.ms, color: Colors.red.withValues(alpha: 0.5))
          .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 250.ms);
    }
    
    return AspectRatio(
      aspectRatio: 1.0,
      child: grid,
    );
  }
}
