import 'package:hive_flutter/hive_flutter.dart';

part 'language.g.dart';

@HiveType(typeId: 20)
class Language extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String flag; // Emoji flag like 🇺🇸, 🇯🇵

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final String level; // A1, A2, B1, B2, C1, C2

  @HiveField(5)
  final int totalMinutesStudied;

  @HiveField(6)
  final int currentStreak;

  @HiveField(7)
  final int bestStreak;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? lastStudiedAt;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final int order;

  Language({
    required this.id,
    required this.name,
    required this.flag,
    required this.colorValue,
    this.level = 'A1',
    this.totalMinutesStudied = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
    this.lastStudiedAt,
    this.notes,
    this.order = 0,
  });

  Language copyWith({
    String? id,
    String? name,
    String? flag,
    int? colorValue,
    String? level,
    int? totalMinutesStudied,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? lastStudiedAt,
    String? notes,
    int? order,
  }) {
    return Language(
      id: id ?? this.id,
      name: name ?? this.name,
      flag: flag ?? this.flag,
      colorValue: colorValue ?? this.colorValue,
      level: level ?? this.level,
      totalMinutesStudied: totalMinutesStudied ?? this.totalMinutesStudied,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }

  String get formattedTotalTime {
    final hours = totalMinutesStudied ~/ 60;
    final minutes = totalMinutesStudied % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get studiedToday {
    if (lastStudiedAt == null) return false;
    final now = DateTime.now();
    return lastStudiedAt!.year == now.year &&
        lastStudiedAt!.month == now.month &&
        lastStudiedAt!.day == now.day;
  }
}

// Lista de níveis de proficiência CEFR
class LanguageLevels {
  static const List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  
  static String getDescription(String level) {
    switch (level) {
      case 'A1': return 'Iniciante';
      case 'A2': return 'Básico';
      case 'B1': return 'Intermediário';
      case 'B2': return 'Intermediário Superior';
      case 'C1': return 'Avançado';
      case 'C2': return 'Proficiente';
      default: return 'Iniciante';
    }
  }
}

// Ícones estilizados para idiomas (usando caracteres/letras estilizadas)
class LanguageIcons {
  static const Map<String, String> icons = {
    'english': 'EN',
    'spanish': 'ES',
    'french': 'FR',
    'german': 'DE',
    'italian': 'IT',
    'japanese': 'あ',
    'korean': '한',
    'mandarin': '中',
    'russian': 'RU',
    'portuguese': 'PT',
    'arabic': 'ع',
    'hindi': 'हि',
    'dutch': 'NL',
    'swedish': 'SV',
    'turkish': 'TR',
    'polish': 'PL',
    'greek': 'Ω',
    'hebrew': 'עב',
    'thai': 'ไท',
    'vietnamese': 'VI',
    'custom': '✦',
  };

  static String getIcon(String languageKey) {
    return icons[languageKey.toLowerCase()] ?? icons['custom']!;
  }
}

// Idiomas comuns pré-configurados
class CommonLanguages {
  static List<Map<String, dynamic>> get list => [
    {'name': 'Inglês', 'icon': 'EN', 'color': 0xFF3B82F6, 'key': 'english'},
    {'name': 'Espanhol', 'icon': 'ES', 'color': 0xFFEF4444, 'key': 'spanish'},
    {'name': 'Francês', 'icon': 'FR', 'color': 0xFF8B5CF6, 'key': 'french'},
    {'name': 'Alemão', 'icon': 'DE', 'color': 0xFFF59E0B, 'key': 'german'},
    {'name': 'Italiano', 'icon': 'IT', 'color': 0xFF10B981, 'key': 'italian'},
    {'name': 'Japonês', 'icon': 'あ', 'color': 0xFFEC4899, 'key': 'japanese'},
    {'name': 'Coreano', 'icon': '한', 'color': 0xFF06B6D4, 'key': 'korean'},
    {'name': 'Mandarim', 'icon': '中', 'color': 0xFFDC2626, 'key': 'mandarin'},
    {'name': 'Russo', 'icon': 'RU', 'color': 0xFF6366F1, 'key': 'russian'},
    {'name': 'Português', 'icon': 'PT', 'color': 0xFF22C55E, 'key': 'portuguese'},
    {'name': 'Árabe', 'icon': 'ع', 'color': 0xFF14B8A6, 'key': 'arabic'},
    {'name': 'Hindi', 'icon': 'हि', 'color': 0xFFF97316, 'key': 'hindi'},
    {'name': 'Holandês', 'icon': 'NL', 'color': 0xFFFF6B6B, 'key': 'dutch'},
    {'name': 'Sueco', 'icon': 'SV', 'color': 0xFF4ECDC4, 'key': 'swedish'},
    {'name': 'Turco', 'icon': 'TR', 'color': 0xFFFFE66D, 'key': 'turkish'},
  ];
}
