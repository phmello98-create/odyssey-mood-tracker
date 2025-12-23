import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:odyssey/main.dart';
import 'package:odyssey/src/features/auth/domain/models/auth_result.dart';
import 'package:odyssey/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:odyssey/src/features/auth/domain/models/odyssey_user.dart';
import 'package:odyssey/src/features/auth/presentation/login_screen.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/migration_providers.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/providers/app_initializer_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<OdysseyUser?> get authStateChanges => Stream.value(null);

  @override
  bool get isAuthenticated => false;

  @override
  OdysseyUser? get currentUser => null;

  @override
  Future<AuthResult> deleteAccount() =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<bool> checkEmailVerified() => Future.value(false);

  @override
  Future<AuthResult> resetPassword(String email) =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> signInAsGuest() =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> signInWithEmail(String email, String password) =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> signInWithGoogle() =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> signOut() =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) => Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> upgradeGuestAccount(String email, String password) =>
      Future.value(const AuthResult.failure(message: 'not implemented'));

  @override
  Future<AuthResult> updateProfile({String? displayName, String? photoURL}) =>
      Future.value(const AuthResult.failure(message: 'not implemented'));
  @override
  Future<AuthResult> resendVerificationEmail() =>
      Future.value(const AuthResult.failure(message: 'not implemented'));
}

class _FakeAppInitializer extends AppInitializer {
  _FakeAppInitializer() : super() {
    state = const AppInitState(status: AppInitStatus.success);
  }

  Future<void> initialize() async {
    state = const AppInitState(status: AppInitStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'splash_animation_enabled': false, // reduz espera do splash no teste
    });
  });

  testWidgets('smoke: app inicializa e mostra login', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          welcomeServiceProvider.overrideWithValue(WelcomeService(prefs)),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          needsMigrationProvider.overrideWith((ref) async => false),
          appInitializerProvider.overrideWith((ref) => _FakeAppInitializer()),
        ],
        child: const OdysseyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
