// lib/src/utils/services/note_intelligence_service.dart
// Integração do Sentiment Analysis com Notas e Intelligence System

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sentiment_service.dart';

/// Dados de inteligência associados a uma nota
class NoteIntelligence {
  final String noteId;
  final SentimentResult? sentiment;
  final List<String> extractedTopics;
  final List<String> suggestedTags;
  final int? suggestedMoodValue;
  final DateTime analyzedAt;
  final Map<String, dynamic>? additionalInsights;

  NoteIntelligence({
    required this.noteId,
    this.sentiment,
    this.extractedTopics = const [],
    this.suggestedTags = const [],
    this.suggestedMoodValue,
    required this.analyzedAt,
    this.additionalInsights,
  });

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'sentiment': sentiment?.toJson(),
        'extractedTopics': extractedTopics,
        'suggestedTags': suggestedTags,
        'suggestedMoodValue': suggestedMoodValue,
        'analyzedAt': analyzedAt.toIso8601String(),
        'additionalInsights': additionalInsights,
      };

  factory NoteIntelligence.fromJson(Map<String, dynamic> json) {
    return NoteIntelligence(
      noteId: json['noteId'] as String,
      sentiment: json['sentiment'] != null
          ? SentimentResult.fromJson(
              Map<String, dynamic>.from(json['sentiment'] as Map))
          : null,
      extractedTopics: List<String>.from(json['extractedTopics'] ?? []),
      suggestedTags: List<String>.from(json['suggestedTags'] ?? []),
      suggestedMoodValue: json['suggestedMoodValue'] as int?,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      additionalInsights: json['additionalInsights'] != null
          ? Map<String, dynamic>.from(json['additionalInsights'] as Map)
          : null,
    );
  }
}

/// Resumo de sentimentos de todas as notas
class SentimentSummary {
  final int totalNotes;
  final int positiveCount;
  final int negativeCount;
  final int neutralCount;
  final double averageSentiment; // -1 a 1
  final Map<String, int> topicsFrequency;
  final List<TrendPoint> sentimentTrend;

  SentimentSummary({
    required this.totalNotes,
    required this.positiveCount,
    required this.negativeCount,
    required this.neutralCount,
    required this.averageSentiment,
    required this.topicsFrequency,
    required this.sentimentTrend,
  });

  double get positivePercentage =>
      totalNotes > 0 ? (positiveCount / totalNotes) * 100 : 0;
  double get negativePercentage =>
      totalNotes > 0 ? (negativeCount / totalNotes) * 100 : 0;
  double get neutralPercentage =>
      totalNotes > 0 ? (neutralCount / totalNotes) * 100 : 0;

  String get overallMood {
    if (averageSentiment > 0.3) return 'Positivo';
    if (averageSentiment < -0.3) return 'Negativo';
    return 'Equilibrado';
  }
}

class TrendPoint {
  final DateTime date;
  final double sentiment;
  final int noteCount;

  TrendPoint({
    required this.date,
    required this.sentiment,
    required this.noteCount,
  });
}

/// Serviço que gerencia a inteligência das notas
class NoteIntelligenceService {
  static const String _boxName = 'note_intelligence';
  final SentimentService _sentimentService;
  Box? _box;
  bool _initialized = false;

  NoteIntelligenceService(this._sentimentService);

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing NoteIntelligenceService: $e');
    }
  }

  /// Analisa uma nota e armazena os resultados
  Future<NoteIntelligence?> analyzeNote(
    String noteId,
    String content, {
    String? title,
  }) async {
    await _ensureInitialized();

    // Combina título e conteúdo para análise
    final textToAnalyze = [
      if (title != null && title.isNotEmpty) title,
      content,
    ].join('. ');

    // Analisa sentimento
    final sentiment = await _sentimentService.analyze(textToAnalyze);

    // Extrai tópicos (palavras-chave simples por enquanto)
    final topics = _extractTopics(textToAnalyze);

    // Sugere tags baseadas no conteúdo
    final suggestedTags = _suggestTags(textToAnalyze, sentiment);

    final intelligence = NoteIntelligence(
      noteId: noteId,
      sentiment: sentiment,
      extractedTopics: topics,
      suggestedTags: suggestedTags,
      suggestedMoodValue: sentiment?.toMoodValue(),
      analyzedAt: DateTime.now(),
      additionalInsights: {
        'wordCount': textToAnalyze.split(' ').length,
        'hasTitle': title != null && title.isNotEmpty,
      },
    );

    // Salva no Hive
    await _box?.put(noteId, intelligence.toJson());

    return intelligence;
  }

  /// Obtém a inteligência de uma nota específica
  NoteIntelligence? getIntelligence(String noteId) {
    if (!_initialized || _box == null) return null;
    
    final data = _box!.get(noteId);
    if (data == null) return null;
    
    return NoteIntelligence.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Obtém todas as análises
  List<NoteIntelligence> getAllIntelligence() {
    if (!_initialized || _box == null) return [];
    
    return _box!.values
        .map((e) => NoteIntelligence.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gera resumo de sentimentos
  SentimentSummary getSentimentSummary({int? lastDays}) {
    final all = getAllIntelligence();
    
    final filtered = lastDays != null
        ? all.where((i) =>
            i.analyzedAt.isAfter(DateTime.now().subtract(Duration(days: lastDays))))
            .toList()
        : all;

    int positive = 0;
    int negative = 0;
    int neutral = 0;
    double totalSentiment = 0;
    final topicsMap = <String, int>{};

    for (final intel in filtered) {
      if (intel.sentiment != null) {
        switch (intel.sentiment!.label) {
          case 'positive':
            positive++;
            totalSentiment += intel.sentiment!.score;
            break;
          case 'negative':
            negative++;
            totalSentiment -= intel.sentiment!.score;
            break;
          default:
            neutral++;
        }
      }

      for (final topic in intel.extractedTopics) {
        topicsMap[topic] = (topicsMap[topic] ?? 0) + 1;
      }
    }

    // Calcula tendência por dia
    final trendMap = <String, List<double>>{};
    for (final intel in filtered) {
      if (intel.sentiment != null) {
        final dateKey = '${intel.analyzedAt.year}-${intel.analyzedAt.month}-${intel.analyzedAt.day}';
        trendMap.putIfAbsent(dateKey, () => []);
        
        final value = intel.sentiment!.label == 'positive'
            ? intel.sentiment!.score
            : intel.sentiment!.label == 'negative'
                ? -intel.sentiment!.score
                : 0.0;
        trendMap[dateKey]!.add(value);
      }
    }

    final trend = trendMap.entries.map((e) {
      final parts = e.key.split('-');
      return TrendPoint(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        sentiment: e.value.reduce((a, b) => a + b) / e.value.length,
        noteCount: e.value.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SentimentSummary(
      totalNotes: filtered.length,
      positiveCount: positive,
      negativeCount: negative,
      neutralCount: neutral,
      averageSentiment: filtered.isNotEmpty ? totalSentiment / filtered.length : 0,
      topicsFrequency: topicsMap,
      sentimentTrend: trend,
    );
  }

  /// Extrai tópicos/palavras-chave do texto
  List<String> _extractTopics(String text) {
    // Lista de stopwords em português
    const stopwords = {
      'a', 'o', 'e', 'de', 'da', 'do', 'que', 'em', 'para', 'com', 'não',
      'uma', 'um', 'os', 'as', 'por', 'mais', 'como', 'mas', 'ao',
      'ele', 'ela', 'isso', 'este', 'esta', 'esse', 'essa', 'seu', 'sua',
      'ou', 'ser', 'quando', 'muito', 'há', 'nos', 'já', 'está', 'eu',
      'também', 'só', 'pelo', 'pela', 'até', 'entre',
      'depois', 'sem', 'mesmo', 'aos', 'ter', 'seus', 'quem', 'nas',
      'me', 'eles', 'você', 'num', 'nem', 'suas', 'meu',
      'minha', 'numa', 'pelos', 'elas', 'qual', 'nós', 'lhe', 'deles',
      'hoje', 'dia', 'fui', 'foi', 'estou', 'estava', 'tinha', 'tenho',
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sáàâãéèêíìîóòôõúùûç]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !stopwords.contains(w))
        .toList();

    // Conta frequência
    final frequency = <String, int>{};
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Retorna os 5 mais frequentes
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Sugere tags baseadas no conteúdo e sentimento
  List<String> _suggestTags(String text, SentimentResult? sentiment) {
    final tags = <String>[];
    final lower = text.toLowerCase();

    // Tags baseadas em categorias detectadas
    final categories = {
      'trabalho': ['trabalho', 'reunião', 'projeto', 'escritório', 'chefe', 'cliente'],
      'saúde': ['exercício', 'academia', 'médico', 'saúde', 'doente', 'remédio'],
      'família': ['família', 'mãe', 'pai', 'filho', 'filha', 'irmão', 'irmã'],
      'relacionamento': ['namorado', 'namorada', 'amor', 'relacionamento', 'casal'],
      'estudo': ['estudo', 'prova', 'faculdade', 'escola', 'curso', 'aula'],
      'lazer': ['filme', 'série', 'jogo', 'passeio', 'viagem', 'festa'],
      'finanças': ['dinheiro', 'conta', 'salário', 'compra', 'gasto'],
      'reflexão': ['pensei', 'refleti', 'percebi', 'aprendi', 'entendi'],
    };

    for (final entry in categories.entries) {
      if (entry.value.any((word) => lower.contains(word))) {
        tags.add(entry.key);
      }
    }

    // Tag baseada no sentimento
    if (sentiment != null) {
      if (sentiment.label == 'positive' && sentiment.score > 0.7) {
        tags.add('dia-bom');
      } else if (sentiment.label == 'negative' && sentiment.score > 0.7) {
        tags.add('dia-difícil');
      }
    }

    return tags.take(5).toList();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Remove análise de uma nota deletada
  Future<void> deleteIntelligence(String noteId) async {
    await _ensureInitialized();
    await _box?.delete(noteId);
  }
}

/// Provider do serviço de inteligência de notas
final noteIntelligenceServiceProvider = Provider<NoteIntelligenceService>((ref) {
  final sentimentService = ref.watch(sentimentServiceProvider);
  return NoteIntelligenceService(sentimentService);
});

/// Provider para resumo de sentimentos
final sentimentSummaryProvider = FutureProvider<SentimentSummary>((ref) async {
  final service = ref.watch(noteIntelligenceServiceProvider);
  await service.initialize();
  return service.getSentimentSummary(lastDays: 30);
});

/// Provider para analisar uma nota específica
final analyzeNoteProvider =
    FutureProvider.family<NoteIntelligence?, (String, String, String?)>(
  (ref, params) async {
    final (noteId, content, title) = params;
    final service = ref.watch(noteIntelligenceServiceProvider);
    await service.initialize();
    return service.analyzeNote(noteId, content, title: title);
  },
);
