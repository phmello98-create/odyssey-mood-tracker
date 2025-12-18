/// Sistema de Tags/Hashtags da Comunidade

/// Tag de um post
class PostTag {
  final String name;
  final int postCount;
  final bool isTrending;

  const PostTag({
    required this.name,
    this.postCount = 0,
    this.isTrending = false,
  });

  String get displayName => '#$name';

  Map<String, dynamic> toJson() => {
    'name': name,
    'postCount': postCount,
    'isTrending': isTrending,
  };

  factory PostTag.fromJson(Map<String, dynamic> json) => PostTag(
    name: json['name'],
    postCount: json['postCount'] ?? 0,
    isTrending: json['isTrending'] ?? false,
  );

  /// Extrai tags de um texto (procura por #hashtags)
  static List<String> extractFromText(String text) {
    final regex = RegExp(r'#(\w+)', unicode: true);
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }
}

/// Tags sugeridas/populares
class SuggestedTags {
  static const List<String> all = [
    'produtividade',
    'meditação',
    'foco',
    'motivação',
    'gratidão',
    'hábitos',
    'saúdemental',
    'ansiedade',
    'mindfulness',
    'rotina',
    'autodisciplina',
    'metas',
    'progresso',
    'conquistas',
    'dicas',
    'apoio',
    'inspiração',
    'desafio',
    'vitória',
    'aprendizado',
  ];
}
