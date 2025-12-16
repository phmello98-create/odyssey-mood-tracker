import 'package:flutter/material.dart';

class StaggeredListAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double verticalOffset;

  const StaggeredListAnimation({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 400),
    this.verticalOffset = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration.inMilliseconds + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, verticalOffset * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }
}
