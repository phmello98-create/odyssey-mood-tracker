import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/constants/app_themes.dart';

/// Estado das configurações do app
class AppSettings {
  final ThemeMode themeMode;
  final AppThemeType selectedTheme; // Novo: tema selecionado
  final bool notificationsEnabled;
  final List<TimeOfDay> reminderTimes;
  final String? avatarPath;
  final String? bannerPath;
  final String userName;
  final int selectedTitleIndex; // Índice do título selecionado
  final bool soundEnabled;
  final bool autoBackup;
  final bool newsUseWebViewFallback;
  final bool splashAnimationEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.selectedTheme = AppThemeType.ultraviolet, // Tema padrão
    this.notificationsEnabled = true,
    this.reminderTimes = const [
      TimeOfDay(hour: 9, minute: 0),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 21, minute: 0),
    ],
    this.avatarPath,
    this.bannerPath,
    this.userName = 'Meu Perfil',
    this.selectedTitleIndex = -1, // -1 = usar título baseado em XP
    this.soundEnabled = true,
    this.autoBackup = false,
    this.newsUseWebViewFallback = true,
    this.splashAnimationEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppThemeType? selectedTheme,
    bool? notificationsEnabled,
    List<TimeOfDay>? reminderTimes,
    String? avatarPath,
    String? bannerPath,
    String? userName,
    int? selectedTitleIndex,
    bool? soundEnabled,
    bool? autoBackup,
    bool? newsUseWebViewFallback,
    bool? splashAnimationEnabled,
    bool clearAvatar = false,
    bool clearBanner = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      bannerPath: clearBanner ? null : (bannerPath ?? this.bannerPath),
      userName: userName ?? this.userName,
      selectedTitleIndex: selectedTitleIndex ?? this.selectedTitleIndex,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoBackup: autoBackup ?? this.autoBackup,
      newsUseWebViewFallback:
          newsUseWebViewFallback ?? this.newsUseWebViewFallback,
      splashAnimationEnabled:
          splashAnimationEnabled ?? this.splashAnimationEnabled,
    );
  }
}

/// Provider de configurações
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  final ImagePicker _picker = ImagePicker();

  static const _themeModeKey = 'theme_mode';
  static const _selectedThemeKey = 'selected_theme';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _reminderTimesKey = 'reminder_times';
  static const _avatarPathKey = 'avatar_path';
  static const _bannerPathKey = 'banner_path';
  static const _userNameKey = 'user_name';
  static const _selectedTitleIndexKey = 'selected_title_index';
  static const _soundEnabledKey = 'sound_enabled';
  static const _autoBackupKey = 'auto_backup';
  static const _newsUseWebViewFallbackKey = 'news_use_webview_fallback';
  static const _splashAnimationEnabledKey = 'splash_animation_enabled';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 2; // default dark
    final themeMode = ThemeMode.values[themeModeIndex];

    // Load selected theme
    final selectedThemeIndex = prefs.getInt(_selectedThemeKey) ?? 0;
    final selectedTheme = AppThemeType
        .values[selectedThemeIndex.clamp(0, AppThemeType.values.length - 1)];

    // Load notifications enabled
    final notificationsEnabled =
        prefs.getBool(_notificationsEnabledKey) ?? true;

    // Load reminder times
    final reminderTimesStr = prefs.getStringList(_reminderTimesKey);
    List<TimeOfDay> reminderTimes;
    if (reminderTimesStr != null && reminderTimesStr.isNotEmpty) {
      reminderTimes = reminderTimesStr.map((str) {
        final parts = str.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    } else {
      reminderTimes = const [
        TimeOfDay(hour: 9, minute: 0),
        TimeOfDay(hour: 14, minute: 0),
        TimeOfDay(hour: 21, minute: 0),
      ];
    }

    // Load avatar path
    final avatarPath = prefs.getString(_avatarPathKey);

    // Load banner path
    final bannerPath = prefs.getString(_bannerPathKey);

    // Load user name
    final userName = prefs.getString(_userNameKey) ?? 'Meu Perfil';

    // Load selected title index
    final selectedTitleIndex = prefs.getInt(_selectedTitleIndexKey) ?? -1;

    // Load sound enabled
    final soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;

    // Load auto backup
    final autoBackup = prefs.getBool(_autoBackupKey) ?? false;

    // Load news webview fallback
    final newsUseWebViewFallback =
        prefs.getBool(_newsUseWebViewFallbackKey) ?? true;

    // Load splash animation enabled
    final splashAnimationEnabled =
        prefs.getBool(_splashAnimationEnabledKey) ?? true;

    // Sincroniza soundService com configuração salva
    soundService.soundEnabled = soundEnabled;

    state = AppSettings(
      themeMode: themeMode,
      selectedTheme: selectedTheme,
      notificationsEnabled: notificationsEnabled,
      reminderTimes: reminderTimes,
      avatarPath: avatarPath,
      bannerPath: bannerPath,
      userName: userName,
      selectedTitleIndex: selectedTitleIndex,
      soundEnabled: soundEnabled,
      autoBackup: autoBackup,
      newsUseWebViewFallback: newsUseWebViewFallback,
      splashAnimationEnabled: splashAnimationEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    // Encontrar o tema apropriado para o novo modo
    var newSelectedTheme = state.selectedTheme;
    final currentThemeData = AppThemes.getThemeData(state.selectedTheme);
    final isNewModeDark = mode == ThemeMode.dark;

    // Se o modo mudou (ex: Dark -> Light) e o tema atual não é compatível
    if (currentThemeData.isDark != isNewModeDark) {
      if (isNewModeDark) {
        // Mudando para Dark: Mapear light -> dark
        switch (state.selectedTheme) {
          case AppThemeType.lightUltraviolet:
            newSelectedTheme = AppThemeType.ultraviolet;
            break;
          case AppThemeType.lightMint:
            newSelectedTheme = AppThemeType.emerald;
            break;
          case AppThemeType.lightPeach:
            newSelectedTheme = AppThemeType.sunset;
            break;
          case AppThemeType.lightSky:
            newSelectedTheme =
                AppThemeType.ocean; // ocean mapeia melhor que midnight
            break;
          default:
            newSelectedTheme = AppThemeType.ultraviolet;
        }
      } else {
        // Mudando para Light: Mapear dark -> light
        switch (state.selectedTheme) {
          case AppThemeType.ultraviolet:
          case AppThemeType.sakura:
            newSelectedTheme = AppThemeType.lightUltraviolet;
            break;
          case AppThemeType.emerald:
            newSelectedTheme = AppThemeType.lightMint;
            break;
          case AppThemeType.sunset:
            newSelectedTheme = AppThemeType.lightPeach;
            break;
          case AppThemeType.ocean:
          case AppThemeType.midnight:
            newSelectedTheme = AppThemeType.lightSky;
            break;
          default:
            newSelectedTheme = AppThemeType.lightUltraviolet;
        }
      }

      // Salvar o novo tema selecionado
      await prefs.setInt(_selectedThemeKey, newSelectedTheme.index);
    }

    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode, selectedTheme: newSelectedTheme);
  }

  Future<void> setSelectedTheme(AppThemeType theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedThemeKey, theme.index);

    // Atualiza o themeMode baseado no tema selecionado
    final themeData = AppThemes.getThemeData(theme);
    final newMode = themeData.isDark ? ThemeMode.dark : ThemeMode.light;
    await prefs.setInt(_themeModeKey, newMode.index);

    state = state.copyWith(selectedTheme: theme, themeMode: newMode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);

    // Ativar/desativar notificações reais
    if (enabled) {
      for (final time in state.reminderTimes) {
        await NotificationService.instance.scheduleDailyMoodReminder(
          hour: time.hour,
          minute: time.minute,
        );
      }
    } else {
      await NotificationService.instance.cancelMoodReminder();
    }
  }

  Future<void> setReminderTimes(List<TimeOfDay> times) async {
    final prefs = await SharedPreferences.getInstance();
    final timesStr = times.map((t) => '${t.hour}:${t.minute}').toList();
    await prefs.setStringList(_reminderTimesKey, timesStr);
    state = state.copyWith(reminderTimes: times);

    // Reagendar notificações se habilitadas
    if (state.notificationsEnabled) {
      await NotificationService.instance.cancelMoodReminder();
      for (final time in times) {
        await NotificationService.instance.scheduleDailyMoodReminder(
          hour: time.hour,
          minute: time.minute,
        );
      }
    }
  }

  Future<void> addReminderTime(TimeOfDay time) async {
    final newTimes = [...state.reminderTimes, time];
    await setReminderTimes(newTimes);
  }

  Future<void> removeReminderTime(int index) async {
    final newTimes = [...state.reminderTimes];
    if (newTimes.length > 1) {
      newTimes.removeAt(index);
      await setReminderTimes(newTimes);
    }
  }

  Future<void> updateReminderTime(int index, TimeOfDay time) async {
    final newTimes = [...state.reminderTimes];
    newTimes[index] = time;
    await setReminderTimes(newTimes);
  }

  Future<void> setAvatarFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      // Salvar imagem localmente
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar.jpg');
      await File(image.path).copy(avatarFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarPathKey, avatarFile.path);
      state = state.copyWith(avatarPath: avatarFile.path);
    }
  }

  Future<void> setAvatarFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar.jpg');
      await File(image.path).copy(avatarFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarPathKey, avatarFile.path);
      state = state.copyWith(avatarPath: avatarFile.path);
    }
  }

  Future<void> removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarPathKey);

    // Deletar arquivo se existir
    if (state.avatarPath != null) {
      final file = File(state.avatarPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    state = state.copyWith(clearAvatar: true);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    state = state.copyWith(userName: name);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
    soundService.soundEnabled = enabled; // Sincroniza com o serviço
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    state = state.copyWith(autoBackup: enabled);
  }

  Future<void> setNewsUseWebViewFallback(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newsUseWebViewFallbackKey, enabled);
    state = state.copyWith(newsUseWebViewFallback: enabled);
  }

  Future<void> setSplashAnimationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_splashAnimationEnabledKey, enabled);
    state = state.copyWith(splashAnimationEnabled: enabled);
  }

  // === Banner Methods ===
  Future<void> setBannerFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      await _saveBanner(pickedFile.path);
    }
  }

  Future<void> setBannerFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      await _saveBanner(pickedFile.path);
    }
  }

  Future<void> _saveBanner(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final bannerFile = File(sourcePath);
    final savedPath = '${directory.path}/profile_banner.jpg';
    await bannerFile.copy(savedPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bannerPathKey, savedPath);
    state = state.copyWith(bannerPath: savedPath);
  }

  Future<void> removeBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bannerPathKey);

    if (state.bannerPath != null) {
      final file = File(state.bannerPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    state = state.copyWith(clearBanner: true);
  }

  // === Title Selection ===
  Future<void> setSelectedTitleIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedTitleIndexKey, index);
    state = state.copyWith(selectedTitleIndex: index);
  }
}

/// Provider global de configurações
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

/// Provider específico para o tema
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Provider para o tema selecionado
final selectedThemeProvider = Provider<AppThemeType>((ref) {
  return ref.watch(settingsProvider).selectedTheme;
});

/// Provider que retorna o ThemeData atual
final currentThemeProvider = Provider<ThemeData>((ref) {
  final selectedTheme = ref.watch(selectedThemeProvider);
  return AppThemes.getTheme(selectedTheme);
});
