import 'package:odyssey/src/features/library/domain/book.dart';
// Removing potential duplicate imports if any.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'dart:math';

import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/gen/assets.gen.dart';
import 'package:odyssey/src/shared/data/isar_service.dart';
import 'package:odyssey/src/features/diary/data/models/diary_entry_isar.dart';

class DataSeeder {
  static final Random _random = Random();

  /// Verifica cada box e popula dados se estiver vazia (ou forçado)
  static Future<void> seedIfEmpty({bool force = false}) async {
    // 1. Mood Records
    try {
      final moodBox = await Hive.openBox<MoodRecord>('mood_records');
      if (moodBox.isEmpty || force) {
        debugPrint('🌱 Seeding Mood Records...');
        await _seedMoodRecords(moodBox);
      }
    } catch (e) {
      debugPrint('Error accessing mood box in seeder: $e');
    }

    // 2. Time Tracking
    try {
      final timeBox = await Hive.openBox<TimeTrackingRecord>(
        'time_tracking_records',
      );
      if (timeBox.isEmpty || force) {
        debugPrint('🌱 Seeding Time Tracking...');
        await _seedTimeTrackingRecords(timeBox);
      }
    } catch (e) {
      debugPrint('Error accessing time tracking box: $e');
    }

    // 3. Notes (Legacy Hive) - Keeping as is just in case, or skipping if unused
    try {
      final notesBox = await Hive.openBox('notes');
      if (notesBox.isEmpty || force) {
        await _seedNotes(notesBox);
      }
    } catch (e) {
      debugPrint('Error accessing notes box: $e');
    }

    // 4. Tasks (dados ricos)
    try {
      final taskBox = await Hive.openBox('tasks');
      if (taskBox.length < 5 || force) {
        debugPrint('🌱 Seeding Tasks...');
        await _seedTasks(taskBox);
      }
    } catch (e) {
      debugPrint('Error accessing tasks box: $e');
    }

    // 5. Habits
    try {
      if (Hive.isAdapterRegistered(10)) {
        final habitBox = await Hive.openBox<Habit>('habits');
        if (habitBox.length < 2 || force) {
          debugPrint('🌱 Seeding Habits...');
          await _seedHabits(habitBox);
        }
      }
    } catch (e) {
      debugPrint('Error accessing habits box: $e');
    }

    // 6. Gamification
    try {
      final gameBox = await Hive.openBox('gamification');
      if (gameBox.isEmpty || force) {
        debugPrint('🌱 Seeding Gamification...');
        await _seedGamificationData(gameBox);
      }
    } catch (e) {
      debugPrint('Error accessing gamification box: $e');
    }

    // 7. Diary (Isar)
    try {
      final isar = IsarService.instance;
      // Verifica se o schema está acessível via count
      final count = await isar.diaryEntryIsars.count();
      if (count < 2 || force) {
        debugPrint('🌱 Seeding Diary (Isar)...');
        await _seedDiary(isar);
      }
    } catch (e) {
      debugPrint('Error seeding diary: $e');
    }
  }

  static Future<void> seedAllData({bool force = false}) async {
    await seedIfEmpty(force: force);

    // Seed Library (Books & Articles)
    try {
      final booksBox = await Hive.openBox<Book>('books_v3');
      if (booksBox.isEmpty || force) {
        debugPrint('🌱 Seeding Books...');
        await _seedBooks(booksBox);
      }

      final articlesBox = await Hive.openBox<Article>('articles');
      if (articlesBox.isEmpty || force) {
        debugPrint('🌱 Seeding Articles...');
        await _seedArticles(articlesBox);
      }
    } catch (e) {
      debugPrint('Error accessing library boxes: $e');
    }
  }

  static Future<void> _seedDiary(Isar isar) async {
    final now = DateTime.now();

    final sampleEntries = [
      DiaryEntryIsar()
        ..entryDate = now.subtract(const Duration(hours: 2))
        ..createdAt = now.subtract(const Duration(hours: 2))
        ..updatedAt = now.subtract(const Duration(hours: 2))
        ..title = 'Reflexões sobre Produtividade'
        ..content =
            '[{"insert":"Hoje tive um insight interessante sobre como organizo meu tempo.\\n\\nPercebi que fazer as tarefas mais difíceis pela manhã muda completamente o ritmo do dia. A sensação de dever cumprido logo cedo libera uma energia incrível!\\n\\nVou tentar manter esse hábito amanhã.\\n"}]'
        ..searchableText =
            'Hoje tive um insight interessante sobre como organizo meu tempo. Percebi que fazer as tarefas mais difíceis pela manhã muda completamente o ritmo do dia. A sensação de dever cumprido logo cedo libera uma energia incrível! Vou tentar manter esse hábito amanhã.'
        ..feeling = 'amazing'
        ..tags = ['Produtividade', 'Insight', 'Manhã']
        ..isStarred = true,

      DiaryEntryIsar()
        ..entryDate = now.subtract(const Duration(days: 1))
        ..createdAt = now.subtract(const Duration(days: 1))
        ..updatedAt = now.subtract(const Duration(days: 1))
        ..title = 'Um dia difícil mas necessário'
        ..content =
            '[{"insert":"Às vezes as coisas não saem como planejado e tudo bem.\\nO projeto atrasou e fiquei frustrado, mas respirei fundo e replanejei.\\n\\nO importante é não paralisar diante dos obstáculos.\\n"}]'
        ..searchableText =
            'Às vezes as coisas não saem como planejado e tudo bem. O projeto atrasou e fiquei frustrado, mas respirei fundo e replanejei. O importante é não paralisar diante dos obstáculos.'
        ..feeling = 'bad'
        ..tags = ['Trabalho', 'Resiliência']
        ..isStarred = false,

      DiaryEntryIsar()
        ..entryDate = now.subtract(const Duration(days: 3))
        ..createdAt = now.subtract(const Duration(days: 3))
        ..updatedAt = now.subtract(const Duration(days: 3))
        ..title = 'Caminhada no Parque'
        ..content =
            '[{"insert":"O contato com a natureza sempre me renova.\\nO dia estava lindo, sol suave e brisa fresca.\\nVi várias pessoas passeando com cachorros e crianças brincando.\\n\\nMe sinto leve.\\n"}]'
        ..searchableText =
            'O contato com a natureza sempre me renova. O dia estava lindo, sol suave e brisa fresca. Vi várias pessoas passeando com cachorros e crianças brincando. Me sinto leve.'
        ..feeling = 'good'
        ..tags = ['Natureza', 'Paz', 'Lazer']
        ..isStarred = true,

      DiaryEntryIsar()
        ..entryDate = now.subtract(const Duration(days: 5))
        ..createdAt = now.subtract(const Duration(days: 5))
        ..updatedAt = now.subtract(const Duration(days: 5))
        ..title = 'Aprendendo Flutter'
        ..content =
            '[{"insert":"Estou adorando aprender sobre Riverpod e arquitetura limpa.\\nÉ desafiador, mas cada pequena vitória conta.\\nHoje consegui refatorar um módulo inteiro!\\n\\n#CodingLife\\n"}]'
        ..searchableText =
            'Estou adorando aprender sobre Riverpod e arquitetura limpa. É desafiador, mas cada pequena vitória conta. Hoje consegui refatorar um módulo inteiro! #CodingLife'
        ..feeling = 'amazing'
        ..tags = ['Flutter', 'Estudos', 'Tech']
        ..isStarred = false,
    ];

    await isar.writeTxn(() async {
      await isar.diaryEntryIsars.putAll(sampleEntries);
    });
  }

  static Future<void> _seedMoodRecords(Box<MoodRecord> box) async {
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

    final now = DateTime.now();
    for (int day = 30; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      final recordsToday = _random.nextInt(3) + 1;

      for (int i = 0; i < recordsToday; i++) {
        final recordDate = DateTime(
          date.year,
          date.month,
          date.day,
          8 + _random.nextInt(14),
          _random.nextInt(60),
        );
        final mood = moods[_weightedRandom([0.15, 0.35, 0.25, 0.15, 0.10])];

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
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          8 + _random.nextInt(12),
          _random.nextInt(60),
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
      await box.put(
        'note_${DateTime.now().millisecondsSinceEpoch + i}',
        sampleNotes[i],
      );
    }
  }

  static Future<void> _seedTasks(Box box) async {
    await box.clear();
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String();

    final tasksData = [
      {
        'title': 'Reunião de Design System',
        'notes': 'Discutir a paleta de cores e tipografia.',
        'completed': false,
        'priority': 'high',
        'category': 'Trabalho',
        'dueDate': iso(now),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(hours: 2))),
      },
      {
        'title': 'Ir à Academia',
        'notes': 'Treino de perna e cardio.',
        'completed': false,
        'priority': 'medium',
        'category': 'Saúde',
        'dueDate': iso(now),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(hours: 4))),
      },
      {
        'title': 'Ler documentação',
        'notes': 'Focar em testes.',
        'completed': false,
        'priority': 'low',
        'category': 'Estudo',
        'dueDate': iso(now.add(const Duration(days: 1))),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(days: 1))),
      },
      {
        'title': 'Comprar Mantimentos',
        'notes': 'Lista semanal.',
        'completed': true,
        'priority': 'medium',
        'category': 'Pessoal',
        'dueDate': iso(now.subtract(const Duration(days: 1))),
        'dueTime': null,
        'createdAt': iso(now.subtract(const Duration(days: 2))),
        'completedAt': iso(now.subtract(const Duration(days: 1))),
      },
    ];

    for (var i = 0; i < tasksData.length; i++) {
      final key = DateTime.now().millisecondsSinceEpoch + i;
      await box.put(key.toString(), tasksData[i]);
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
        scheduledTime: null,
        daysOfWeek: [],
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
        scheduledTime: null,
        daysOfWeek: [],
        completedDates: [],
        currentStreak: 0,
        bestStreak: 5,
        createdAt: now.subtract(const Duration(days: 10)),
        order: 2,
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

  static Future<void> _seedBooks(Box<Book> box) async {
    await box.clear();
    final now = DateTime.now();

    final books = [
      Book(
        id: 'book_1',
        title: 'O Poder do Hábito',
        author: 'Charles Duhigg',
        description: 'Por que fazemos o que fazemos na vida e nos negócios.',
        statusIndex: BookStatus.read.index,
        formatIndex: BookFormat.paperback.index,
        rating: 90, // 4.5 estrelas
        pages: 408,
        currentPage: 408,
        genre: 'Produtividade',
        dateAdded: now.subtract(const Duration(days: 60)),
        dateModified: now.subtract(const Duration(days: 30)),
        tags: 'hábito|||||psicologia|||||produtividade',
        myReview: 'Mudou minha forma de ver rotinas.',
        totalReadingTimeSeconds: 36000,
        readingsData: ReadingPeriod(
          startDate: now.subtract(const Duration(days: 60)),
          finishDate: now.subtract(const Duration(days: 30)),
        ).toString(),
      ),
      Book(
        id: 'book_2',
        title: 'Hábitos Atômicos',
        author: 'James Clear',
        description:
            'Um método fácil e comprovado de criar bons hábitos e se livrar dos maus.',
        statusIndex: BookStatus.inProgress.index,
        formatIndex: BookFormat.ebook.index,
        rating: null,
        pages: 320,
        currentPage: 150,
        genre: 'Autoajuda',
        dateAdded: now.subtract(const Duration(days: 15)),
        dateModified: now,
        tags: 'hábito|||||crescimento',
        totalReadingTimeSeconds: 12000,
        readingsData: ReadingPeriod(
          startDate: now.subtract(const Duration(days: 15)),
        ).toString(),
      ),
      Book(
        id: 'book_3',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        description: 'A Handbook of Agile Software Craftsmanship.',
        statusIndex: BookStatus.forLater.index,
        formatIndex: BookFormat.hardcover.index,
        pages: 464,
        currentPage: 0,
        genre: 'Tecnologia',
        dateAdded: now.subtract(const Duration(days: 5)),
        dateModified: now.subtract(const Duration(days: 5)),
        tags: 'programação|||||técnico',
      ),
    ];

    for (final book in books) {
      await box.put(book.id, book);
    }
  }

  static Future<void> _seedArticles(Box<Article> box) async {
    await box.clear();
    final now = DateTime.now();

    final articles = [
      Article(
        id: 'article_1',
        title: 'Introduction to Riverpod',
        author: 'Remi Rousselet',
        source: 'Riverpod.dev',
        url: 'https://riverpod.dev',
        statusIndex: ArticleStatus.read.index,
        dateAdded: now.subtract(const Duration(days: 10)),
        dateRead: now.subtract(const Duration(days: 9)),
        readingTimeMinutes: 15,
        rating: 50, // 5.0
        tags: 'flutter|||||state-management',
        category: 'Tecnologia',
        summary: 'Excelente introdução ao gerenciamento de estado moderno.',
      ),
      Article(
        id: 'article_2',
        title: 'O poder do sono',
        author: 'Matthew Walker',
        source: 'Blog de Saúde',
        statusIndex: ArticleStatus.reading.index,
        dateAdded: now.subtract(const Duration(days: 2)),
        readingTimeMinutes: 10,
        tags: 'saúde|||||sono',
        category: 'Saúde',
      ),
      Article(
        id: 'article_3',
        title: 'Como organizar suas finanças',
        source: 'Investidor Inteligente',
        statusIndex: ArticleStatus.toRead.index,
        dateAdded: now.subtract(const Duration(days: 1)),
        tags: 'finanças|||||planejamento',
      ),
    ];

    for (final article in articles) {
      await box.put(article.id, article);
    }
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
