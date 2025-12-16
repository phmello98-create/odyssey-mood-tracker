import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/odyssey_user.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';

// ============== PROVIDERS ==============

/// Provider para SharedPreferences (deve ser inicializado no main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences não foi inicializado. '
      'Use ProviderScope overrides no main.dart');
});

/// Provider para o AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FirebaseAuthRepository(prefs: prefs);
});

/// Provider para o usuário atual (stream)
final authStateChangesProvider = StreamProvider<OdysseyUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider para o usuário atual (síncrono)
final currentUserProvider = Provider<OdysseyUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
});

/// Provider para verificar se está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Provider para verificar se é guest
final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isGuest ?? false;
});

/// Provider para verificar se é PRO
final isProUserProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.hasValidProAccess ?? false;
});

// ============== AUTH CONTROLLER ==============

/// Estado do controller de autenticação
class AuthControllerState {
  final AuthResult? lastResult;
  final bool isLoading;

  const AuthControllerState({
    this.lastResult,
    this.isLoading = false,
  });

  AuthControllerState copyWith({
    AuthResult? lastResult,
    bool? isLoading,
  }) {
    return AuthControllerState(
      lastResult: lastResult ?? this.lastResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller para operações de autenticação
/// 
/// Gerencia o estado de loading e resultados das operações,
/// delegando a lógica real para o AuthRepository.
class AuthController extends StateNotifier<AuthControllerState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthControllerState());

  /// Login com Google
  Future<AuthResult> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signInWithGoogle();
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Login com Email/Password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signInWithEmail(email, password);
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Cadastro com Email/Password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signUpWithEmail(
      email,
      password,
      displayName,
    );
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Entrar como visitante
  Future<AuthResult> signInAsGuest() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signInAsGuest();
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Recuperar senha
  Future<AuthResult> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.resetPassword(email);
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Logout
  Future<AuthResult> signOut() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signOut();
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Deletar conta
  Future<AuthResult> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.deleteAccount();
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Converter conta guest em conta real
  Future<AuthResult> upgradeGuestAccount(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.upgradeGuestAccount(email, password);
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Atualizar perfil
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
    
    state = state.copyWith(
      isLoading: false,
      lastResult: result,
    );
    
    return result;
  }

  /// Reenviar email de verificação
  Future<AuthResult> resendVerificationEmail() async {
    return await _authRepository.resendVerificationEmail();
  }

  /// Verificar se email foi confirmado
  Future<bool> checkEmailVerified() async {
    return await _authRepository.checkEmailVerified();
  }

  /// Limpar último resultado
  void clearLastResult() {
    state = state.copyWith(lastResult: null);
  }
}

/// Provider para o AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

/// Provider para estado de loading
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoading;
});

/// Provider para último resultado de operação
final authLastResultProvider = Provider<AuthResult?>((ref) {
  return ref.watch(authControllerProvider).lastResult;
});
