// lib/src/features/mood_records/data/mood_log/synced_mood_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';
import 'mood_record_repository.dart';

/// Repository wrapper que adiciona sincronização automática após operações CRUD
/// 
/// Este wrapper utiliza o MoodRecordRepository existente e adiciona
/// lógica de sincronização via fila offline quando o usuário está logado.
/// 
/// Mudanças são salvas localmente primeiro, depois enfileiradas para sync.
/// Quando online, a fila é processada automaticamente.
class SyncedMoodRepository with SyncedRepositoryMixin {
  final MoodRecordRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'moods';
  
  SyncedMoodRepository(this._localRepository, this.ref);
  
  /// Acesso direto ao box Hive (compatibilidade com código existente)
  Box<MoodRecord> get box => _localRepository.box;
  
  /// Cria um mood record e enfileira para sincronização
  Future<int> createMoodRecord(MoodRecord record) async {
    // Salva localmente primeiro (sempre funciona, mesmo offline)
    final key = await _localRepository.createMoodRecord(record);
    
    // Enfileira para sincronização em background
    await enqueueCreate(
      key.toString(),
      _moodRecordToMap(record, key.toString()),
    );
    
    return key;
  }
  
  /// Atualiza um mood record e enfileira para sincronização
  Future<void> updateMoodRecord(int key, MoodRecord record) async {
    await _localRepository.updateMoodRecord(key, record);
    
    await enqueueUpdate(
      key.toString(),
      _moodRecordToMap(record, key.toString()),
    );
  }
  
  /// Deleta um mood record e enfileira para sincronização
  Future<void> deleteMoodRecord(int key) async {
    await _localRepository.deleteMoodRecord(key);
    
    await enqueueDelete(key.toString());
  }
  
  /// Busca todos os mood records (apenas local)
  Map<dynamic, MoodRecord> fetchMoodRecords() {
    return _localRepository.fetchMoodRecords();
  }
  
  /// Busca mood records por data (apenas local)
  Map<dynamic, MoodRecord> fetchMoodRecordsByDate({
    required DateTime before,
    required DateTime after,
  }) {
    return _localRepository.fetchMoodRecordsByDate(before: before, after: after);
  }
  
  /// Converte MoodRecord para Map para sincronização
  Map<String, dynamic> _moodRecordToMap(MoodRecord mood, String key) {
    return {
      'id': key,
      'label': mood.label,
      'score': mood.score,
      'iconPath': mood.iconPath,
      'color': mood.color,
      'date': mood.date.toIso8601String(),
      'note': mood.note,
      'activities': mood.activities.map((a) => {
        'activityName': a.activityName,
        'iconCode': a.iconCode,
      }).toList(),
    };
  }
}

/// Provider para o SyncedMoodRepository
final syncedMoodRepositoryProvider = Provider<SyncedMoodRepository>((ref) {
  final localRepository = ref.watch(moodRecordRepositoryProvider);
  return SyncedMoodRepository(localRepository, ref);
});
