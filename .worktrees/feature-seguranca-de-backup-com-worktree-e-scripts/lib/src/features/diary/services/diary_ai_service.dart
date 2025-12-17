// lib/src/features/diary/services/diary_ai_service.dart

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/synced_diary_repository.dart';

/// Resultado da análise de sentimento
class SentimentAnalysis {
  final double score; // -1.0 (negativo) a 1.0 (positivo)
  final String dominantEmotion;
  final Map<String, double> emotions;
  final List<String> keyPhrases;
  final String summary;

  const SentimentAnalysis({
    required this.score,
    required this.dominantEmotion,
    required this.emotions,
    required this.keyPhrases,
    required this.summary,
  });

  String get sentimentLabel {
    if (score >= 0.5) return 'muito_positivo';
    if (score >= 0.2) return 'positivo';
    if (score >= -0.2) return 'neutro';
    if (score >= -0.5) return 'negativo';
    return 'muito_negativo';
  }

  String get emoji {
    if (score >= 0.5) return '😊';
    if (score >= 0.2) return '🙂';
    if (score >= -0.2) return '😐';
    if (score >= -0.5) return '😔';
    return '😢';
  }
}

/// Prompt de escrita gerado
class WritingPrompt {
  final String id;
  final String text;
  final String textEn;
  final String category;
  final String emoji;
  final List<String> suggestedTags;

  const WritingPrompt({
    required this.id,
    required this.text,
    required this.textEn,
    required this.category,
    required this.emoji,
    this.suggestedTags = const [],
  });
}

/// Insight gerado sobre o diário
class DiaryInsight {
  final String id;
  final String type;
  final String title;
  final String description;
  final String emoji;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  const DiaryInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.data,
    required this.generatedAt,
  });
}

/// Serviço de IA para o diário
class DiaryAIService {
  final SyncedDiaryRepository _repository;
  final math.Random _random = math.Random();

  DiaryAIService(this._repository);

  // ============================================================
  // PROMPTS DE ESCRITA CONTEXTUAIS
  // ============================================================

  /// Prompts para diferentes momentos do dia
  static const Map<String, List<WritingPrompt>> _timeBasedPrompts = {
    'morning': [
      WritingPrompt(
        id: 'morning_1',
        text: 'Como você se sente ao começar o dia? O que espera realizar?',
        textEn: 'How do you feel starting the day? What do you hope to accomplish?',
        category: 'morning',
        emoji: '🌅',
        suggestedTags: ['manhã', 'intenções'],
      ),
      WritingPrompt(
        id: 'morning_2',
        text: 'Descreva seu sonho desta noite ou como foi acordar hoje.',
        textEn: 'Describe your dream last night or how waking up felt today.',
        category: 'morning',
        emoji: '🛏️',
        suggestedTags: ['sonhos', 'despertar'],
      ),
      WritingPrompt(
        id: 'morning_3',
        text: 'Pelo que você é grato nesta manhã?',
        textEn: 'What are you grateful for this morning?',
        category: 'morning',
        emoji: '🙏',
        suggestedTags: ['gratidão', 'manhã'],
      ),
    ],
    'afternoon': [
      WritingPrompt(
        id: 'afternoon_1',
        text: 'Como está sendo seu dia até agora? Algum momento especial?',
        textEn: 'How is your day going so far? Any special moments?',
        category: 'afternoon',
        emoji: '☀️',
        suggestedTags: ['tarde', 'progresso'],
      ),
      WritingPrompt(
        id: 'afternoon_2',
        text: 'O que você aprendeu ou descobriu hoje?',
        textEn: 'What did you learn or discover today?',
        category: 'afternoon',
        emoji: '💡',
        suggestedTags: ['aprendizado', 'descobertas'],
      ),
      WritingPrompt(
        id: 'afternoon_3',
        text: 'Descreva uma conversa interessante ou pessoa que encontrou.',
        textEn: 'Describe an interesting conversation or person you met.',
        category: 'afternoon',
        emoji: '💬',
        suggestedTags: ['pessoas', 'conexões'],
      ),
    ],
    'evening': [
      WritingPrompt(
        id: 'evening_1',
        text: 'Qual foi o destaque do seu dia? O que te fez sorrir?',
        textEn: 'What was the highlight of your day? What made you smile?',
        category: 'evening',
        emoji: '🌆',
        suggestedTags: ['destaques', 'alegria'],
      ),
      WritingPrompt(
        id: 'evening_2',
        text: 'O que você gostaria de lembrar sobre hoje daqui a um ano?',
        textEn: 'What would you like to remember about today in a year?',
        category: 'evening',
        emoji: '📸',
        suggestedTags: ['memórias', 'reflexão'],
      ),
      WritingPrompt(
        id: 'evening_3',
        text: 'Se pudesse mudar algo sobre hoje, o que seria?',
        textEn: 'If you could change something about today, what would it be?',
        category: 'evening',
        emoji: '🔄',
        suggestedTags: ['reflexão', 'crescimento'],
      ),
    ],
    'night': [
      WritingPrompt(
        id: 'night_1',
        text: 'Como você está se sentindo antes de dormir? O que está em sua mente?',
        textEn: 'How are you feeling before sleep? What is on your mind?',
        category: 'night',
        emoji: '🌙',
        suggestedTags: ['noite', 'pensamentos'],
      ),
      WritingPrompt(
        id: 'night_2',
        text: 'Liste 3 coisas boas que aconteceram hoje.',
        textEn: 'List 3 good things that happened today.',
        category: 'night',
        emoji: '✨',
        suggestedTags: ['gratidão', 'positivo'],
      ),
      WritingPrompt(
        id: 'night_3',
        text: 'O que você está ansioso(a) para fazer amanhã?',
        textEn: 'What are you looking forward to tomorrow?',
        category: 'night',
        emoji: '🌟',
        suggestedTags: ['esperança', 'futuro'],
      ),
    ],
  };

  /// Prompts por emoção/humor
  static const Map<String, List<WritingPrompt>> _moodBasedPrompts = {
    'happy': [
      WritingPrompt(
        id: 'happy_1',
        text: 'O que está te deixando feliz? Descreva em detalhes.',
        textEn: 'What is making you happy? Describe it in detail.',
        category: 'happy',
        emoji: '😊',
        suggestedTags: ['felicidade', 'alegria'],
      ),
      WritingPrompt(
        id: 'happy_2',
        text: 'Como você pode preservar esse sentimento?',
        textEn: 'How can you preserve this feeling?',
        category: 'happy',
        emoji: '💫',
        suggestedTags: ['bem-estar', 'gratidão'],
      ),
    ],
    'sad': [
      WritingPrompt(
        id: 'sad_1',
        text: 'Está tudo bem não estar bem. O que está te preocupando?',
        textEn: "It's okay not to be okay. What is worrying you?",
        category: 'sad',
        emoji: '💙',
        suggestedTags: ['desabafo', 'emoções'],
      ),
      WritingPrompt(
        id: 'sad_2',
        text: 'O que poderia te ajudar a se sentir um pouco melhor agora?',
        textEn: 'What could help you feel a bit better right now?',
        category: 'sad',
        emoji: '🫂',
        suggestedTags: ['autocuidado', 'apoio'],
      ),
    ],
    'anxious': [
      WritingPrompt(
        id: 'anxious_1',
        text: 'Escreva tudo que está em sua mente, sem filtro. Deixe fluir.',
        textEn: 'Write everything on your mind, unfiltered. Let it flow.',
        category: 'anxious',
        emoji: '🌊',
        suggestedTags: ['desabafo', 'ansiedade'],
      ),
      WritingPrompt(
        id: 'anxious_2',
        text: 'Liste o que você pode controlar e o que não pode.',
        textEn: 'List what you can control and what you cannot.',
        category: 'anxious',
        emoji: '📋',
        suggestedTags: ['controle', 'perspectiva'],
      ),
    ],
    'grateful': [
      WritingPrompt(
        id: 'grateful_1',
        text: 'Escreva uma carta de agradecimento para alguém especial.',
        textEn: 'Write a thank you letter to someone special.',
        category: 'grateful',
        emoji: '💌',
        suggestedTags: ['gratidão', 'conexões'],
      ),
    ],
    'creative': [
      WritingPrompt(
        id: 'creative_1',
        text: 'Descreva um dia perfeito em um mundo imaginário.',
        textEn: 'Describe a perfect day in an imaginary world.',
        category: 'creative',
        emoji: '🎨',
        suggestedTags: ['criatividade', 'imaginação'],
      ),
      WritingPrompt(
        id: 'creative_2',
        text: 'Se sua vida fosse um filme, qual seria a cena de hoje?',
        textEn: 'If your life were a movie, what would be today\'s scene?',
        category: 'creative',
        emoji: '🎬',
        suggestedTags: ['criatividade', 'narrativa'],
      ),
    ],
  };

  /// Prompts especiais para datas
  static const Map<String, WritingPrompt> _specialDatePrompts = {
    'new_year': WritingPrompt(
      id: 'new_year',
      text: 'Um novo ano começa! Quais são suas esperanças e intenções?',
      textEn: 'A new year begins! What are your hopes and intentions?',
      category: 'special',
      emoji: '🎆',
      suggestedTags: ['ano novo', 'metas'],
    ),
    'birthday': WritingPrompt(
      id: 'birthday',
      text: 'Mais um ano de vida! Reflita sobre o ano que passou e o que está por vir.',
      textEn: 'Another year of life! Reflect on the past year and what is to come.',
      category: 'special',
      emoji: '🎂',
      suggestedTags: ['aniversário', 'reflexão'],
    ),
    'monday': WritingPrompt(
      id: 'monday',
      text: 'Uma nova semana começa. Quais são suas prioridades?',
      textEn: 'A new week begins. What are your priorities?',
      category: 'weekday',
      emoji: '📆',
      suggestedTags: ['planejamento', 'semana'],
    ),
    'friday': WritingPrompt(
      id: 'friday',
      text: 'A semana está terminando. O que você conquistou?',
      textEn: 'The week is ending. What did you achieve?',
      category: 'weekday',
      emoji: '🎉',
      suggestedTags: ['conquistas', 'semana'],
    ),
    'sunday': WritingPrompt(
      id: 'sunday',
      text: 'Domingo, dia de descanso e reflexão. Como foi sua semana?',
      textEn: 'Sunday, a day for rest and reflection. How was your week?',
      category: 'weekday',
      emoji: '☕',
      suggestedTags: ['domingo', 'reflexão'],
    ),
  };

  /// Obtém prompts contextuais baseados no momento e histórico
  Future<List<WritingPrompt>> getContextualPrompts({
    String? mood,
    DateTime? date,
    int limit = 5,
  }) async {
    final prompts = <WritingPrompt>[];
    final now = date ?? DateTime.now();
    
    // 1. Verificar data especial
    if (now.month == 1 && now.day == 1) {
      prompts.add(_specialDatePrompts['new_year']!);
    }
    
    // Prompts por dia da semana
    switch (now.weekday) {
      case DateTime.monday:
        prompts.add(_specialDatePrompts['monday']!);
        break;
      case DateTime.friday:
        prompts.add(_specialDatePrompts['friday']!);
        break;
      case DateTime.sunday:
        prompts.add(_specialDatePrompts['sunday']!);
        break;
    }
    
    // 2. Prompts baseados no humor
    if (mood != null && _moodBasedPrompts.containsKey(mood)) {
      prompts.addAll(_moodBasedPrompts[mood]!);
    }
    
    // 3. Prompts baseados na hora do dia
    final hour = now.hour;
    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }
    
    prompts.addAll(_timeBasedPrompts[timeOfDay] ?? []);
    
    // 4. Shuffle e limitar
    prompts.shuffle(_random);
    return prompts.take(limit).toList();
  }

  /// Obtém um prompt aleatório
  WritingPrompt getRandomPrompt() {
    final allPrompts = <WritingPrompt>[];
    
    for (final list in _timeBasedPrompts.values) {
      allPrompts.addAll(list);
    }
    for (final list in _moodBasedPrompts.values) {
      allPrompts.addAll(list);
    }
    
    return allPrompts[_random.nextInt(allPrompts.length)];
  }

  // ============================================================
  // ANÁLISE DE SENTIMENTO (Local, sem API)
  // ============================================================

  /// Palavras-chave para análise de sentimento
  static const _positiveWords = {
    // Português
    'feliz', 'alegria', 'amor', 'amei', 'incrível', 'maravilhoso', 'ótimo',
    'excelente', 'fantástico', 'gratidão', 'grato', 'conquista', 'sucesso',
    'realizado', 'paz', 'tranquilo', 'motivado', 'animado', 'empolgado',
    'orgulho', 'satisfeito', 'esperança', 'sorrir', 'sorrindo', 'divertido',
    'energia', 'produtivo', 'inspirado', 'criativo', 'conectado', 'amigo',
    'família', 'carinho', 'abraço', 'presente', 'especial', 'lindo', 'belo',
    // English
    'happy', 'joy', 'love', 'loved', 'amazing', 'wonderful', 'great',
    'excellent', 'fantastic', 'grateful', 'success', 'peace', 'motivated',
    'excited', 'proud', 'satisfied', 'hope', 'smile', 'fun', 'energy',
    'productive', 'inspired', 'creative', 'connected', 'friend', 'family',
    'beautiful', 'special', 'gift',
  };

  static const _negativeWords = {
    // Português
    'triste', 'tristeza', 'ansioso', 'ansiedade', 'medo', 'preocupado',
    'estresse', 'cansado', 'exausto', 'frustrado', 'irritado', 'raiva',
    'decepcionado', 'sozinho', 'solidão', 'dor', 'doente', 'difícil',
    'problema', 'falha', 'fracasso', 'desânimo', 'deprimido', 'nervoso',
    'angústia', 'chateado', 'aborrecido', 'desapontado', 'inseguro',
    'perdido', 'confuso', 'arrependido', 'culpa', 'vergonha',
    // English
    'sad', 'sadness', 'anxious', 'anxiety', 'fear', 'worried', 'stress',
    'tired', 'exhausted', 'frustrated', 'angry', 'disappointed', 'lonely',
    'pain', 'sick', 'difficult', 'problem', 'failure', 'depressed',
    'nervous', 'confused', 'regret', 'guilt', 'shame',
  };

  /// Analisa o sentimento de um texto
  SentimentAnalysis analyzeSentiment(String text) {
    final lowerText = text.toLowerCase();
    final words = lowerText.split(RegExp(r'\s+'));
    
    int positiveCount = 0;
    int negativeCount = 0;
    final emotions = <String, double>{};
    final keyPhrases = <String>[];
    
    // Contar palavras positivas e negativas
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (_positiveWords.contains(cleanWord)) {
        positiveCount++;
      } else if (_negativeWords.contains(cleanWord)) {
        negativeCount++;
      }
    }
    
    // Detectar emoções específicas
    if (lowerText.contains('feliz') || lowerText.contains('alegr') || lowerText.contains('happy')) {
      emotions['alegria'] = (emotions['alegria'] ?? 0) + 1;
    }
    if (lowerText.contains('trist') || lowerText.contains('sad')) {
      emotions['tristeza'] = (emotions['tristeza'] ?? 0) + 1;
    }
    if (lowerText.contains('grat') || lowerText.contains('grateful')) {
      emotions['gratidão'] = (emotions['gratidão'] ?? 0) + 1;
    }
    if (lowerText.contains('ansi') || lowerText.contains('anxious') || lowerText.contains('preocup')) {
      emotions['ansiedade'] = (emotions['ansiedade'] ?? 0) + 1;
    }
    if (lowerText.contains('raiva') || lowerText.contains('irritad') || lowerText.contains('angry')) {
      emotions['raiva'] = (emotions['raiva'] ?? 0) + 1;
    }
    if (lowerText.contains('paz') || lowerText.contains('tranquil') || lowerText.contains('calm')) {
      emotions['serenidade'] = (emotions['serenidade'] ?? 0) + 1;
    }
    if (lowerText.contains('amor') || lowerText.contains('amo') || lowerText.contains('love')) {
      emotions['amor'] = (emotions['amor'] ?? 0) + 1;
    }
    if (lowerText.contains('medo') || lowerText.contains('afraid') || lowerText.contains('fear')) {
      emotions['medo'] = (emotions['medo'] ?? 0) + 1;
    }
    
    // Calcular score
    final total = positiveCount + negativeCount;
    double score = 0;
    if (total > 0) {
      score = (positiveCount - negativeCount) / total;
    }
    
    // Determinar emoção dominante
    String dominantEmotion = 'neutro';
    if (emotions.isNotEmpty) {
      dominantEmotion = emotions.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    } else if (score > 0.2) {
      dominantEmotion = 'positivo';
    } else if (score < -0.2) {
      dominantEmotion = 'negativo';
    }
    
    // Extrair frases-chave (simplificado)
    final sentences = text.split(RegExp(r'[.!?]'));
    for (final sentence in sentences) {
      if (sentence.length > 20 && sentence.length < 100) {
        if (_containsEmotionalWord(sentence.toLowerCase())) {
          keyPhrases.add(sentence.trim());
        }
      }
    }
    
    // Gerar resumo
    String summary;
    if (score >= 0.3) {
      summary = 'Essa entrada transmite sentimentos predominantemente positivos.';
    } else if (score <= -0.3) {
      summary = 'Essa entrada expressa sentimentos difíceis. Lembre-se: está tudo bem sentir assim.';
    } else {
      summary = 'Essa entrada tem um tom equilibrado, misturando diferentes emoções.';
    }
    
    return SentimentAnalysis(
      score: score,
      dominantEmotion: dominantEmotion,
      emotions: emotions,
      keyPhrases: keyPhrases.take(3).toList(),
      summary: summary,
    );
  }

  bool _containsEmotionalWord(String text) {
    return _positiveWords.any((w) => text.contains(w)) ||
           _negativeWords.any((w) => text.contains(w));
  }

  // ============================================================
  // INSIGHTS E ANÁLISES
  // ============================================================

  /// Gera insights baseados no histórico do diário
  Future<List<DiaryInsight>> generateInsights() async {
    final insights = <DiaryInsight>[];
    final now = DateTime.now();
    
    try {
      final stats = await _repository.getStatistics();
      final allEntries = await _repository.getAllEntries();
      final recentEntries = allEntries.take(30).toList();
      
      // Insight 1: Streak atual
      if (stats.currentStreak >= 3) {
        insights.add(DiaryInsight(
          id: 'streak_${stats.currentStreak}',
          type: 'streak',
          title: '${stats.currentStreak} dias consecutivos!',
          description: 'Você está mantendo uma sequência incrível de escrita. Continue assim!',
          emoji: '🔥',
          data: {'streak': stats.currentStreak},
          generatedAt: now,
        ));
      }
      
      // Insight 2: Melhor dia da semana
      if (stats.entriesByDayOfWeek.isNotEmpty) {
        final bestDay = stats.entriesByDayOfWeek.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        
        insights.add(DiaryInsight(
          id: 'best_day',
          type: 'pattern',
          title: 'Você escreve mais às ${dayNames[bestDay.key - 1]}s',
          description: 'Esse é o seu dia favorito para reflexões.',
          emoji: '📅',
          data: {'weekday': bestDay.key, 'count': bestDay.value},
          generatedAt: now,
        ));
      }
      
      // Insight 3: Sentimento predominante recente
      if (recentEntries.isNotEmpty) {
        final feelings = <String, int>{};
        for (final entry in recentEntries) {
          if (entry.feeling != null) {
            feelings[entry.feeling!] = (feelings[entry.feeling!] ?? 0) + 1;
          }
        }
        
        if (feelings.isNotEmpty) {
          final topFeeling = feelings.entries
              .reduce((a, b) => a.value > b.value ? a : b);
          
          insights.add(DiaryInsight(
            id: 'mood_trend',
            type: 'mood',
            title: 'Seu humor recente: ${topFeeling.key}',
            description: 'Nos últimos 30 dias, você usou esse sentimento ${topFeeling.value} vezes.',
            emoji: topFeeling.key,
            data: {'feeling': topFeeling.key, 'count': topFeeling.value},
            generatedAt: now,
          ));
        }
      }
      
      // Insight 4: Marcos
      if (stats.totalEntries == 10 || stats.totalEntries == 25 || 
          stats.totalEntries == 50 || stats.totalEntries == 100) {
        insights.add(DiaryInsight(
          id: 'milestone_${stats.totalEntries}',
          type: 'milestone',
          title: '${stats.totalEntries} entradas! 🎉',
          description: 'Parabéns por esse marco! Você está construindo um rico arquivo de memórias.',
          emoji: '🏆',
          data: {'total': stats.totalEntries},
          generatedAt: now,
        ));
      }
      
      // Insight 5: Média de palavras
      if (stats.totalEntries >= 5 && stats.totalWords > 0) {
        final avgWords = stats.totalWords ~/ stats.totalEntries;
        String description;
        String emoji;
        
        if (avgWords >= 300) {
          description = 'Você escreve entradas detalhadas. Excelente para preservar memórias!';
          emoji = '✍️';
        } else if (avgWords >= 100) {
          description = 'Um bom equilíbrio entre brevidade e detalhes.';
          emoji = '📝';
        } else {
          description = 'Entradas curtas e diretas. Tente expandir quando tiver tempo!';
          emoji = '💡';
        }
        
        insights.add(DiaryInsight(
          id: 'avg_words',
          type: 'stats',
          title: 'Média: $avgWords palavras por entrada',
          description: description,
          emoji: emoji,
          data: {'avgWords': avgWords},
          generatedAt: now,
        ));
      }
      
    } catch (e) {
      debugPrint('[DiaryAI] Erro ao gerar insights: $e');
    }
    
    return insights;
  }

  /// Sugere tags baseadas no conteúdo
  List<String> suggestTags(String content) {
    final suggestions = <String>{};
    final lowerContent = content.toLowerCase();
    
    // Tags por palavras-chave
    final tagKeywords = {
      'trabalho': ['trabalho', 'emprego', 'reunião', 'projeto', 'chefe', 'colega', 'work', 'meeting'],
      'família': ['família', 'mãe', 'pai', 'irmão', 'irmã', 'filho', 'filha', 'family'],
      'saúde': ['saúde', 'médico', 'exercício', 'academia', 'doença', 'health', 'exercise'],
      'amor': ['amor', 'namorado', 'namorada', 'relacionamento', 'love', 'relationship'],
      'amizade': ['amigo', 'amiga', 'amizade', 'friend'],
      'viagem': ['viagem', 'viajar', 'férias', 'travel', 'vacation'],
      'comida': ['comida', 'restaurante', 'cozinhar', 'food', 'cooking'],
      'estudos': ['estudo', 'estudar', 'faculdade', 'curso', 'study', 'school'],
      'finanças': ['dinheiro', 'salário', 'conta', 'economia', 'money', 'finance'],
      'lazer': ['filme', 'série', 'livro', 'música', 'jogo', 'hobby'],
      'natureza': ['natureza', 'praia', 'montanha', 'parque', 'nature'],
      'criatividade': ['arte', 'criar', 'desenho', 'escrita', 'creative', 'art'],
      'gratidão': ['grato', 'agradeço', 'gratidão', 'grateful', 'thankful'],
      'reflexão': ['pensar', 'refletir', 'perceber', 'aprender', 'reflect'],
      'conquista': ['consegui', 'conquistei', 'vitória', 'sucesso', 'achieved'],
      'desafio': ['difícil', 'desafio', 'problema', 'obstáculo', 'challenge'],
    };
    
    for (final entry in tagKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerContent.contains(keyword)) {
          suggestions.add(entry.key);
          break;
        }
      }
    }
    
    return suggestions.take(5).toList();
  }
}

/// Provider para DiaryAIService
final diaryAIServiceProvider = Provider<DiaryAIService>((ref) {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return DiaryAIService(repository);
});

/// Provider para prompts contextuais
final contextualPromptsProvider = FutureProvider.family<List<WritingPrompt>, String?>((ref, mood) async {
  final service = ref.watch(diaryAIServiceProvider);
  return service.getContextualPrompts(mood: mood);
});

/// Provider para insights do diário
final diaryInsightsProvider = FutureProvider<List<DiaryInsight>>((ref) async {
  final service = ref.watch(diaryAIServiceProvider);
  return service.generateInsights();
});
