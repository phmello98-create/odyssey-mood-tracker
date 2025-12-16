import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/mixins/sfx_mixin.dart';

/// Botão com som embutido - reproduz SFX automaticamente ao pressionar
/// 
/// Uso:
/// ```dart
/// SoundButton(
///   onPressed: () => salvarTarefa(),
///   sfxType: SfxType.success,
///   child: Text(AppLocalizations.of(context)!.save),
/// )
/// ```
class SoundButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final SfxType sfxType;
  final ButtonStyle? style;

  const SoundButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.sfxType = SfxType.button,
    this.style,
  }) : super(key: key);

  void _playSound() {
    switch (sfxType) {
      case SfxType.tap:
        soundService.playTap();
        break;
      case SfxType.button:
        soundService.playButtonClick();
        break;
      case SfxType.success:
        soundService.playSuccessChime();
        break;
      case SfxType.error:
        soundService.playErrorBeep();
        break;
      case SfxType.add:
        soundService.playAddItem();
        break;
      case SfxType.delete:
        soundService.playDeleteWhoosh();
        break;
      case SfxType.edit:
        soundService.playEdit();
        break;
      case SfxType.navigation:
        soundService.playNavigationSfx();
        break;
      case SfxType.modalOpen:
        soundService.playModalOpenSfx();
        break;
      case SfxType.modalClose:
        soundService.playModalCloseSfx();
        break;
      case SfxType.notification:
        soundService.playNotification();
        break;
      case SfxType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              _playSound();
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}

/// TextButton com som embutido
class SoundTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final SfxType sfxType;
  final ButtonStyle? style;

  const SoundTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.sfxType = SfxType.tap,
    this.style,
  }) : super(key: key);

  void _playSound() {
    switch (sfxType) {
      case SfxType.tap:
        soundService.playTapSoft();
        break;
      case SfxType.button:
        soundService.playButtonClick();
        break;
      case SfxType.success:
        soundService.playSuccessChime();
        break;
      case SfxType.error:
        soundService.playErrorBeep();
        break;
      default:
        soundService.playTapSoft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              _playSound();
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}

/// IconButton com som embutido
/// 
/// Uso:
/// ```dart
/// SoundIconButton(
///   onPressed: () => deletarItem(),
///   icon: Icon(Icons.delete),
///   sfxType: SfxType.delete,
/// )
/// ```
class SoundIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final SfxType sfxType;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const SoundIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.sfxType = SfxType.tap,
    this.iconSize,
    this.color,
    this.tooltip,
    this.padding,
  }) : super(key: key);

  void _playSound() {
    switch (sfxType) {
      case SfxType.tap:
        soundService.playTapSoft();
        break;
      case SfxType.button:
        soundService.playButtonClick();
        break;
      case SfxType.delete:
        soundService.playDeleteWhoosh();
        break;
      case SfxType.edit:
        soundService.playEdit();
        break;
      case SfxType.add:
        soundService.playAddItem();
        break;
      case SfxType.navigation:
        soundService.playNavigationSfx();
        break;
      default:
        soundService.playTapSoft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null
          ? null
          : () {
              _playSound();
              onPressed!();
            },
      icon: icon,
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
      padding: padding,
    );
  }
}

/// FloatingActionButton com som embutido
class SoundFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final SfxType sfxType;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool mini;
  final Object? heroTag;

  const SoundFAB({
    Key? key,
    required this.onPressed,
    required this.child,
    this.sfxType = SfxType.add,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.mini = false,
    this.heroTag,
  }) : super(key: key);

  void _playSound() {
    switch (sfxType) {
      case SfxType.add:
        soundService.playAddItem();
        break;
      case SfxType.button:
        soundService.playButtonClick();
        break;
      case SfxType.success:
        soundService.playSuccessChime();
        break;
      default:
        soundService.playButtonClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed == null
          ? null
          : () {
              _playSound();
              onPressed!();
            },
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      mini: mini,
      heroTag: heroTag,
      child: child,
    );
  }
}

/// Checkbox com som embutido
class SoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final bool tristate;

  const SoundCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
    this.tristate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              // Toca som de sucesso se marcando, tap se desmarcando
              if (newValue == true) {
                soundService.playSuccessChime();
              } else {
                soundService.playTapSoft();
              }
              onChanged!(newValue);
            },
      activeColor: activeColor,
      checkColor: checkColor,
      tristate: tristate,
    );
  }
}

/// Switch com som embutido
class SoundSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;

  const SoundSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              soundService.playTapSoft();
              onChanged!(newValue);
            },
      activeThumbColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );
  }
}
