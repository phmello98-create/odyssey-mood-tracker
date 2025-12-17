
// AUTO-GENERATED - Lexicon Analyzer for Portuguese
// Gerado por scripts/tflite_models_info.py

/// Analisador léxico para português brasileiro
/// Não requer ML - usa dicionário de palavras
class PortugueseLexiconAnalyzer {
  // Palavras positivas em português
  static const positiveWords = {
    // Emoções positivas
    'feliz', 'alegre', 'contente', 'satisfeito', 'animado',
    'empolgado', 'entusiasmado', 'radiante', 'eufórico', 'extasiado',
    'grato', 'agradecido', 'abençoado', 'sortudo', 'privilegiado',
    'amado', 'querido', 'adorado', 'apreciado', 'valorizado',
    'tranquilo', 'sereno', 'calmo', 'relaxado', 'zen',
    'confiante', 'seguro', 'forte', 'capaz', 'competente',
    'orgulhoso', 'realizado', 'vitorioso', 'bem-sucedido',
    'inspirado', 'motivado', 'determinado', 'focado',
    'esperançoso', 'otimista', 'positivo',
    
    // Experiências positivas
    'maravilhoso', 'incrível', 'fantástico', 'excelente', 'ótimo',
    'perfeito', 'sensacional', 'espetacular', 'extraordinário',
    'bom', 'legal', 'bacana', 'massa', 'top', 'demais',
    'lindo', 'bonito', 'belo', 'gracioso', 'encantador',
    'divertido', 'engraçado', 'hilário', 'prazeroso',
    'delicioso', 'gostoso', 'saboroso', 'apetitoso',
    
    // Ações positivas
    'consegui', 'conquistei', 'alcancei', 'realizei', 'completei',
    'superei', 'venci', 'ganhei', 'melhorei', 'progredi',
    'aprendi', 'cresci', 'evolui', 'desenvolvi',
    'amei', 'adorei', 'curti', 'aprovei', 'apreciei',
  };

  // Palavras negativas em português
  static const negativeWords = {
    // Emoções negativas
    'triste', 'deprimido', 'melancólico', 'abatido', 'desanimado',
    'frustrado', 'decepcionado', 'desiludido', 'desapontado',
    'ansioso', 'nervoso', 'preocupado', 'apreensivo', 'tenso',
    'estressado', 'sobrecarregado', 'exausto', 'esgotado', 'cansado',
    'irritado', 'bravo', 'furioso', 'irado', 'revoltado',
    'com raiva', 'zangado', 'indignado', 'enfurecido',
    'medo', 'assustado', 'apavorado', 'aterrorizado', 'temor',
    'inseguro', 'vulnerável', 'frágil', 'incapaz', 'impotente',
    'solitário', 'sozinho', 'abandonado', 'isolado', 'rejeitado',
    'culpado', 'arrependido', 'envergonhado', 'humilhado',
    
    // Experiências negativas
    'terrível', 'horrível', 'péssimo', 'ruim', 'mal',
    'difícil', 'complicado', 'problemático', 'desafiador',
    'doloroso', 'sofrido', 'angustiante', 'agonizante',
    'chato', 'entediante', 'monótono', 'tedioso',
    'feio', 'horrendo', 'desagradável', 'repugnante',
    
    // Ações/situações negativas
    'perdi', 'fracassei', 'falhei', 'errei', 'estraguei',
    'chorei', 'chorar', 'chorando', 'lágrimas',
    'odiei', 'detestei', 'não gostei', 'não suportei',
    'desisti', 'abandonei', 'larguei', 'parei',
    'briguei', 'discuti', 'conflito', 'confusão',
  };

  // Intensificadores
  static const intensifiers = {
    'muito': 1.5,
    'demais': 1.5,
    'super': 1.5,
    'extremamente': 2.0,
    'incrivelmente': 2.0,
    'absurdamente': 2.0,
    'pouco': 0.5,
    'levemente': 0.5,
    'um pouco': 0.5,
  };

  // Negadores
  static const negators = {'não', 'nem', 'nunca', 'jamais', 'nada'};

  /// Analisa o sentimento de um texto
  /// Retorna um valor entre 0 (muito negativo) e 1 (muito positivo)
  static double analyzeSentiment(String text) {
    final words = _tokenize(text.toLowerCase());
    
    if (words.isEmpty) return 0.5;
    
    double positiveScore = 0;
    double negativeScore = 0;
    double multiplier = 1.0;
    bool negated = false;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Check for negators
      if (negators.contains(word)) {
        negated = true;
        continue;
      }
      
      // Check for intensifiers
      if (intensifiers.containsKey(word)) {
        multiplier = intensifiers[word]!;
        continue;
      }
      
      // Score the word
      if (positiveWords.contains(word)) {
        if (negated) {
          negativeScore += multiplier;
        } else {
          positiveScore += multiplier;
        }
      } else if (negativeWords.contains(word)) {
        if (negated) {
          positiveScore += multiplier;
        } else {
          negativeScore += multiplier;
        }
      }
      
      // Reset modifiers after each scored word
      multiplier = 1.0;
      negated = false;
    }
    
    final total = positiveScore + negativeScore;
    if (total == 0) return 0.5;
    
    return positiveScore / total;
  }

  /// Detecta emoções específicas no texto
  static Map<String, double> detectEmotions(String text) {
    final lowerText = text.toLowerCase();
    
    // Padrões de emoção
    final emotionPatterns = {
      'alegria': ['feliz', 'alegr', 'content', 'animad', 'empolgad', '😊', '😄', '🎉'],
      'tristeza': ['trist', 'chorand', 'deprimi', 'melanc', 'abatid', '😢', '😭', '💔'],
      'raiva': ['raiv', 'irritad', 'brav', 'furios', 'revoltad', '😡', '🤬', '💢'],
      'medo': ['med', 'assust', 'ansios', 'preocu', 'pânic', '😰', '😨', '😱'],
      'surpresa': ['surpres', 'espant', 'chocad', 'incrível', '😮', '😲', '🤯'],
      'nojo': ['nojo', 'repugn', 'asco', '🤢', '🤮'],
      'amor': ['am', 'ador', 'querid', 'paixão', '❤️', '💕', '😍'],
      'gratidão': ['grat', 'agradeç', 'obrigad', '🙏'],
    };
    
    final emotions = <String, double>{};
    
    for (final entry in emotionPatterns.entries) {
      int matches = 0;
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) matches++;
      }
      if (matches > 0) {
        emotions[entry.key] = (matches / entry.value.length).clamp(0.0, 1.0);
      }
    }
    
    return emotions;
  }

  /// Calcula um mood score de 1-5 baseado no texto
  static double calculateMoodScore(String text) {
    final sentiment = analyzeSentiment(text);
    // Converte 0-1 para 1-5
    return 1 + (sentiment * 4);
  }

  static List<String> _tokenize(String text) {
    // Remove pontuação e divide em palavras
    return text
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
  }
}
