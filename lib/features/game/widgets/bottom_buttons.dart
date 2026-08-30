import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _gameplaySprites = 'assets/images/sprites/gameplay';

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
        count: hintCount,
        onTap: onHintTap,
      ),
      _PowerAction(
        label: 'Solve Row',
        assetPath: 'assets/icons/powers/solve_row.svg',
        count: bulbCount,
        onTap: onBulbTap,
      ),
      _PowerAction(
        label: 'Undo',
        assetPath: 'assets/icons/powers/undo.svg',
        count: undoCount,
        onTap: onUndoTap,
      ),
      _PowerAction(
        label: 'AutoMark',
        assetPath: 'assets/icons/powers/auto_mark.svg',
        count: autoMarkCount,
        onTap: onAutoMarkTap,
      ),
    ];

    return SizedBox(
      height: 158,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: 6,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: width,
                    height: 70,
                    child: _PowerButton(action: action, enabled: enabled),
                  ),
              ],
            );
          },
        ),
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
    this.size = 38,
  });

  final String assetPath;
  final Color color;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (assetPath.endsWith('hint.svg')) {
      icon = Image.asset('$_gameplaySprites/hint_bulb.png');
    } else if (assetPath.endsWith('undo.svg')) {
      icon = Image.asset('$_gameplaySprites/undo_arrow.png');
    } else if (assetPath.endsWith('solve_row.svg')) {
      icon = FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final flower in [
              'flower_yellow',
              'flower_pink',
              'flower_purple'
            ])
              Image.asset('$_gameplaySprites/$flower.png', width: size * 0.43),
          ],
        ),
      );
    } else if (assetPath.endsWith('auto_mark.svg')) {
      icon = Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('$_gameplaySprites/flower_pink.png', width: size * 0.7),
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: Icon(Icons.close_rounded,
                  size: size * 0.38, color: const Color(0xFF667D1C)),
            ),
        ],
      );
    } else {
      icon = SvgPicture.asset(
        assetPath,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Opacity(opacity: enabled ? 1 : 0.42, child: icon),
    );
  }
}

class _PowerAction {
  const _PowerAction({
    required this.label,
    required this.assetPath,
    required this.count,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final int count;
  final VoidCallback onTap;
}

class _PowerButton extends StatefulWidget {
  const _PowerButton({required this.action, required this.enabled});

  final _PowerAction action;
  final bool enabled;

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isAd = widget.action.count <= 0;
    final frame = !widget.enabled
        ? 'power_button_disabled'
        : isAd
            ? 'power_button_ad'
            : 'power_button';
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label:
          '${widget.action.label}, ${isAd ? 'watch ad' : widget.action.count}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.action.onTap : null,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 80),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                '$_gameplaySprites/$frame.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PowerButtonIcon(
                      assetPath: widget.action.assetPath,
                      color: const Color(0xFFFFC13A),
                      enabled: widget.enabled,
                      size: 42,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.action.label,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Color(0xFFFFE9B5),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: Color(0xFF3B1C0D),
                                  offset: Offset(0, 2),
                                  blurRadius: 1)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 1,
                top: -5,
                width: 39,
                height: 39,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('$_gameplaySprites/inventory_badge.png'),
                    Text(
                      isAd ? 'AD' : '${widget.action.count}',
                      style: const TextStyle(
                        color: Color(0xFFFFF1C7),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        shadows: [
                          Shadow(
                              color: Color(0xFF32170A),
                              offset: Offset(0, 1),
                              blurRadius: 1)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
