import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:odyssey/firebase_options.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/providers/locale_provider.dart';
import 'package:odyssey/src/features/splash/presentation/splash_screen.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/utils/services/notification_action_handler.dart';
import 'package:odyssey/src/utils/services/app_lifecycle_service.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/sound_helpers.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/subscription/services/admob_service.dart';
import 'package:odyssey/src/features/subscription/services/purchase_service.dart';
import 'package:odyssey/src/features/welcome/services/welcome_service.dart';
import 'package:odyssey/src/config/app_flavor.dart';
import 'package:toastification/toastification.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Bootstrap do app - inicializa todos os serviços e roda o app
///
/// [flavor] define se é ambiente Dev ou Prod
Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar o flavor PRIMEIRO
  FlavorConfig.setFlavor(flavor);

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('🚀 Iniciando Odyssey - Flavor: ${flavor.displayName}');
  debugPrint('═══════════════════════════════════════════════════════');

  // Inicializar JustAudioBackground para reprodução em background (Android/iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'io.odyssey.moodtracker.radio',
        androidNotificationChannelName: 'Rádio Odyssey',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        notificationColor: const Color(0xFF6C63FF),
      );
      debugPrint('🎵 JustAudioBackground inicializado (Android/iOS)');
    } catch (e) {
      debugPrint('⚠️ Erro ao inicializar JustAudioBackground: $e');
    }
  }

  // Inicializar MediaKit Apenas para Linux/Windows
  if (!Platform.isAndroid && !Platform.isIOS) {
    try {
      JustAudioMediaKit.protocolWhitelist = const [
        'http',
        'https',
        'file',
        'rtsp',
        'rtmp',
      ];
      JustAudioMediaKit.bufferSize = 8 * 1024 * 1024;
      JustAudioMediaKit.ensureInitialized();
      debugPrint('🎵 JustAudioMediaKit inicializado (Linux/Desktop)');
    } catch (e) {
      debugPrint('⚠️ JustAudioMediaKit não disponível: $e');
      debugPrint('💡 Instale libmpv-devel para habilitar áudio no Linux');
    }
  }

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('🔥 Firebase inicializado');
  } catch (e) {
    debugPrint('⚠️ Firebase não disponível ou falhou: $e');
  }

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Inicializar SoundService SND
  await soundService.init();
  debugPrint('🔊 SoundService SND inicializado');

  // Configurar listeners de notificação
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationService.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationService.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationService.onDismissActionReceivedMethod,
  );

  // Inicializar serviço de notificações modernas
  await ModernNotificationService.instance.initialize();

  // Inicializar AdMob (apenas em Prod ou se quiser testar em Dev)
  await AdMobService().initialize();

  // Inicializar In-App Purchases
  await PurchaseService().initialize();

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('✅ Bootstrap completo - Iniciando UI');
  debugPrint('═══════════════════════════════════════════════════════');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        welcomeServiceProvider.overrideWithValue(
          WelcomeService(sharedPreferences),
        ),
      ],
      child: const OdysseyApp(),
    ),
  );
}

class OdysseyApp extends ConsumerStatefulWidget {
  const OdysseyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<OdysseyApp> createState() => _OdysseyAppState();
}

class _OdysseyAppState extends ConsumerState<OdysseyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLifecycleServiceProvider);
      NotificationActionHandler.setRef(ref);
      NotificationActionHandler.checkPendingAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final localeState = ref.watch(localeStateProvider);
    final flavor = ref.watch(currentFlavorProvider);

    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: NotificationActionHandler.navigatorKey,
        navigatorObservers: [SoundNavigatorObserver()],
        debugShowCheckedModeBanner: flavor.isDev, // Banner só em Dev!
        title: flavor.displayName, // Nome dinâmico
        theme: currentTheme,
        darkTheme: currentTheme,
        themeMode: themeMode,
        locale: localeState.currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppFlowyEditorLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
        // Banner visual em Dev
        builder: flavor.isDev ? _devBannerBuilder : null,
      ),
    );
  }

  /// Adiciona um banner visual no canto para identificar versão Dev
  Widget _devBannerBuilder(BuildContext context, Widget? child) {
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
