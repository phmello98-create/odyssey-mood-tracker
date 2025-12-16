// lib/src/features/diary/domain/entities/diary_entry_entity.dart

import 'diary_preferences.dart';

/// Entidade de entrada de diário - modelo puro de domínio
///
/// Esta é a entidade "limpa" sem dependências de Hive ou Freezed.
/// Usada para passar dados entre camadas de forma desacoplada.
class DiaryEntryEntity {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime entryDate;
  final String? title;
  final String content; // Quill Delta JSON
  final List<String> photoIds;
  final bool starred;
  final String? feeling; // Emoji code
  final List<String> tags;
  final String? searchableText; // Texto plano para busca
  final int? wordCount;
  final int? readingTimeMinutes;
  final String? templateId;
  final String? location;
  final String? weather;
  final DiaryPreferences? preferences; // Preferências visuais personalizadas

  const DiaryEntryEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.entryDate,
    this.title,
    required this.content,
    this.photoIds = const [],
    this.starred = false,
    this.feeling,
    this.tags = const [],
    this.searchableText,
    this.wordCount,
    this.readingTimeMinutes,
    this.templateId,
    this.location,
    this.weather,
    this.preferences,
  });

  /// Cria uma cópia com campos modificados
  DiaryEntryEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? entryDate,
    String? title,
    String? content,
    List<String>? photoIds,
    bool? starred,
    String? feeling,
    List<String>? tags,
    String? searchableText,
    int? wordCount,
    int? readingTimeMinutes,
    String? templateId,
    String? location,
    String? weather,
    DiaryPreferences? preferences,
  }) {
    return DiaryEntryEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      content: content ?? this.content,
      photoIds: photoIds ?? this.photoIds,
      starred: starred ?? this.starred,
      feeling: feeling ?? this.feeling,
      tags: tags ?? this.tags,
      searchableText: searchableText ?? this.searchableText,
      wordCount: wordCount ?? this.wordCount,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      templateId: templateId ?? this.templateId,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Cria uma entrada vazia
  factory DiaryEntryEntity.empty() {
    final now = DateTime.now();
    return DiaryEntryEntity(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      entryDate: now,
      content: '[]', // Empty Quill Delta
    );
  }

  /// Cria uma entrada para uma data específica
  factory DiaryEntryEntity.forDate(DateTime date) {
    final now = DateTime.now();
    return DiaryEntryEntity(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      entryDate: date,
      content: '[]',
    );
  }

  /// Verifica se a entrada tem conteúdo
  bool get hasContent => content != '[]' && content.isNotEmpty;

  /// Verifica se a entrada tem título
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// Verifica se a entrada tem fotos
  bool get hasPhotos => photoIds.isNotEmpty;

  /// Verifica se a entrada tem tags
  bool get hasTags => tags.isNotEmpty;

  /// Verifica se é uma entrada de hoje
  bool get isToday {
    final now = DateTime.now();
    return entryDate.year == now.year &&
           entryDate.month == now.month &&
           entryDate.day == now.day;
  }

  /// Retorna a contagem de palavras (calculada ou armazenada)
  int get effectiveWordCount {
    if (wordCount != null) return wordCount!;
    if (searchableText == null || searchableText!.isEmpty) return 0;
    return searchableText!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Retorna o tempo de leitura estimado em minutos
  int get effectiveReadingTime {
    if (readingTimeMinutes != null) return readingTimeMinutes!;
    // Média de 200 palavras por minuto
    return (effectiveWordCount / 200).ceil().clamp(1, 999);
  }

  /// Retorna um preview do conteúdo em texto plano
  String get plainTextPreview {
    if (searchableText != null && searchableText!.isNotEmpty) {
      return searchableText!.length > 150 
          ? '${searchableText!.substring(0, 150)}...' 
          : searchableText!;
    }
    // Tentar extrair texto do content (Quill Delta)
    if (content == '[]' || content.isEmpty) return '';
    try {
      // Simples extração - procurar por "insert" com texto
      final regex = RegExp(r'"insert"\s*:\s*"([^"]+)"');
      final matches = regex.allMatches(content);
      final text = matches.map((m) => m.group(1) ?? '').join(' ').trim();
      return text.length > 150 ? '${text.substring(0, 150)}...' : text;
    } catch (_) {
      return '';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntryEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DiaryEntryEntity(id: $id, title: $title, date: $entryDate)';
}
