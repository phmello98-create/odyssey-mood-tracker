import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para controlar a navegação global entre as abas
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void goToTab(int index) {
    state = index;
  }

  void goToHome() => goToTab(0);
  void goToLog() => goToTab(1);
  void goToMood() => goToTab(2);
  void goToTimer() => goToTab(3);
  void goToProfile() => goToTab(4);
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});
