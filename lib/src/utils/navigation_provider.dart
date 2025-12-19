import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para controlar a aba selecionada no Perfil
final profileTabProvider = StateProvider<int>((ref) => 0);

// Provider para controlar a navegação global entre as abas
class NavigationNotifier extends StateNotifier<int> {
  final Ref ref;
  NavigationNotifier(this.ref) : super(0);

  void goToTab(int index) {
    state = index;
  }

  void goToHome() => goToTab(0);
  void goToLog() => goToTab(1);
  void goToMood() => goToTab(2);
  void goToTimer() => goToTab(3);
  void goToProfile({int tabIndex = 0}) {
    ref.read(profileTabProvider.notifier).state = tabIndex;
    goToTab(4);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier(ref);
});
