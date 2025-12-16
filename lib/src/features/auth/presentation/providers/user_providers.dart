// lib/src/features/auth/presentation/providers/user_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/odyssey_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_firestore_repository.dart';
import 'auth_providers.dart';
import 'sync_providers.dart';

// ===========================================
// USER REPOSITORY PROVIDER
// ===========================================

/// Provider para o UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserFirestoreRepository(firestore: firestore);
});

// ===========================================
// USER DATA PROVIDER
// ===========================================

/// Provider para os dados do usuário no Firestore
/// 
/// Este provider carrega e observa os dados do usuário em tempo real.
/// Retorna null se o usuário não estiver autenticado ou for guest.
final userDataProvider = StreamProvider<OdysseyUser?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  // Se não há usuário ou é guest, retorna null
  if (currentUser == null || currentUser.isGuest) {
    return Stream.value(null);
  }
  
  final repository = ref.watch(userRepositoryProvider);
  return repository.watchUser(currentUser.uid);
});

/// Provider para o usuário atual combinado (local + Firestore)
/// 
/// Combina dados do auth provider com dados do Firestore,
/// priorizando os dados do Firestore quando disponíveis.
final combinedUserProvider = Provider<OdysseyUser?>((ref) {
  final authUser = ref.watch(currentUserProvider);
  final firestoreUser = ref.watch(userDataProvider).valueOrNull;
  
  // Se não há usuário auth, retorna null
  if (authUser == null) return null;
  
  // Se é guest ou não há dados Firestore, retorna usuário auth
  if (authUser.isGuest || firestoreUser == null) return authUser;
  
  // Combina dados - Firestore tem prioridade para campos específicos
  return authUser.copyWith(
    isPro: firestoreUser.isPro,
    accountType: firestoreUser.accountType,
    proExpiresAt: firestoreUser.proExpiresAt,
    lastSyncAt: firestoreUser.lastSyncAt,
    preferences: firestoreUser.preferences,
    devices: firestoreUser.devices,
    currentDeviceId: firestoreUser.currentDeviceId,
  );
});

// ===========================================
// USER CONTROLLER
// ===========================================

/// Estado do controller de usuário
class UserControllerState {
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  
  const UserControllerState({
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
  });
  
  UserControllerState copyWith({
    bool? isLoading,
    String? error,
    bool? isUpdating,
  }) {
    return UserControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

/// Controller para operações do usuário
class UserController extends StateNotifier<UserControllerState> {
  final UserRepository _repository;
  final Ref _ref;
  
  UserController(this._repository, this._ref) : super(const UserControllerState());
  
  /// Salva ou atualiza o usuário no Firestore
  Future<bool> saveUser(OdysseyUser user) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.saveUser(user);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  /// Cria usuário no Firestore após registro
  Future<bool> createUserAfterSignup(OdysseyUser user) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Verifica se já existe
      final exists = await _repository.userExists(user.uid);
      
      if (!exists) {
        await _repository.saveUser(user);
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  /// Atualiza campos específicos do usuário
  Future<bool> updateUser(Map<String, dynamic> updates) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      await _repository.updateUser(currentUser.uid, updates);
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }
  
  /// Atualiza nome de exibição
  Future<bool> updateDisplayName(String displayName) async {
    return updateUser({'displayName': displayName});
  }
  
  /// Atualiza foto de perfil
  Future<bool> updatePhotoURL(String? photoURL) async {
    return updateUser({'photoURL': photoURL});
  }
  
  /// Atualiza preferências
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      await _repository.updatePreferences(currentUser.uid, preferences);
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }
  
  /// Atualiza status PRO
  Future<bool> updateProStatus({
    required bool isPro,
    DateTime? expiresAt,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    state = state.copyWith(isUpdating: true, error: null);
    
    try {
      await _repository.updateProStatus(
        currentUser.uid,
        isPro: isPro,
        expiresAt: expiresAt,
      );
      state = state.copyWith(isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }
  
  /// Registra dispositivo atual
  Future<bool> registerDevice(String deviceId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    try {
      await _repository.addDevice(currentUser.uid, deviceId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  /// Remove dispositivo
  Future<bool> removeDevice(String deviceId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    try {
      await _repository.removeDevice(currentUser.uid, deviceId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  /// Deleta conta do usuário
  Future<bool> deleteAccount() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || currentUser.isGuest) return false;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.deleteUser(currentUser.uid);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider para o UserController
final userControllerProvider = StateNotifierProvider<UserController, UserControllerState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserController(repository, ref);
});

// ===========================================
// CONVENIENCE PROVIDERS
// ===========================================

/// Provider que indica se o usuário atual é PRO (com dados atualizados do Firestore)
final isUserProProvider = Provider<bool>((ref) {
  final user = ref.watch(combinedUserProvider);
  return user?.hasValidProAccess ?? false;
});

/// Provider para as preferências do usuário
final userPreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final user = ref.watch(combinedUserProvider);
  return user?.preferences ?? {};
});

/// Provider que indica se está carregando dados do usuário
final isUserLoadingProvider = Provider<bool>((ref) {
  final controllerState = ref.watch(userControllerProvider);
  final userDataState = ref.watch(userDataProvider);
  
  return controllerState.isLoading || userDataState.isLoading;
});

/// Provider para erro do usuário
final userErrorProvider = Provider<String?>((ref) {
  final controllerState = ref.watch(userControllerProvider);
  final userDataState = ref.watch(userDataProvider);
  
  if (controllerState.error != null) return controllerState.error;
  if (userDataState.hasError) return userDataState.error.toString();
  return null;
});
