// lib/src/features/diary/domain/entities/diary_template.dart

/// Template de entrada de diário
class DiaryTemplate {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final String initialContent; // Quill Delta JSON
  final List<String> suggestedTags;
  final bool isCustom;

  const DiaryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.initialContent,
    this.suggestedTags = const [],
    this.isCustom = false,
  });

  /// Templates padrão do app
  static List<DiaryTemplate> get defaultTemplates => [
    const DiaryTemplate(
      id: 'free',
      name: 'Diário Livre',
      description: 'Página em branco para escrever livremente',
      iconEmoji: '📝',
      initialContent: '[]',
    ),
    const DiaryTemplate(
      id: 'gratitude',
      name: 'Gratidão',
      description: '3 coisas boas do dia',
      iconEmoji: '🙏',
      initialContent: _gratitudeTemplate,
      suggestedTags: ['gratidão', 'positivo'],
    ),
    const DiaryTemplate(
      id: 'reflection',
      name: 'Reflexão Guiada',
      description: 'Perguntas para refletir sobre o dia',
      iconEmoji: '🤔',
      initialContent: _reflectionTemplate,
      suggestedTags: ['reflexão', 'autoconhecimento'],
    ),
    const DiaryTemplate(
      id: 'mood_journal',
      name: 'Mood Journal',
      description: 'Humor + eventos + reflexão',
      iconEmoji: '😊',
      initialContent: _moodJournalTemplate,
      suggestedTags: ['humor', 'bem-estar'],
    ),
    const DiaryTemplate(
      id: 'bullet',
      name: 'Bullet Journal',
      description: 'Lista de eventos, tarefas e notas',
      iconEmoji: '📋',
      initialContent: _bulletTemplate,
      suggestedTags: ['organização', 'tarefas'],
    ),
  ];

  /// Template de Gratidão
  static const String _gratitudeTemplate = '''[
    {"insert": "🙏 Hoje sou grato(a) por:\\n\\n"},
    {"insert": "1. "},
    {"insert": "\\n"},
    {"insert": "2. "},
    {"insert": "\\n"},
    {"insert": "3. "},
    {"insert": "\\n\\n"},
    {"insert": "💭 Por que essas coisas são importantes?\\n"},
    {"insert": "\\n"}
  ]''';

  /// Template de Reflexão Guiada
  static const String _reflectionTemplate = '''[
    {"insert": "📅 Como foi meu dia?\\n"},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "📚 O que aprendi hoje?\\n"},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "💪 Quais desafios enfrentei?\\n"},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "🎯 O que posso fazer melhor amanhã?\\n"},
    {"insert": "\\n"}
  ]''';

  /// Template de Mood Journal
  static const String _moodJournalTemplate = '''[
    {"insert": "😊 Como estou me sentindo?\\n"},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "📍 O que aconteceu hoje?\\n"},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "💭 Reflexão do dia:\\n"},
    {"insert": "\\n"}
  ]''';

  /// Template de Bullet Journal
  static const String _bulletTemplate = '''[
    {"insert": "📌 Eventos\\n"},
    {"insert": "• "},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "✅ Tarefas\\n"},
    {"insert": "☐ "},
    {"insert": "\\n"},
    {"insert": "\\n"},
    {"insert": "💡 Notas\\n"},
    {"insert": "- "},
    {"insert": "\\n"}
  ]''';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
