import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class GuidedRulePreview extends StatefulWidget {
  final String rule;
  final VoidCallback onComplete;

  const GuidedRulePreview({
    super.key,
    required this.rule,
    required this.onComplete,
  });

  @override
  State<GuidedRulePreview> createState() => _GuidedRulePreviewState();
}

class _GuidedRulePreviewState extends State<GuidedRulePreview> {
  // Animation duration of the last step in the sequence:
  // last flower fades in at delay 1000ms + 300ms = 1300ms
  // ✕ fades in at delay 1500ms + 200ms = 1700ms
  // shake is ~300ms → total ~2000ms. Add 300ms buffer = 2300ms.
  static const _animDuration = Duration(milliseconds: 2300);

  bool _isAnimating = true;
  // A version counter used to force a full widget subtree rebuild on replay,
  // which resets all flutter_animate controllers back to their initial state.
  int _replayKey = 0;

  @override
  void initState() {
    super.initState();
    _scheduleAnimationEnd();
  }

  void _scheduleAnimationEnd() {
    Future.delayed(_animDuration, () {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    });
  }

  void _replay() {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _replayKey++;
    });
    _scheduleAnimationEnd();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    String title = "";
    String subtitle = "";

    final colors = [
      theme.tileColors[0],
      theme.tileColors[1],
      theme.tileColors[2],
    ];

    List<Widget> Function() buildGridItems;

    if (widget.rule == 'rowColumn') {
      title = "Rule 1: Rows & Columns";
      subtitle = "Only ONE flower per row & column";
      buildGridItems = () => List.generate(9, (index) {
            int r = index ~/ 3;
            int c = index % 3;
            bool isTarget = (r == 1 && c == 0);
            bool isInvalid = (r == 1 && c == 2);
            return _buildCell(
              color: colors[0],
              isTarget: isTarget,
              isInvalid: isInvalid,
              accentColor: theme.accentColor,
            );
          });
    } else if (widget.rule == 'colorRegion') {
      title = "Rule 2: Colors";
      subtitle = "Only ONE flower per color";
      buildGridItems = () => List.generate(9, (index) {
            bool isColor1 = index < 4;
            bool isTarget = (index == 0);
            bool isInvalid = (index == 3);
            return _buildCell(
              color: isColor1 ? colors[0] : colors[1],
              isTarget: isTarget,
              isInvalid: isInvalid,
              accentColor: theme.accentColor,
            );
          });
    } else {
      title = "Rule 3: Spacing";
      subtitle = "Flowers can't touch — not even diagonally";
      buildGridItems = () => List.generate(9, (index) {
            int r = index ~/ 3;
            int c = index % 3;
            bool isTarget = (r == 1 && c == 1);
            bool isInvalid = (r == 2 && c == 2);
            return _buildCell(
              color: colors[(r + c) % 3],
              isTarget: isTarget,
              isInvalid: isInvalid,
              accentColor: theme.accentColor,
            );
          });
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54, blurRadius: 20, spreadRadius: 5)
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Key forces full subtree rebuild on replay, resetting all animations.
                KeyedSubtree(
                  key: ValueKey(_replayKey),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: buildGridItems(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Replay button — visible and enabled only when animation is not playing.
                AnimatedOpacity(
                  opacity: _isAnimating ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: const Icon(Icons.replay_rounded),
                    color: theme.accentColor,
                    tooltip: 'Replay animation',
                    // Prevent taps while fading out or while animating.
                    onPressed: _isAnimating ? null : _replay,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                // "Got it" is ALWAYS tappable — not gated on animation state.
                ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Got it",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
              .animate()
              .scale(curve: Curves.easeOutBack, duration: 400.ms)
              .fadeIn(),
        ),
      ),
    );
  }

  Widget _buildCell({
    required Color color,
    required bool isTarget,
    required bool isInvalid,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isTarget)
            Icon(Icons.local_florist, color: accentColor, size: 24)
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms),
          if (isInvalid)
            Icon(Icons.local_florist, color: accentColor, size: 24)
                .animate()
                .fadeIn(duration: 300.ms, delay: 1000.ms),
          if (isTarget || isInvalid)
            Icon(Icons.close, color: Colors.redAccent, size: 36)
                .animate()
                .fadeIn(duration: 200.ms, delay: 1500.ms)
                .scale(
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                    duration: 200.ms)
                .then()
                .shake(),
        ],
      ),
    );
  }
}
