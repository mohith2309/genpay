import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class BudgetRing extends StatefulWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final String centerText;
  final String? subText;
  final bool animate;

  const BudgetRing({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 8,
    required this.centerText,
    this.subText,
    this.animate = true,
  });

  @override
  State<BudgetRing> createState() => _BudgetRingState();
}

class _BudgetRingState extends State<BudgetRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage.clamp(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) _controller.forward();
  }

  @override
  void didUpdateWidget(BudgetRing old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage.clamp(0, 1),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForPercentage(double pct) {
    if (pct < 0.6) return AppColors.credit;
    if (pct < 0.8) return AppColors.amber;
    if (pct < 1.0) return const Color(0xFFFF9933);
    return AppColors.debit;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final pct = _animation.value;
        final color = _colorForPercentage(pct);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  percentage: pct,
                  color: color,
                  strokeWidth: widget.strokeWidth,
                  trackColor: Theme.of(context).dividerColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontSize: widget.size * 0.18,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subText != null)
                    Text(
                      widget.subText!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: widget.size * 0.12,
                          ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  _RingPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * percentage.clamp(0, 1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percentage != percentage || old.color != color;
}
