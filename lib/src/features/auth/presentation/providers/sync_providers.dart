// lib/src/features/auth/presentation/providers/sync_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/sync_service.dart';
import '../../services/cloud_storage_service.dart';
import '../../services/offline_sync_queue.dart';
import '../../services/realtime_sync_service.dart';
import 'auth_providers.dart';

// SyncConfig is exported from realtime_sync_service.dart
export '../../services/realtime_sync_service.dart' show SyncConfig;

// ============================================
// FIREBASE PROVIDERS
// ============================================

/// Provider para FirebaseFirestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  if (Firebase.apps.isEmpty) {
    throw Exception('Firebase não inicializado');
  }
  return FirebaseFirestore.instance;
});

/// Provider para FirebaseStorage
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ============================================
// SYNC CONFIG PROVIDER
// ============================================

/// Provider para a configuração de sincronização
/// Persiste em SharedPreferences
class SyncConfigNotifier extends StateNotifier<SyncConfig> {
  SyncConfigNotifier() : super(SyncConfig.all()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('sync_config');
      if (configJson != null) {
        // Parse básico dos campos
        state = SyncConfig(
          moods: prefs.getBool('sync_moods') ?? true,
          tasks: prefs.getBool('sync_tasks') ?? true,
          habits: prefs.getBool('sync_habits') ?? true,
          notes: prefs.getBool('sync_notes') ?? true,
          quotes: prefs.getBool('sync_quotes') ?? true,
          gamification: prefs.getBool('sync_gamification') ?? true,
          timeTracking: prefs.getBool('sync_timeTracking') ?? true,
          books: prefs.getBool('sync_books') ?? true,
        );
      }
    } catch (e) {
      // Mantém configuração padrão se houver erro
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sync_moods', state.moods);
      await prefs.setBool('sync_tasks', state.tasks);
      await prefs.setBool('sync_habits', state.habits);
      await prefs.setBool('sync_notes', state.notes);
      await prefs.setBool('sync_quotes', state.quotes);
      await prefs.setBool('sync_gamification', state.gamification);
      await prefs.setBool('sync_timeTracking', state.timeTracking);
      await prefs.setBool('sync_books', state.books);
    } catch (e) {
      // Ignora erros de persistência
    }
  }

  void toggleMoods() {
    state = state.copyWith(moods: !state.moods);
    _saveConfig();
  }

  void toggleTasks() {
    state = state.copyWith(tasks: !state.tasks);
    _saveConfig();
  }

  void toggleHabits() {
    state = state.copyWith(habits: !state.habits);
    _saveConfig();
  }

  void toggleNotes() {
    state = state.copyWith(notes: !state.notes);
    _saveConfig();
  }

  void toggleQuotes() {
    state = state.copyWith(quotes: !state.quotes);
    _saveConfig();
  }

  void toggleGamification() {
    state = state.copyWith(gamification: !state.gamification);
    _saveConfig();
  }

  void toggleTimeTracking() {
    state = state.copyWith(timeTracking: !state.timeTracking);
    _saveConfig();
  }

  void toggleBooks() {
    state = state.copyWith(books: !state.books);
    _saveConfig();
  }

  void enableAll() {
    state = SyncConfig.all();
    _saveConfig();
  }

  void disableAll() {
    state = SyncConfig.none();
    _saveConfig();
  }
}

final syncConfigProvider =
    StateNotifierProvider<SyncConfigNotifier, SyncConfig>((ref) {
      return SyncConfigNotifier();
    });

// ============================================
// SYNC SERVICE PROVIDER
// ============================================

/// Provider para o SyncService
///
/// Retorna null se o usuário não estiver autenticado ou for guest.
/// Isso evita sincronização acidental de dados de usuários não logados.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final user = ref.watch(currentUserProvider);

  // Não fornece sync service se não houver usuário ou for guest
  if (user == null || user.isGuest) {
    return null;
  }

  final firestore = ref.watch(firestoreProvider);
  return SyncService(firestore: firestore, userId: user.uid);
});

// ============================================
// REALTIME SYNC SERVICE PROVIDER
// ============================================

/// Provider para o RealtimeSyncService (sync bidirecional)
///
/// Escuta mudanças no Firestore e aplica localmente.
final realtimeSyncServiceProvider = Provider<RealtimeSyncService?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null || user.isGuest) {
    return null;
  }

  final firestore = ref.watch(firestoreProvider);
  final config = ref.watch(syncConfigProvider);

  final service = RealtimeSyncService(
    firestore: firestore,
    userId: user.uid,
    config: config,
  );

  // Iniciar escuta automaticamente
  service.startListening();

  // Limpar recursos quando o provider for descartado
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream de eventos de sync em tempo real
final realtimeSyncEventsProvider = StreamProvider<SyncChangeEvent>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  if (service == null) {
    return const Stream.empty();
  }
  return service.changeStream;
});

// ============================================
// CLOUD STORAGE SERVICE PROVIDER
// ============================================

/// Provider para o CloudStorageService
///
/// Usado para upload de fotos de perfil e capas de livros.
/// Retorna null se o usuário não estiver autenticado ou for guest.
final cloudStorageServiceProvider = Provider<CloudStorageService?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null || user.isGuest) {
    return null;
  }

  return CloudStorageService(userId: user.uid);
});

// ============================================
// OFFLINE SYNC QUEUE PROVIDER
// ============================================

/// Provider para o OfflineSyncQueue
///
/// Gerencia fila de operações offline com auto-sync quando volta online.
/// Retorna null se o usuário não estiver autenticado ou for guest.
final offlineSyncQueueProvider = Provider<OfflineSyncQueue?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null || user.isGuest) {
    return null;
  }

  final firestore = ref.watch(firestoreProvider);
  final queue = OfflineSyncQueue(
    firestore: firestore,
    userId: user.uid,
    strategy: ConflictResolutionStrategy.lastWriteWins,
  );

  // Inicializar a fila
  queue.initialize();

  // Limpar recursos quando o provider for descartado
  ref.onDispose(() {
    queue.dispose();
  });

  return queue;
});

/// Provider para o status da fila offline
final offlineSyncStatusProvider = StreamProvider<SyncQueueStatus>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  if (queue == null) {
    return Stream.value(
      const SyncQueueStatus(pendingCount: 0, isSyncing: false, isOnline: true),
    );
  }
  return queue.statusStream;
});

/// Provider para verificar se está online
final isOnlineProvider = StreamProvider<bool>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  if (queue == null) {
    return Stream.value(true);
  }
  return queue.connectivityStream;
});

/// Provider para quantidade de operações pendentes
final pendingSyncCountProvider = Provider<int>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  return queue?.pendingCount ?? 0;
});

// ============================================
// SYNC STATE
// ============================================

/// Estado da sincronização
class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final Map<String, SyncResult>? lastResults;
  final String? currentOperation;
  final String? errorMessage;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastResults,
    this.currentOperation,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    Map<String, SyncResult>? lastResults,
    String? currentOperation,
    String? errorMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastResults: lastResults ?? this.lastResults,
      currentOperation: currentOperation ?? this.currentOperation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Verifica se todas as operações foram bem-sucedidas
  bool get allSuccessful {
    if (lastResults == null) return false;
    return lastResults!.values.every((r) => r.success);
  }

  /// Conta total de itens sincronizados
  int get totalItemsSynced {
    if (lastResults == null) return 0;
    return lastResults!.values
        .where((r) => r.success)
        .fold(0, (sum, r) => sum + r.itemsSynced);
  }

  /// Retorna mensagens de erro das operações que falharam
  List<String> get errorMessages {
    if (lastResults == null) return [];
    return lastResults!.entries
        .where((e) => !e.value.success && e.value.errorMessage != null)
        .map((e) => '${e.key}: ${e.value.errorMessage}')
        .toList();
  }
}

// ============================================
// SYNC CONTROLLER
// ============================================

/// Controller para gerenciar operações de sincronização
///
/// Inclui rate limiting para evitar chamadas excessivas ao Firebase.
class SyncController extends StateNotifier<SyncState> {
  final SyncService? _syncService;

  /// Intervalo mínimo entre syncs (30 segundos)
  static const Duration _minSyncInterval = Duration(seconds: 30);

  /// Timestamp da última tentativa de sync
  DateTime? _lastSyncAttempt;

  SyncController(this._syncService) : super(const SyncState());

  /// Verifica se o sync está disponível
  bool get isAvailable => _syncService != null;

  /// Verifica se pode sincronizar (rate limiting)
  bool get _canSync {
    if (_lastSyncAttempt == null) return true;
    final elapsed = DateTime.now().difference(_lastSyncAttempt!);
    return elapsed >= _minSyncInterval;
  }

  /// Tempo restante até poder sincronizar novamente
  Duration get timeUntilNextSync {
    if (_lastSyncAttempt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastSyncAttempt!);
    final remaining = _minSyncInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Sincroniza todos os dados locais com o Firestore
  ///
  /// Inclui rate limiting para evitar chamadas excessivas.
  /// [force] ignora o rate limiting (use com cuidado).
  Future<void> syncAll({bool force = false}) async {
    if (_syncService == null) {
      state = state.copyWith(
        errorMessage: 'Sync não disponível. Faça login para sincronizar.',
      );
      return;
    }

    // Rate limiting check
    if (!force && !_canSync) {
      final remaining = timeUntilNextSync.inSeconds;
      state = state.copyWith(
        errorMessage: 'Aguarde ${remaining}s antes de sincronizar novamente.',
      );
      return;
    }

    _lastSyncAttempt = DateTime.now();

    state = state.copyWith(
      isSyncing: true,
      currentOperation: 'Iniciando sincronização...',
      errorMessage: null,
    );

    try {
      final results = await _syncService.syncAll(
        onProgress: (category, status) {
          if (status == SyncOperationStatus.syncing) {
            state = state.copyWith(
              currentOperation: 'Sincronizando $category...',
            );
          }
        },
      );

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastResults: results,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Erro ao sincronizar: $e',
        currentOperation: null,
      );
    }
  }

  /// Baixa todos os dados do Firestore
  Future<void> downloadAll() async {
    if (_syncService == null) {
      state = state.copyWith(
        errorMessage: 'Sync não disponível. Faça login para baixar dados.',
      );
      return;
    }

    state = state.copyWith(
      isSyncing: true,
      currentOperation: 'Iniciando download...',
      errorMessage: null,
    );

    try {
      final results = await _syncService.downloadAll(
        onProgress: (category, status) {
          if (status == SyncOperationStatus.syncing) {
            state = state.copyWith(currentOperation: 'Baixando $category...');
          }
        },
      );

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastResults: results,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Erro ao baixar dados: $e',
        currentOperation: null,
      );
    }
  }

  /// Sincroniza apenas uma categoria específica
  Future<void> syncCategory(String category) async {
    if (_syncService == null) {
      state = state.copyWith(errorMessage: 'Sync não disponível.');
      return;
    }

    state = state.copyWith(
      isSyncing: true,
      currentOperation: 'Sincronizando $category...',
      errorMessage: null,
    );

    try {
      SyncResult result;
      switch (category) {
        case 'moods':
          result = await _syncService.syncMoods();
          break;
        case 'tasks':
          result = await _syncService.syncTasks();
          break;
        case 'habits':
          result = await _syncService.syncHabits();
          break;
        case 'notes':
          result = await _syncService.syncNotes();
          break;
        case 'quotes':
          result = await _syncService.syncQuotes();
          break;
        case 'gamification':
          result = await _syncService.syncGamification();
          break;
        case 'timeTracking':
          result = await _syncService.syncTimeTracking();
          break;
        case 'books':
          result = await _syncService.syncBooks();
          break;
        default:
          result = SyncResult.error('Categoria desconhecida: $category');
      }

      final results = Map<String, SyncResult>.from(state.lastResults ?? {});
      results[category] = result;

      state = state.copyWith(
        isSyncing: false,
        lastResults: results,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Erro ao sincronizar $category: $e',
        currentOperation: null,
      );
    }
  }

  /// Limpa o erro
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtém o timestamp da última sincronização do servidor
  Future<DateTime?> getLastSyncFromServer() async {
    return await _syncService?.getLastSyncTimestamp();
  }
}

/// Provider para o SyncController
final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>(
  (ref) {
    final syncService = ref.watch(syncServiceProvider);
    return SyncController(syncService);
  },
);

// ============================================
// CONVENIENCE PROVIDERS
// ============================================

/// Provider para verificar se está sincronizando
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncControllerProvider).isSyncing;
});

/// Provider para a última hora de sincronização
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncControllerProvider).lastSyncTime;
});

/// Provider para verificar se sync está disponível
final isSyncAvailableProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && !user.isGuest;
});

/// Provider que executa sync automático quando o usuário faz login
final autoSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) return;

  // Verifica se há dados não sincronizados
  final hasUnsynced = await syncService.hasUnsyncedData();
  if (hasUnsynced) {
    // Sync automático em background
    await syncService.syncAll();
  }
});

/// Provider para verificar se precisa sincronizar
final needsSyncProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) return false;

  return await syncService.hasUnsyncedData();
});
