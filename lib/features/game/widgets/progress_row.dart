import 'package:flutter/material.dart';

const _gameplaySprites = 'assets/images/sprites/gameplay';
const _mainMenuSprites = 'assets/images/sprites/main_menu';

class ProgressRow extends StatelessWidget {
  const ProgressRow({
    super.key,
    required this.placedCount,
    required this.totalCount,
    required this.lives,
    required this.score,
    required this.timerText,
    required this.heartKeys,
  });

  final int placedCount;
  final int totalCount;
  final int lives;
  final int score;
  final String timerText;
  final List<GlobalKey> heartKeys;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: _CounterShell(
                  asset: 'heart_counter',
                  semanticLabel: '$lives lives remaining',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        if (index >= lives) return const SizedBox(width: 27);
                        return SizedBox.square(
                          key: index < heartKeys.length
                              ? heartKeys[index]
                              : null,
                          dimension: 27,
                          child: Image.asset(
                            '$_mainMenuSprites/heart.png',
                            filterQuality: FilterQuality.high,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 9,
                child: _CounterShell(
                  asset: 'timer_counter',
                  semanticLabel: 'Elapsed time $timerText',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 35, right: 8),
                    child: _CounterText(timerText, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 12,
                child: _CounterShell(
                  asset: 'flower_counter',
                  semanticLabel: '$placedCount of $totalCount flowers placed',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 34, right: 7),
                    child: _CounterText(
                      '$placedCount / $totalCount FLOWERS',
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _CounterShell extends StatelessWidget {
  const _CounterShell({
    required this.asset,
    required this.semanticLabel,
    required this.child,
  });

  final String asset;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              '$_gameplaySprites/$asset.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
            child,
          ],
        ),
      );
}

class _CounterText extends StatelessWidget {
  const _CounterText(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFEEC3),
              shadows: const [
                Shadow(
                    color: Color(0xFF3D1F10),
                    offset: Offset(0, 2),
                    blurRadius: 1),
              ],
            ),
          ),
        ),
      );
}

class GameplayScoreBar extends StatelessWidget {
  const GameplayScoreBar({
    super.key,
    required this.score,
    required this.progress,
  });

  final int score;
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 3, 12, 5),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 37,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A2C13),
                    borderRadius: BorderRadius.circular(19),
                    border:
                        Border.all(color: const Color(0xFFE5A73B), width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 5,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 20,
                            backgroundColor: const Color(0xFF351A0D),
                            color: const Color(0xFF7DB619),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      for (var index = 0; index < 3; index++) ...[
                        Image.asset(
                          '$_gameplaySprites/star_empty.png',
                          width: 35,
                          height: 35,
                          filterQuality: FilterQuality.high,
                        ),
                        if (index != 2) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: _CounterShell(
                  asset: 'score_counter',
                  semanticLabel: 'Score $score',
                  child: _CounterText(
                    _formatScore(score),
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  static String _formatScore(int score) {
    final value = score.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) buffer.write(',');
      buffer.write(value[index]);
    }
    return buffer.toString();
  }
}
