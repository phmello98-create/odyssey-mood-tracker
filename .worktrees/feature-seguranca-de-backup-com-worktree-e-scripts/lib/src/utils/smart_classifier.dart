/// Sistema inteligente de classificação Hábito vs Tarefa
/// 
/// Analisa o texto inserido pelo usuário e determina automaticamente
/// se deve ser tratado como hábito (recorrente) ou tarefa (única).

class SmartClassifier {
  /// Palavras-chave que indicam TAREFA (ação única com fim)
  static const List<String> _taskKeywords = [
    // Verbos de ação única
    'comprar', 'enviar', 'ligar', 'marcar', 'agendar', 'pagar',
    'entregar', 'buscar', 'levar', 'pegar', 'devolver', 'cancelar',
    'renovar', 'assinar', 'resolver', 'consertar', 'instalar',
    'configurar', 'atualizar', 'baixar', 'responder', 'confirmar',
    'reservar', 'preparar', 'organizar', 'limpar', 'arrumar',
    
    // Indicadores de urgência/prazo
    'urgente', 'hoje', 'amanhã', 'semana', 'mês', 'até',
    'deadline', 'prazo', 'vencimento',
    
    // Contexto de trabalho pontual
    'reunião', 'apresentação', 'relatório', 'documento', 'email',
    'projeto', 'entrega', 'prova', 'exame', 'consulta', 'compromisso',
    
    // Compras e transações
    'presente', 'ingresso', 'passagem', 'conta', 'boleto', 'fatura',
  ];

  /// Palavras-chave que indicam HÁBITO (ação recorrente)
  static const List<String> _habitKeywords = [
    // Atividades de rotina
    'meditar', 'meditação', 'exercitar', 'exercício', 'treinar', 'treino',
    'correr', 'caminhar', 'academia', 'yoga', 'alongar', 'alongamento',
    
    // Saúde e bem-estar
    'dormir', 'acordar', 'água', 'beber', 'vitamina', 'remédio',
    'skincare', 'higiene', 'escovar', 'fio dental',
    
    // Desenvolvimento pessoal
    'ler', 'leitura', 'estudar', 'estudo', 'aprender', 'praticar',
    'revisar', 'journaling', 'diário', 'gratidão', 'reflexão',
    
    // Produtividade recorrente
    'planejar', 'revisar', 'organizar o dia', 'inbox zero',
    'pomodoro', 'foco', 'mindfulness',
    
    // Indicadores de frequência
    'diário', 'diariamente', 'sempre', 'todo dia', 'toda manhã',
    'toda noite', 'rotina', 'hábito', 'consistência',
    
    // Alimentação saudável
    'café da manhã', 'almoçar', 'jantar', 'frutas', 'vegetais',
    'sem açúcar', 'jejum',
  ];

  /// Padrões que indicam TAREFA (regex)
  static final List<RegExp> _taskPatterns = [
    RegExp(r'\d{1,2}/\d{1,2}', caseSensitive: false), // Datas: 15/12
    RegExp(r'\d{1,2}h', caseSensitive: false), // Horários específicos: 14h
    RegExp(r'às \d', caseSensitive: false), // "às 15h"
    RegExp(r'para o|para a', caseSensitive: false), // "para o João"
    RegExp(r'no dia', caseSensitive: false), // "no dia 10"
    RegExp(r'na (segunda|terça|quarta|quinta|sexta|sábado|domingo)', caseSensitive: false),
  ];

  /// Padrões que indicam HÁBITO (regex)
  static final List<RegExp> _habitPatterns = [
    RegExp(r'todo(s)? (os)? dia(s)?', caseSensitive: false),
    RegExp(r'toda(s)? (as)? (manhã|noite|tarde)(s)?', caseSensitive: false),
    RegExp(r'\d+x (por|na) semana', caseSensitive: false), // "3x por semana"
    RegExp(r'(diário|semanal|mensal)', caseSensitive: false),
    RegExp(r'(manhã|noite|tarde) de (segunda|terça|quarta|quinta|sexta|sábado|domingo)', caseSensitive: false),
  ];

  /// Resultado da classificação
  static ClassificationResult classify(String input) {
    final text = input.toLowerCase().trim();
    
    if (text.isEmpty) {
      return ClassificationResult(
        type: ItemType.unknown,
        confidence: 0.0,
        reason: 'Texto vazio',
      );
    }

    double taskScore = 0;
    double habitScore = 0;
    List<String> taskReasons = [];
    List<String> habitReasons = [];

    // Verificar palavras-chave de tarefa
    for (final keyword in _taskKeywords) {
      if (text.contains(keyword)) {
        taskScore += 1.0;
        taskReasons.add('Contém "$keyword"');
      }
    }

    // Verificar palavras-chave de hábito
    for (final keyword in _habitKeywords) {
      if (text.contains(keyword)) {
        habitScore += 1.0;
        habitReasons.add('Contém "$keyword"');
      }
    }

    // Verificar padrões de tarefa (peso maior)
    for (final pattern in _taskPatterns) {
      if (pattern.hasMatch(text)) {
        taskScore += 2.0;
        taskReasons.add('Padrão de data/hora detectado');
      }
    }

    // Verificar padrões de hábito (peso maior)
    for (final pattern in _habitPatterns) {
      if (pattern.hasMatch(text)) {
        habitScore += 2.0;
        habitReasons.add('Padrão de recorrência detectado');
      }
    }

    // Análise de comprimento e estrutura
    final words = text.split(' ');
    if (words.length <= 3) {
      // Textos curtos sem verbo de ação tendem a ser hábitos
      // Ex: "Meditação", "Leitura", "Exercício"
      if (!_startsWithActionVerb(text)) {
        habitScore += 0.5;
        habitReasons.add('Texto curto (possível nome de hábito)');
      }
    }

    // Calcular resultado
    final total = taskScore + habitScore;
    if (total == 0) {
      // Sem indicadores claros - perguntar ao usuário
      return ClassificationResult(
        type: ItemType.unknown,
        confidence: 0.0,
        reason: 'Não foi possível determinar automaticamente',
        suggestion: 'Isso é algo que você faz regularmente (hábito) ou uma vez só (tarefa)?',
      );
    }

    final taskConfidence = taskScore / total;
    final habitConfidence = habitScore / total;

    if (taskConfidence > habitConfidence) {
      return ClassificationResult(
        type: ItemType.task,
        confidence: taskConfidence,
        reason: taskReasons.take(3).join(', '),
      );
    } else if (habitConfidence > taskConfidence) {
      return ClassificationResult(
        type: ItemType.habit,
        confidence: habitConfidence,
        reason: habitReasons.take(3).join(', '),
      );
    } else {
      // Empate - pedir confirmação
      return ClassificationResult(
        type: ItemType.unknown,
        confidence: 0.5,
        reason: 'Características mistas detectadas',
        suggestion: 'Isso é algo que você faz regularmente (hábito) ou uma vez só (tarefa)?',
      );
    }
  }

  /// Verifica se começa com verbo de ação (indicador de tarefa)
  static bool _startsWithActionVerb(String text) {
    final actionVerbs = [
      'comprar', 'enviar', 'ligar', 'fazer', 'criar', 'escrever',
      'mandar', 'pegar', 'levar', 'buscar', 'marcar', 'agendar',
    ];
    
    for (final verb in actionVerbs) {
      if (text.startsWith(verb)) return true;
    }
    return false;
  }

  /// Sugestões inteligentes baseadas no contexto
  static List<String> getSuggestions(ItemType type) {
    if (type == ItemType.habit) {
      return [
        '🧘 Meditação',
        '📚 Leitura',
        '💪 Exercício',
        '💧 Beber água',
        '🌅 Acordar cedo',
        '📝 Journaling',
        '🍎 Alimentação saudável',
        '😴 Dormir 8h',
      ];
    } else {
      return [
        '📧 Responder emails',
        '📞 Ligar para...',
        '🛒 Comprar...',
        '📅 Agendar...',
        '💰 Pagar conta',
        '📝 Enviar relatório',
        '🔧 Consertar...',
        '📦 Entregar...',
      ];
    }
  }
}

enum ItemType {
  habit,
  task,
  unknown,
}

class ClassificationResult {
  final ItemType type;
  final double confidence; // 0.0 a 1.0
  final String reason;
  final String? suggestion;

  ClassificationResult({
    required this.type,
    required this.confidence,
    required this.reason,
    this.suggestion,
  });

  bool get isConfident => confidence >= 0.6;
  
  String get typeLabel {
    switch (type) {
      case ItemType.habit:
        return 'Hábito';
      case ItemType.task:
        return 'Tarefa';
      case ItemType.unknown:
        return 'Indefinido';
    }
  }

  String get confidenceLabel {
    if (confidence >= 0.8) return 'Alta';
    if (confidence >= 0.6) return 'Média';
    if (confidence >= 0.4) return 'Baixa';
    return 'Muito baixa';
  }
}
