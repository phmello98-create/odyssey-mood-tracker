import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Navigator com sons automáticos de transição
/// 
/// Uso:
/// ```dart
/// SoundNavigator.push(context, MaterialPageRoute(
///   builder: (context) => DetailScreen(),
/// ));
/// 
/// SoundNavigator.pop(context);
/// ```
class SoundNavigator {
  /// Push com som de navegação
  static Future<T?> push<T>(
    BuildContext context,
    Route<T> route, {
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playNavigationSfx();
    }
    return Navigator.push(context, route);
  }

  /// Pop com som de fechamento
  static void pop<T>(
    BuildContext context, {
    T? result,
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playModalCloseSfx();
    }
    Navigator.pop(context, result);
  }

  /// PushNamed com som de navegação
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playNavigationSfx();
    }
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// PushReplacement com som de transição
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> route, {
    TO? result,
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playPageTransition();
    }
    return Navigator.pushReplacement(context, route, result: result);
  }

  /// PushReplacementNamed com som de transição
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playPageTransition();
    }
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// PushAndRemoveUntil com som de navegação
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> route,
    bool Function(Route<dynamic>) predicate, {
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playPageTransition();
    }
    return Navigator.pushAndRemoveUntil(context, route, predicate);
  }

  /// PopUntil com som de fechamento
  static void popUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate, {
    bool playSound = true,
  }) {
    if (playSound) {
      soundService.playModalCloseSfx();
    }
    Navigator.popUntil(context, predicate);
  }

  /// MaybePop com som de fechamento
  static Future<bool> maybePop<T extends Object?>(
    BuildContext context, {
    T? result,
    bool playSound = true,
  }) async {
    final canPop = Navigator.canPop(context);
    if (canPop && playSound) {
      soundService.playModalCloseSfx();
    }
    return Navigator.maybePop(context, result);
  }

  /// CanPop (sem som)
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}

/// Extension no Navigator para facilitar uso
extension NavigatorSoundExtension on NavigatorState {
  /// Push com som
  Future<T?> pushWithSound<T extends Object?>(Route<T> route) {
    soundService.playNavigationSfx();
    return push(route);
  }

  /// Pop com som
  void popWithSound<T extends Object?>([T? result]) {
    soundService.playModalCloseSfx();
    pop(result);
  }

  /// PushNamed com som
  Future<T?> pushNamedWithSound<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    soundService.playNavigationSfx();
    return pushNamed(routeName, arguments: arguments);
  }

  /// PushReplacement com som
  Future<T?> pushReplacementWithSound<T extends Object?, TO extends Object?>(
    Route<T> route, {
    TO? result,
  }) {
    soundService.playPageTransition();
    return pushReplacement(route, result: result);
  }
}
