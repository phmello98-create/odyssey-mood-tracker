import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';

/// Dialog de confirmação para desmarcar uma atividade como concluída
class ConfirmUnmarkDialog extends StatelessWidget {
  final String activityName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmUnmarkDialog({
    super.key,
    required this.activityName,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Mostra o dialog e retorna true se confirmado, false se cancelado
  static Future<bool> show({
    required BuildContext context,
    required String activityName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmUnmarkDialog(
        activityName: activityName,
        onConfirm: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(ctx, true);
        },
        onCancel: () {
          Navigator.pop(ctx, false);
        },
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de alerta
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.undo_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            Text(
              'Quer mesmo desmarcar?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            Text(
              'A atividade "${_truncateName(activityName)}" será marcada como pendente novamente.',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 28),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    child: Text(AppLocalizations.of(context)!.no,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sim, desmarcar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncateName(String name) {
    return name.length > 30 ? '${name.substring(0, 27)}...' : name;
  }
}
