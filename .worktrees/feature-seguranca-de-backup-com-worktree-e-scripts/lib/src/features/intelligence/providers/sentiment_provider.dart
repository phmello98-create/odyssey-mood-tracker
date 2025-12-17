import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/huggingface_service.dart';

/// Provider da API Key do HuggingFace
/// Configure em: Settings > AI > HuggingFace API Key
final huggingFaceApiKeyProvider = StateProvider<String?>((ref) {
  // TODO: Carregar de secure storage
  return null;
});

/// Provider do serviço HuggingFace
final huggingFaceServiceProvider = Provider<HuggingFaceService?>((ref) {
  final apiKey = ref.watch(huggingFaceApiKeyProvider);
  
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }
  
  final service = HuggingFaceService(apiKey: apiKey);
  ref.onDispose(() => service.dispose());
  
  return service;
});

/// Provider do serviço híbrido (local + cloud)
final hybridSentimentServiceProvider = Provider<HybridSentimentService>((ref) {
  final apiKey = ref.watch(huggingFaceApiKeyProvider);
  
  final service = HybridSentimentService(
    huggingFaceApiKey: apiKey,
    useCloud: apiKey != null && apiKey.isNotEmpty,
  );
  
  ref.onDispose(() => service.dispose());
  
  return service;
});

/// Provider para analisar um texto específico
final sentimentAnalysisProvider = FutureProvider.family<SentimentResult?, String>((ref, text) async {
  final service = ref.watch(hybridSentimentServiceProvider);
  return service.analyze(text);
});

/// Estado para análise de múltiplos textos (notas do diário)
class DiaryAnalysisNotifier extends StateNotifier<AsyncValue<Map<String, SentimentResult>>> {
  final HybridSentimentService _service;
  
  DiaryAnalysisNotifier(this._service) : super(const AsyncValue.data({}));
  
  /// Analisa todas as notas pendentes
  Future<void> analyzeNotes(Map<String, String> notes) async {
    state = const AsyncValue.loading();
    
    try {
      final results = <String, SentimentResult>{};
      
      for (final entry in notes.entries) {
        final result = await _service.analyze(entry.value);
        results[entry.key] = result;
      }
      
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// Analisa uma nota individual e adiciona ao estado
  Future<SentimentResult?> analyzeNote(String noteId, String text) async {
    try {
      final result = await _service.analyze(text);
      
      state = AsyncValue.data({
        ...state.value ?? {},
        noteId: result,
      });
      
      return result;
    } catch (_) {
      return null;
    }
  }
}

/// Provider para análise de notas do diário
final diaryAnalysisProvider = StateNotifierProvider<DiaryAnalysisNotifier, AsyncValue<Map<String, SentimentResult>>>((ref) {
  final service = ref.watch(hybridSentimentServiceProvider);
  return DiaryAnalysisNotifier(service);
});
