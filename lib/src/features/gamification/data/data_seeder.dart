import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/gen/assets.gen.dart';

class DataSeeder {
  static final Random _random = Random();

  /// Verifica cada box e popula dados se estiver vazia
  static Future<void> seedIfEmpty() async {
    // 1. Mood Records
    try {
      final moodBox = await Hive.openBox<MoodRecord>('moodRecordsBox_v2');
      if (moodBox.isEmpty) {
        await _seedMoodRecords(moodBox);
      }
    } catch (e) {
      debugPrint('Error accessing mood box in seeder: $e');
    }

    // 2. Time Tracking
    try {
      final timeBox = await Hive.openBox<TimeTrackingRecord>(
        'timeTrackingRecordsBox',
      );
      if (timeBox.isEmpty) {
        await _seedTimeTrackingRecords(timeBox);
      }
    } catch (e) {
      debugPrint('Error accessing time tracking box: $e');
    }

    // 3. Notes
    try {
      final notesBox = await Hive.openBox('notes');
      if (notesBox.isEmpty) {
        await _seedNotes(notesBox);
      }
    } catch (e) {
      debugPrint('Error accessing notes box: $e');
    }

    // 4. Tasks (dados ricos)
    try {
      final taskBox = await Hive.openBox('tasks');
      // Relaxed check: if we have few tasks (likely just old mocks or empty), re-seed
      if (taskBox.length < 5) {
        debugPrint('🌱 Seeding Tasks (Standard Set)...');
        await _seedTasks(taskBox);
      }
    } catch (e) {
      debugPrint('Error accessing tasks box: $e');
    }

    // 5. Habits
    try {
      // Verifica se o adapter já está registrado (HabitRepository deve ter feito isso)
      if (Hive.isAdapterRegistered(10)) {
        final habitBox = await Hive.openBox<Habit>('habits');
        if (habitBox.length < 2) {
          debugPrint('🌱 Seeding Habits (Standard Set)...');
          await _seedHabits(habitBox);
        }
      }
    } catch (e) {
      debugPrint('Error accessing habits box: $e');
    }

    // 6. Gamification
    try {
      final gameBox = await Hive.openBox('gamification');
      if (gameBox.isEmpty) {
        await _seedGamificationData(gameBox);
      }
    } catch (e) {
      debugPrint('Error accessing gamification box: $e');
    }
  }

  static Future<void> seedAllData() async {
    // Força re-seed de tudo (cuidado ao usar)
    await seedIfEmpty();
  }

  static Future<void> _seedMoodRecords(Box<MoodRecord> box) async {
    // Clear existing data (redundant if checking isEmpty but safe)
    await box.clear();

    final moods = [
      {
        'label': 'Great',
        'score': 5,
        'color': Colors.green.value,
        'icon': Assets.moodIcons.happy,
      },
      {
        'label': 'Good',
        'score': 4,
        'color': Colors.cyan.value,
        'icon': Assets.moodIcons.smile,
      },
      {
        'label': 'Alright',
        'score': 3,
        'color': Colors.blue.value,
        'icon': Assets.moodIcons.neutral,
      },
      {
        'label': 'Not Good',
        'score': 2,
        'color': Colors.orange.value,
        'icon': Assets.moodIcons.confused,
      },
      {
        'label': 'Terrible',
        'score': 1,
        'color': Colors.red.value,
        'icon': Assets.moodIcons.crying,
      },
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
      final recordsToday = _random.nextInt(3) + 1;

      for (int i = 0; i < recordsToday; i++) {
        final hour = 8 + _random.nextInt(14); // Between 8am and 10pm
        final minute = _random.nextInt(60);
        final recordDate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        final moodIndex = _weightedRandom([0.15, 0.35, 0.25, 0.15, 0.10]);
        final mood = moods[moodIndex];

        final record = MoodRecord(
          label: mood['label'] as String,
          score: mood['score'] as int,
          color: mood['color'] as int,
          iconPath: mood['icon'] as String,
          date: recordDate,
          note: notes[_random.nextInt(notes.length)],
          activities: [],
        );

        await box.add(record);
      }
    }
  }

  static Future<void> _seedTimeTrackingRecords(
    Box<TimeTrackingRecord> box,
  ) async {
    await box.clear();

    final activities = [
      {'name': 'Trabalho', 'icon': 0xe8f9},
      {'name': 'Estudo', 'icon': 0xe86d},
      {'name': 'Exercício', 'icon': 0xe563},
      {'name': 'Meditação', 'icon': 0xe32d},
      {'name': 'Leitura', 'icon': 0xe86d},
      {'name': 'Coding', 'icon': 0xe86f},
      {'name': 'Projeto Pessoal', 'icon': 0xe8af},
    ];

    final notes = [
      'Sessão produtiva',
      'Foquei bem hoje',
      'Um pouco distraído',
      'Consegui terminar o que queria',
      null,
      null,
    ];

    final now = DateTime.now();
    for (int day = 20; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      final recordsToday = _random.nextInt(4) + 1;

      for (int i = 0; i < recordsToday; i++) {
        final hour = 8 + _random.nextInt(12);
        final minute = _random.nextInt(60);
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
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

  static Future<void> _seedNotes(Box box) async {
    await box.clear();

    final sampleNotes = [
      {
        'content':
            'Ideia para novo projeto: App de meditação com gamificação integrada.',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
      },
      {
        'content': 'Lista de livros para ler:\n• Atomic Habits\n• Deep Work',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      },
      {
        'content':
            'Metas do mês:\n1. Meditar 10 min/dia\n2. Exercitar 3x/semana',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];

    for (var i = 0; i < sampleNotes.length; i++) {
      final note = sampleNotes[i];
      await box.put('note_${DateTime.now().millisecondsSinceEpoch + i}', note);
    }
  }

  static Future<void> _seedTasks(Box box) async {
    await box.clear();
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String();

    // Dados para popular
    final tasksData = [
      // Pendentes - Hoje
      {
        'title': 'Reunião de Design System',
        'notes':
            'Discutir a paleta de cores e tipografia para a nova versão. Revisar componentes no Figma.',
        'completed': false,
        'priority': 'high',
        'category': 'Trabalho',
        'dueDate': iso(now),
        'dueTime': '14:30',
        'createdAt': iso(now.subtract(const Duration(hours: 2))),
      },
      {
        'title': 'Ir à Academia',
        'notes': 'Treino de perna e cardio - 30 minutos de esteira.',
        'completed': false,
        'priority': 'medium',
        'category': 'Saúde',
        'dueDate': iso(now),
        'dueTime': '18:00',
        'createdAt': iso(now.subtract(const Duration(hours: 4))),
      },
      // Pendentes - Amanhã
      {
        'title': 'Ler documentação do Riverpod',
        'notes': 'Focar em AsyncNotifier e testes de unidade.',
        'completed': false,
        'priority': 'low',
        'category': 'Estudo',
        'dueDate': iso(now.add(const Duration(days: 1))),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(days: 1))),
      },
      // Pendentes - Semana
      {
        'title': 'Compras da semana',
        'notes': 'Frutas, vegetais, ovos, itens de limpeza e ração do gato.',
        'completed': false,
        'priority': 'medium',
        'category': 'Pessoal',
        'dueDate': iso(now.add(const Duration(days: 2))),
        'dueTime': '10:00',
        'createdAt': iso(now.subtract(const Duration(days: 1))),
      },
      // Completadas
      {
        'title': 'Pagar conta de internet',
        'notes': null,
        'completed': true,
        'priority': 'high',
        'category': 'Finanças',
        'dueDate': iso(now.subtract(const Duration(days: 1))),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(days: 5))),
        'completedAt': iso(now.subtract(const Duration(days: 1))),
      },
      {
        'title': 'Consulta odontológica',
        'notes': 'Check-up semestral',
        'completed': true,
        'priority': 'medium',
        'category': 'Saúde',
        'dueDate': iso(now.subtract(const Duration(days: 3))),
        'dueTime': '15:00',
        'createdAt': iso(now.subtract(const Duration(days: 10))),
        'completedAt': iso(now.subtract(const Duration(days: 3))),
      },
    ];

    for (var i = 0; i < tasksData.length; i++) {
      final task = tasksData[i];
      // Gerar chave baseada no tempo para garantir ordem
      final key = DateTime.now().millisecondsSinceEpoch + i;
      await box.put(key.toString(), task);
    }
  }

  static Future<void> _seedHabits(Box<Habit> box) async {
    await box.clear();
    final now = DateTime.now();

    final sampleHabits = [
      Habit(
        id: 'habit_1_${now.millisecondsSinceEpoch}',
        name: 'Meditação Diária',
        iconCode: Icons.self_improvement.codePoint,
        colorValue: const Color(0xFF9B51E0).value,
        scheduledTime: '06:30',
        daysOfWeek: [], // Todos os dias
        completedDates: [
          now.subtract(const Duration(days: 1)),
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 3)),
        ],
        currentStreak: 3,
        bestStreak: 7,
        createdAt: now.subtract(const Duration(days: 30)),
        order: 0,
      ),
      Habit(
        id: 'habit_2_${now.millisecondsSinceEpoch}',
        name: 'Beber 2L água',
        iconCode: Icons.water_drop.codePoint,
        colorValue: const Color(0xFF00B4D8).value,
        scheduledTime: null,
        daysOfWeek: [],
        completedDates: [now, now.subtract(const Duration(days: 1))],
        currentStreak: 2,
        bestStreak: 15,
        createdAt: now.subtract(const Duration(days: 20)),
        order: 1,
      ),
      Habit(
        id: 'habit_3_${now.millisecondsSinceEpoch}',
        name: 'Ler 30 min',
        iconCode: Icons.menu_book.codePoint,
        colorValue: const Color(0xFF07E092).value,
        scheduledTime: '22:00',
        daysOfWeek: [],
        completedDates: [],
        currentStreak: 0,
        bestStreak: 5,
        createdAt: now.subtract(const Duration(days: 10)),
        order: 2,
      ),
      Habit(
        id: 'habit_4_${now.millisecondsSinceEpoch}',
        name: 'Corrida Matinal',
        iconCode: Icons.directions_run.codePoint,
        colorValue: const Color(0xFFFF6B6B).value,
        scheduledTime: '07:00',
        daysOfWeek: [1, 3, 5], // Seg, Qua, Sex
        completedDates: [
          now.subtract(const Duration(days: 2)),
        ], // Qua (se hoje for Sex, por exemplo)
        currentStreak: 1,
        bestStreak: 10,
        createdAt: now.subtract(const Duration(days: 45)),
        order: 3,
      ),
    ];

    for (final habit in sampleHabits) {
      await box.put(habit.id, habit);
    }
  }

  static Future<void> _seedGamificationData(Box box) async {
    await box.clear();
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
        'pomo_5',
      ],
    });
  }

  static int _weightedRandom(List<double> weights) {
    final total = weights.reduce((a, b) => a + b);
    final random = _random.nextDouble() * total;
    double cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) return i;
    }
    return weights.length - 1;
  }
}
