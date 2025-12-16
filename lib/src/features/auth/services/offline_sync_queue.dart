// lib/src/features/auth/services/offline_sync_queue.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de operações na fila
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Uma operação pendente na fila de sincronização
class PendingSyncOperation {
  final String id;
  final String collection;
  final String documentId;
  final SyncOperationType type;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime localModifiedAt;
  final int retryCount;
  final String? errorMessage;

  PendingSyncOperation({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
    required this.createdAt,
    required this.localModifiedAt,
    this.retryCount = 0,
    this.errorMessage,
  });

  PendingSyncOperation copyWith({
    int? retryCount,
    String? errorMessage,
  }) {
    return PendingSyncOperation(
      id: id,
      collection: collection,
      documentId: documentId,
      type: type,
      data: data,
      createdAt: createdAt,
      localModifiedAt: localModifiedAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'documentId': documentId,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'localModifiedAt': localModifiedAt.toIso8601String(),
        'retryCount': retryCount,
        'errorMessage': errorMessage,
      };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      collection: json['collection'] as String,
      documentId: json['documentId'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.update,
      ),
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      localModifiedAt: DateTime.parse(json['localModifiedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Estratégia de resolução de conflitos
enum ConflictResolutionStrategy {
  /// Última escrita ganha (padrão atual)
  lastWriteWins,
  
  /// Servidor ganha sempre
  serverWins,
  
  /// Cliente ganha sempre
  clientWins,
  
  /// Merge de campos (mantém ambos)
  merge,
}

/// Resultado da resolução de conflito
class ConflictResolution {
  final bool hasConflict;
  final Map<String, dynamic>? resolvedData;
  final String? conflictDescription;

  const ConflictResolution({
    required this.hasConflict,
    this.resolvedData,
    this.conflictDescription,
  });

  factory ConflictResolution.noConflict(Map<String, dynamic> data) =>
      ConflictResolution(hasConflict: false, resolvedData: data);

  factory ConflictResolution.resolved(Map<String, dynamic> data, String description) =>
      ConflictResolution(
        hasConflict: true,
        resolvedData: data,
        conflictDescription: description,
      );
}

/// Serviço de fila de sincronização offline
/// 
/// Recursos:
/// - Enfileira operações quando offline
/// - Sincroniza automaticamente quando volta online
/// - Resolução de conflitos baseada em timestamps
/// - Retry com backoff exponencial
class OfflineSyncQueue {
  final FirebaseFirestore _firestore;
  final String userId;
  final ConflictResolutionStrategy strategy;

  // Nome do box Hive para persistir a fila
  static const String _queueBoxName = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  // Configurações de retry
  static const int maxRetries = 5;
  static const Duration initialRetryDelay = Duration(seconds: 2);

  // Stream controllers
  final _syncStatusController = StreamController<SyncQueueStatus>.broadcast();
  final _connectivityController = StreamController<bool>.broadcast();

  // Estado interno
  bool _isSyncing = false;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  Box? _queueBox;

  OfflineSyncQueue({
    required FirebaseFirestore firestore,
    required this.userId,
    this.strategy = ConflictResolutionStrategy.lastWriteWins,
  }) : _firestore = firestore;

  /// Stream do status da sincronização
  Stream<SyncQueueStatus> get statusStream => _syncStatusController.stream;

  /// Stream do status de conectividade
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Inicializa o serviço
  Future<void> initialize() async {
    // Abrir box da fila
    _queueBox = await Hive.openBox(_queueBoxName);

    // Monitorar conectividade
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    // Verificar conectividade inicial
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResult.contains(ConnectivityResult.none);

    // Se online e houver itens na fila, sincronizar
    if (_isOnline && pendingCount > 0) {
      _scheduleSyncRetry();
    }

    debugPrint('[OfflineSyncQueue] Initialized. Pending: $pendingCount, Online: $_isOnline');
  }

  /// Quantidade de operações pendentes
  int get pendingCount => _queueBox?.length ?? 0;

  /// Se está sincronizando
  bool get isSyncing => _isSyncing;

  /// Se está online
  bool get isOnline => _isOnline;

  /// Adiciona uma operação à fila
  Future<void> enqueue({
    required String collection,
    required String documentId,
    required SyncOperationType type,
    Map<String, dynamic>? data,
  }) async {
    final operation = PendingSyncOperation(
      id: '${collection}_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
      collection: collection,
      documentId: documentId,
      type: type,
      data: data != null
          ? {
              ...data,
              '_localModifiedAt': DateTime.now().toIso8601String(),
            }
          : null,
      createdAt: DateTime.now(),
      localModifiedAt: DateTime.now(),
    );

    await _queueBox?.put(operation.id, jsonEncode(operation.toJson()));

    debugPrint('[OfflineSyncQueue] Enqueued: ${operation.type.name} ${operation.collection}/${operation.documentId}');

    _emitStatus();

    // Se online, tentar sincronizar imediatamente
    if (_isOnline && !_isSyncing) {
      _scheduleSyncRetry(immediate: true);
    }
  }

  /// Processa a fila de sincronização
  Future<SyncQueueResult> processQueue() async {
    if (_isSyncing) {
      return const SyncQueueResult(
        success: false,
        message: 'Sincronização já em andamento',
      );
    }

    if (!_isOnline) {
      return const SyncQueueResult(
        success: false,
        message: 'Sem conexão com a internet',
      );
    }

    if (pendingCount == 0) {
      return const SyncQueueResult(success: true, processed: 0, failed: 0);
    }

    _isSyncing = true;
    _emitStatus();

    int processed = 0;
    int failed = 0;
    final failedOperations = <PendingSyncOperation>[];

    try {
      final keys = _queueBox?.keys.toList() ?? [];

      for (final key in keys) {
        final jsonStr = _queueBox?.get(key) as String?;
        if (jsonStr == null) continue;

        final operation = PendingSyncOperation.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );

        try {
          await _processOperation(operation);
          await _queueBox?.delete(key);
          processed++;
          debugPrint('[OfflineSyncQueue] Processed: ${operation.collection}/${operation.documentId}');
        } catch (e) {
          debugPrint('[OfflineSyncQueue] Failed: ${operation.collection}/${operation.documentId} - $e');

          if (operation.retryCount < maxRetries) {
            // Atualizar retry count
            final updated = operation.copyWith(
              retryCount: operation.retryCount + 1,
              errorMessage: e.toString(),
            );
            await _queueBox?.put(key, jsonEncode(updated.toJson()));
            failedOperations.add(updated);
          } else {
            // Excedeu retries, remover da fila (ou mover para dead letter queue)
            await _queueBox?.delete(key);
            debugPrint('[OfflineSyncQueue] Max retries exceeded, removing: ${operation.id}');
          }
          failed++;
        }
      }

      // Atualizar timestamp da última sincronização
      if (processed > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      }

      debugPrint('[OfflineSyncQueue] Sync complete. Processed: $processed, Failed: $failed');

      return SyncQueueResult(
        success: failed == 0,
        processed: processed,
        failed: failed,
        failedOperations: failedOperations,
      );
    } finally {
      _isSyncing = false;
      _emitStatus();

      // Se ainda houver itens na fila, agendar retry
      if (pendingCount > 0) {
        _scheduleSyncRetry();
      }
    }
  }

  /// Processa uma operação individual
  Future<void> _processOperation(PendingSyncOperation operation) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(operation.collection)
        .doc(operation.documentId);

    switch (operation.type) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        if (operation.data == null) {
          throw Exception('Data is required for create/update operations');
        }

        // Resolver conflitos
        final resolution = await _resolveConflict(docRef, operation);

        if (resolution.resolvedData != null) {
          // Adicionar metadata de sincronização
          final dataToSave = {
            ...resolution.resolvedData!,
            '_syncedAt': FieldValue.serverTimestamp(),
            '_syncedFrom': 'offline_queue',
          };

          await docRef.set(dataToSave, SetOptions(merge: true));

          if (resolution.hasConflict) {
            debugPrint('[OfflineSyncQueue] Conflict resolved: ${resolution.conflictDescription}');
          }
        }
        break;

      case SyncOperationType.delete:
        await docRef.delete();
        break;
    }
  }

  /// Resolve conflitos entre dados locais e do servidor
  Future<ConflictResolution> _resolveConflict(
    DocumentReference docRef,
    PendingSyncOperation operation,
  ) async {
    final localData = operation.data!;
    final localModifiedAt = operation.localModifiedAt;

    // Buscar dados do servidor
    final serverDoc = await docRef.get();

    if (!serverDoc.exists) {
      // Documento não existe no servidor, sem conflito
      return ConflictResolution.noConflict(localData);
    }

    final serverData = serverDoc.data() as Map<String, dynamic>?;
    if (serverData == null) {
      return ConflictResolution.noConflict(localData);
    }

    // Verificar timestamp do servidor
    DateTime? serverModifiedAt;
    if (serverData['_syncedAt'] != null) {
      if (serverData['_syncedAt'] is Timestamp) {
        serverModifiedAt = (serverData['_syncedAt'] as Timestamp).toDate();
      }
    } else if (serverData['_localModifiedAt'] != null) {
      serverModifiedAt = DateTime.tryParse(serverData['_localModifiedAt'] as String);
    }

    // Se não há timestamp do servidor, local ganha
    if (serverModifiedAt == null) {
      return ConflictResolution.noConflict(localData);
    }

    // Há conflito se servidor foi modificado depois que enfileiramos
    final hasConflict = serverModifiedAt.isAfter(localModifiedAt);

    if (!hasConflict) {
      return ConflictResolution.noConflict(localData);
    }

    // Resolver baseado na estratégia
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        // Compara timestamps, o mais recente ganha
        if (localModifiedAt.isAfter(serverModifiedAt)) {
          return ConflictResolution.resolved(
            localData,
            'Local mais recente, usando dados locais',
          );
        } else {
          // Servidor ganha, não sobrescrever
          return ConflictResolution.resolved(
            serverData,
            'Servidor mais recente, mantendo dados do servidor',
          );
        }

      case ConflictResolutionStrategy.serverWins:
        return ConflictResolution.resolved(
          serverData,
          'Estratégia: servidor sempre ganha',
        );

      case ConflictResolutionStrategy.clientWins:
        return ConflictResolution.resolved(
          localData,
          'Estratégia: cliente sempre ganha',
        );

      case ConflictResolutionStrategy.merge:
        // Merge inteligente: combina campos de ambos
        final merged = _mergeData(serverData, localData, localModifiedAt);
        return ConflictResolution.resolved(
          merged,
          'Dados mesclados de servidor e cliente',
        );
    }
  }

  /// Faz merge inteligente de dados
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> serverData,
    Map<String, dynamic> localData,
    DateTime localModifiedAt,
  ) {
    final merged = Map<String, dynamic>.from(serverData);

    for (final entry in localData.entries) {
      final key = entry.key;
      final localValue = entry.value;

      // Ignorar campos de metadata
      if (key.startsWith('_')) continue;

      // Se servidor não tem o campo, usar local
      if (!serverData.containsKey(key)) {
        merged[key] = localValue;
        continue;
      }

      final serverValue = serverData[key];

      // Se valores são iguais, ignorar
      if (serverValue == localValue) continue;

      // Para listas, fazer union
      if (localValue is List && serverValue is List) {
        final unionSet = {...serverValue, ...localValue};
        merged[key] = unionSet.toList();
        continue;
      }

      // Para maps, merge recursivo
      if (localValue is Map && serverValue is Map) {
        merged[key] = _mergeData(
          Map<String, dynamic>.from(serverValue),
          Map<String, dynamic>.from(localValue),
          localModifiedAt,
        );
        continue;
      }

      // Para outros valores, usar o local (mais recente do ponto de vista do usuário)
      merged[key] = localValue;
    }

    merged['_mergedAt'] = DateTime.now().toIso8601String();
    return merged;
  }

  /// Lida com mudanças de conectividade
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    _connectivityController.add(_isOnline);

    debugPrint('[OfflineSyncQueue] Connectivity changed: $_isOnline');

    // Se voltou online e há itens na fila, sincronizar
    if (!wasOnline && _isOnline && pendingCount > 0) {
      debugPrint('[OfflineSyncQueue] Back online, starting sync...');
      _scheduleSyncRetry(immediate: true);
    }

    _emitStatus();
  }

  /// Agenda retry de sincronização com backoff exponencial
  void _scheduleSyncRetry({bool immediate = false}) {
    _syncTimer?.cancel();

    final delay = immediate ? Duration.zero : _calculateBackoff();

    _syncTimer = Timer(delay, () async {
      if (_isOnline && !_isSyncing && pendingCount > 0) {
        await processQueue();
      }
    });

    if (!immediate) {
      debugPrint('[OfflineSyncQueue] Retry scheduled in ${delay.inSeconds}s');
    }
  }

  /// Calcula delay com backoff exponencial
  Duration _calculateBackoff() {
    // Encontrar maior retry count na fila
    int maxRetryCount = 0;
    for (final key in _queueBox?.keys ?? []) {
      final jsonStr = _queueBox?.get(key) as String?;
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final retryCount = data['retryCount'] as int? ?? 0;
        if (retryCount > maxRetryCount) maxRetryCount = retryCount;
      }
    }

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final multiplier = (1 << maxRetryCount).clamp(1, 16);
    return initialRetryDelay * multiplier;
  }

  /// Emite status atual
  void _emitStatus() {
    _syncStatusController.add(SyncQueueStatus(
      pendingCount: pendingCount,
      isSyncing: _isSyncing,
      isOnline: _isOnline,
    ));
  }

  /// Limpa toda a fila (use com cuidado!)
  Future<void> clearQueue() async {
    await _queueBox?.clear();
    _emitStatus();
    debugPrint('[OfflineSyncQueue] Queue cleared');
  }

  /// Obtém timestamp da última sincronização
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastSyncKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Libera recursos
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _connectivityController.close();
  }
}

/// Status da fila de sincronização
class SyncQueueStatus {
  final int pendingCount;
  final bool isSyncing;
  final bool isOnline;

  const SyncQueueStatus({
    required this.pendingCount,
    required this.isSyncing,
    required this.isOnline,
  });

  bool get hasPending => pendingCount > 0;
  bool get canSync => isOnline && !isSyncing && hasPending;
}

/// Resultado do processamento da fila
class SyncQueueResult {
  final bool success;
  final int processed;
  final int failed;
  final String? message;
  final List<PendingSyncOperation> failedOperations;

  const SyncQueueResult({
    required this.success,
    this.processed = 0,
    this.failed = 0,
    this.message,
    this.failedOperations = const [],
  });
}
