# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Odyssey (package name: `odyssey`) is a mood tracker Flutter application with features for tracking moods, habits, tasks, time tracking (Pomodoro), notes, diary, book library, language learning, and gamification. Built with Hive for local storage, Riverpod for state management, and Firebase for cloud sync.

## Common Commands

```bash
# Run the app
flutter run

# Analyze code for errors
flutter analyze

# Run tests
flutter test

# Run a specific test file
flutter test test/path/to/test_file.dart

# Generate code (Freezed, Hive adapters, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes during development
flutter pub run build_runner watch --delete-conflicting-outputs

# Get SHA-1 for Google Sign In setup (Android)
cd android && ./gradlew signingReport

# Clean build
flutter clean && flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons
```

## Architecture

### Feature-Based Structure (`lib/src/features/`)

Each feature follows a clean architecture pattern with three layers:
- `data/` - Repositories and data sources (Hive boxes, Firestore, APIs)
- `domain/` - Models and business logic (Freezed classes, notifiers)
- `presentation/` - UI screens, controllers, and widgets

Main features:
- `mood_records/` - Mood logging with activities
- `time_tracker/` - Pomodoro timer and time tracking
- `gamification/` - User stats, levels, achievements, XP system
- `habits/` - Habit tracking with notifications
- `tasks/` - Task management with tags and sync
- `notes/` - Note taking with AppFlowy editor
- `diary/` - Diary entries with flutter_quill editor
- `library/` - Book tracking with Open Library API
- `language_learning/` - Language study tracking (sessions, vocabulary, immersion logs)
- `calendar/` - Calendar view
- `analytics/` - Charts and mood insights (fl_chart)
- `settings/` - App settings and backup
- `auth/` - Firebase Auth, user management, cloud sync
- `subscription/` - AdMob ads and in-app purchases
- `suggestions/` - Smart suggestions system
- `onboarding/` - Showcaseview tutorials

### State Management

- Uses Riverpod (`flutter_riverpod`) throughout
- Providers defined in feature files and `lib/src/providers/`
- Key providers: `appInitializerProvider`, `moodRecordRepositoryProvider`, `timerProvider`, `themeModeProvider`, `currentUserProvider`

### Initialization Flow

App initialization is managed by `AppInitializer` in `lib/src/providers/app_initializer_provider.dart`:

1. **main.dart**: Firebase init, SharedPreferences, SoundService, AwesomeNotifications listeners, AdMob, PurchaseService
2. **AppInitializer**: Date formatting, Hive init, Hive adapter registration, repositories, DataSeeder, parallel service init (Firebase, notifications, sound, backup)

**Important**: Hive adapters are registered in `AppInitializer._registerHiveAdapters()`, NOT in main.dart.

### Persistence

**Hive (Local Storage)**:
- Hive adapters must be registered in `AppInitializer._registerHiveAdapters()` before use
- Freezed models generate adapters with "Impl" suffix (e.g., `MoodRecordImplAdapter`)
- Sensitive boxes use AES-256 encryption via `SecureHiveManager`
- Sensitive boxes: `mood_records`, `diary_entries`, `notes_v2`, `tasks`, `habits`
- Non-sensitive boxes: `settings`, `gamification`, `quotes`, `books_v3`, `time_tracking_records`

**Firebase (Cloud Sync)**:
- Firebase Auth for user accounts (email/password, Google Sign-In)
- Firestore for cloud data sync
- `SyncedRepositoryMixin` provides offline-first sync with automatic queue
- `OfflineSyncQueue` handles pending operations when offline
- Google Drive backup available via `BackupService`

### Synced Repository Pattern

For repositories that need cloud sync:
1. Use `SyncedRepositoryMixin` mixin
2. Implement `Ref get ref` and `String get collectionName`
3. Call `enqueueCreate()`, `enqueueUpdate()`, `enqueueDelete()` for operations
4. Operations auto-queue when offline and sync when connectivity restored

Example synced repositories: `SyncedTaskRepository`, `SyncedBookRepository`, `SyncedNotesRepository`

### Navigation

- Main app uses `PageView` with 5 tabs: Home, Log, Mood, Timer, Profile
- Secondary screens accessed via "More" menu
- Navigation state managed by `screenNavigationProvider`
- Deep linking from notifications via `NotificationActionHandler.navigatorKey`

### Theming

- Multiple theme system in `lib/src/constants/app_themes.dart`
- Theme selection via `currentThemeProvider`
- Supports light/dark mode via `themeModeProvider`

## Code Generation

This project uses code generation for:
- **Freezed** - Immutable data classes (`*.freezed.dart`)
- **Hive** - Type adapters (`*.g.dart`) - note the "Impl" suffix for Freezed classes
- **json_serializable** - JSON serialization for Firestore

After modifying models with `@freezed`, `@HiveType`, or `@JsonSerializable` annotations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Then register new Hive adapters in `AppInitializer._registerHiveAdapters()`.

## Key Patterns

- Models use Freezed for immutability (e.g., `MoodRecord`, `Activity`, `Book`)
- Repositories handle data access (Hive local, Firestore cloud)
- Controllers manage UI state and business logic
- Services (`lib/src/utils/services/`) for cross-cutting concerns:
  - `NotificationService` / `ModernNotificationService` - local notifications
  - `SoundService` - UI/UX sounds with flutter_soloud
  - `BackupService` - Google Drive backup
  - `FirebaseService` - FCM push notifications
  - `HapticService` - haptic feedback

## Security

- LGPD/GDPR compliant data handling
- Sensitive Hive boxes encrypted with AES-256 via `SecureHiveManager`
- Encryption key stored in flutter_secure_storage
- Use `SecureHiveManager.openEncryptedBox<T>()` for sensitive data

## Localization

- Portuguese (pt_BR) is the primary locale, English (en) supported
- ARB files in `lib/l10n/`
- Date formatting initialized with `initializeDateFormatting('pt_BR', null)`
- Access translations via `AppLocalizations.of(context)`
