// lib/src/features/auth/services/synced_repository_mixin.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/auth_providers.dart';
import '../presentation/providers/sync_providers.dart';
import 'offline_sync_queue.dart';

/// Mixin que adiciona capacidade de sincronização a repositórios
/// 
/// Usar este mixin para:
/// 1. Enfileirar operações offline automaticamente
/// 2. Ouvir mudanças do Firestore (sync bidirecional)
/// 3. Gerenciar estado de sync por coleção
mixin SyncedRepositoryMixin {
  /// Referência ao Riverpod para acessar providers
  Ref get ref;
  
  /// Nome da coleção no Firestore
  String get collectionName;
  
  /// Verifica se o usuário pode sincronizar
  bool get canSync {
    final user = ref.read(currentUserProvider);
    return user != null && !user.isGuest && user.syncEnabled;
  }
  
  /// Enfileira uma operação de criação
  Future<void> enqueueCreate(String documentId, Map<String, dynamic> data) async {
    if (!canSync) return;
    
    try {
      final queue = ref.read(offlineSyncQueueProvider);
      if (queue != null) {
        await queue.enqueue(
          collection: collectionName,
          documentId: documentId,
          type: SyncOperationType.create,
          data: data,
        );
        debugPrint('[SyncedRepository] Enqueued CREATE: $collectionName/$documentId');
      }
    } catch (e) {
      debugPrint('[SyncedRepository] Error enqueueing create: $e');
    }
  }
  
  /// Enfileira uma operação de atualização
  Future<void> enqueueUpdate(String documentId, Map<String, dynamic> data) async {
    if (!canSync) return;
    
    try {
      final queue = ref.read(offlineSyncQueueProvider);
      if (queue != null) {
        await queue.enqueue(
          collection: collectionName,
          documentId: documentId,
          type: SyncOperationType.update,
          data: data,
        );
        debugPrint('[SyncedRepository] Enqueued UPDATE: $collectionName/$documentId');
      }
    } catch (e) {
      debugPrint('[SyncedRepository] Error enqueueing update: $e');
    }
  }
  
  /// Enfileira uma operação de deleção
  Future<void> enqueueDelete(String documentId) async {
    if (!canSync) return;
    
    try {
      final queue = ref.read(offlineSyncQueueProvider);
      if (queue != null) {
        await queue.enqueue(
          collection: collectionName,
          documentId: documentId,
          type: SyncOperationType.delete,
        );
        debugPrint('[SyncedRepository] Enqueued DELETE: $collectionName/$documentId');
      }
    } catch (e) {
      debugPrint('[SyncedRepository] Error enqueueing delete: $e');
    }
  }
  
  /// Sincroniza imediatamente a coleção inteira (útil para primeira migração)
  Future<void> syncImmediately() async {
    if (!canSync) return;
    
    try {
      final syncController = ref.read(syncControllerProvider.notifier);
      await syncController.syncCategory(collectionName);
    } catch (e) {
      debugPrint('[SyncedRepository] Error in immediate sync: $e');
    }
  }
}

/// Extensão para converter objetos comuns para Map com timestamp
extension SyncDataExtension on Map<String, dynamic> {
  /// Adiciona timestamp de modificação local
  Map<String, dynamic> withLocalTimestamp() {
    return {
      ...this,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}
