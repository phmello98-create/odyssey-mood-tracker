import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'immersion_log.g.dart';

@HiveType(typeId: 24)
class ImmersionLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String languageId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final String type; // movie, series, anime, music, podcast, youtube, book, game, conversation

  @HiveField(5)
  final String? title; // Title of what was watched/listened

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final int? rating; // 1-5 how useful it was

  @HiveField(8)
  final bool withSubtitles;

  @HiveField(9)
  final String? subtitleLanguage; // "native", "target", "none"

  ImmersionLog({
    required this.id,
    required this.languageId,
    required this.date,
    required this.durationMinutes,
    required this.type,
    this.title,
    this.notes,
    this.rating,
    this.withSubtitles = false,
    this.subtitleLanguage,
  });

  ImmersionLog copyWith({
    String? id,
    String? languageId,
    DateTime? date,
    int? durationMinutes,
    String? type,
    String? title,
    String? notes,
    int? rating,
    bool? withSubtitles,
    String? subtitleLanguage,
  }) {
    return ImmersionLog(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      withSubtitles: withSubtitles ?? this.withSubtitles,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
    );
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class ImmersionTypes {
  static const String movie = 'movie';
  static const String series = 'series';
  static const String anime = 'anime';
  static const String music = 'music';
  static const String podcast = 'podcast';
  static const String youtube = 'youtube';
  static const String book = 'book';
  static const String game = 'game';
  static const String conversation = 'conversation';
  static const String social = 'social';
  static const String news = 'news';

  static List<Map<String, dynamic>> get all => [
    {'id': movie, 'name': 'Filme', 'icon': 0xe40a, 'color': 0xFFEF4444, 'defaultDuration': 120}, // movie
    {'id': series, 'name': 'Série', 'icon': 0xe879, 'color': 0xFF8B5CF6, 'defaultDuration': 45}, // tv
    {'id': anime, 'name': 'Anime', 'icon': 0xe87d, 'color': 0xFFEC4899, 'defaultDuration': 25}, // theaters
    {'id': music, 'name': 'Música', 'icon': 0xe3e9, 'color': 0xFF10B981, 'defaultDuration': 30}, // music_note
    {'id': podcast, 'name': 'Podcast', 'icon': 0xe33a, 'color': 0xFFF59E0B, 'defaultDuration': 45}, // podcasts
    {'id': youtube, 'name': 'YouTube', 'icon': 0xe037, 'color': 0xFFDC2626, 'defaultDuration': 20}, // ondemand_video
    {'id': book, 'name': 'Livro', 'icon': 0xe3f3, 'color': 0xFF3B82F6, 'defaultDuration': 30}, // book
    {'id': game, 'name': 'Jogo', 'icon': 0xe30f, 'color': 0xFF14B8A6, 'defaultDuration': 60}, // games
    {'id': conversation, 'name': 'Conversa', 'icon': 0xe0ca, 'color': 0xFF06B6D4, 'defaultDuration': 30}, // chat
    {'id': social, 'name': 'Redes', 'icon': 0xe7fd, 'color': 0xFF6366F1, 'defaultDuration': 15}, // public
    {'id': news, 'name': 'Notícias', 'icon': 0xe3e0, 'color': 0xFF64748B, 'defaultDuration': 20}, // article
  ];

  static String getName(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'name': id})['name'];
  }

  static int getIconCode(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'icon': 0xe40a})['icon'];
  }

  static int getColor(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'color': 0xFF3B82F6})['color'];
  }

  static int getDefaultDuration(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'defaultDuration': 30})['defaultDuration'];
  }

  static IconData getIcon(String id) {
    switch (id) {
      case movie:
        return const IconData(0xe40a, fontFamily: 'MaterialIcons');
      case series:
        return const IconData(0xe879, fontFamily: 'MaterialIcons');
      case anime:
        return const IconData(0xe87d, fontFamily: 'MaterialIcons');
      case music:
        return const IconData(0xe3e9, fontFamily: 'MaterialIcons');
      case podcast:
        return const IconData(0xe33a, fontFamily: 'MaterialIcons');
      case youtube:
        return const IconData(0xe037, fontFamily: 'MaterialIcons');
      case book:
        return const IconData(0xe3f3, fontFamily: 'MaterialIcons');
      case game:
        return const IconData(0xe30f, fontFamily: 'MaterialIcons');
      case conversation:
        return const IconData(0xe0ca, fontFamily: 'MaterialIcons');
      case social:
        return const IconData(0xe7fd, fontFamily: 'MaterialIcons');
      case news:
        return const IconData(0xe3e0, fontFamily: 'MaterialIcons');
      default:
        return const IconData(0xe40a, fontFamily: 'MaterialIcons');
    }
  }
}
