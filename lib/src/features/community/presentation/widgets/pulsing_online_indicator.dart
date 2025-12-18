import 'package:flutter/material.dart';

/// Indicador pulsante de online (bolinha verde piscando)
class PulsingOnlineIndicator extends StatefulWidget {
  final double size;
  final Color color;

  const PulsingOnlineIndicator({
    super.key,
    this.size = 10,
    this.color = const Color(0xFF4CAF50),
  });

  @override
  State<PulsingOnlineIndicator> createState() => _PulsingOnlineIndicatorState();
}

class _PulsingOnlineIndicatorState extends State<PulsingOnlineIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: widget.size * 1.6,
              height: widget.size * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_animation.value * 0.3),
              ),
            ),
            // Inner dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_animation.value * 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
