import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/gen/assets.gen.dart';

class DataSeeder {
  static final Random _random = Random();

  /// Seeds data only if boxes are empty
  static Future<void> seedIfEmpty() async {
    Box<MoodRecord> moodBox;
    try {
      moodBox = await Hive.openBox<MoodRecord>('moodRecordsBox_v2');
    } catch (e) {
      debugPrint('Error opening moodRecordsBox_v2 in seeder: $e');
      try {
        await Hive.deleteBoxFromDisk('moodRecordsBox_v2');
      } catch (e) {
        debugPrint('Error deleting moodRecordsBox_v2: $e');
      }
      moodBox = await Hive.openBox<MoodRecord>('moodRecordsBox_v2');
    }

    if (moodBox.isEmpty) {
      await seedAllData();
    }
  }

  static Future<void> seedAllData() async {
    await _seedMoodRecords();
    await _seedTimeTrackingRecords();
    await _seedNotes();
    await _seedTasks();
    await _seedGamificationData();
  }

  static Future<void> _seedMoodRecords() async {
    final box = await Hive.openBox<MoodRecord>('moodRecordsBox_v2');
    
    // Clear existing data
    await box.clear();

    final moods = [
      {'label': 'Great', 'score': 5, 'color': Colors.green.value, 'icon': Assets.moodIcons.happy},
      {'label': 'Good', 'score': 4, 'color': Colors.cyan.value, 'icon': Assets.moodIcons.smile},
      {'label': 'Alright', 'score': 3, 'color': Colors.blue.value, 'icon': Assets.moodIcons.neutral},
      {'label': 'Not Good', 'score': 2, 'color': Colors.orange.value, 'icon': Assets.moodIcons.confused},
      {'label': 'Terrible', 'score': 1, 'color': Colors.red.value, 'icon': Assets.moodIcons.crying},
    ];

    final activities = [
      'Trabalho', 'Exercício', 'Família', 'Leitura', 'Meditação',
      'Música', 'Natureza', 'Amigos', 'Descanso', 'Estudo'
    ];

    final notes = [
      'Dia produtivo!',
      'Me senti muito bem depois de fazer exercício',
      'Reunião estressante no trabalho',
      'Passei tempo de qualidade com a família',
      'Meditei pela manhã e fez diferença',
      'Li um livro incrível',
      'Dormi pouco ontem',
      'Caminhada ao ar livre foi renovadora',
      'Ansioso com o projeto',
      'Gratidão pelo dia de hoje',
      null,
      null,
      null,
    ];

    // Create records for the last 30 days
    final now = DateTime.now();
    for (int day = 30; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      // 1-3 records per day
      final recordsToday = _random.nextInt(3) + 1;
      
      for (int i = 0; i < recordsToday; i++) {
        final hour = 8 + _random.nextInt(14); // Between 8am and 10pm
        final minute = _random.nextInt(60);
        final recordDate = DateTime(date.year, date.month, date.day, hour, minute);
        
        // Slightly favor good moods (more realistic)
        final moodIndex = _weightedRandom([0.15, 0.35, 0.25, 0.15, 0.10]);
        final mood = moods[moodIndex];
        
        final record = MoodRecord(
          label: mood['label'] as String,
          score: mood['score'] as int,
          color: mood['color'] as int,
          iconPath: mood['icon'] as String,
          date: recordDate,
          note: notes[_random.nextInt(notes.length)],
          activities: [], // Would need Activity objects
        );
        
        await box.add(record);
      }
    }
  }

  static Future<void> _seedTimeTrackingRecords() async {
    final box = await Hive.openBox<TimeTrackingRecord>('timeTrackingRecordsBox');
    
    await box.clear();

    final activities = [
      {'name': 'Trabalho', 'icon': 0xe8f9}, // work
      {'name': 'Estudo', 'icon': 0xe86d}, // menu_book
      {'name': 'Exercício', 'icon': 0xe563}, // fitness_center
      {'name': 'Meditação', 'icon': 0xe32d}, // self_improvement
      {'name': 'Leitura', 'icon': 0xe86d}, // book
      {'name': 'Coding', 'icon': 0xe86f}, // code
      {'name': 'Projeto Pessoal', 'icon': 0xe8af}, // folder
      {'name': 'Revisão', 'icon': 0xe8b5}, // find_in_page
    ];

    final notes = [
      'Sessão produtiva',
      'Foquei bem hoje',
      'Um pouco distraído',
      'Consegui terminar o que queria',
      'Preciso melhorar amanhã',
      null,
      null,
      null,
    ];

    final now = DateTime.now();
    for (int day = 20; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      // 1-4 time records per day
      final recordsToday = _random.nextInt(4) + 1;
      
      for (int i = 0; i < recordsToday; i++) {
        final hour = 8 + _random.nextInt(12);
        final minute = _random.nextInt(60);
        final startTime = DateTime(date.year, date.month, date.day, hour, minute);
        
        // Duration between 15 and 120 minutes
        final durationMinutes = 15 + _random.nextInt(106);
        final endTime = startTime.add(Duration(minutes: durationMinutes));
        
        final activity = activities[_random.nextInt(activities.length)];
        
        final record = TimeTrackingRecord(
          id: '${date.millisecondsSinceEpoch}_$i',
          activityName: activity['name'] as String,
          iconCode: activity['icon'] as int,
          startTime: startTime,
          endTime: endTime,
          duration: Duration(minutes: durationMinutes),
          notes: notes[_random.nextInt(notes.length)],
        );
        
        await box.add(record);
      }
    }
  }

  static Future<void> _seedNotes() async {
    final box = await Hive.openBox('notes');
    
    await box.clear();

    final sampleNotes = [
      {
        'content': 'Ideia para novo projeto: App de meditação com gamificação integrada. '
            'Poderia ter desafios semanais e recompensas por consistência.',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'content': 'Lista de livros para ler:\n'
            '• Atomic Habits - James Clear\n'
            '• Deep Work - Cal Newport\n'
            '• The Power of Now - Eckhart Tolle',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'content': 'Reflexão do dia: Hoje percebi como pequenas pausas durante o trabalho '
            'melhoram muito minha produtividade. Vou implementar a técnica Pomodoro.',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'content': 'Metas do mês:\n'
            '1. Meditar 10 min/dia\n'
            '2. Exercitar 3x/semana\n'
            '3. Ler 30 min/dia\n'
            '4. Dormir antes das 23h',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'content': 'Receita de smoothie verde:\n'
            '- 1 banana\n'
            '- Punhado de espinafre\n'
            '- 1 colher de pasta de amendoim\n'
            '- 200ml leite de amêndoas\n'
            '- Gelo',
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'content': 'Insight interessante: A qualidade do meu humor está diretamente relacionada '
            'à quantidade de horas de sono da noite anterior. Preciso priorizar o sono!',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'content': 'Exercícios de respiração:\n'
            '4-7-8: Inspirar 4s, segurar 7s, expirar 8s\n'
            'Box breathing: 4s cada fase\n'
            'Funciona muito bem para ansiedade!',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
    ];

    for (var i = 0; i < sampleNotes.length; i++) {
      final note = sampleNotes[i];
      await box.put('note_${DateTime.now().millisecondsSinceEpoch + i}', note);
    }
  }

  static Future<void> _seedTasks() async {
    final box = await Hive.openBox('tasks');
    
    await box.clear();

    final tasks = [
      // Pending tasks
      {'title': 'Revisar apresentação do projeto', 'completed': false},
      {'title': 'Ligar para o médico', 'completed': false},
      {'title': 'Comprar presentes de aniversário', 'completed': false},
      {'title': 'Estudar Flutter por 1h', 'completed': false},
      {'title': 'Organizar mesa de trabalho', 'completed': false},
      {'title': 'Fazer backup do celular', 'completed': false},
      
      // Completed tasks
      {'title': 'Terminar relatório semanal', 'completed': true},
      {'title': 'Reunião com equipe', 'completed': true},
      {'title': 'Pagar contas do mês', 'completed': true},
      {'title': 'Ir à academia', 'completed': true},
      {'title': 'Responder emails', 'completed': true},
      {'title': 'Comprar mantimentos', 'completed': true},
      {'title': 'Meditar 15 minutos', 'completed': true},
      {'title': 'Ler capítulo do livro', 'completed': true},
    ];

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      await box.put('task_${DateTime.now().millisecondsSinceEpoch + i}', {
        'title': task['title'],
        'completed': task['completed'],
        'createdAt': DateTime.now().subtract(Duration(days: tasks.length - i)).toIso8601String(),
      });
    }
  }

  static Future<void> _seedGamificationData() async {
    final box = await Hive.openBox('gamification');
    
    await box.put('user_stats', {
      'totalXP': 2850,
      'level': 7,
      'currentStreak': 12,
      'longestStreak': 18,
      'lastActiveDate': DateTime.now().toIso8601String(),
      'moodRecordsCount': 45,
      'timeTrackedMinutes': 725,
      'tasksCompleted': 48,
      'notesCreated': 15,
      'pomodoroSessions': 32,
      'unlockedBadges': [
        'first_mood',
        'first_task',
        'streak_3',
        'streak_7',
        'mood_10',
        'tasks_10',
        'time_60',
        'time_300',
        'time_600',
        'pomo_5',
        'pomo_25',
        'notes_10',
        'tasks_10',
      ],
    });
  }

  // Weighted random selection
  static int _weightedRandom(List<double> weights) {
    final total = weights.reduce((a, b) => a + b);
    final random = _random.nextDouble() * total;
    
    double cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return i;
      }
    }
    return weights.length - 1;
  }
}
