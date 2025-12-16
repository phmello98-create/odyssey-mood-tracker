import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Helpers para exibir dialogs e modais com sons automáticos
/// 
/// Uso:
/// ```dart
/// final result = await showSoundDialog(
///   context: context,
///   dialog: AlertDialog(
///     title: Text(AppLocalizations.of(context)!.confirm),
///     content: Text(AppLocalizations.of(context)!.desejaContinuar),
///     actions: [
///       TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.no)),
///       TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.yes)),
///     ],
///   ),
/// );
/// ```

/// Exibe um dialog com sons de abertura e fechamento automáticos
Future<T?> showSoundDialog<T>({
  required BuildContext context,
  required Widget dialog,
  bool barrierDismissible = true,
  bool playSoundOnOpen = true,
  bool playSoundOnClose = true,
}) async {
  if (playSoundOnOpen) {
    soundService.playModalOpenSfx();
  }

  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => dialog,
  );

  if (playSoundOnClose) {
    soundService.playModalCloseSfx();
  }

  return result;
}

/// Exibe um BottomSheet com sons automáticos
Future<T?> showSoundBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  bool playSoundOnOpen = true,
  bool playSoundOnClose = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
}) async {
  if (playSoundOnOpen) {
    soundService.playModalOpenSfx();
  }

  final result = await showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
  );

  if (playSoundOnClose) {
    soundService.playModalCloseSfx();
  }

  return result;
}

/// Exibe um SnackBar com som de notificação opcional
void showSoundSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  bool playSound = true,
  bool isError = false,
}) {
  if (playSound) {
    if (isError) {
      soundService.playErrorBeep();
    } else {
      soundService.playAlertPing();
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
    ),
  );
}

/// Exibe um dialog de confirmação com sons
Future<bool> showSoundConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  bool isDangerous = false,
}) async {
  soundService.playModalOpenSfx();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            soundService.playTapSoft();
            Navigator.pop(context, false);
          },
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            if (isDangerous) {
              soundService.playDeleteWhoosh();
            } else {
              soundService.playSuccessChime();
            }
            Navigator.pop(context, true);
          },
          style: isDangerous
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );

  soundService.playModalCloseSfx();
  return result ?? false;
}

/// Exibe um dialog de erro
Future<void> showSoundErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
}) async {
  soundService.playErrorBeep();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            soundService.playTapSoft();
            Navigator.pop(context);
          },
          child: Text(buttonText),
        ),
      ],
    ),
  );

  soundService.playModalCloseSfx();
}

/// Exibe um dialog de sucesso
Future<void> showSoundSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
}) async {
  soundService.playSuccessChime();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            soundService.playTapSoft();
            Navigator.pop(context);
          },
          child: Text(buttonText),
        ),
      ],
    ),
  );

  soundService.playModalCloseSfx();
}
