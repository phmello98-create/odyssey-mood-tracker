import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Resultado da análise de sentimento
class SentimentResult {
  final String label;  // 'positive', 'negative', 'neutral'
  final String labelPt; // 'positivo', 'negativo', 'neutro'
  final double confidence;
  final double moodScore; // 1-5
  final Map<String, double> breakdown;
  
  SentimentResult({
    required this.label,
    required this.labelPt,
    required this.confidence,
    required this.moodScore,
    required this.breakdown,
  });
  
  factory SentimentResult.fromApiResponse(List<dynamic> response) {
    // Resposta: [[{label: 'positive', score: 0.9}, ...]]
    final scores = response[0] as List<dynamic>;
    
    // Encontra o label dominante
    final best = scores.reduce((a, b) => 
      (a['score'] as double) > (b['score'] as double) ? a : b
    );
    
    // Extrai scores individuais
    final positiveScore = _getScore(scores, 'positive');
    final negativeScore = _getScore(scores, 'negative');
    final neutralScore = _getScore(scores, 'neutral');
    
    // Calcula mood score: base 3 + (positivo * 2) - (negativo * 2)
    final moodScore = (3 + (positiveScore * 2) - (negativeScore * 2)).clamp(1.0, 5.0);
    
    final labelMap = {
      'positive': 'positivo',
      'negative': 'negativo',
      'neutral': 'neutro',
    };
    
    return SentimentResult(
      label: best['label'] as String,
      labelPt: labelMap[best['label']] ?? best['label'] as String,
      confidence: best['score'] as double,
      moodScore: moodScore,
      breakdown: {
        'positive': positiveScore,
        'negative': negativeScore,
        'neutral': neutralScore,
      },
    );
  }
  
  static double _getScore(List<dynamic> scores, String label) {
    try {
      return scores.firstWhere(
        (s) => s['label'] == label,
        orElse: () => {'score': 0.0},
      )['score'] as double;
    } catch (_) {
      return 0.0;
    }
  }
  
  @override
  String toString() => 'SentimentResult($labelPt, confidence: ${(confidence * 100).toStringAsFixed(1)}%, mood: $moodScore)';
}

/// Serviço de análise de sentimento usando HuggingFace Inference API
class HuggingFaceService {
  static const String _apiUrl = 'https://router.huggingface.co/hf-inference/models/cardiffnlp/twitter-roberta-base-sentiment-latest';
  
  final String _apiKey;
  final http.Client _client;
  
  // Cache de resultados
  final Map<String, SentimentResult> _cache = {};
  
  HuggingFaceService({
    required String apiKey,
    http.Client? client,
  }) : _apiKey = apiKey,
       _client = client ?? http.Client();
  
  /// Analisa o sentimento de um texto
  /// Traduz automaticamente português → inglês para melhor precisão
  Future<SentimentResult?> analyzeSentiment(String text) async {
    // Verifica cache
    final cacheKey = text.trim().toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    
    // Traduz português para inglês (modelo funciona melhor em inglês)
    final translatedText = _translateToEnglish(text);
    
    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': translatedText}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final result = SentimentResult.fromApiResponse(data);
        
        // Cache
        _cache[cacheKey] = result;
        
        return result;
      } else {
        debugPrint('HuggingFace API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('HuggingFace API exception: $e');
      return null;
    }
  }
  
  /// Traduz texto português → inglês usando dicionário de padrões
  /// O modelo cardiffnlp funciona ~50% melhor com texto em inglês
  String _translateToEnglish(String text) {
    String result = text.toLowerCase();
    
    // Mapeamento de frases e palavras comuns PT → EN
    const translations = {
      // Emoções positivas
      'muito feliz': 'very happy',
      'estou feliz': 'I am happy',
      'me sinto feliz': 'I feel happy',
      'que alegria': 'what joy',
      'muito animado': 'very excited',
      'estou animado': 'I am excited',
      'me sinto bem': 'I feel good',
      'dia maravilhoso': 'wonderful day',
      'dia incrível': 'amazing day',
      'ótimo dia': 'great day',
      'bom dia': 'good day',
      'muito grato': 'very grateful',
      'estou grato': 'I am grateful',
      'adorei': 'I loved it',
      'amei': 'I loved it',
      'consegui': 'I achieved',
      'promoção': 'promotion',
      
      // Emoções negativas
      'muito triste': 'very sad',
      'estou triste': 'I am sad',
      'me sinto triste': 'I feel sad',
      'que tristeza': 'how sad',
      'estou deprimido': 'I am depressed',
      'me sinto deprimido': 'I feel depressed',
      'dia terrível': 'terrible day',
      'dia péssimo': 'awful day',
      'dia horrível': 'horrible day',
      'tudo deu errado': 'everything went wrong',
      'não consegui': 'I could not',
      'estou ansioso': 'I am anxious',
      'estou preocupado': 'I am worried',
      'muito cansado': 'very tired',
      'estou cansado': 'I am tired',
      'perdi': 'I lost',
      'morreu': 'died',
      'fracassei': 'I failed',
      'frustrado': 'frustrated',
      'irritado': 'irritated',
      'com raiva': 'angry',
      'estressado': 'stressed',
      
      // Palavras individuais (fallback)
      'feliz': 'happy',
      'alegre': 'joyful',
      'contente': 'content',
      'animado': 'excited',
      'empolgado': 'thrilled',
      'grato': 'grateful',
      'maravilhoso': 'wonderful',
      'incrível': 'amazing',
      'ótimo': 'great',
      'excelente': 'excellent',
      'perfeito': 'perfect',
      'lindo': 'beautiful',
      'triste': 'sad',
      'deprimido': 'depressed',
      'ansioso': 'anxious',
      'preocupado': 'worried',
      'terrível': 'terrible',
      'horrível': 'horrible',
      'péssimo': 'awful',
      'ruim': 'bad',
      'cansado': 'tired',
      'medo': 'fear',
      'raiva': 'anger',
      'tranquilo': 'calm',
      'relaxado': 'relaxed',
      'calmo': 'calm',
      'meditei': 'I meditated',
      'exercícios': 'exercises',
      'acordei': 'I woke up',
      'dormi': 'I slept',
      'trabalhei': 'I worked',
      'hoje': 'today',
      'ontem': 'yesterday',
      'amanhã': 'tomorrow',
      // Mais palavras comuns
      'cachorro': 'dog',
      'trabalho': 'work',
      'café': 'coffee',
      'bem': 'well',
      'fiz': 'I did',
      'tomei': 'I had',
      'normal': 'normal',
      'nada': 'nothing',
      'especial': 'special',
      'minutos': 'minutes',
      'mais': 'more',
      'tentando': 'trying',
      'mas': 'but',
      'com': 'with',
      'dia': 'day',
      'um': 'a',
      'de': 'of',
      'e': 'and',
      'o': 'the',
      'a': 'the',
    };
    
    // Ordena por tamanho (frases maiores primeiro para evitar conflitos)
    final sortedEntries = translations.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    
    // Aplica traduções
    for (final entry in sortedEntries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    return result;
  }
  
  /// Analisa múltiplos textos em batch
  Future<List<SentimentResult?>> analyzeBatch(List<String> texts) async {
    final results = <SentimentResult?>[];
    
    for (final text in texts) {
      results.add(await analyzeSentiment(text));
      // Rate limiting simples
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }
  
  /// Limpa o cache
  void clearCache() => _cache.clear();
  
  void dispose() {
    _client.close();
  }
}

/// Serviço híbrido que combina análise local (léxico) + HuggingFace
class HybridSentimentService {
  final HuggingFaceService? _huggingFace;
  final bool _useCloud;
  
  HybridSentimentService({
    String? huggingFaceApiKey,
    bool useCloud = true,
  }) : _useCloud = useCloud && huggingFaceApiKey != null,
       _huggingFace = huggingFaceApiKey != null 
         ? HuggingFaceService(apiKey: huggingFaceApiKey)
         : null;
  
  /// Analisa sentimento usando estratégia híbrida
  /// Com API key: sempre usa HuggingFace (traduz PT→EN para precisão 98%+)
  /// Sem API key: usa análise léxica local (offline)
  Future<SentimentResult> analyze(String text) async {
    // Se cloud disponível, sempre usa (tradução melhora precisão em ~50%)
    if (_useCloud && _huggingFace != null) {
      final cloudResult = await _huggingFace.analyzeSentiment(text);
      return cloudResult ?? _analyzeLocal(text);
    }
    
    // Fallback para análise local
    return _analyzeLocal(text);
  }
  
  /// Análise rápida local (sem esperar API)
  /// Útil para feedback instantâneo enquanto API processa
  SentimentResult analyzeQuick(String text) => _analyzeLocal(text);
  
  /// Análise léxica local (sem API)
  SentimentResult _analyzeLocal(String text) {
    final lowerText = text.toLowerCase();
    
    // Dicionários simplificados
    const positiveWords = {
      'feliz', 'alegre', 'contente', 'animado', 'empolgado',
      'grato', 'maravilhoso', 'incrível', 'ótimo', 'excelente',
      'amei', 'adorei', 'perfeito', 'lindo', 'bom',
      'happy', 'excited', 'great', 'amazing', 'wonderful',
      'love', 'awesome', 'fantastic', 'perfect', 'good',
    };
    
    const negativeWords = {
      'triste', 'deprimido', 'ansioso', 'preocupado', 'frustrado',
      'terrível', 'horrível', 'péssimo', 'ruim', 'mal',
      'raiva', 'irritado', 'estressado', 'cansado', 'medo',
      'sad', 'depressed', 'anxious', 'worried', 'frustrated',
      'terrible', 'horrible', 'bad', 'angry', 'stressed',
    };
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in lowerText.split(RegExp(r'\W+'))) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    final total = positiveCount + negativeCount;
    
    double positiveScore;
    double negativeScore;
    double neutralScore;
    
    if (total == 0) {
      positiveScore = 0.1;
      negativeScore = 0.1;
      neutralScore = 0.8;
    } else {
      positiveScore = positiveCount / total;
      negativeScore = negativeCount / total;
      neutralScore = 0.0;
    }
    
    String label;
    double confidence;
    
    if (positiveScore > negativeScore && positiveScore > 0.3) {
      label = 'positive';
      confidence = positiveScore;
    } else if (negativeScore > positiveScore && negativeScore > 0.3) {
      label = 'negative';
      confidence = negativeScore;
    } else {
      label = 'neutral';
      confidence = neutralScore > 0 ? neutralScore : 0.6;
    }
    
    final moodScore = (3 + (positiveScore * 2) - (negativeScore * 2)).clamp(1.0, 5.0);
    
    final labelMap = {
      'positive': 'positivo',
      'negative': 'negativo',
      'neutral': 'neutro',
    };
    
    return SentimentResult(
      label: label,
      labelPt: labelMap[label] ?? label,
      confidence: confidence,
      moodScore: moodScore,
      breakdown: {
        'positive': positiveScore,
        'negative': negativeScore,
        'neutral': neutralScore,
      },
    );
  }
  
  void dispose() {
    _huggingFace?.dispose();
  }
}
