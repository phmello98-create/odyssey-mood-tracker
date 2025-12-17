import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';

/// Frases e trechos de Abraham Maslow
/// Fonte: "Motivação e Personalidade" e "Introdução à Psicologia do Ser"
/// 
/// NOTA: Maslow NUNCA desenhou uma pirâmide! A hierarquia é dinâmica e simultânea.
/// Uma pessoa pode estar 85% satisfeita em fisiologia, 70% em segurança,
/// 50% em amor, 40% em estima e 10% em autoatualização - SIMULTANEAMENTE.
const List<Map<String, String>> _maslowQuotes = [
  // ═══════════════════════════════════════════════════════════════════════════
  // AUTOATUALIZAÇÃO / INDIVIDUAÇÃO (Self-Actualization)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'O que um homem pode ser, ele deve ser. Esta necessidade chamamos de autorrealização.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'autorrealizacao',
  },
  {
    'text': 'A autorrealização é o processo de realização de potenciais, capacidades e talentos, como realização plena de missão, vocação ou destino.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'autorrealizacao',
  },
  {
    'text': 'Autoatualização não é um estado estático. É um processo contínuo de Vir a Ser, não apenas de Ser.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'autorrealizacao',
  },
  {
    'text': 'Um músico deve fazer música, um artista deve pintar, um poeta deve escrever, se quiser estar em paz consigo mesmo.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'autorrealizacao',
  },
  {
    'text': 'O crescimento é, em si mesmo, um processo compensador e excitante. A pessoa quer cada vez mais, não cada vez menos.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'autorrealizacao',
  },
  {
    'text': 'Pessoas saudáveis são motivadas por tendências para a individuação: conhecimento mais completo e aceitação da própria natureza intrínseca.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'autorrealizacao',
  },
  {
    'text': 'A ambição de ser um bom ser humano é a mais importante de todas as motivações de crescimento.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'autorrealizacao',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // EXPERIÊNCIAS CULMINANTES (Peak Experiences)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'Nas experiências culminantes, há uma desorientação no tempo e espaço. Um minuto intensamente vivido pode parecer um dia.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'experiencia_culminante',
  },
  {
    'text': 'As experiências culminantes de puro prazer estão entre as metas fundamentais da existência e são validações da vida.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'experiencia_culminante',
  },
  {
    'text': 'No furor criativo, o poeta ou artista esquece-se de tudo ao redor e da passagem do tempo. Quando desperta, é-lhe impossível ajuizar quanto tempo transcorreu.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'experiencia_culminante',
  },
  {
    'text': 'Nas experiências culminantes, a pessoa se torna mais integrada, mais individual, mais espontânea, mais expressiva e mais corajosa.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'experiencia_culminante',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ESTIMA E RESPEITO (Esteem Needs)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'A forma mais estável de autoestima é baseada no respeito merecido dos outros, não na fama ou reputação externa.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'estima',
  },
  {
    'text': 'A satisfação da necessidade de autoestima leva a sentimentos de autoconfiança, valor, força, capacidade e adequação.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'estima',
  },
  {
    'text': 'Pessoas capazes de individuação podem perceber a realidade mais eficientemente, com menos contaminação motivacional.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'estima',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AMOR E PERTENCIMENTO (Love & Belonging)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'A pessoa sadia, saciada em sua necessidade de amor, precisa menos de receber amor, mas é mais suscetível de DAR amor.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'amor',
  },
  {
    'text': 'Amor-B admira o outro como ele é, sem precisar dele. Amor-D precisa do outro para preencher uma carência.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'amor',
  },
  {
    'text': 'O verdadeiro conhecimento de outro ser humano só se torna possível quando nada se precisa dele, quando ele não é necessário.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'amor',
  },
  {
    'text': 'As pessoas autorrealizadas são extremamente individuais E extremamente compassivas e altruístas ao mesmo tempo.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'amor',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SEGURANÇA E ESTABILIDADE (Safety Needs)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'A pessoa saudável não é perfeita. Ela é boa o suficiente.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'seguranca',
  },
  {
    'text': 'Ordem não é prisão, é liberdade organizada. Rotinas são os trilhos por onde grandes vidas correm.',
    'author': 'Baseado em Maslow',
    'source': 'Interpretação',
    'level': 'seguranca',
  },
  {
    'text': 'A segurança financeira e emocional é a base que permite à pessoa buscar necessidades mais elevadas.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'seguranca',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CRESCIMENTO E METAMOTIVAÇÃO (Growth & Metamotivation)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'Em qualquer momento, temos duas opções: avançar em direção ao crescimento ou recuar em direção à segurança.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'crescimento',
  },
  {
    'text': 'Crescer e ser crescido são coisas diferentes. A vida plena é uma jornada, não um destino.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'crescimento',
  },
  {
    'text': 'A satisfação gera uma CRESCENTE, não decrescente, motivação. O apetite de crescimento é estimulado pela satisfação.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'crescimento',
  },
  {
    'text': 'Necessidades básicas e individuação não se contradizem, assim como infância e maturidade. Uma é condição prévia da outra.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'crescimento',
  },
  {
    'text': 'Os impulsos de crescimento são desejados e bem acolhidos. O criador acolhe seus impulsos criadores.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'crescimento',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HIERARQUIA DINÂMICA (Dynamic Hierarchy - NÃO é pirâmide rígida!)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'A hierarquia NÃO é rígida. Uma pessoa pode estar 85% satisfeita em fisiologia, 50% em amor e 10% em autoatualização - simultaneamente.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'hierarquia',
  },
  {
    'text': 'As necessidades coexistem. O surgimento de uma necessidade mais elevada não elimina as mais básicas.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'hierarquia',
  },
  {
    'text': 'Em algumas pessoas, a criatividade parece ser mais importante do que qualquer necessidade básica, surgindo APESAR das carências.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'hierarquia',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SAÚDE PSICOLÓGICA E TERCEIRA FORÇA
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'Saúde psicológica não só sente-se bem, mas é também correta, verdadeira, real. É "melhor" que a doença.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'saude',
  },
  {
    'text': 'Pessoas maravilhosas existem, mesmo em curta quantidade. Isso basta para nos dar coragem e esperança.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'saude',
  },
  {
    'text': 'A demanda por "Nirvana Agora!" é fonte de mal. Se você exige um líder perfeito, desiste de escolher entre melhor e pior.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'saude',
  },
  {
    'text': 'Se o imperfeito é definido como mal, então tudo se torna mal, pois tudo é imperfeito.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'saude',
  },
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SABEDORIA GERAL
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'text': 'Se a única ferramenta que você tem é um martelo, você tende a ver cada problema como um prego.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'geral',
  },
  {
    'text': 'O fato é que as pessoas são boas. Dê-lhes afeto e segurança, e elas darão afeto e segurança de volta.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'geral',
  },
  {
    'text': 'A maioria de nós poderia ser muito melhor do que somos.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'geral',
  },
  {
    'text': 'Podemos usar nós próprios, em nossos momentos mais perceptivos, para nos informar sobre verdades mais profundas.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'geral',
  },
  {
    'text': 'É possível amar a verdade que ainda está por nascer, confiar nela, maravilhar-se com sua natureza à medida que se revela.',
    'author': 'Abraham Maslow',
    'source': 'Motivation and Personality',
    'level': 'geral',
  },
  {
    'text': 'O terapeuta ideal deve ser, pelo menos, um ser humano francamente sadio.',
    'author': 'Abraham Maslow',
    'source': 'Introdução à Psicologia do Ser',
    'level': 'geral',
  },
];

/// Motor de insights que analisa dados e gera mensagens personalizadas
class InsightsEngine {
  final MoodRecordRepository moodRepo;
  final SyncedTimeTrackingRepository timeRepo;
  final GamificationRepository? gamificationRepo;

  InsightsEngine({
    required this.moodRepo,
    required this.timeRepo,
    this.gamificationRepo,
  });

  /// Gera um insight dinâmico baseado nos dados do usuário
  InsightData generateInsight() {
    final insights = <InsightData>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Coleta dados
    final allMoods = moodRepo.box.values.cast<MoodRecord>().toList();
    final allTime = timeRepo.box.values.cast<TimeTrackingRecord>().toList();
    
    final todayMoods = allMoods.where((m) => _isSameDay(m.date, today)).toList();
    final yesterdayMoods = allMoods.where((m) => _isSameDay(m.date, yesterday)).toList();
    final todayTime = allTime.where((t) => _isSameDay(t.startTime, today)).toList();
    final yesterdayTime = allTime.where((t) => _isSameDay(t.startTime, yesterday)).toList();
    
    final weekMoods = allMoods.where((m) => 
        m.date.isAfter(today.subtract(const Duration(days: 7)))).toList();
    final weekTime = allTime.where((t) => 
        t.startTime.isAfter(today.subtract(const Duration(days: 7)))).toList();

    // 1. Sem registro de humor hoje
    if (todayMoods.isEmpty) {
      if (yesterdayMoods.isNotEmpty) {
        final lastMood = yesterdayMoods.last;
        insights.add(InsightData(
          type: InsightType.suggestion,
          icon: Icons.mood,
          title: 'Como você está hoje?',
          message: 'Ontem você registrou "${lastMood.label}". Como está se sentindo agora?',
          actionLabel: 'Registrar Humor',
          actionType: InsightAction.recordMood,
          priority: 10,
        ));
      } else {
        insights.add(InsightData(
          type: InsightType.suggestion,
          icon: Icons.psychology,
          title: 'Momento de reflexão',
          message: 'Parar para registrar seu humor ajuda no autoconhecimento.',
          actionLabel: 'Registrar',
          actionType: InsightAction.recordMood,
          priority: 8,
        ));
      }
    }

    // 2. Comparação de tempo focado
    if (todayTime.isNotEmpty || yesterdayTime.isNotEmpty) {
      final todayMins = todayTime.fold<int>(0, (sum, t) => sum + t.durationInSeconds) ~/ 60;
      final yesterdayMins = yesterdayTime.fold<int>(0, (sum, t) => sum + t.durationInSeconds) ~/ 60;
      
      if (todayMins > yesterdayMins && yesterdayMins > 0) {
        final diff = todayMins - yesterdayMins;
        insights.add(InsightData(
          type: InsightType.achievement,
          icon: Icons.trending_up,
          title: 'Você está arrasando! 🔥',
          message: 'Hoje você focou $diff minutos a mais que ontem. Continue assim!',
          priority: 9,
        ));
      } else if (todayMins == 0 && yesterdayMins > 30) {
        insights.add(InsightData(
          type: InsightType.motivation,
          icon: Icons.timer,
          title: 'Hora de focar?',
          message: 'Ontem você teve ${yesterdayMins}min de foco. Vamos manter o ritmo?',
          actionLabel: 'Iniciar Timer',
          actionType: InsightAction.startTimer,
          priority: 7,
        ));
      }
    }

    // 3. Análise de humor da semana
    if (weekMoods.length >= 3) {
      final avgScore = weekMoods.map((m) => m.score).reduce((a, b) => a + b) / weekMoods.length;
      
      if (avgScore >= 4) {
        insights.add(InsightData(
          type: InsightType.achievement,
          icon: Icons.emoji_emotions,
          title: 'Semana positiva! 🌟',
          message: 'Sua média de humor esta semana está ótima. O que está funcionando?',
          priority: 6,
        ));
      } else if (avgScore <= 2) {
        insights.add(InsightData(
          type: InsightType.support,
          icon: Icons.favorite,
          title: 'Semana difícil?',
          message: 'Está tudo bem não estar bem. Que tal registrar o que está sentindo?',
          actionLabel: 'Registrar',
          actionType: InsightAction.recordMood,
          priority: 10,
        ));
      }
    }

    // 4. Streak em risco
    if (gamificationRepo != null) {
      try {
        final stats = gamificationRepo!.getStats();
        if (stats.currentStreak > 0 && stats.lastActiveDate != null) {
          final lastActive = DateTime(
            stats.lastActiveDate!.year,
            stats.lastActiveDate!.month,
            stats.lastActiveDate!.day,
          );
          if (today.difference(lastActive).inDays == 1 && todayMoods.isEmpty && todayTime.isEmpty) {
            insights.add(InsightData(
              type: InsightType.warning,
              icon: Icons.local_fire_department,
              title: 'Streak de ${stats.currentStreak} dias! 🔥',
              message: 'Registre algo hoje para não perder seu progresso!',
              actionLabel: 'Manter Streak',
              actionType: InsightAction.recordMood,
              priority: 10,
            ));
          }
        }
      } catch (_) {}
    }

    // 5. Conquista de tempo
    final totalWeekMins = weekTime.fold<int>(0, (sum, t) => sum + t.durationInSeconds) ~/ 60;
    if (totalWeekMins >= 60 && totalWeekMins < 120) {
      insights.add(InsightData(
        type: InsightType.achievement,
        icon: Icons.workspace_premium,
        title: 'Mais de 1 hora esta semana!',
        message: 'Você acumulou ${totalWeekMins}min de foco. Excelente progresso!',
        priority: 5,
      ));
    } else if (totalWeekMins >= 300) {
      insights.add(InsightData(
        type: InsightType.achievement,
        icon: Icons.military_tech,
        title: 'Produtividade máxima! 🚀',
        message: 'Incrível! ${totalWeekMins ~/ 60}h de foco esta semana!',
        priority: 8,
      ));
    }

    // 6. Primeiro registro do dia
    if (todayMoods.length == 1 && todayMoods.first.date.hour < 12) {
      insights.add(InsightData(
        type: InsightType.achievement,
        icon: Icons.wb_sunny,
        title: 'Bom dia produtivo! ☀️',
        message: 'Você já registrou seu humor hoje cedo. Ótimo hábito!',
        priority: 4,
      ));
    }

    // 7. Insights motivacionais de fallback (agora com Maslow!)
    if (insights.isEmpty) {
      final maslowQuote = _maslowQuotes[Random().nextInt(_maslowQuotes.length)];
      insights.add(InsightData(
        type: InsightType.motivation,
        icon: Icons.psychology_alt,
        title: '💭 Reflexão',
        message: maslowQuote['text']!,
        priority: 1,
      ));
      
      // Adiciona mais um insight motivacional alternativo
      final motivationalInsights = [
        InsightData(
          type: InsightType.motivation,
          icon: Icons.auto_awesome,
          title: 'Você é feito de estrelas ✨',
          message: 'Literalmente. Cada átomo seu já existiu em uma estrela.',
          priority: 1,
        ),
        InsightData(
          type: InsightType.motivation,
          icon: Icons.self_improvement,
          title: 'Momento de presença',
          message: 'Respire fundo. O agora é tudo que existe.',
          priority: 1,
        ),
        InsightData(
          type: InsightType.suggestion,
          icon: Icons.trending_up,
          title: 'Pequenos passos',
          message: 'Cada ação mínima constrói algo maior com o tempo.',
          priority: 1,
        ),
      ];
      insights.add(motivationalInsights[Random().nextInt(motivationalInsights.length)]);
    }

    // Ordena por prioridade e retorna o mais relevante
    insights.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Adiciona um pouco de aleatoriedade entre os top insights
    final topInsights = insights.take(3).toList();
    return topInsights[Random().nextInt(topInsights.length)];
  }

  /// Gera múltiplos insights para exibir em lista
  List<InsightData> generateMultipleInsights({int maxCount = 3}) {
    final insights = <InsightData>[];
    final baseInsight = generateInsight();
    insights.add(baseInsight);
    
    // Adiciona insights complementares
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayMoods = moodRepo.box.values.cast<MoodRecord>()
        .where((m) => _isSameDay(m.date, today)).toList();
    final todayTime = timeRepo.box.values.cast<TimeTrackingRecord>()
        .where((t) => _isSameDay(t.startTime, today)).toList();

    // Quick action suggestions
    if (todayMoods.isEmpty && !insights.any((i) => i.actionType == InsightAction.recordMood)) {
      insights.add(InsightData(
        type: InsightType.suggestion,
        icon: Icons.add_reaction,
        title: 'Registre seu humor',
        message: 'Um registro rápido ajuda a entender seus padrões.',
        actionLabel: 'Registrar',
        actionType: InsightAction.recordMood,
        priority: 5,
      ));
    }

    if (todayTime.isEmpty && !insights.any((i) => i.actionType == InsightAction.startTimer)) {
      insights.add(InsightData(
        type: InsightType.suggestion,
        icon: Icons.play_circle,
        title: 'Comece uma sessão de foco',
        message: 'Use o timer para aumentar sua produtividade.',
        actionLabel: 'Iniciar',
        actionType: InsightAction.startTimer,
        priority: 4,
      ));
    }

    return insights.take(maxCount).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Dados de um insight
class InsightData {
  final InsightType type;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final InsightAction? actionType;
  final int priority;

  InsightData({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionType,
    this.priority = 5,
  });
}

enum InsightType {
  suggestion,
  achievement,
  motivation,
  warning,
  support,
}

enum InsightAction {
  recordMood,
  startTimer,
  viewAnalytics,
  createTask,
  createNote,
}

/// Provider do InsightsEngine
final insightsEngineProvider = Provider<InsightsEngine>((ref) {
  final moodRepo = ref.watch(moodRecordRepositoryProvider);
  final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
  
  GamificationRepository? gamificationRepo;
  try {
    gamificationRepo = ref.watch(gamificationRepositoryProvider);
  } catch (_) {}
  
  return InsightsEngine(
    moodRepo: moodRepo,
    timeRepo: timeRepo,
    gamificationRepo: gamificationRepo,
  );
});

/// Provider para o insight atual
final currentInsightProvider = Provider<InsightData>((ref) {
  final engine = ref.watch(insightsEngineProvider);
  return engine.generateInsight();
});

/// Retorna uma frase aleatória de Maslow
Map<String, String> getRandomMaslowQuote() {
  return _maslowQuotes[Random().nextInt(_maslowQuotes.length)];
}

/// Provider de frases de Maslow
final maslowQuotesProvider = Provider<List<Map<String, String>>>((ref) {
  return _maslowQuotes;
});
