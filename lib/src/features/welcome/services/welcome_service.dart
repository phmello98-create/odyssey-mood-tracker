import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de boas-vindas que o app pode mostrar
enum WelcomeType {
  /// Primeiro acesso - mostra onboarding completo
  firstTime,
  
  /// Voltando após muito tempo (7+ dias)
  longTimeNoSee,
  
  /// Voltando após alguns dias (2-7 dias)
  welcomeBack,
  
  /// Voltando no mesmo dia ou dia seguinte
  quickReturn,
  
  /// Novo dia, hora de começar bem
  newDay,
  
  /// Nada especial para mostrar
  none,
}

/// Dados contextuais para personalizar a mensagem de boas-vindas
class WelcomeContext {
  final WelcomeType type;
  final String userName;
  final int daysAway;
  final int currentStreak;
  final int totalMoodRecords;
  final int uncompletedHabits;
  final int pendingTasks;
  final DateTime? lastMoodRecord;
  final TimeOfDay currentTime;
  final bool isFirstTimeToday;

  WelcomeContext({
    required this.type,
    required this.userName,
    required this.daysAway,
    this.currentStreak = 0,
    this.totalMoodRecords = 0,
    this.uncompletedHabits = 0,
    this.pendingTasks = 0,
    this.lastMoodRecord,
    required this.currentTime,
    required this.isFirstTimeToday,
  });

  /// Retorna uma saudação baseada na hora do dia
  String get timeGreeting {
    final hour = currentTime.hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  /// Verifica se deve sugerir registrar humor
  bool get shouldSuggestMood {
    if (lastMoodRecord == null) return true;
    final now = DateTime.now();
    final diff = now.difference(lastMoodRecord!);
    return diff.inHours >= 4; // Sugere se passou 4h desde último registro
  }
}

/// Serviço que gerencia a lógica de boas-vindas
class WelcomeService {
  static const String _lastVisitKey = 'welcome_last_visit';
  static const String _firstTimeKey = 'welcome_first_time_completed';
  static const String _lastWelcomeShownKey = 'welcome_last_shown_date';
  
  final SharedPreferences _prefs;
  
  WelcomeService(this._prefs);

  /// Verifica se é a primeira vez do usuário
  bool get isFirstTime => !(_prefs.getBool(_firstTimeKey) ?? false);

  /// Marca o onboarding de primeira vez como completo
  Future<void> completeFirstTime() async {
    await _prefs.setBool(_firstTimeKey, true);
    await _updateLastVisit();
  }

  /// Atualiza a última visita
  Future<void> _updateLastVisit() async {
    await _prefs.setString(_lastVisitKey, DateTime.now().toIso8601String());
  }

  /// Obtém a última visita
  DateTime? get lastVisit {
    final str = _prefs.getString(_lastVisitKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Verifica se já mostrou boas-vindas hoje
  bool get hasShownWelcomeToday {
    final lastShown = _prefs.getString(_lastWelcomeShownKey);
    if (lastShown == null) return false;
    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return false;
    final now = DateTime.now();
    return lastDate.year == now.year && 
           lastDate.month == now.month && 
           lastDate.day == now.day;
  }

  /// Marca que mostrou boas-vindas hoje
  Future<void> markWelcomeShown() async {
    await _prefs.setString(_lastWelcomeShownKey, DateTime.now().toIso8601String());
    await _updateLastVisit();
  }

  /// Determina o tipo de boas-vindas a mostrar
  WelcomeType determineWelcomeType() {
    // Primeira vez sempre mostra onboarding completo
    if (isFirstTime) {
      return WelcomeType.firstTime;
    }

    // Se já mostrou hoje, não mostra de novo
    if (hasShownWelcomeToday) {
      return WelcomeType.none;
    }

    final last = lastVisit;
    if (last == null) {
      return WelcomeType.welcomeBack;
    }

    final now = DateTime.now();
    final diff = now.difference(last);

    // Mais de 7 dias = saudade!
    if (diff.inDays >= 7) {
      return WelcomeType.longTimeNoSee;
    }

    // 2-7 dias = bem-vindo de volta
    if (diff.inDays >= 2) {
      return WelcomeType.welcomeBack;
    }

    // Mesmo dia ou dia seguinte
    if (diff.inDays >= 1 || _isDifferentDay(last, now)) {
      return WelcomeType.newDay;
    }

    // Retorno rápido (algumas horas) - não mostra nada
    return WelcomeType.none;
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  /// Reseta o estado de boas-vindas (para debug)
  Future<void> reset() async {
    await _prefs.remove(_lastVisitKey);
    await _prefs.remove(_firstTimeKey);
    await _prefs.remove(_lastWelcomeShownKey);
  }
}

/// Provider para o WelcomeService
final welcomeServiceProvider = Provider<WelcomeService>((ref) {
  throw UnimplementedError('Must be overridden with SharedPreferences');
});

/// Provider para determinar o tipo de boas-vindas
final welcomeTypeProvider = Provider<WelcomeType>((ref) {
  final service = ref.watch(welcomeServiceProvider);
  return service.determineWelcomeType();
});
