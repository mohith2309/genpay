import 'package:flutter/material.dart';
import '../core/utils.dart';

class AnimatedAmount extends StatefulWidget {
  final double amount;
  final TextStyle? style;
  final Duration duration;
  final bool showRupee;
  final Color? color;

  const AnimatedAmount({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.showRupee = true,
    this.color,
  });

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousAmount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedAmount old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _previousAmount = old.amount;
      _animation = Tween<double>(begin: _previousAmount, end: widget.amount).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final text = widget.showRupee
            ? AppUtils.formatCurrency(_animation.value)
            : _animation.value.toStringAsFixed(0);
        return Text(
          text,
          style: (widget.style ?? Theme.of(context).textTheme.displayLarge)
              ?.copyWith(color: widget.color),
        );
      },
    );
  }
}
