import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_sizes.dart';

/// Coleção de transições de página customizadas para navegação fluida
/// 
/// Uso:
/// ```dart
/// Navigator.push(context, AppPageRoutes.fade(const MyScreen()));
/// Navigator.push(context, AppPageRoutes.slideUp(const MyScreen()));
/// ```

class AppPageRoutes {
  /// Transição de fade (dissolve)
  static Route<T> fade<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
        );
      },
    );
  }

  /// Transição slide da direita (padrão iOS)
  static Route<T> slideRight<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Transição slide de baixo para cima (modal style)
  static Route<T> slideUp<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
    bool opaque = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: opaque,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Transição de escala (zoom in)
  static Route<T> scale<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          alignment: alignment,
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Transição slide + fade combinada (Material 3 style)
  static Route<T> material<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Transição shared axis horizontal (Material motion)
  static Route<T> sharedAxisX<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
    bool forward = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final offsetStart = forward ? 0.3 : -0.3;

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(offsetStart, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Transição shared axis vertical (Material motion)
  static Route<T> sharedAxisY<T>(
    Widget page, {
    Duration duration = AppDuration.page,
    RouteSettings? settings,
    bool forward = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final offsetStart = forward ? 0.3 : -0.3;

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, offsetStart),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Transição container transform (Material motion)
  static Route<T> containerTransform<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Sem transição (instantâneo)
  static Route<T> none<T>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// Extensão para navegação facilitada com transições
extension NavigatorExtension on NavigatorState {
  Future<T?> pushFade<T>(Widget page) => push(AppPageRoutes.fade<T>(page));
  Future<T?> pushSlideRight<T>(Widget page) => push(AppPageRoutes.slideRight<T>(page));
  Future<T?> pushSlideUp<T>(Widget page) => push(AppPageRoutes.slideUp<T>(page));
  Future<T?> pushScale<T>(Widget page) => push(AppPageRoutes.scale<T>(page));
  Future<T?> pushMaterial<T>(Widget page) => push(AppPageRoutes.material<T>(page));
  Future<T?> pushReplacementFade<T, TO>(Widget page) => pushReplacement(AppPageRoutes.fade<T>(page));
}

/// Extensão para BuildContext com navegação facilitada
extension NavigationContext on BuildContext {
  NavigatorState get navigator => Navigator.of(this);

  Future<T?> pushFade<T>(Widget page) => navigator.push(AppPageRoutes.fade<T>(page));
  Future<T?> pushSlide<T>(Widget page) => navigator.push(AppPageRoutes.slideRight<T>(page));
  Future<T?> pushModal<T>(Widget page) => navigator.push(AppPageRoutes.slideUp<T>(page));
  Future<T?> pushScale<T>(Widget page) => navigator.push(AppPageRoutes.scale<T>(page));
  Future<T?> pushMaterial<T>(Widget page) => navigator.push(AppPageRoutes.material<T>(page));
  Future<T?> pushReplacementFade<T, TO>(Widget page) => navigator.pushReplacement(AppPageRoutes.fade<T>(page));

  void pop<T>([T? result]) => navigator.pop(result);
  void popUntil(RoutePredicate predicate) => navigator.popUntil(predicate);
  void popToRoot() => navigator.popUntil((route) => route.isFirst);
  bool get canPop => navigator.canPop();
}

/// Widget wrapper para Hero transitions customizadas
class HeroTransitionWidget extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enabled;
  final CreateRectTween? createRectTween;

  const HeroTransitionWidget({
    super.key,
    required this.tag,
    required this.child,
    this.enabled = true,
    this.createRectTween,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Hero(
      tag: tag,
      createRectTween: createRectTween ?? _defaultCreateTween,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  static RectTween _defaultCreateTween(Rect? begin, Rect? end) {
    return MaterialRectCenterArcTween(begin: begin, end: end);
  }
}

/// Transição de tab com animação
class AnimatedTabTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final bool forward;

  const AnimatedTabTransition({
    super.key,
    required this.child,
    required this.animation,
    this.forward = true,
  });

  @override
  Widget build(BuildContext context) {
    final offset = forward ? 0.1 : -0.1;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(offset, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// PageView com transições customizadas entre páginas
class AnimatedPageView extends StatefulWidget {
  final List<Widget> children;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final PageController? controller;
  final bool enableSwipe;

  const AnimatedPageView({
    super.key,
    required this.children,
    this.initialPage = 0,
    this.onPageChanged,
    this.controller,
    this.enableSwipe = true,
  });

  @override
  State<AnimatedPageView> createState() => _AnimatedPageViewState();
}

class _AnimatedPageViewState extends State<AnimatedPageView> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: widget.enableSwipe
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      onPageChanged: widget.onPageChanged,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double value = 1.0;
            if (_controller.position.haveDimensions) {
              value = _controller.page! - index;
              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
            }

            return Transform.scale(
              scale: Curves.easeOut.transform(value),
              child: Opacity(
                opacity: Curves.easeOut.transform(value),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}

/// Bottom sheet com animação customizada
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.transparent,
    elevation: elevation ?? 0,
    shape: shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
  );
}

/// Dialog com animação customizada
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration transitionDuration = AppDuration.normal,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}
