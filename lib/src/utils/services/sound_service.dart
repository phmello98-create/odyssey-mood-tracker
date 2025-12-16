import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de som usando flutter_soloud - não interrompe outras apps
/// Baixa latência, perfeito para efeitos sonoros de UI
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool _initialized = false;
  double _volume = 0.5;
  double _ambientVolume = 0.3;
  
  // Cache de sons carregados para performance
  final Map<String, AudioSource> _loadedSounds = {};
  
  // Handle do som ambiente atual (para loop)
  SoundHandle? _ambientHandle;
  String? _currentAmbientKey;
  
  // Tick do timer
  bool _isTickingEnabled = false;
  Timer? _tickTimer;
  String _tickType = 'soft_tick';
  double _tickVolume = 0.3;

  // Getters/Setters
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
    if (!value) {
      stopAmbientSound();
      stopTickSound();
    }
  }
  
  double get volume => _volume;
  set volume(double value) => _volume = value.clamp(0.0, 1.0);
  
  double get ambientVolume => _ambientVolume;
  set ambientVolume(double value) => _ambientVolume = value.clamp(0.0, 1.0);
  
  double get tickVolume => _tickVolume;
  set tickVolume(double value) => _tickVolume = value.clamp(0.0, 1.0);
  
  bool get isTickingEnabled => _isTickingEnabled;
  bool get isAmbientPlaying => _ambientHandle != null;
  String? get currentAmbientSound => _currentAmbientKey;
  String get tickType => _tickType;
  set tickType(String value) => _tickType = value;
  
  // Mapa de nomes amigáveis (compatibilidade)
  static Map<String, String> get ambientSoundNames {
    return ambientSoundsLibrary.map((key, value) => MapEntry(key, value.name));
  }
  
  // Categorias de sons
  static const Map<String, String> categoryNames = {
    'nature': '🌿 Natureza',
    'ambient': '🎧 Ambiente',
  };
  
  // Verifica se som está baixado (sempre true pois são locais)
  Future<bool> isSoundDownloaded(String key) async {
    return ambientSoundsLibrary.containsKey(key);
  }

  // Sons de ambiente disponíveis
  static const Map<String, AmbientSoundInfo> ambientSoundsLibrary = {
    'none': AmbientSoundInfo(
      name: '🔇 Sem Som',
      description: 'Silêncio total',
      source: '',
      category: 'none',
    ),
    'forest': AmbientSoundInfo(
      name: '🌳 Floresta',
      description: 'Sons da natureza',
      source: 'sounds/ambient/forest.mp3',
      category: 'nature',
    ),
    'fire': AmbientSoundInfo(
      name: '🔥 Fogueira',
      description: 'Crepitar relaxante',
      source: 'sounds/ambient/fire.mp3',
      category: 'nature',
    ),
    'birds': AmbientSoundInfo(
      name: '🐦 Pássaros',
      description: 'Canto calmo',
      source: 'sounds/ambient/birds-chirping-calm-173695.mp3',
      category: 'nature',
    ),
    'cafe': AmbientSoundInfo(
      name: '☕ Cafeteria',
      description: 'Ambiente de café',
      source: 'sounds/ambient/cafe.mp3',
      category: 'ambient',
    ),
    'library': AmbientSoundInfo(
      name: '📚 Biblioteca',
      description: 'Silêncio suave',
      source: 'sounds/ambient/library-ambiance-60000.mp3',
      category: 'ambient',
    ),
  };

  // Mapa de sons de UI (curtos)
  static const Map<String, String> _uiSounds = {
    // === SONS SND01_sine (novos, profissionais) ===
    'snd_button': 'sounds/button.wav',           // Botão com função específica
    'snd_tap_01': 'sounds/tap_01.wav',          // Feedback tátil (variação 1)
    'snd_tap_02': 'sounds/tap_02.wav',          // Feedback tátil (variação 2)
    'snd_tap_03': 'sounds/tap_03.wav',          // Feedback tátil (variação 3)
    'snd_tap_04': 'sounds/tap_04.wav',          // Feedback tátil (variação 4)
    'snd_tap_05': 'sounds/tap_05.wav',          // Feedback tátil (variação 5)
    'snd_select': 'sounds/select.wav',          // Seleção de checkbox/radio
    'snd_disabled': 'sounds/disabled.wav',       // Botão desabilitado
    'snd_toggle_on': 'sounds/toggle_on.wav',    // Switch ativado
    'snd_toggle_off': 'sounds/toggle_off.wav',  // Switch desativado
    'snd_transition_up': 'sounds/transition_up.wav',     // Abrir modal/dialog
    'snd_transition_down': 'sounds/transition_down.wav', // Fechar modal/dialog
    'snd_swipe_01': 'sounds/swipe_01.wav',      // Transição horizontal (var 1)
    'snd_swipe_02': 'sounds/swipe_02.wav',      // Transição horizontal (var 2)
    'snd_swipe_03': 'sounds/swipe_03.wav',      // Transição horizontal (var 3)
    'snd_swipe_04': 'sounds/swipe_04.wav',      // Transição horizontal (var 4)
    'snd_swipe_05': 'sounds/swipe_05.wav',      // Transição horizontal (var 5)
    'snd_type_01': 'sounds/type_01.wav',        // Digitação (variação 1)
    'snd_type_02': 'sounds/type_02.wav',        // Digitação (variação 2)
    'snd_type_03': 'sounds/type_03.wav',        // Digitação (variação 3)
    'snd_type_04': 'sounds/type_04.wav',        // Digitação (variação 4)
    'snd_type_05': 'sounds/type_05.wav',        // Digitação (variação 5)
    'snd_notification': 'sounds/notification.wav',  // Notificação
    'snd_caution': 'sounds/caution.wav',        // Aviso negativo
    'snd_celebration': 'sounds/celebration.wav', // Conquista máxima
    'snd_progress_loop': 'sounds/progress_loop.wav', // Loop de processamento
    'snd_ringtone_loop': 'sounds/ringtone_loop.wav', // Alarme (loop)
    
    // === LEGACY (apontando para novos sons melhores) ===
    'click': 'sounds/ui/clicks/click_soft.ogg',      // MELHORADO - KeypressStandard
    'button': 'sounds/ui/clicks/button_click.ogg',   // MELHORADO - TW_Touch (iOS)
    'success': 'sounds/ui/feedback/success_chime.ogg', // MELHORADO - iOS Popcorn
    'fail': 'sounds/ui/feedback/error_beep.ogg',     // MELHORADO - Ambient LowBattery
    'happy': 'sounds/ui/feedback/happy_bop.ogg',     // MELHORADO - Oxygen OS surprise
    'xp': 'sounds/ui/feedback/success_chime.ogg',    // MELHORADO
    'coin': 'sounds/ui/feedback/success_chime.ogg',  // MELHORADO
    'trophy': 'sounds/ui/feedback/success_chime.ogg', // MELHORADO
    'levelup': 'sounds/ui/feedback/success_chime.ogg', // MELHORADO
    'achievement': 'sounds/ui/notifications/reminder_ding.ogg', // MELHORADO - MIUI CrystalPiano
    'timer_end': 'sounds/ui/notifications/alert_ping.ogg', // MELHORADO - Zen UI DingDong
    'notification': 'sounds/ui/notifications/reminder_general.ogg', // NOVO - camera_focus (chamativo!)
    'scroll_open': 'sounds/ui/popups/modal_open.ogg', // MELHORADO - iOS Cam_Start
    'scroll_close': 'sounds/ui/popups/modal_close.ogg', // MELHORADO - iOS Cam_Stop
    'ready': 'sounds/ui/feedback/add_item.ogg',      // MELHORADO - Ambient Dock
    'tick_soft': 'sounds/tick_soft.mp3',             // mantém original
    'tick_clock': 'sounds/tick_clock.mp3',           // mantém original
    'swipe': 'sounds/ui/transitions/swipe_clean.ogg', // MELHORADO - iOS Unlock
    'mood_select': 'sounds/ui/mood/mood_select.ogg', // NOVO - iOS PowerOn (legal!)
    
    // === NOVOS SONS PROFISSIONAIS (iOS, Ambient OS, MIUI) ===
    // Clicks/Taps
    'button_click': 'sounds/ui/clicks/button_click.ogg',  // TW_Touch (iOS)
    'tap_soft': 'sounds/ui/clicks/tap_soft.ogg',          // S_HW_Touch (iOS)
    'edit_click': 'sounds/ui/clicks/edit_click.ogg',      // Effect_Tick (Ambient)
    'click_soft': 'sounds/ui/clicks/click_soft.ogg',      // KeypressStandard (Ambient)
    
    // Transitions
    'page_turn': 'sounds/ui/transitions/page_turn.ogg',       // Ambient Lock
    'swipe_clean': 'sounds/ui/transitions/swipe_clean.ogg',   // iOS Unlock
    'navigation_sfx': 'sounds/ui/transitions/navigation.ogg', // Ambient Unlock
    
    // Feedback
    'success_chime': 'sounds/ui/feedback/success_chime.ogg',   // iOS Popcorn
    'error_beep': 'sounds/ui/feedback/error_beep.ogg',         // Ambient LowBattery
    'add_item': 'sounds/ui/feedback/add_item.ogg',             // Ambient Dock
    'delete_whoosh': 'sounds/ui/feedback/delete_whoosh.ogg',   // Ambient Undock
    'happy_bop': 'sounds/ui/feedback/happy_bop.ogg',           // Oxygen OS surprise
    'habit_complete': 'sounds/ui/feedback/habit_complete.ogg', // NOVO - Ambient Unlock
    'task_complete': 'sounds/ui/feedback/task_complete.ogg',   // NOVO - Ambient Undock
    'timer_stop': 'sounds/ui/feedback/timer_stop.ogg',         // NOVO - Ambient Trusted
    
    // Popups
    'modal_open': 'sounds/ui/popups/modal_open.ogg',     // iOS Cam_Start
    'modal_close': 'sounds/ui/popups/modal_close.ogg',   // iOS Cam_Stop
    
    // Notifications
    'reminder_ding': 'sounds/ui/notifications/reminder_ding.ogg',     // MIUI CrystalPiano
    'alert_ping': 'sounds/ui/notifications/alert_ping.ogg',           // Zen UI DingDong
    'reminder_general': 'sounds/ui/notifications/reminder_general.ogg', // NOVO - camera_focus
    
    // Mood (carinhas) - PERSONALIZADOS!
    'mood_warm': 'sounds/ui/mood/mood_select.ogg',   // iOS PowerOn (legal!)
    'mood_happy': 'sounds/ui/mood/mood_happy.ogg',   // Xperia pop
    'mood_tap': 'sounds/ui/mood/mood_tap.ogg',       // Ambient Trusted
  };
  
  // Contador de instâncias para rate limiting
  final Map<String, int> _playingInstances = {};
  static const int _maxSimultaneousInstances = 3;
  
  // Durações estimadas por som (para rate limiting)
  static const Map<String, int> _soundDurations = {
    // Sons SND01_sine
    'snd_button': 150, 'snd_tap_01': 80, 'snd_tap_02': 80, 'snd_tap_03': 80, 
    'snd_tap_04': 80, 'snd_tap_05': 80,
    'snd_select': 150, 'snd_disabled': 100,
    'snd_toggle_on': 150, 'snd_toggle_off': 150,
    'snd_transition_up': 150, 'snd_transition_down': 150,
    'snd_swipe_01': 200, 'snd_swipe_02': 200, 'snd_swipe_03': 200, 
    'snd_swipe_04': 200, 'snd_swipe_05': 200,
    'snd_type_01': 80, 'snd_type_02': 80, 'snd_type_03': 80, 
    'snd_type_04': 80, 'snd_type_05': 80,
    'snd_notification': 300, 'snd_caution': 250, 'snd_celebration': 800,
    
    // Clicks
    'button_click': 100, 'tap_soft': 100, 'edit_click': 120, 'click_soft': 120,
    // Transitions
    'page_turn': 300, 'swipe_clean': 200, 'navigation_sfx': 250,
    // Feedback
    'success_chime': 400, 'error_beep': 300, 'add_item': 300, 'delete_whoosh': 400,
    'happy_bop': 350, 'habit_complete': 250, 'task_complete': 400, 'timer_stop': 300,
    // Popups
    'modal_open': 200, 'modal_close': 180,
    // Notifications
    'reminder_ding': 400, 'alert_ping': 350, 'reminder_general': 350,
    // Mood (carinhas)
    'mood_warm': 400, 'mood_happy': 350, 'mood_tap': 300,
    // Legacy (mapeados para novos)
    'click': 120, 'button': 100, 'success': 400, 'fail': 300,
    'happy': 350, 'mood_select': 400, 'notification': 350,
  };

  /// Inicializa o serviço de som
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // Inicializa o SoLoud
      await SoLoud.instance.init();
      _initialized = true;
      
      // Carrega configurações salvas
      await _loadSettings();
      
      // Pre-carrega sons mais usados para latência zero
      _preloadCommonSounds(); // Não aguarda, faz em background
      
      debugPrint('🔊 SoundService initialized with flutter_soloud');
    } catch (e) {
      debugPrint('⚠️ SoundService init error (sounds disabled): $e');
      // Mesmo com erro, marca como inicializado para não travar o app
      // Sons simplesmente não vão tocar
      _initialized = false;
    }
  }
  
  /// Carrega configurações salvas
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ambientVolume = prefs.getDouble('ambient_volume') ?? 0.3;
      _tickVolume = prefs.getDouble('tick_volume') ?? 0.3;
      _isTickingEnabled = prefs.getBool('tick_enabled') ?? false;
      _tickType = prefs.getString('tick_type') ?? 'soft_tick';
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
    }
  }
  
  /// Salva configurações
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ambient_volume', _ambientVolume);
      await prefs.setDouble('tick_volume', _tickVolume);
      await prefs.setBool('tick_enabled', _isTickingEnabled);
      await prefs.setString('tick_type', _tickType);
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }
  }
  
  /// Pre-carrega sons mais usados por categoria
  Future<void> _preloadCommonSounds() async {
    // Categoria 1: Sons SND críticos (usados constantemente) - carregar primeiro
    final criticalSndSounds = [
      'snd_button', 'snd_tap_01', 'snd_tap_02', 'snd_tap_03', 'snd_tap_04', 'snd_tap_05',
      'snd_select', 'snd_disabled', 'snd_toggle_on', 'snd_toggle_off',
    ];
    for (final key in criticalSndSounds) {
      await _loadSound(key);
    }
    
    // Categoria 2: Clicks legacy (usados constantemente) - carregar primeiro
    final criticalSounds = ['click', 'button_click', 'tap_soft', 'click_soft'];
    for (final key in criticalSounds) {
      await _loadSound(key);
    }
    
    // Categoria 3: Sons SND frequentes (transições, typing) - carregar em paralelo
    final frequentSndSounds = [
      'snd_transition_up', 'snd_transition_down',
      'snd_swipe_01', 'snd_swipe_02', 'snd_swipe_03', 'snd_swipe_04', 'snd_swipe_05',
      'snd_type_01', 'snd_type_02', 'snd_type_03', 'snd_type_04', 'snd_type_05',
      'snd_notification', 'snd_caution',
    ];
    Future.wait(frequentSndSounds.map((key) => _loadSound(key)));
    
    // Categoria 4: Feedback e Mood legacy (usados frequentemente) - carregar em paralelo
    final frequentSounds = [
      'success_chime', 'add_item', 'error_beep', 'happy_bop',
      'mood_warm', 'mood_happy', 'mood_tap', // Sons de mood (carinhas)
      'task_complete', 'habit_complete', // Sons específicos
    ];
    Future.wait(frequentSounds.map((key) => _loadSound(key)));
    
    // Categoria 5: Popups, transitions, notifications e outros - carregar com delay
    Future.delayed(const Duration(seconds: 2), () {
      final moderateSounds = [
        'modal_open', 'modal_close', 'delete_whoosh',
        'navigation_sfx', 'swipe_clean', 'page_turn',
        'reminder_ding', 'alert_ping', 'reminder_general',
        'timer_stop', // Som de parar timer
        'snd_celebration', // Celebration SND
      ];
      Future.wait(moderateSounds.map((key) => _loadSound(key)));
    });
    
    debugPrint('🔊 Pre-loaded ${criticalSndSounds.length + criticalSounds.length} critical sounds (SND + legacy)');
  }
  
  /// Carrega um som no cache
  Future<AudioSource?> _loadSound(String key) async {
    if (_loadedSounds.containsKey(key)) {
      return _loadedSounds[key];
    }
    
    final path = _uiSounds[key];
    if (path == null) return null;
    
    try {
      final source = await SoLoud.instance.loadAsset('assets/$path');
      _loadedSounds[key] = source;
      return source;
    } catch (e) {
      debugPrint('⚠️ Could not load sound: $key ($e)');
      return null;
    }
  }
  
  /// Toca um som pelo key com rate limiting
  Future<void> _play(String key, {double volume = 0.5}) async {
    if (!_soundEnabled || !_initialized) return;
    
    // Rate limiting: verifica limite de instâncias simultâneas
    final currentInstances = _playingInstances[key] ?? 0;
    if (currentInstances >= _maxSimultaneousInstances) {
      return; // Ignora se muitas instâncias já tocando
    }
    
    try {
      var source = _loadedSounds[key];
      source ??= await _loadSound(key);
      
      if (source != null) {
        // Incrementa contador de instâncias
        _playingInstances[key] = currentInstances + 1;
        
        await SoLoud.instance.play(source, volume: volume * _volume);
        
        // Decrementa contador após duração estimada
        final durationMs = _soundDurations[key] ?? 300;
        Future.delayed(Duration(milliseconds: durationMs), () {
          _playingInstances[key] = (_playingInstances[key] ?? 1) - 1;
        });
      }
    } catch (e) {
      debugPrint('Sound play error ($key): $e');
    }
  }

  // ==========================================
  // SONS DE INTERFACE (UI) - NOVOS MÉTODOS OCTAVE
  // ==========================================

  /// Som de click de botão (Octave - profissional)
  Future<void> playButtonClick() async {
    await _play('button_click', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  /// Som de tap suave (Octave)
  Future<void> playTapSoft() async {
    await _play('tap_soft', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  /// Som de edição iniciada/salva (Octave)
  Future<void> playEdit() async {
    await _play('edit_click', volume: 0.25);
    await HapticFeedback.lightImpact();
  }

  /// Som de transição de página (Octave)
  Future<void> playPageTransition() async {
    await _play('page_turn', volume: 0.3);
    await HapticFeedback.selectionClick();
  }

  /// Som de swipe limpo (Octave)
  Future<void> playSwipeClean() async {
    await _play('swipe_clean', volume: 0.25);
    await HapticFeedback.selectionClick();
  }

  /// Som de navegação customizado (Octave)
  Future<void> playNavigationSfx() async {
    await _play('navigation_sfx', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  /// Som de sucesso com chime (Octave)
  Future<void> playSuccessChime() async {
    await _play('success_chime', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }

  /// Som de erro curto (Octave)
  Future<void> playErrorBeep() async {
    await _play('error_beep', volume: 0.35);
    await HapticFeedback.heavyImpact();
  }

  /// Som de adicionar item (Octave)
  Future<void> playAddItem() async {
    await _play('add_item', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  /// Som de deletar com whoosh (Octave)
  Future<void> playDeleteWhoosh() async {
    await _play('delete_whoosh', volume: 0.32);
    await HapticFeedback.mediumImpact();
  }

  /// Som de modal abrindo (Octave)
  Future<void> playModalOpenSfx() async {
    await _play('modal_open', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  /// Som de modal fechando (Octave)
  Future<void> playModalCloseSfx() async {
    await _play('modal_close', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  /// Som de lembrete/reminder (Octave)
  Future<void> playReminderDing() async {
    await _play('reminder_ding', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  /// Som de alerta/ping (Octave)
  Future<void> playAlertPing() async {
    await _play('alert_ping', volume: 0.42);
    await HapticFeedback.mediumImpact();
  }

  // ==========================================
  // SONS DE INTERFACE (UI) - LEGACY (compatibilidade)
  // ==========================================
  
  /// Som de toque/clique
  Future<void> playTap() async {
    await _play('click', volume: 0.3);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de botão
  Future<void> playButton() async {
    await _play('button', volume: 0.35);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de navegação
  Future<void> playNavigation() async {
    await _play('click', volume: 0.25);
    await HapticFeedback.selectionClick();
  }
  
  /// Som de swipe
  Future<void> playSwipe() async {
    await _play('click', volume: 0.2);
    await HapticFeedback.selectionClick();
  }
  
  /// Som de modal abrindo
  Future<void> playModalOpen() async {
    await _play('scroll_open', volume: 0.3);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de modal fechando
  Future<void> playModalClose() async {
    await _play('scroll_close', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  // ==========================================
  // SONS DE AÇÕES/TAREFAS
  // ==========================================
  
  /// Som de sucesso geral
  Future<void> playSuccess() async {
    await _play('success', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de tarefa completa (satisfatório)
  Future<void> playComplete() async {
    await _play('success', volume: 0.45);
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }
  
  /// Som de tarefa completa (NOVO - Ambient Undock!)
  Future<void> playTaskComplete() async {
    await _play('task_complete', volume: 0.48);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de item adicionado
  Future<void> playAdd() async {
    await _play('button', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de item deletado
  Future<void> playDelete() async {
    await _play('fail', volume: 0.35);
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de erro
  Future<void> playError() async {
    await _play('fail', volume: 0.4);
    await HapticFeedback.heavyImpact();
  }

  // ==========================================
  // SONS DE GAMIFICAÇÃO
  // ==========================================
  
  /// Som de XP ganho
  Future<void> playXPGain() async {
    await _play('xp', volume: 0.4);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de moedas
  Future<void> playCoin() async {
    await _play('coin', volume: 0.4);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de troféu
  Future<void> playTrophy() async {
    await _play('trophy', volume: 0.5);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de level up
  Future<void> playLevelUp() async {
    await _play('levelup', volume: 0.55);
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de conquista (MELHORADO!)
  Future<void> playAchievement() async {
    await _play('reminder_ding', volume: 0.55);
    for (int i = 0; i < 2; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de felicidade/alegria (MELHORADO - bop alegre!)
  Future<void> playHappy() async {
    await _play('happy_bop', volume: 0.4);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de bônus (MELHORADO!)
  Future<void> playBonus() async {
    await _play('success_chime', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de baú abrindo (MELHORADO!)
  Future<void> playChestOpen() async {
    await _play('modal_open', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de parabéns (MELHORADO!)
  Future<void> playCongrats() async {
    await _play('happy_bop', volume: 0.5);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de progresso
  Future<void> playProgress() async {
    await _play('xp', volume: 0.3);
  }

  // ==========================================
  // SONS DE TIMER/POMODORO
  // ==========================================
  
  /// Som de início do timer
  Future<void> playTimerStart() async {
    await _play('ready', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de fim do timer
  Future<void> playTimerEnd() async {
    await _play('timer_end', volume: 0.6);
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
  
  /// Som de parar timer/pomodoro (NOVO - Ambient Trusted!)
  Future<void> playTimerStop() async {
    await _play('timer_stop', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de timer ding
  Future<void> playTimerDing() async {
    await _play('notification', volume: 0.4);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de notificação (NOVO - camera_focus chamativo!)
  Future<void> playNotification() async {
    await _play('reminder_general', volume: 0.5);
    await HapticFeedback.selectionClick();
  }

  // ==========================================
  // SONS DE HÁBITOS/HUMOR - MELHORADOS!
  // ==========================================
  
  /// Som de mood selecionado (NOVO - warmguitar suave!)
  Future<void> playMoodSelect() async {
    await _play('mood_warm', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de mood feliz (NOVO - plucked alegre!)
  Future<void> playMoodHappy() async {
    await _play('mood_happy', volume: 0.42);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som de mood tap (NOVO - tap suave)
  Future<void> playMoodTap() async {
    await _play('mood_tap', volume: 0.35);
    await HapticFeedback.lightImpact();
  }
  
  /// Som de hábito completado (NOVO - Ambient Unlock!)
  Future<void> playHabitComplete() async {
    await _play('habit_complete', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }
  
  /// Som de streak mantida (MELHORADO!)
  Future<void> playStreak() async {
    await _play('success_chime', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som curto genérico
  Future<void> playShort(String key, {double volume = 0.4}) async {
    await _play(key, volume: volume);
    await HapticFeedback.lightImpact();
  }

  // ==========================================
  // SONS SND01_sine - NOVOS MÉTODOS PROFISSIONAIS
  // ==========================================
  
  /// Som SND: Tap aleatório (5 variações) - feedback tátil responsivo
  Future<void> playSndTap() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_tap_0$variation', volume: 0.28);
    await HapticFeedback.selectionClick();
  }
  
  /// Som SND: Botão com função específica
  Future<void> playSndButton() async {
    await _play('snd_button', volume: 0.35);
    await HapticFeedback.lightImpact();
  }
  
  /// Som SND: Select (checkbox, radio, form)
  Future<void> playSndSelect() async {
    await _play('snd_select', volume: 0.32);
    await HapticFeedback.lightImpact();
  }
  
  /// Som SND: Botão desabilitado
  Future<void> playSndDisabled() async {
    await _play('snd_disabled', volume: 0.3);
    await HapticFeedback.lightImpact();
  }
  
  /// Som SND: Toggle ON (grave -> agudo)
  Future<void> playSndToggleOn() async {
    await _play('snd_toggle_on', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som SND: Toggle OFF (agudo -> grave)
  Future<void> playSndToggleOff() async {
    await _play('snd_toggle_off', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som SND: Abrir modal/dialog (transição hierárquica up)
  Future<void> playSndTransitionUp() async {
    await _play('snd_transition_up', volume: 0.35);
    await HapticFeedback.lightImpact();
  }
  
  /// Som SND: Fechar modal/dialog (transição hierárquica down)
  Future<void> playSndTransitionDown() async {
    await _play('snd_transition_down', volume: 0.32);
    await HapticFeedback.lightImpact();
  }
  
  /// Som SND: Swipe aleatório (5 variações) - transição horizontal
  Future<void> playSndSwipe() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_swipe_0$variation', volume: 0.28);
    await HapticFeedback.selectionClick();
  }
  
  /// Som SND: Type aleatório (5 variações) - digitação
  Future<void> playSndType() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_type_0$variation', volume: 0.25);
  }
  
  /// Som SND: Notificação
  Future<void> playSndNotification() async {
    await _play('snd_notification', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }
  
  /// Som SND: Caution (aviso negativo)
  Future<void> playSndCaution() async {
    await _play('snd_caution', volume: 0.42);
    await HapticFeedback.heavyImpact();
  }
  
  /// Som SND: Celebration (conquista máxima!)
  Future<void> playSndCelebration() async {
    await _play('snd_celebration', volume: 0.6);
    // Haptic sequence para celebration
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  /// Som SND: Inicia loop de progresso
  SoundHandle? _progressLoopHandle;
  Future<void> startSndProgressLoop() async {
    if (!_soundEnabled || !_initialized) return;
    
    try {
      await stopSndProgressLoop(); // Para loop anterior se existir
      
      var source = _loadedSounds['snd_progress_loop'];
      source ??= await _loadSound('snd_progress_loop');
      
      if (source != null) {
        _progressLoopHandle = await SoLoud.instance.play(
          source,
          volume: 0.3 * _volume,
          looping: true,
        );
      }
    } catch (e) {
      debugPrint('Error starting progress loop: $e');
    }
  }
  
  /// Som SND: Para loop de progresso
  Future<void> stopSndProgressLoop() async {
    if (_progressLoopHandle != null) {
      try {
        await SoLoud.instance.stop(_progressLoopHandle!);
      } catch (e) {
        debugPrint('Error stopping progress loop: $e');
      }
      _progressLoopHandle = null;
    }
  }
  
  /// Som SND: Inicia loop de ringtone/alarme
  SoundHandle? _ringtoneLoopHandle;
  Future<void> startSndRingtoneLoop() async {
    if (!_soundEnabled || !_initialized) return;
    
    try {
      await stopSndRingtoneLoop(); // Para loop anterior se existir
      
      var source = _loadedSounds['snd_ringtone_loop'];
      source ??= await _loadSound('snd_ringtone_loop');
      
      if (source != null) {
        _ringtoneLoopHandle = await SoLoud.instance.play(
          source,
          volume: 0.5 * _volume,
          looping: true,
        );
      }
    } catch (e) {
      debugPrint('Error starting ringtone loop: $e');
    }
  }
  
  /// Som SND: Para loop de ringtone/alarme
  Future<void> stopSndRingtoneLoop() async {
    if (_ringtoneLoopHandle != null) {
      try {
        await SoLoud.instance.stop(_ringtoneLoopHandle!);
      } catch (e) {
        debugPrint('Error stopping ringtone loop: $e');
      }
      _ringtoneLoopHandle = null;
    }
  }

  // ==========================================
  // SONS DE AMBIENTE (LOOP)
  // ==========================================
  
  /// Inicia som de ambiente
  Future<void> startAmbientSound(String soundKey) async {
    if (!_soundEnabled || !_initialized) return;
    if (soundKey == 'none' || !ambientSoundsLibrary.containsKey(soundKey)) {
      await stopAmbientSound();
      return;
    }
    
    try {
      // Para o som atual se houver
      await stopAmbientSound();
      
      final soundInfo = ambientSoundsLibrary[soundKey]!;
      if (soundInfo.source.isEmpty) return;
      
      // Carrega o som
      final source = await SoLoud.instance.loadAsset('assets/${soundInfo.source}');
      
      // Toca em loop
      _ambientHandle = await SoLoud.instance.play(
        source,
        volume: _ambientVolume,
        looping: true,
      );
      _currentAmbientKey = soundKey;
      
      debugPrint('🎵 Ambient started: $soundKey');
    } catch (e) {
      debugPrint('Error playing ambient: $e');
      _currentAmbientKey = null;
    }
  }
  
  /// Para som de ambiente
  Future<void> stopAmbientSound() async {
    if (_ambientHandle != null) {
      try {
        await SoLoud.instance.stop(_ambientHandle!);
      } catch (e) {
        debugPrint('Error stopping ambient: $e');
      }
      _ambientHandle = null;
    }
    _currentAmbientKey = null;
  }
  
  /// Ajusta volume do ambiente
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    if (_ambientHandle != null) {
      try {
        SoLoud.instance.setVolume(_ambientHandle!, _ambientVolume);
      } catch (e) {
        debugPrint('Error setting ambient volume: $e');
      }
    }
    await _saveSettings();
  }

  // ==========================================
  // TICK DO TIMER
  // ==========================================
  
  /// Inicia som de tick
  Future<void> startTickSound({String? type}) async {
    if (!_soundEnabled || !_initialized) return;
    
    if (type != null) _tickType = type;
    _isTickingEnabled = true;
    
    _tickTimer?.cancel();
    
    // Carrega o som de tick
    final tickKey = _tickType == 'clock_tick' ? 'tick_clock' : 'tick_soft';
    await _loadSound(tickKey);
    
    // Timer que toca tick a cada segundo
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_soundEnabled && _isTickingEnabled) {
        _play(tickKey, volume: _tickVolume);
      }
    });
    
    // Toca o primeiro tick imediatamente
    await _play(tickKey, volume: _tickVolume);
    
    debugPrint('🔊 Tick started: $_tickType');
    await _saveSettings();
  }
  
  /// Para som de tick
  Future<void> stopTickSound() async {
    _isTickingEnabled = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    debugPrint('🔇 Tick stopped');
    await _saveSettings();
  }
  
  /// Alterna tick
  Future<void> toggleTickSound() async {
    if (_isTickingEnabled) {
      await stopTickSound();
    } else {
      await startTickSound();
    }
  }
  
  /// Ajusta volume do tick
  Future<void> setTickVolume(double volume) async {
    _tickVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  // ==========================================
  // CONTROLES DO TIMER
  // ==========================================
  
  /// Inicia sons do timer
  Future<void> startTimerSounds({String? ambientKey, bool enableTick = false}) async {
    if (ambientKey != null && ambientKey != 'none') {
      await startAmbientSound(ambientKey);
    }
    if (enableTick) {
      await startTickSound();
    }
  }
  
  /// Para todos os sons do timer
  Future<void> stopTimerSounds() async {
    await stopAmbientSound();
    await stopTickSound();
  }
  
  /// Para o som atual
  Future<void> stop() async {
    // SoLoud para automaticamente sons curtos
  }

  /// Libera recursos
  void dispose() {
    _tickTimer?.cancel();
    stopAmbientSound();
    
    // Libera sons carregados
    for (final source in _loadedSounds.values) {
      SoLoud.instance.disposeSource(source);
    }
    _loadedSounds.clear();
    
    SoLoud.instance.deinit();
  }
}

// Provider global
final soundService = SoundService();

/// Info de som ambiente
class AmbientSoundInfo {
  final String name;
  final String description;
  final String source;
  final String category;
  final bool isLocal;
  final bool isTick;
  
  const AmbientSoundInfo({
    required this.name,
    required this.description,
    required this.source,
    required this.category,
    this.isLocal = true,
    this.isTick = false,
  });
}
