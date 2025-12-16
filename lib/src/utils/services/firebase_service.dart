import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:odyssey/firebase_options.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';

/// Handler para mensagens em background (deve ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Background message: ${message.notification?.title ?? message.data['title']}');

  // Ensure Awesome Notifications is initialized in this isolate (no permissions request)
  try {
    await NotificationService.instance.initialize(requestPermissions: false, configureListeners: false);
  } catch (e) {
    debugPrint('❌ Erro ao inicializar NotificationService no background: $e');
  }

  // Mostrar notificação via Awesome Notifications (suporta data-only payloads)
  final title = message.notification?.title ?? message.data['title'] ?? 'Odyssey';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  await NotificationService.instance.showRemoteNotification(
    title: title,
    body: body,
    payload: message.data,
  );
}

/// Serviço centralizado do Firebase para Push Notifications modernas
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  static FirebaseService get instance => _instance;

  FirebaseService._();

  bool _initialized = false;
  String? _fcmToken;

  // Firebase instances
  FirebaseMessaging? _messaging;
  FirebaseAnalytics? _analytics;
  FirebaseRemoteConfig? _remoteConfig;

  // Streams
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  // Getters
  String? get fcmToken => _fcmToken;
  FirebaseAnalytics? get analytics => _analytics;
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;
  bool get isInitialized => _initialized;

  /// Inicializa todos os serviços Firebase
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Verificar se Firebase Core já foi inicializado (no main.dart)
      try {
        Firebase.app();
        debugPrint('🔥 Firebase Core já inicializado');
      } catch (e) {
        // Se não foi inicializado, inicializar agora
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('🔥 Firebase Core inicializado');
      }

      // Inicializar Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      await _setupMessaging();
      debugPrint('📬 Firebase Messaging configurado');

      // Inicializar Firebase Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('📊 Firebase Analytics ativo');

      // Inicializar Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _setupRemoteConfig();
      debugPrint('🔧 Firebase Remote Config configurado');

      _initialized = true;
      debugPrint('✅ Firebase Service completamente inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Firebase: $e');
      // Continuar sem Firebase - app deve funcionar offline
    }
  }

  /// Configura Firebase Messaging
  Future<void> _setupMessaging() async {
    // Configurar handler de background (unconditional)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listener para mensagens em foreground (unconditional)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Listener para quando app é aberto via notificação (unconditional)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Registrar token refresh listener
    _messaging!.onTokenRefresh.listen(_onTokenRefresh);

    // Solicitar permissões (para notificações e analytics)
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📬 Permissão de notificação: ${settings.authorizationStatus}');

    // Obter token FCM sempre (algumas OEMs bloqueiam data messages, but token can be obtained)
    _fcmToken = await _messaging!.getToken();
    debugPrint('📬 FCM Token: $_fcmToken');

    // Verificar se app foi aberto via notificação (cold start)
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    // Subscrever a tópicos padrão apenas se permissões permitirem
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _subscribeToDefaultTopics();
    }
  }

  /// Handler para mensagens em foreground
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message: ${message.notification?.title}');

    _messageController.add(message);

    // Mostrar notificação via Awesome Notifications
    if (message.notification != null) {
      NotificationService.instance.showRemoteNotification(
        title: message.notification!.title ?? 'Odyssey',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }

    // Track analytics
    trackNotificationReceived(message);
  }

  /// Handler para quando app é aberto via notificação
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('📬 App aberto via notificação: ${message.notification?.title}');

    // Track analytics
    trackNotificationOpened(message);

    // Processar ação baseada no payload
    _processNotificationAction(message.data);
  }

  /// Handler para atualização de token
  void _onTokenRefresh(String newToken) {
    debugPrint('📬 Token FCM atualizado: $newToken');
    _fcmToken = newToken;

    // Aqui você poderia enviar o token para seu backend
    // _sendTokenToServer(newToken);
  }

  /// Processa ação da notificação baseada no payload
  void _processNotificationAction(Map<String, dynamic> data) {
    final action = data['action'];

    switch (action) {
      case 'open_mood':
        // Navegar para tela de humor
        debugPrint('📬 Ação: Abrir mood tracker');
        break;
      case 'open_pomodoro':
        // Navegar para Pomodoro
        debugPrint('📬 Ação: Abrir Pomodoro');
        break;
      case 'open_profile':
        // Navegar para perfil
        debugPrint('📬 Ação: Abrir perfil');
        break;
      case 'open_achievement':
        // Mostrar achievement
        final achievementId = data['achievement_id'];
        debugPrint('📬 Ação: Mostrar achievement $achievementId');
        break;
      default:
        debugPrint('📬 Ação não reconhecida: $action');
    }
  }

  /// Subscreve a tópicos padrão
  Future<void> _subscribeToDefaultTopics() async {
    try {
      await _messaging!.subscribeToTopic('all_users');
      await _messaging!.subscribeToTopic('mood_reminders');
      await _messaging!.subscribeToTopic('gamification');
      debugPrint('📬 Inscrito nos tópicos padrão');
    } catch (e) {
      debugPrint('❌ Erro ao subscrever tópicos: $e');
    }
  }

  /// Configura Remote Config com valores padrão
  Future<void> _setupRemoteConfig() async {
    try {
      // Valores padrão
      await _remoteConfig!.setDefaults({
        'mood_reminder_enabled': true,
        'mood_reminder_hour': 20,
        'notification_variant': 'standard',
        'gamification_notifications': true,
        'smart_notifications': true,
        'ab_test_group': 'control',
      });

      // Configurar fetch settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Fetch inicial
      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      debugPrint('❌ Erro ao configurar Remote Config: $e');
    }
  }

  // ===========================================
  // MÉTODOS DE ANALYTICS
  // ===========================================

  /// Rastreia evento de notificação recebida
  Future<void> trackNotificationReceived(RemoteMessage message) async {
    try {
      await _analytics?.logEvent(
        name: 'notification_received',
        parameters: {
          'notification_id': message.messageId ?? 'unknown',
          'notification_type': message.data['type'] ?? 'general',
          'title': message.notification?.title ?? '',
        },
      );
    } catch (e) {
      debugPrint('❌ Erro ao rastrear notificação recebida: $e');
    }
  }

  /// Rastreia evento de notificação aberta
  Future<void> trackNotificationOpened(RemoteMessage message) async {
    try {
      await _analytics?.logEvent(
        name: 'notification_opened',
        parameters: {
          'notification_id': message.messageId ?? 'unknown',
          'notification_type': message.data['type'] ?? 'general',
          'action': message.data['action'] ?? 'default',
        },
      );
    } catch (e) {
      debugPrint('❌ Erro ao rastrear notificação aberta: $e');
    }
  }

  /// Rastreia interação com notificação
  Future<void> trackNotificationInteraction({
    required String notificationId,
    required String action,
    Map<String, dynamic>? extraParams,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'notification_interaction',
        parameters: {
          'notification_id': notificationId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?extraParams,
        },
      );
    } catch (e) {
      debugPrint('❌ Erro ao rastrear interação: $e');
    }
  }

  /// Define propriedade de usuário para segmentação
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('❌ Erro ao definir propriedade: $e');
    }
  }

  /// Define segmento do usuário baseado em stats
  Future<void> setUserSegment({
    required int level,
    required int streak,
    required int totalXP,
  }) async {
    String segment;

    if (level >= 10 && streak >= 30) {
      segment = 'power_user';
    } else if (streak >= 7) {
      segment = 'consistent';
    } else if (level >= 5) {
      segment = 'engaged';
    } else {
      segment = 'casual';
    }

    await setUserProperty(name: 'user_segment', value: segment);
    await setUserProperty(name: 'user_level', value: level.toString());
  }

  // ===========================================
  // MÉTODOS DE TÓPICOS
  // ===========================================

  /// Subscreve a um tópico específico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('📬 Inscrito no tópico: $topic');
    } catch (e) {
      debugPrint('❌ Erro ao subscrever tópico $topic: $e');
    }
  }

  /// Cancela subscrição de um tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('📬 Desinscrito do tópico: $topic');
    } catch (e) {
      debugPrint('❌ Erro ao desinscrever tópico $topic: $e');
    }
  }

  // ===========================================
  // REMOTE CONFIG HELPERS
  // ===========================================

  /// Obtém valor booleano do Remote Config
  bool getRemoteConfigBool(String key) {
    return _remoteConfig?.getBool(key) ?? false;
  }

  /// Obtém valor string do Remote Config
  String getRemoteConfigString(String key) {
    return _remoteConfig?.getString(key) ?? '';
  }

  /// Obtém valor int do Remote Config
  int getRemoteConfigInt(String key) {
    return _remoteConfig?.getInt(key) ?? 0;
  }

  /// Força atualização do Remote Config
  Future<bool> fetchRemoteConfig() async {
    try {
      return await _remoteConfig?.fetchAndActivate() ?? false;
    } catch (e) {
      debugPrint('❌ Erro ao fetch Remote Config: $e');
      return false;
    }
  }

  /// Dispose
  void dispose() {
    _messageController.close();
  }
}
