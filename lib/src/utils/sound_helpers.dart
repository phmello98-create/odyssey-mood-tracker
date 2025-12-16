import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// NavigatorObserver que toca sons SND em transições de rotas
/// 
/// Inspirado em https://snd.dev - diferencia entre:
/// - Transições horizontais (push/pop mesmo nível) = swipe
/// - Transições hierárquicas (modal, dialog) = transition up/down
/// 
/// Uso no MaterialApp/GoRouter:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [SoundNavigatorObserver()],
///   ...
/// )
/// ```
class SoundNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _playTransitionSound(route, isOpening: true);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _playTransitionSound(route, isOpening: false);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _playTransitionSound(newRoute, isOpening: true);
    }
  }

  void _playTransitionSound(Route route, {required bool isOpening}) {
    // Detecta se é uma transição hierárquica (modal/dialog) ou horizontal (página)
    final isDialog = route is DialogRoute;
    final isModalBottomSheet = route is ModalBottomSheetRoute;
    final isPopup = route is PopupRoute;

    if (isDialog || isModalBottomSheet || isPopup) {
      // Transição hierárquica (modal, dialog, bottom sheet)
      if (isOpening) {
        soundService.playSndTransitionUp();
      } else {
        soundService.playSndTransitionDown();
      }
    } else if (route is PageRoute) {
      // Transição horizontal (navegação entre páginas)
      soundService.playSndSwipe();
    }
  }
}

/// Mixin para adicionar sons SND em widgets de forma fácil
/// 
/// Uso:
/// ```dart
/// class MyWidget extends StatelessWidget with SoundMixin {
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: () => withButtonSound(() => print('clicked')),
///       child: Text('Click me'),
///     );
///   }
/// }
/// ```
mixin SoundMixin {
  /// Executa callback com som de botão
  void withButtonSound(VoidCallback callback) {
    soundService.playSndButton();
    callback();
  }

  /// Executa callback com som de tap
  void withTapSound(VoidCallback callback) {
    soundService.playSndTap();
    callback();
  }

  /// Executa callback com som de select
  void withSelectSound(VoidCallback callback) {
    soundService.playSndSelect();
    callback();
  }

  /// Executa callback com som de swipe
  void withSwipeSound(VoidCallback callback) {
    soundService.playSndSwipe();
    callback();
  }

  /// Executa callback assíncrono com som de botão
  Future<void> withButtonSoundAsync(Future<void> Function() callback) async {
    soundService.playSndButton();
    await callback();
  }

  /// Toca som de sucesso
  void playSuccessSound() {
    soundService.playSndNotification();
  }

  /// Toca som de erro
  void playErrorSound() {
    soundService.playSndCaution();
  }

  /// Toca som de celebration
  void playCelebrationSound() {
    soundService.playSndCelebration();
  }
}

/// Extension para adicionar sons em GestureDetector facilmente
extension SoundGestureDetectorExtension on GestureDetector {
  /// Cria GestureDetector com som de tap
  static GestureDetector withTapSound({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        soundService.playSndTap();
        onTap();
      },
      child: child,
    );
  }

  /// Cria GestureDetector com som de swipe horizontal
  static GestureDetector withSwipeSound({
    Key? key,
    required Widget child,
    VoidCallback? onHorizontalDragEnd,
  }) {
    return GestureDetector(
      key: key,
      onHorizontalDragEnd: onHorizontalDragEnd != null
          ? (_) {
              soundService.playSndSwipe();
              onHorizontalDragEnd();
            }
          : null,
      child: child,
    );
  }
}

/// Extension para adicionar sons em InkWell facilmente
extension SoundInkWellExtension on InkWell {
  /// Cria InkWell com som de tap
  static InkWell withTapSound({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
  }) {
    return InkWell(
      key: key,
      borderRadius: borderRadius,
      onTap: () {
        soundService.playSndTap();
        onTap();
      },
      child: child,
    );
  }
}

/// Helper para showDialog com som de transição
Future<T?> showSoundDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
}) {
  soundService.playSndTransitionUp();
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
  ).then((result) {
    soundService.playSndTransitionDown();
    return result;
  });
}

/// Helper para showModalBottomSheet com som de transição
Future<T?> showSoundModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  soundService.playSndTransitionUp();
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    isScrollControlled: isScrollControlled,
  ).then((result) {
    soundService.playSndTransitionDown();
    return result;
  });
}

/// Helper para SnackBar com som de notificação
void showSoundSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  bool playSound = true,
}) {
  if (playSound) {
    soundService.playSndNotification();
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
    ),
  );
}

/// Helper para SnackBar de erro com som de caution
void showErrorSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  soundService.playSndCaution();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

/// Helper para SnackBar de sucesso com som de celebration
void showSuccessSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  bool celebration = false,
}) {
  if (celebration) {
    soundService.playSndCelebration();
  } else {
    soundService.playSndNotification();
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      backgroundColor: Colors.green,
    ),
  );
}
