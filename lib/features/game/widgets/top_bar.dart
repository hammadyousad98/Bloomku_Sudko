import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

const _gameplaySprites = 'assets/images/sprites/gameplay';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.level,
    required this.gridSize,
    required this.onSettings,
  });

  final int level;
  final int gridSize;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final chapter = chapterForLevel(level)?.name ?? 'Daily Garden';
    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 9,
            width: 70,
            height: 74,
            child: _GameImageButton(
              semanticLabel: 'Back',
              asset: 'back_button',
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            left: 72,
            right: 72,
            top: 2,
            bottom: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    '$_gameplaySprites/level_plaque.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 42),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OutlinedGameText(
                        'LEVEL $level',
                        fontSize: 26,
                      ),
                      const SizedBox(height: 1),
                      _OutlinedGameText(
                        chapter.toUpperCase(),
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 9,
            width: 70,
            height: 74,
            child: _GameImageButton(
              semanticLabel: 'Pause',
              asset: 'pause_button',
              onTap: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameImageButton extends StatefulWidget {
  const _GameImageButton({
    required this.semanticLabel,
    required this.asset,
    required this.onTap,
  });

  final String semanticLabel;
  final String asset;
  final VoidCallback onTap;

  @override
  State<_GameImageButton> createState() => _GameImageButtonState();
}

class _GameImageButtonState extends State<_GameImageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 90),
            child: Image.asset(
              '$_gameplaySprites/${widget.asset}.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
}

class _OutlinedGameText extends StatelessWidget {
  const _OutlinedGameText(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          children: [
            ExcludeSemantics(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  height: 1,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = fontSize * 0.1
                    ..color = const Color(0xFF4A2614),
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                height: 1,
                color: const Color(0xFFFFF0C7),
              ),
            ),
          ],
        ),
      );
}
