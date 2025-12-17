import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Mixin para facilitar uso de SFX em widgets StatefulWidget
/// 
/// Uso:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   _MyScreenState createState() => _MyScreenState();
/// }
/// 
/// class _MyScreenState extends State<MyScreen> with SfxMixin {
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: withSound(() => doSomething()),
///       child: Text(AppLocalizations.of(context)!.botao),
///     );
///   }
/// }
/// ```
mixin SfxMixin<T extends StatefulWidget> on State<T> {
  final SoundService _sfx = soundService;

  // === CLICKS ===
  
  /// Som de tap genérico
  void playTap() => _sfx.playTap();
  
  /// Som de botão (Octave)
  void playButtonClick() => _sfx.playButtonClick();
  
  /// Som de tap suave (Octave)
  void playTapSoft() => _sfx.playTapSoft();
  
  /// Som de edição (Octave)
  void playEdit() => _sfx.playEdit();

  // === FEEDBACK ===
  
  /// Som de sucesso
  void playSuccess() => _sfx.playSuccess();
  
  /// Som de sucesso chime (Octave)
  void playSuccessChime() => _sfx.playSuccessChime();
  
  /// Som de erro
  void playError() => _sfx.playError();
  
  /// Som de erro beep (Octave)
  void playErrorBeep() => _sfx.playErrorBeep();
  
  /// Som de adicionar item (Octave)
  void playAddItem() => _sfx.playAddItem();
  
  /// Som de deletar (Octave)
  void playDelete() => _sfx.playDeleteWhoosh();

  // === NAVIGATION ===
  
  /// Som de navegação
  void playNavigation() => _sfx.playNavigation();
  
  /// Som de navegação (Octave)
  void playNavigationSfx() => _sfx.playNavigationSfx();
  
  /// Som de transição de página (Octave)
  void playPageTransition() => _sfx.playPageTransition();
  
  /// Som de swipe (Octave)
  void playSwipeClean() => _sfx.playSwipeClean();

  // === POPUPS ===
  
  /// Som de modal abrindo (Octave)
  void playModalOpen() => _sfx.playModalOpenSfx();
  
  /// Som de modal fechando (Octave)
  void playModalClose() => _sfx.playModalCloseSfx();

  // === NOTIFICATIONS ===
  
  /// Som de notificação
  void playNotification() => _sfx.playNotification();
  
  /// Som de lembrete (Octave)
  void playReminder() => _sfx.playReminderDing();
  
  /// Som de alerta (Octave)
  void playAlert() => _sfx.playAlertPing();

  // === MOOD (Carinhas) ===
  
  /// Som de mood selecionado (warmguitar - principal)
  void playMoodSelect() => _sfx.playMoodSelect();
  
  /// Som de mood feliz (plucked - alegre)
  void playMoodHappy() => _sfx.playMoodHappy();
  
  /// Som de mood tap (suave)
  void playMoodTap() => _sfx.playMoodTap();

  // === GAMIFICATION ===
  
  /// Som de XP ganho
  void playXP() => _sfx.playXPGain();
  
  /// Som de level up
  void playLevelUp() => _sfx.playLevelUp();
  
  /// Som de conquista
  void playAchievement() => _sfx.playAchievement();
  
  /// Som de tarefa completa
  void playComplete() => _sfx.playComplete();

  // === HELPERS ===
  
  /// Wrapper para adicionar som a qualquer callback
  /// 
  /// Exemplo:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: withSound(() => salvar()),
  ///   child: Text(AppLocalizations.of(context)!.save),
  /// )
  /// ```
  VoidCallback withSound(VoidCallback action, {SfxType sfx = SfxType.button}) {
    return () {
      _playSfxType(sfx);
      action();
    };
  }
  
  /// Wrapper assíncrono para adicionar som a qualquer callback
  VoidCallback withSoundAsync(Future<void> Function() action, {SfxType sfx = SfxType.button}) {
    return () async {
      _playSfxType(sfx);
      await action();
    };
  }
  
  void _playSfxType(SfxType sfx) {
    switch (sfx) {
      case SfxType.tap:
        playTap();
        break;
      case SfxType.button:
        playButtonClick();
        break;
      case SfxType.success:
        playSuccessChime();
        break;
      case SfxType.error:
        playErrorBeep();
        break;
      case SfxType.add:
        playAddItem();
        break;
      case SfxType.delete:
        playDelete();
        break;
      case SfxType.edit:
        playEdit();
        break;
      case SfxType.navigation:
        playNavigationSfx();
        break;
      case SfxType.modalOpen:
        playModalOpen();
        break;
      case SfxType.modalClose:
        playModalClose();
        break;
      case SfxType.notification:
        playNotification();
        break;
      case SfxType.none:
        break;
    }
  }
}

/// Tipos de SFX disponíveis
enum SfxType {
  none,
  tap,
  button,
  success,
  error,
  add,
  delete,
  edit,
  navigation,
  modalOpen,
  modalClose,
  notification,
}
