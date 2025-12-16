import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:odyssey/src/utils/services/firebase_service.dart';
import 'package:odyssey/src/utils/services/notification_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Variantes disponíveis para testes A/B
enum ABVariant {
  /// Grupo de controle - comportamento padrão
  control,

  /// Variante A - primeira alternativa
  variantA,

  /// Variante B - segunda alternativa
  variantB,
}

/// Experimento de A/B Testing
class ABExperiment {
  final String id;
  final String name;
  final String description;
  final Map<ABVariant, String> variantDescriptions;
  final bool enabled;
  final DateTime? startDate;
  final DateTime? endDate;

  const ABExperiment({
    required this.id,
    required this.name,
    required this.description,
    required this.variantDescriptions,
    this.enabled = true,
    this.startDate,
    this.endDate,
  });

  bool get isActive {
    if (!enabled) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

/// Serviço de A/B Testing para notificações
class ABTestingService {
  static final ABTestingService _instance = ABTestingService._();
  static ABTestingService get instance => _instance;

  ABTestingService._();

  SharedPreferences? _prefs;
  final _random = Random();

  // Keys para persistência
  static const String _keyPrefix = 'ab_test_';
  static const String _keyUserVariant = '${_keyPrefix}variant_';
  static const String _keyExperimentData = '${_keyPrefix}data_';

  /// Experimentos disponíveis
  static const Map<String, ABExperiment> experiments = {
    'mood_reminder_timing': ABExperiment(
      id: 'mood_reminder_timing',
      name: 'Horário do Lembrete de Humor',
      description: 'Testa diferentes horários para enviar lembretes de humor',
      variantDescriptions: {
        ABVariant.control: 'Horário fixo às 20h',
        ABVariant.variantA: 'Horário personalizado baseado em uso',
        ABVariant.variantB: 'Dois lembretes: manhã e noite',
      },
    ),
    'notification_style': ABExperiment(
      id: 'notification_style',
      name: 'Estilo de Notificação',
      description: 'Testa diferentes estilos de mensagem',
      variantDescriptions: {
        ABVariant.control: 'Mensagens formais',
        ABVariant.variantA: 'Mensagens com emojis e casual',
        ABVariant.variantB: 'Mensagens personalizadas com nome',
      },
    ),
    'streak_urgency': ABExperiment(
      id: 'streak_urgency',
      name: 'Urgência do Alerta de Streak',
      description: 'Testa diferentes níveis de urgência',
      variantDescriptions: {
        ABVariant.control: 'Alerta suave',
        ABVariant.variantA: 'Alerta urgente',
        ABVariant.variantB: 'Alerta com contagem regressiva',
      },
    ),
    'reengagement_approach': ABExperiment(
      id: 'reengagement_approach',
      name: 'Abordagem de Re-engajamento',
      description: 'Testa diferentes estratégias para usuários inativos',
      variantDescriptions: {
        ABVariant.control: 'Mensagem gentil depois de 3 dias',
        ABVariant.variantA: 'Mensagem com incentivo de conquista',
        ABVariant.variantB: 'Mensagem mostrando o que perdeu',
      },
    ),
    'gamification_level': ABExperiment(
      id: 'gamification_level',
      name: 'Nível de Gamificação',
      description: 'Testa intensidade das notificações de gamificação',
      variantDescriptions: {
        ABVariant.control: 'Apenas level up e conquistas',
        ABVariant.variantA: 'Inclui micro-celebrações',
        ABVariant.variantB: 'Gamificação completa com rankings',
      },
    ),
  };

  /// Inicializa o serviço
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Atribuir variantes para experimentos que o usuário ainda não tem
    for (final experiment in experiments.values) {
      if (experiment.isActive) {
        await _ensureVariantAssigned(experiment.id);
      }
    }

    debugPrint('🧪 ABTestingService inicializado');
  }

  /// Obtém a variante do usuário para um experimento
  Future<ABVariant> getVariant(String experimentId) async {
    final key = '$_keyUserVariant$experimentId';
    final stored = _prefs?.getString(key);

    if (stored != null) {
      return ABVariant.values.firstWhere(
        (v) => v.name == stored,
        orElse: () => ABVariant.control,
      );
    }

    // Atribuir nova variante
    return _assignVariant(experimentId);
  }

  /// Atribui uma variante aleatória para um experimento
  Future<ABVariant> _assignVariant(String experimentId) async {
    // Verificar se Remote Config tem uma variante forçada
    final remoteVariant = FirebaseService.instance
        .getRemoteConfigString('ab_${experimentId}_variant');

    if (remoteVariant.isNotEmpty) {
      final variant = ABVariant.values.firstWhere(
        (v) => v.name == remoteVariant,
        orElse: () => _randomVariant(),
      );
      await _saveVariant(experimentId, variant);
      return variant;
    }

    // Atribuir aleatoriamente
    final variant = _randomVariant();
    await _saveVariant(experimentId, variant);

    // Registrar no Firebase para segmentação
    await FirebaseService.instance.setUserProperty(
      name: 'ab_$experimentId',
      value: variant.name,
    );

    debugPrint('🧪 Variante atribuída para $experimentId: ${variant.name}');
    return variant;
  }

  /// Gera uma variante aleatória com distribuição igual
  ABVariant _randomVariant() {
    final roll = _random.nextInt(100);
    if (roll < 33) return ABVariant.control;
    if (roll < 66) return ABVariant.variantA;
    return ABVariant.variantB;
  }

  /// Salva a variante do usuário
  Future<void> _saveVariant(String experimentId, ABVariant variant) async {
    final key = '$_keyUserVariant$experimentId';
    await _prefs?.setString(key, variant.name);
  }

  /// Garante que o usuário tem uma variante atribuída
  Future<void> _ensureVariantAssigned(String experimentId) async {
    final key = '$_keyUserVariant$experimentId';
    if (_prefs?.getString(key) == null) {
      await _assignVariant(experimentId);
    }
  }

  /// Registra uma conversão para o experimento
  Future<void> trackConversion({
    required String experimentId,
    required String conversionType,
    Map<String, dynamic>? extraParams,
  }) async {
    final variant = await getVariant(experimentId);

    // Incrementar contador local
    final key = '$_keyExperimentData${experimentId}_${variant.name}_$conversionType';
    final current = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, current + 1);

    // Enviar para Firebase
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'ab_$experimentId',
      action: conversionType,
      extraParams: {
        'experiment': experimentId,
        'variant': variant.name,
        ...?extraParams,
      },
    );

    // Rastrear no Analytics também
    await NotificationAnalyticsService.instance.trackNotificationAction(
      notificationId: 'ab_$experimentId',
      type: 'ab_test',
      action: conversionType,
      extraParams: {
        'experiment': experimentId,
        'variant': variant.name,
      },
    );

    debugPrint('🧪 Conversão registrada: $experimentId / ${variant.name} / $conversionType');
  }

  /// Obtém estatísticas de um experimento
  Future<Map<String, dynamic>> getExperimentStats(String experimentId) async {
    final stats = <String, dynamic>{
      'experiment': experimentId,
      'variants': {},
    };

    for (final variant in ABVariant.values) {
      final impressions = _prefs?.getInt(
            '$_keyExperimentData${experimentId}_${variant.name}_impression',
          ) ??
          0;
      final conversions = _prefs?.getInt(
            '$_keyExperimentData${experimentId}_${variant.name}_conversion',
          ) ??
          0;

      stats['variants'][variant.name] = {
        'impressions': impressions,
        'conversions': conversions,
        'conversion_rate': impressions > 0
            ? '${((conversions / impressions) * 100).toStringAsFixed(1)}%'
            : '0%',
      };
    }

    return stats;
  }

  /// Verifica se um experimento está ativo
  bool isExperimentActive(String experimentId) {
    final experiment = experiments[experimentId];
    return experiment?.isActive ?? false;
  }

  /// Obtém descrição da variante atual do usuário
  Future<String?> getVariantDescription(String experimentId) async {
    final experiment = experiments[experimentId];
    if (experiment == null) return null;

    final variant = await getVariant(experimentId);
    return experiment.variantDescriptions[variant];
  }

  /// Força uma variante específica (para debug)
  Future<void> forceVariant(String experimentId, ABVariant variant) async {
    await _saveVariant(experimentId, variant);
    debugPrint('🧪 Variante forçada: $experimentId -> ${variant.name}');
  }

  /// Reseta todos os experimentos do usuário (para debug)
  Future<void> resetExperiments() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    debugPrint('🧪 Experimentos resetados');
  }

  /// Exporta dados de todos os experimentos
  Future<Map<String, dynamic>> exportAllExperiments() async {
    final data = <String, dynamic>{};

    for (final experimentId in experiments.keys) {
      final variant = await getVariant(experimentId);
      data[experimentId] = {
        'variant': variant.name,
        'stats': await getExperimentStats(experimentId),
      };
    }

    return data;
  }
}

/// Helpers para usar variantes nos serviços
extension ABVariantHelpers on ABVariant {
  /// Verifica se é o grupo de controle
  bool get isControl => this == ABVariant.control;

  /// Verifica se é uma variante de teste
  bool get isTest => this != ABVariant.control;

  /// Nome formatado da variante
  String get displayName {
    switch (this) {
      case ABVariant.control:
        return 'Controle';
      case ABVariant.variantA:
        return 'Variante A';
      case ABVariant.variantB:
        return 'Variante B';
    }
  }
}
