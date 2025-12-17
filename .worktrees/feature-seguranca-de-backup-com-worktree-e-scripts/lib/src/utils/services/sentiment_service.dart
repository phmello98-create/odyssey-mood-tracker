// lib/src/utils/services/sentiment_service.dart
// Serviço de análise de sentimento usando HuggingFace API

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Resultado da análise de sentimento
class SentimentResult {
  final String label; // positive, negative, neutral
  final double score; // 0.0 a 1.0
  final Map<String, double> allScores; // Todos os scores por label
  final DateTime analyzedAt;
  final String? originalText;

  SentimentResult({
    required this.label,
    required this.score,
    required this.allScores,
    required this.analyzedAt,
    this.originalText,
  });

  /// Converte para valor de humor (1-5)
  int toMoodValue() {
    if (label == 'positive') {
      if (score > 0.8) return 5;
      if (score > 0.6) return 4;
      return 4;
    } else if (label == 'negative') {
      if (score > 0.8) return 1;
      if (score > 0.6) return 2;
      return 2;
    }
    return 3; // neutral
  }

  /// Emoji representativo
  String get emoji {
    switch (label) {
      case 'positive':
        return score > 0.8 ? '😄' : '🙂';
      case 'negative':
        return score > 0.8 ? '😢' : '😕';
      default:
        return '😐';
    }
  }

  /// Descrição em português
  String get description {
    switch (label) {
      case 'positive':
        return score > 0.8 ? 'Muito Positivo' : 'Positivo';
      case 'negative':
        return score > 0.8 ? 'Muito Negativo' : 'Negativo';
      default:
        return 'Neutro';
    }
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'score': score,
        'allScores': allScores,
        'analyzedAt': analyzedAt.toIso8601String(),
        'moodValue': toMoodValue(),
      };

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      label: json['label'] as String,
      score: (json['score'] as num).toDouble(),
      allScores: Map<String, double>.from(
        (json['allScores'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

/// Serviço de análise de sentimento via HuggingFace
class SentimentService {
  static const String _apiUrl =
      'https://api-inference.huggingface.co/models/cardiffnlp/twitter-roberta-base-sentiment-latest';
  
  // Modelo multilíngue para português (correto)
  static const String _multilingualUrl =
      'https://api-inference.huggingface.co/models/cardiffnlp/twitter-xlm-roberta-base-sentiment-multilingual';

  final String _apiKey;
  final bool _useMultilingual;

  SentimentService({
    required String apiKey,
    bool useMultilingual = true, // Português = multilingual
  })  : _apiKey = apiKey,
        _useMultilingual = useMultilingual;

  /// Analisa o sentimento de um texto
  Future<SentimentResult?> analyze(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      final url = _useMultilingual ? _multilingualUrl : _apiUrl;
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResponse(data, text);
      } else if (response.statusCode == 503) {
        // Modelo carregando, tenta novamente
        debugPrint('Modelo carregando, aguardando...');
        await Future.delayed(const Duration(seconds: 2));
        return analyze(text);
      } else {
        debugPrint('Erro na API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao analisar sentimento: $e');
      return null;
    }
  }

  /// Analisa múltiplos textos em batch
  Future<List<SentimentResult?>> analyzeBatch(List<String> texts) async {
    final results = <SentimentResult?>[];
    
    // HuggingFace suporta batch, mas fazemos sequencial para evitar rate limit
    for (final text in texts) {
      final result = await analyze(text);
      results.add(result);
      
      // Pequeno delay para evitar rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  SentimentResult? _parseResponse(dynamic data, String originalText) {
    try {
      // A resposta vem como [[{label, score}, ...]]
      if (data is List && data.isNotEmpty) {
        final scores = data[0] as List;
        
        final allScores = <String, double>{};
        String topLabel = 'neutral';
        double topScore = 0.0;

        for (final item in scores) {
          final label = _normalizeLabel(item['label'] as String);
          final score = (item['score'] as num).toDouble();
          allScores[label] = score;
          
          if (score > topScore) {
            topScore = score;
            topLabel = label;
          }
        }

        return SentimentResult(
          label: topLabel,
          score: topScore,
          allScores: allScores,
          analyzedAt: DateTime.now(),
          originalText: originalText,
        );
      }
    } catch (e) {
      debugPrint('Erro ao parsear resposta: $e');
    }
    return null;
  }

  String _normalizeLabel(String label) {
    // Normaliza labels do modelo para nosso padrão
    final lower = label.toLowerCase();
    if (lower.contains('positive') || lower == 'positive') return 'positive';
    if (lower.contains('negative') || lower == 'negative') return 'negative';
    return 'neutral';
  }
}

/// Provider do serviço de sentimento
final sentimentServiceProvider = Provider<SentimentService>((ref) {
  // API Key do HuggingFace
  const apiKey = String.fromEnvironment(
    'HF_API_KEY',
    defaultValue: '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',
  );
  
  return SentimentService(
    apiKey: apiKey,
    useMultilingual: true, // App em português
  );
});

/// Provider para analisar texto sob demanda
final analyzeSentimentProvider = FutureProvider.family<SentimentResult?, String>(
  (ref, text) async {
    final service = ref.watch(sentimentServiceProvider);
    return service.analyze(text);
  },
);
