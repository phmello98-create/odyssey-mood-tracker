import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'study_session.g.dart';

@HiveType(typeId: 21)
class StudySession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String languageId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final String activityType; // reading, writing, listening, speaking, grammar, vocabulary

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final int? rating; // 1-5 stars for how productive the session was

  @HiveField(7)
  final String? resource; // Book, app, course name, etc.

  StudySession({
    required this.id,
    required this.languageId,
    required this.startTime,
    required this.durationMinutes,
    required this.activityType,
    this.notes,
    this.rating,
    this.resource,
  });

  StudySession copyWith({
    String? id,
    String? languageId,
    DateTime? startTime,
    int? durationMinutes,
    String? activityType,
    String? notes,
    int? rating,
    String? resource,
  }) {
    return StudySession(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      activityType: activityType ?? this.activityType,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      resource: resource ?? this.resource,
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

// Tipos de atividade de estudo
class StudyActivityTypes {
  static const String reading = 'reading';
  static const String writing = 'writing';
  static const String listening = 'listening';
  static const String speaking = 'speaking';
  static const String grammar = 'grammar';
  static const String vocabulary = 'vocabulary';
  static const String conversation = 'conversation';
  static const String immersion = 'immersion';

  static List<Map<String, dynamic>> get all => [
    {'id': reading, 'name': 'Leitura', 'icon': 0xe3f3}, // book icon
    {'id': writing, 'name': 'Escrita', 'icon': 0xe22b}, // edit icon
    {'id': listening, 'name': 'Escuta', 'icon': 0xe310}, // headphones icon
    {'id': speaking, 'name': 'Fala', 'icon': 0xe3ba}, // mic icon
    {'id': grammar, 'name': 'Gramática', 'icon': 0xe54d}, // school icon
    {'id': vocabulary, 'name': 'Vocabulário', 'icon': 0xe260}, // format_list icon
    {'id': conversation, 'name': 'Conversação', 'icon': 0xe0ca}, // chat icon
    {'id': immersion, 'name': 'Imersão', 'icon': 0xe40a}, // movie icon
  ];

  static String getName(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'name': id})['name'];
  }

  static int getIconCode(String id) {
    return all.firstWhere((a) => a['id'] == id, orElse: () => {'icon': 0xe3f3})['icon'];
  }

  static IconData getIcon(String id) {
    switch (id) {
      case reading:
        return const IconData(0xe3f3, fontFamily: 'MaterialIcons');
      case writing:
        return const IconData(0xe22b, fontFamily: 'MaterialIcons');
      case listening:
        return const IconData(0xe310, fontFamily: 'MaterialIcons');
      case speaking:
        return const IconData(0xe3ba, fontFamily: 'MaterialIcons');
      case grammar:
        return const IconData(0xe54d, fontFamily: 'MaterialIcons');
      case vocabulary:
        return const IconData(0xe260, fontFamily: 'MaterialIcons');
      case conversation:
        return const IconData(0xe0ca, fontFamily: 'MaterialIcons');
      case immersion:
        return const IconData(0xe40a, fontFamily: 'MaterialIcons');
      default:
        return const IconData(0xe3f3, fontFamily: 'MaterialIcons');
    }
  }
}
