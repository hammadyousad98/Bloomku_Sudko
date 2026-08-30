import 'package:flutter/material.dart';

const _gameplaySprites = 'assets/images/sprites/gameplay';

class RulesPanel extends StatelessWidget {
  const RulesPanel({
    super.key,
    required this.blockFullDiagonal,
    required this.blockMinDistance,
    this.minDistance = 2,
    required this.blockKnightMove,
    this.hasMines = false,
    this.highlightedRule,
  });

  final bool blockFullDiagonal;
  final bool blockMinDistance;
  final int minDistance;
  final bool blockKnightMove;
  final bool hasMines;
  final String? highlightedRule;

  @override
  Widget build(BuildContext context) {
    const visibleRules = [
      ('rowColumn', 'One flower\nper row'),
      ('rowColumn', 'One flower\nper column'),
      ('colorRegion', 'One flower\nper region'),
      ('noTouch', 'Flowers\ncannot touch'),
    ];
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Semantics(
          button: true,
          label: 'Puzzle rules. Tap for details.',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _showRules(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  '$_gameplaySprites/rules_panel.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(42, 8, 8, 8),
                  child: Row(
                    children: [
                      for (var index = 0; index < visibleRules.length; index++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration:
                                highlightedRule == visibleRules[index].$1
                                    ? BoxDecoration(
                                        color: const Color(0x55FFD24D),
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : null,
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding:
                                  EdgeInsets.only(left: index == 0 ? 17 : 23),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  visibleRules[index].$2,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4D2B19),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    final rules = <_RuleData>[
      const _RuleData(
        icon: Icons.grid_on_rounded,
        label: 'Rows and columns',
        description: 'Every row and column must contain exactly one flower.',
      ),
      const _RuleData(
        icon: Icons.palette_rounded,
        label: 'Color regions',
        description: 'Every colored region must contain exactly one flower.',
      ),
      const _RuleData(
        icon: Icons.close_rounded,
        label: 'No touching',
        description: 'Flowers cannot touch, including diagonally.',
      ),
      if (blockFullDiagonal)
        const _RuleData(
          icon: Icons.close_fullscreen_rounded,
          label: 'Full diagonals',
          description: 'No two flowers may share a full diagonal.',
        ),
      if (blockMinDistance)
        _RuleData(
          icon: Icons.open_in_full_rounded,
          label: 'Spread $minDistance+',
          description: 'Flowers must remain at least $minDistance steps apart.',
        ),
      if (blockKnightMove)
        const _RuleData(
          icon: Icons.extension_rounded,
          label: 'Knight move',
          description: 'Flowers also block chess-knight destinations.',
        ),
      if (hasMines)
        const _RuleData(
          icon: Icons.warning_amber_rounded,
          label: 'Hidden mines',
          description: 'Some invalid cells hide mines and cost two lives.',
        ),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8E5B9),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          itemCount: rules.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0x409B6337)),
          itemBuilder: (context, index) => ListTile(
            leading: Icon(rules[index].icon, color: const Color(0xFF658B25)),
            title: Text(
              rules[index].label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF4D2B19)),
            ),
            subtitle: Text(rules[index].description),
          ),
        ),
      ),
    );
  }
}

class _RuleData {
  const _RuleData({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;
}
