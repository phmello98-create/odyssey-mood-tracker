import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_task_time_tracker/flutter_task_time_tracker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/gamification/data/data_seeder.dart';
import 'package:odyssey/src/features/language_learning/domain/language.dart';
import 'package:odyssey/src/features/language_learning/domain/study_session.dart';
import 'package:odyssey/src/features/language_learning/domain/vocabulary_item.dart';
import 'package:odyssey/src/features/language_learning/domain/immersion_log.dart';
import 'package:odyssey/src/features/auth/data/adapters/user_hive_adapter.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_analytics.dart';
import 'package:odyssey/src/features/diary/data/models/diary_entry.dart';
import 'package:odyssey/src/utils/services/notification_manager.dart';
import 'package:odyssey/src/utils/services/notification_scheduler.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/utils/services/modern_notification_scheduler.dart';
import 'package:odyssey/src/utils/services/foreground_service.dart';
// sound_service import removido - já inicializado no main.dart
import 'package:odyssey/src/utils/services/backup_service.dart';
import 'package:odyssey/src/utils/services/firebase_service.dart';
import 'package:odyssey/src/security/secure_hive_manager.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart';

enum AppInitStatus { initial, loading, success, error }

@immutable
class AppInitState {
  final AppInitStatus status;
  final MoodRecordRepository? moodRepository;
  final TimeTrackingRepository? timeTrackingRepository;
  final String? errorMessage;

  const AppInitState({
    this.status = AppInitStatus.initial,
    this.moodRepository,
    this.timeTrackingRepository,
    this.errorMessage,
  });

  AppInitState copyWith({
    AppInitStatus? status,
    MoodRecordRepository? moodRepository,
    TimeTrackingRepository? timeTrackingRepository,
    String? errorMessage,
  }) {
    return AppInitState(
      status: status ?? this.status,
      moodRepository: moodRepository ?? this.moodRepository,
      timeTrackingRepository:
          timeTrackingRepository ?? this.timeTrackingRepository,
      errorMessage: errorMessage,
    );
  }
}

class AppInitializer extends StateNotifier<AppInitState> {
  AppInitializer() : super(const AppInitState());

  Future<void> initialize() async {
    if (state.status == AppInitStatus.loading ||
        state.status == AppInitStatus.success)
      return;

    state = state.copyWith(status: AppInitStatus.loading);
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Core Framework Init (handled in main usually, but date formatting here)
      debugPrint('🚀 [AppInit] Iniciando inicialização...');
      await initializeDateFormatting('pt_BR', null);
      debugPrint(
        '✅ [AppInit] Date formatting: ${stopwatch.elapsedMilliseconds}ms',
      );

      // 2. Hive Init
      await Hive.initFlutter();
      _registerHiveAdapters();
      await _preOpenHiveBoxes();
      debugPrint('✅ [AppInit] Hive: ${stopwatch.elapsedMilliseconds}ms');

      // 2.5. ShowcaseService Init (precisa do Hive)
      await ShowcaseService.init();
      debugPrint(
        '🎯 ShowcaseService inicializado: ${stopwatch.elapsedMilliseconds}ms',
      );

      // 3. Time Tracker Init
      try {
        await FlutterTaskTimeTracker().init(
          addSecondsWhenTerminatedState: true,
          autoStart: true,
        );
        debugPrint(
          '✅ [AppInit] TimeTracker: ${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e) {
        debugPrint('Error initializing FlutterTaskTimeTracker: $e');
      }

      // 4. Repositories
      final moodRepository = await MoodRecordRepository.createRepository();
      final timeTrackingRepository =
          await TimeTrackingRepository.createTimeTrackingRepository();
      debugPrint(
        '✅ [AppInit] Repositories: ${stopwatch.elapsedMilliseconds}ms',
      );

      // 5. Data Seeding
      await DataSeeder.seedIfEmpty();
      debugPrint('✅ [AppInit] DataSeeder: ${stopwatch.elapsedMilliseconds}ms');

      // 6. Services (Parallelize where possible, but safely)
      // NOTA: soundService e ModernNotificationService já foram inicializados no main.dart
      await Future.wait([
        _initFirebase(),
        _initNotifications(),
        _initForegroundService(),
        _initBackupService(),
        // _initSoundService() - JÁ INICIALIZADO NO main.dart
      ]);
      debugPrint('✅ [AppInit] Services: ${stopwatch.elapsedMilliseconds}ms');

      // Success
      stopwatch.stop();
      debugPrint(
        '🎉 [AppInit] COMPLETADO em ${stopwatch.elapsedMilliseconds}ms',
      );

      state = state.copyWith(
        status: AppInitStatus.success,
        moodRepository: moodRepository,
        timeTrackingRepository: timeTrackingRepository,
      );
    } catch (e, stack) {
      debugPrint('Error during app initialization: $e');
      debugPrint(stack.toString());
      state = state.copyWith(
        status: AppInitStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _registerHiveAdapters() {
    // Note: Freezed generates adapters with "Impl" suffix (e.g., MoodRecordImplAdapter)
    if (!Hive.isAdapterRegistered(MoodRecordImplAdapter().typeId)) {
      Hive.registerAdapter(MoodRecordImplAdapter());
    }
    if (!Hive.isAdapterRegistered(ActivityImplAdapter().typeId)) {
      Hive.registerAdapter(ActivityImplAdapter());
    }
    if (!Hive.isAdapterRegistered(TimeTrackingRecordAdapter().typeId)) {
      Hive.registerAdapter(TimeTrackingRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(BookAdapter().typeId)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(ReadingPeriodAdapter().typeId)) {
      Hive.registerAdapter(ReadingPeriodAdapter());
    }
    // Language Learning adapters
    if (!Hive.isAdapterRegistered(LanguageAdapter().typeId)) {
      Hive.registerAdapter(LanguageAdapter());
    }
    if (!Hive.isAdapterRegistered(StudySessionAdapter().typeId)) {
      Hive.registerAdapter(StudySessionAdapter());
    }
    if (!Hive.isAdapterRegistered(VocabularyItemAdapter().typeId)) {
      Hive.registerAdapter(VocabularyItemAdapter());
    }
    if (!Hive.isAdapterRegistered(ImmersionLogAdapter().typeId)) {
      Hive.registerAdapter(ImmersionLogAdapter());
    }
    // Auth adapters
    if (!Hive.isAdapterRegistered(OdysseyUserAdapter().typeId)) {
      Hive.registerAdapter(OdysseyUserAdapter());
    }
    if (!Hive.isAdapterRegistered(AccountTypeAdapter().typeId)) {
      Hive.registerAdapter(AccountTypeAdapter());
    }
    // Suggestion adapters
    if (!Hive.isAdapterRegistered(SuggestionAdapter().typeId)) {
      Hive.registerAdapter(SuggestionAdapter());
    }
    if (!Hive.isAdapterRegistered(SuggestionAnalyticsAdapter().typeId)) {
      Hive.registerAdapter(SuggestionAnalyticsAdapter());
    }
    if (!Hive.isAdapterRegistered(SuggestionTypeAdapter().typeId)) {
      Hive.registerAdapter(SuggestionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(SuggestionCategoryAdapter().typeId)) {
      Hive.registerAdapter(SuggestionCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(SuggestionDifficultyAdapter().typeId)) {
      Hive.registerAdapter(SuggestionDifficultyAdapter());
    }
    // Diary adapter
    if (!Hive.isAdapterRegistered(DiaryEntryAdapter().typeId)) {
      Hive.registerAdapter(DiaryEntryAdapter());
    }
  }

  Future<void> _preOpenHiveBoxes() async {
    try {
      // Obter cipher para boxes sensíveis
      final cipher = await SecureHiveManager.getCipher();

      // Boxes sensíveis - abrir COM criptografia
      await Future.wait([
        Hive.openBox('notes_v2', encryptionCipher: cipher),
        Hive.openBox('quotes'), // quotes não é sensível
        Hive.openBox<Book>('books_v3'), // books não é sensível
      ]);
      debugPrint('🔐 Hive boxes pré-abertos com criptografia');
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao pré-abrir Hive boxes com criptografia, tentando sem: $e',
      );
      // Fallback: abrir sem criptografia (primeira execução ou migração)
      try {
        await Future.wait([
          Hive.openBox('notes_v2'),
          Hive.openBox('quotes'),
          Hive.openBox<Book>('books_v3'),
        ]);
        debugPrint(
          'Hive boxes pré-abertos (sem criptografia - migração pendente)',
        );
      } catch (e2) {
        debugPrint('Error pre-opening Hive boxes: $e2');
      }
    }
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationManager.instance.initialize();

      // ModernNotificationService JÁ foi inicializado no main.dart
      // Apenas verificar permissões se necessário
      final allowed = await ModernNotificationService.instance
          .isNotificationAllowed();
      if (!allowed) {
        await ModernNotificationService.instance.requestPermissions();
      }

      // Inicializar o NotificationScheduler com repositórios
      final habitRepo = HabitRepository();
      await habitRepo.init();

      final taskRepo = TaskRepository();
      await taskRepo.init();

      await NotificationScheduler.instance.initialize(
        habitRepo: habitRepo,
        taskRepo: taskRepo,
      );

      // Inicializar NOVO scheduler moderno
      await ModernNotificationScheduler.instance.initialize(
        habitRepo: habitRepo,
        taskRepo: taskRepo,
      );

      debugPrint('✅ Notificações Modernas inicializadas!');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _initForegroundService() async {
    try {
      await ForegroundService.instance.initialize();
    } catch (e) {
      debugPrint('Error initializing foreground service: $e');
    }
  }

  // _initSoundService removido - já inicializado no main.dart

  Future<void> _initBackupService() async {
    try {
      await backupService.init();
    } catch (e) {
      debugPrint('Error initializing backup service: $e');
    }
  }

  Future<void> _initFirebase() async {
    try {
      await FirebaseService.instance.initialize();
      final token = FirebaseService.instance.fcmToken;
      if (token != null) {
        debugPrint('✅ FCM Token obtido: $token');
        debugPrint(
          '🔑 Use este token no Firebase Console para testar notificações!',
        );
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }
}

final appInitializerProvider =
    StateNotifierProvider<AppInitializer, AppInitState>((ref) {
      return AppInitializer();
    });
