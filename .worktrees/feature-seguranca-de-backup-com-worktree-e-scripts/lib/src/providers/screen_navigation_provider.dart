import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScreenType {
  home,
  log,
  mood,
  timer,
  profile,
  logDetails,
  taskDetails,
  none,
}

class NavigationState {
  final ScreenType currentScreen;
  final ScreenType previousScreen;

  NavigationState({
    required this.currentScreen,
    required this.previousScreen,
  });

  NavigationState copyWith({
    ScreenType? currentScreen,
    ScreenType? previousScreen,
  }) {
    return NavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      previousScreen: previousScreen ?? this.previousScreen,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier()
      : super(NavigationState(currentScreen: ScreenType.home, previousScreen: ScreenType.none));

  void navigateToScreen(ScreenType screen) {
    state = state.copyWith(
      previousScreen: state.currentScreen,
      currentScreen: screen,
    );
  }

  void goBack() {
    if (state.previousScreen != ScreenType.none) {
      state = state.copyWith(
        currentScreen: state.previousScreen,
        previousScreen: ScreenType.none,
      );
    }
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
