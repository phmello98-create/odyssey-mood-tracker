import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Detector de long-press refinado com:
/// - Threshold configurável (padrão 450ms)
/// - Cancelamento ao arrastar (>8px por padrão)
/// - Feedback visual progressivo
/// - Feedback haptic
class LongPressDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Duration threshold;
  final double dragCancelDistance;
  final bool enableHapticFeedback;
  final bool enableVisualFeedback;

  const LongPressDetector({
    super.key,
    required this.child,
    this.onLongPress,
    this.onTap,
    this.threshold = const Duration(milliseconds: 450),
    this.dragCancelDistance = 8.0,
    this.enableHapticFeedback = true,
    this.enableVisualFeedback = true,
  });

  @override
  State<LongPressDetector> createState() => _LongPressDetectorState();
}

class _LongPressDetectorState extends State<LongPressDetector>
    with SingleTickerProviderStateMixin {
  Timer? _longPressTimer;
  Offset? _initialPosition;
  bool _isLongPressing = false;
  bool _cancelled = false;
  
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: widget.threshold,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _initialPosition = event.position;
    _cancelled = false;
    _isLongPressing = true;
    
    if (widget.enableVisualFeedback) {
      _scaleController.forward();
    }
    
    _longPressTimer = Timer(widget.threshold, () {
      if (!_cancelled && _isLongPressing) {
        if (widget.enableHapticFeedback) {
          HapticFeedback.mediumImpact();
        }
        widget.onLongPress?.call();
        _resetState();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_initialPosition == null || _cancelled) return;
    
    final distance = (event.position - _initialPosition!).distance;
    if (distance > widget.dragCancelDistance) {
      _cancelLongPress();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_cancelled && _isLongPressing && _longPressTimer?.isActive == true) {
      widget.onTap?.call();
    }
    _resetState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _cancelLongPress();
  }

  void _cancelLongPress() {
    _cancelled = true;
    _resetState();
  }

  void _resetState() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isLongPressing = false;
    _initialPosition = null;
    
    if (widget.enableVisualFeedback && mounted) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.enableVisualFeedback
          ? AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: widget.child,
            )
          : widget.child,
    );
  }
}
