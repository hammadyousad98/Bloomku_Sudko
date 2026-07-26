import 'dart:math';
import 'package:flutter/material.dart';

void showHeartbreakAnimation(BuildContext context, Offset start, Offset end) {
  final overlayState = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return _HeartbreakWidget(
        start: start,
        end: end,
        onComplete: () => entry.remove(),
      );
    },
  );

  overlayState.insert(entry);
}

class _HeartbreakWidget extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const _HeartbreakWidget({
    required this.start,
    required this.end,
    required this.onComplete,
  });

  @override
  State<_HeartbreakWidget> createState() => _HeartbreakWidgetState();
}

class _HeartbreakWidgetState extends State<_HeartbreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleUpAnim;
  late Animation<double> _travelAnim;
  late Animation<double> _dustAnim;

  final int _numParticles = 12;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Phase 1: pop up at the tile (0.0 to 0.15)
    _scaleUpAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    ));

    // Phase 2: travel along arc (0.15 to 0.65)
    _travelAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeInOutSine),
    );

    // Phase 3: dust dissolve at destination (0.65 to 1.0)
    _dustAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    // Initialize particles for the dissolve effect
    final rnd = Random();
    _particles = List.generate(_numParticles, (i) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = rnd.nextDouble() * 40 + 20; // pixels per second-ish
      return _Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: rnd.nextDouble() * 4 + 2,
      );
    });

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Compute position along quadratic bezier curve
        final t = _travelAnim.value;
        // Control point: offset to the side and slightly up to create an arc
        final controlPoint = Offset(
          widget.start.dx + (widget.end.dx - widget.start.dx) * 0.5 + 50,
          widget.start.dy + (widget.end.dy - widget.start.dy) * 0.5 - 100,
        );

        final pX = pow(1 - t, 2) * widget.start.dx +
            2 * (1 - t) * t * controlPoint.dx +
            pow(t, 2) * widget.end.dx;
        final pY = pow(1 - t, 2) * widget.start.dy +
            2 * (1 - t) * t * controlPoint.dy +
            pow(t, 2) * widget.end.dy;

        final pos = Offset(pX, pY);

        return Stack(
          children: [
            if (_controller.value < 0.65)
              Positioned(
                left: pos.dx - 16,
                top: pos.dy - 16,
                child: Transform.scale(
                  scale: _scaleUpAnim.value,
                  child: const Icon(
                    Icons.heart_broken,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),

            // Trail sparkles (optional, simple alpha trail behind)
            if (t > 0 && t < 1)
              for (int i = 1; i <= 3; i++)
                if (t - (i * 0.05) > 0)
                  _buildTrailSparkle(t - (i * 0.05), controlPoint, i),

            if (_controller.value >= 0.65)
              Positioned(
                left: widget.end.dx - 24, // center particles around the heart icon size (~20-24)
                top: widget.end.dy - 24,
                child: CustomPaint(
                  size: const Size(48, 48),
                  painter: _DustPainter(
                    progress: _dustAnim.value,
                    particles: _particles,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrailSparkle(double trailT, Offset control, int index) {
    final tX = pow(1 - trailT, 2) * widget.start.dx +
        2 * (1 - trailT) * trailT * control.dx +
        pow(trailT, 2) * widget.end.dx;
    final tY = pow(1 - trailT, 2) * widget.start.dy +
        2 * (1 - trailT) * trailT * control.dy +
        pow(trailT, 2) * widget.end.dy;

    return Positioned(
      left: tX - 4,
      top: tY - 4,
      child: Opacity(
        opacity: (1.0 - index * 0.25).clamp(0.0, 1.0),
        child: const Icon(
          Icons.star,
          color: Colors.redAccent,
          size: 8,
        ),
      ),
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final double size;
  _Particle({required this.dx, required this.dy, required this.size});
}

class _DustPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _DustPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final pos = center + Offset(p.dx * progress, p.dy * progress);
      canvas.drawCircle(pos, p.size * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
