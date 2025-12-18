import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de som usando audioplayers - multiplataforma e leve
/// Funciona bem em Linux, Android e iOS
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool _initialized = false;
  double _volume = 0.5;
  double _ambientVolume = 0.3;

  // Pool de players para sons curtos (evita criar/destruir players)
  final List<AudioPlayer> _playerPool = [];
  static const int _poolSize = 5;
  int _currentPoolIndex = 0;

  // Player dedicado para sons ambiente (loops)
  AudioPlayer? _ambientPlayer;
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
  bool get isAmbientPlaying =>
      _ambientPlayer != null && _currentAmbientKey != null;
  String? get currentAmbientSound => _currentAmbientKey;
  String get tickType => _tickType;
  set tickType(String value) => _tickType = value;

  // Mapa de nomes amigáveis
  static Map<String, String> get ambientSoundNames {
    return ambientSoundsLibrary.map((key, value) => MapEntry(key, value.name));
  }

  // Categorias de sons
  static const Map<String, String> categoryNames = {
    'nature': '🌿 Natureza',
    'ambient': '🎧 Ambiente',
  };

  // Verifica se som está disponível
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
    // === SONS SND (novos, profissionais) ===
    'snd_button': 'sounds/button.wav',
    'snd_tap_01': 'sounds/tap_01.wav',
    'snd_tap_02': 'sounds/tap_02.wav',
    'snd_tap_03': 'sounds/tap_03.wav',
    'snd_tap_04': 'sounds/tap_04.wav',
    'snd_tap_05': 'sounds/tap_05.wav',
    'snd_select': 'sounds/select.wav',
    'snd_disabled': 'sounds/disabled.wav',
    'snd_toggle_on': 'sounds/toggle_on.wav',
    'snd_toggle_off': 'sounds/toggle_off.wav',
    'snd_transition_up': 'sounds/transition_up.wav',
    'snd_transition_down': 'sounds/transition_down.wav',
    'snd_swipe_01': 'sounds/swipe_01.wav',
    'snd_swipe_02': 'sounds/swipe_02.wav',
    'snd_swipe_03': 'sounds/swipe_03.wav',
    'snd_swipe_04': 'sounds/swipe_04.wav',
    'snd_swipe_05': 'sounds/swipe_05.wav',
    'snd_type_01': 'sounds/type_01.wav',
    'snd_type_02': 'sounds/type_02.wav',
    'snd_type_03': 'sounds/type_03.wav',
    'snd_type_04': 'sounds/type_04.wav',
    'snd_type_05': 'sounds/type_05.wav',
    'snd_notification': 'sounds/notification.wav',
    'snd_caution': 'sounds/caution.wav',
    'snd_celebration': 'sounds/celebration.wav',

    // === LEGACY ===
    'click': 'sounds/ui/clicks/click_soft.ogg',
    'button': 'sounds/ui/clicks/button_click.ogg',
    'success': 'sounds/ui/feedback/success_chime.ogg',
    'fail': 'sounds/ui/feedback/error_beep.ogg',
    'happy': 'sounds/ui/feedback/happy_bop.ogg',
    'xp': 'sounds/ui/feedback/success_chime.ogg',
    'coin': 'sounds/ui/feedback/success_chime.ogg',
    'trophy': 'sounds/ui/feedback/success_chime.ogg',
    'levelup': 'sounds/ui/feedback/success_chime.ogg',
    'achievement': 'sounds/ui/notifications/reminder_ding.ogg',
    'timer_end': 'sounds/ui/notifications/alert_ping.ogg',
    'notification': 'sounds/ui/notifications/reminder_general.ogg',
    'scroll_open': 'sounds/ui/popups/modal_open.ogg',
    'scroll_close': 'sounds/ui/popups/modal_close.ogg',
    'ready': 'sounds/ui/feedback/add_item.ogg',
    'tick_soft': 'sounds/tick_soft.mp3',
    'tick_clock': 'sounds/tick_clock.mp3',
    'swipe': 'sounds/ui/transitions/swipe_clean.ogg',
    'mood_select': 'sounds/ui/mood/mood_select.ogg',

    // === NOVOS SONS PROFISSIONAIS ===
    'button_click': 'sounds/ui/clicks/button_click.ogg',
    'tap_soft': 'sounds/ui/clicks/tap_soft.ogg',
    'edit_click': 'sounds/ui/clicks/edit_click.ogg',
    'click_soft': 'sounds/ui/clicks/click_soft.ogg',
    'page_turn': 'sounds/ui/transitions/page_turn.ogg',
    'swipe_clean': 'sounds/ui/transitions/swipe_clean.ogg',
    'navigation_sfx': 'sounds/ui/transitions/navigation.ogg',
    'success_chime': 'sounds/ui/feedback/success_chime.ogg',
    'error_beep': 'sounds/ui/feedback/error_beep.ogg',
    'add_item': 'sounds/ui/feedback/add_item.ogg',
    'delete_whoosh': 'sounds/ui/feedback/delete_whoosh.ogg',
    'happy_bop': 'sounds/ui/feedback/happy_bop.ogg',
    'habit_complete': 'sounds/ui/feedback/habit_complete.ogg',
    'task_complete': 'sounds/ui/feedback/task_complete.ogg',
    'timer_stop': 'sounds/ui/feedback/timer_stop.ogg',
    'modal_open': 'sounds/ui/popups/modal_open.ogg',
    'modal_close': 'sounds/ui/popups/modal_close.ogg',
    'reminder_ding': 'sounds/ui/notifications/reminder_ding.ogg',
    'alert_ping': 'sounds/ui/notifications/alert_ping.ogg',
    'reminder_general': 'sounds/ui/notifications/reminder_general.ogg',
    'mood_warm': 'sounds/ui/mood/mood_select.ogg',
    'mood_happy': 'sounds/ui/mood/mood_happy.ogg',
    'mood_tap': 'sounds/ui/mood/mood_tap.ogg',
  };

  /// Inicializa o serviço de som
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Cria pool de players
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _playerPool.add(player);
      }

      _initialized = true;

      // Carrega configurações salvas
      await _loadSettings();

      debugPrint(
        '🔊 SoundService initialized with audioplayers (pool size: $_poolSize)',
      );
    } catch (e) {
      debugPrint('⚠️ SoundService init error: $e');
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

  /// Obtém próximo player do pool (round-robin)
  AudioPlayer _getPoolPlayer() {
    final player = _playerPool[_currentPoolIndex];
    _currentPoolIndex = (_currentPoolIndex + 1) % _poolSize;
    return player;
  }

  /// Toca um som pelo key
  Future<void> _play(String key, {double volume = 0.5}) async {
    if (!_soundEnabled || !_initialized) return;

    final path = _uiSounds[key];
    if (path == null) return;

    try {
      final player = _getPoolPlayer();
      await player.stop(); // Para som anterior se existir
      await player.setVolume(volume * _volume);
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('Sound play error ($key): $e');
    }
  }

  // ==========================================
  // SONS DE INTERFACE (UI)
  // ==========================================

  Future<void> playButtonClick() async {
    await _play('button_click', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playTapSoft() async {
    await _play('tap_soft', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  Future<void> playEdit() async {
    await _play('edit_click', volume: 0.25);
    await HapticFeedback.lightImpact();
  }

  Future<void> playPageTransition() async {
    await _play('page_turn', volume: 0.3);
    await HapticFeedback.selectionClick();
  }

  Future<void> playSwipeClean() async {
    await _play('swipe_clean', volume: 0.25);
    await HapticFeedback.selectionClick();
  }

  Future<void> playNavigationSfx() async {
    await _play('navigation_sfx', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  Future<void> playSuccessChime() async {
    await _play('success_chime', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playErrorBeep() async {
    await _play('error_beep', volume: 0.35);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playAddItem() async {
    await _play('add_item', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  Future<void> playDeleteWhoosh() async {
    await _play('delete_whoosh', volume: 0.32);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playModalOpenSfx() async {
    await _play('modal_open', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playModalCloseSfx() async {
    await _play('modal_close', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  Future<void> playReminderDing() async {
    await _play('reminder_ding', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playAlertPing() async {
    await _play('alert_ping', volume: 0.42);
    await HapticFeedback.mediumImpact();
  }

  // LEGACY
  Future<void> playTap() async {
    await _play('click', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  Future<void> playButton() async {
    await _play('button', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playNavigation() async {
    await _play('click', volume: 0.25);
    await HapticFeedback.selectionClick();
  }

  Future<void> playSwipe() async {
    await _play('click', volume: 0.2);
    await HapticFeedback.selectionClick();
  }

  Future<void> playModalOpen() async {
    await _play('scroll_open', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  Future<void> playModalClose() async {
    await _play('scroll_close', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  // ==========================================
  // SONS DE AÇÕES/TAREFAS
  // ==========================================

  Future<void> playSuccess() async {
    await _play('success', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playComplete() async {
    await _play('success', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playTaskComplete() async {
    await _play('task_complete', volume: 0.48);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playAdd() async {
    await _play('button', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playDelete() async {
    await _play('fail', volume: 0.35);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playError() async {
    await _play('fail', volume: 0.4);
    await HapticFeedback.heavyImpact();
  }

  // ==========================================
  // SONS DE GAMIFICAÇÃO
  // ==========================================

  Future<void> playXPGain() async {
    await _play('xp', volume: 0.4);
    await HapticFeedback.lightImpact();
  }

  Future<void> playCoin() async {
    await _play('coin', volume: 0.4);
    await HapticFeedback.lightImpact();
  }

  Future<void> playTrophy() async {
    await _play('trophy', volume: 0.5);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playLevelUp() async {
    await _play('levelup', volume: 0.55);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playAchievement() async {
    await _play('reminder_ding', volume: 0.55);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playHappy() async {
    await _play('happy_bop', volume: 0.4);
    await HapticFeedback.lightImpact();
  }

  Future<void> playBonus() async {
    await _play('success_chime', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playChestOpen() async {
    await _play('modal_open', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playCongrats() async {
    await _play('happy_bop', volume: 0.5);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playProgress() async {
    await _play('xp', volume: 0.3);
  }

  // ==========================================
  // SONS DE TIMER/POMODORO
  // ==========================================

  Future<void> playTimerStart() async {
    await _play('ready', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playTimerEnd() async {
    await _play('timer_end', volume: 0.6);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playTimerStop() async {
    await _play('timer_stop', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playTimerDing() async {
    await _play('notification', volume: 0.4);
    await HapticFeedback.lightImpact();
  }

  Future<void> playNotification() async {
    await _play('reminder_general', volume: 0.5);
    await HapticFeedback.selectionClick();
  }

  // ==========================================
  // SONS DE HÁBITOS/HUMOR
  // ==========================================

  Future<void> playMoodSelect() async {
    await _play('mood_warm', volume: 0.4);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playMoodHappy() async {
    await _play('mood_happy', volume: 0.42);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playMoodTap() async {
    await _play('mood_tap', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playHabitComplete() async {
    await _play('habit_complete', volume: 0.5);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playStreak() async {
    await _play('success_chime', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playShort(String key, {double volume = 0.4}) async {
    await _play(key, volume: volume);
    await HapticFeedback.lightImpact();
  }

  // ==========================================
  // SONS SND
  // ==========================================

  Future<void> playSndTap() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_tap_0$variation', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  Future<void> playSndButton() async {
    await _play('snd_button', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSndSelect() async {
    await _play('snd_select', volume: 0.32);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSndDisabled() async {
    await _play('snd_disabled', volume: 0.3);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSndToggleOn() async {
    await _play('snd_toggle_on', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playSndToggleOff() async {
    await _play('snd_toggle_off', volume: 0.35);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playSndTransitionUp() async {
    await _play('snd_transition_up', volume: 0.35);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSndTransitionDown() async {
    await _play('snd_transition_down', volume: 0.32);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSndSwipe() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_swipe_0$variation', volume: 0.28);
    await HapticFeedback.selectionClick();
  }

  Future<void> playSndType() async {
    final variation = 1 + (DateTime.now().millisecond % 5);
    await _play('snd_type_0$variation', volume: 0.25);
  }

  Future<void> playSndNotification() async {
    await _play('snd_notification', volume: 0.45);
    await HapticFeedback.mediumImpact();
  }

  Future<void> playSndCaution() async {
    await _play('snd_caution', volume: 0.42);
    await HapticFeedback.heavyImpact();
  }

  Future<void> playSndCelebration() async {
    await _play('snd_celebration', volume: 0.6);
    await HapticFeedback.heavyImpact();
  }

  // ==========================================
  // SONS AMBIENTE (LOOPS)
  // ==========================================

  Future<void> playAmbientSound(String key, {double? volume}) async {
    if (!_soundEnabled || !_initialized) return;
    if (key == 'none') {
      await stopAmbientSound();
      return;
    }

    final info = ambientSoundsLibrary[key];
    if (info == null || info.source.isEmpty) return;

    try {
      await stopAmbientSound();

      _ambientPlayer = AudioPlayer();
      await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer!.setVolume((volume ?? _ambientVolume));
      await _ambientPlayer!.play(AssetSource(info.source));
      _currentAmbientKey = key;

      debugPrint('🎵 Playing ambient: $key');
    } catch (e) {
      debugPrint('Error playing ambient sound: $e');
    }
  }

  Future<void> stopAmbientSound() async {
    if (_ambientPlayer != null) {
      await _ambientPlayer!.stop();
      await _ambientPlayer!.dispose();
      _ambientPlayer = null;
      _currentAmbientKey = null;
    }
  }

  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    if (_ambientPlayer != null) {
      await _ambientPlayer!.setVolume(_ambientVolume);
    }
    await _saveSettings();
  }

  /// Alias para playAmbientSound
  Future<void> startAmbientSound(String key, {double? volume}) async {
    await playAmbientSound(key, volume: volume);
  }

  /// Para todos os sons de timer
  void stopTimerSounds() {
    stopTickSound();
    stopAmbientSound();
  }

  /// Define volume do tick
  void setTickVolume(double volume) {
    _tickVolume = volume.clamp(0.0, 1.0);
    _saveSettings();
  }

  // ==========================================
  // TICK SOUND (TIMER)
  // ==========================================

  void startTickSound({String? type, double? volume, int intervalMs = 1000}) {
    if (!_soundEnabled || !_initialized) return;

    stopTickSound();

    _tickType = type ?? _tickType;
    _tickVolume = volume ?? _tickVolume;
    _isTickingEnabled = true;

    _tickTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _playTick();
    });

    _saveSettings();
  }

  void stopTickSound() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _isTickingEnabled = false;
    _saveSettings();
  }

  Future<void> _playTick() async {
    if (!_soundEnabled || !_initialized) return;

    final key = _tickType == 'soft_tick' ? 'tick_soft' : 'tick_clock';
    await _play(key, volume: _tickVolume);
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  Future<void> dispose() async {
    stopTickSound();
    await stopAmbientSound();

    for (final player in _playerPool) {
      await player.dispose();
    }
    _playerPool.clear();

    _initialized = false;
  }
}

/// Informações de som ambiente
class AmbientSoundInfo {
  final String name;
  final String description;
  final String source;
  final String category;

  const AmbientSoundInfo({
    required this.name,
    required this.description,
    required this.source,
    required this.category,
  });

  /// Se é som local (sempre true para audioplayers)
  bool get isLocal => true;
}

/// Singleton global
final soundService = SoundService();
