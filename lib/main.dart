import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:toastification/toastification.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar MediaKit Apenas para Linux/Windows (suporte a streaming de áudio)
  // No Android/iOS, o just_audio usa implementações nativas (ExoPlayer/AVPlayer)
  if (!Platform.isAndroid && !Platform.isIOS) {
    // Configurar para evitar ytdl_hook (youtube-dl) em streams de rádio
    // IMPORTANTE: Configurar propriedades estáticas ANTES de ensureInitialized()
    JustAudioMediaKit.protocolWhitelist = const [
      'http',
      'https',
      'file',
      'rtsp',
      'rtmp',
    ];
    JustAudioMediaKit.bufferSize = 8 * 1024 * 1024; // 8MB buffer para streams
    JustAudioMediaKit.ensureInitialized();
    debugPrint('🎵 JustAudioMediaKit inicializado (Linux/Desktop)');
  }

  // Inicializar Firebase PRIMEIRO (antes de qualquer outro serviço que dependa dele)
  // Nota: Firebase pode não estar disponível em todas as plataformas (ex: Linux)
  try {
    // Timeout para evitar hang infinito em inicialização
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('🔥 Firebase inicializado no main()');
  } catch (e) {
    // Firebase não suportado nesta plataforma (ex: Linux) ou erro de conexão
    debugPrint('⚠️ Firebase não disponível ou falhou: $e');
  }

  // Inicializar SharedPreferences antes do runApp
  final sharedPreferences = await SharedPreferences.getInstance();

  // Inicializar SoundService SND (sons de UI/UX)
  await soundService.init();
  debugPrint('🔊 SoundService SND inicializado');

  // Configurar listeners de notificação ANTES do runApp
  // Isso é necessário para que as ações funcionem mesmo com o app em background
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationService.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationService.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationService.onDismissActionReceivedMethod,
  );

  // Inicializar novo serviço de notificações modernas
  await ModernNotificationService.instance.initialize();

  // Inicializar AdMob
  await AdMobService().initialize();

  // Inicializar In-App Purchases
  await PurchaseService().initialize();

  // NOTA: ShowcaseService será inicializado no AppInitializer após o Hive

  runApp(
    ProviderScope(
      overrides: [
        // Fornecer SharedPreferences para o sistema de auth
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // Fornecer WelcomeService
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
    // Inicializar o serviço de lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLifecycleServiceProvider);

      // Configurar o ref no handler de notificações
      NotificationActionHandler.setRef(ref);

      // Verificar se há ações pendentes de notificação
      NotificationActionHandler.checkPendingAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final localeState = ref.watch(localeStateProvider);

    return ToastificationWrapper(
      child: MaterialApp(
        // Usar o navigatorKey global para deep linking de notificações
        navigatorKey: NotificationActionHandler.navigatorKey,
        // NavigatorObserver para sons SND em transições
        navigatorObservers: [SoundNavigatorObserver()],
        debugShowCheckedModeBanner: false,
        title: 'Odyssey',
        // Usa o tema selecionado diretamente
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
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
      ),
    );
  }
}
