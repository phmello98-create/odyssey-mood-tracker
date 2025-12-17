// lib/src/features/auth/presentation/widgets/migration_progress_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/migration_providers.dart';
import '../../services/migration_service.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Widget que mostra o progresso detalhado da migração
class MigrationProgressWidget extends ConsumerWidget {
  const MigrationProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(migrationControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Barra de progresso animada
        _buildProgressBar(context, colors, state),
        
        const SizedBox(height: 24),

        // Etapas de migração
        _buildStepsList(context, colors, state),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ColorScheme colors,
    MigrationState state,
  ) {
    return Column(
      children: [
        // Porcentagem
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: state.progress * 100),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Text(
              '${value.toInt()}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Barra de progresso
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  state.isFailed ? colors.error : colors.primary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        
        // Status atual
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            state.currentStep ?? 'Preparando...',
            key: ValueKey(state.currentStep),
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList(
    BuildContext context,
    ColorScheme colors,
    MigrationState state,
  ) {
    final steps = _getStepsFromState(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _buildStepIcon(step, colors),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.label,
                    style: TextStyle(
                      color: step.isActive
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontWeight:
                          step.isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (step.count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${step.count}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: step.isCompleted
                            ? Colors.green
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepIcon(_MigrationStep step, ColorScheme colors) {
    if (step.isActive) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primary,
        ),
      );
    }

    if (step.isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: step.hasError ? colors.error : Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          step.hasError ? Icons.close : Icons.check,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.outlineVariant,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  List<_MigrationStep> _getStepsFromState(MigrationState state) {
    final result = state.lastResult;
    final currentStep = state.currentStep?.toLowerCase() ?? '';

    // Definir todas as etapas possíveis
    final allSteps = [
      'moods',
      'tasks',
      'habits',
      'notes',
      'quotes',
      'gamification',
      'timeTracking',
      'books',
    ];

    final stepLabels = {
      'moods': 'Humores',
      'tasks': 'Tarefas',
      'habits': 'Hábitos',
      'notes': 'Notas',
      'quotes': 'Citações',
      'gamification': 'Gamificação',
      'timeTracking': 'Time Tracking',
      'books': 'Biblioteca',
    };

    return allSteps.map((stepId) {
      final label = stepLabels[stepId] ?? stepId;
      final isActive = currentStep.contains(stepId.toLowerCase());
      
      // Verificar se já foi completado
      MigrationStepResult? stepResult;
      if (result != null) {
        stepResult = result.steps.where((s) => s.step == stepId).firstOrNull;
      }

      final isCompleted = stepResult != null;
      final hasError = stepResult?.success == false;
      final count = stepResult?.itemsCount;

      return _MigrationStep(
        id: stepId,
        label: label,
        isActive: isActive,
        isCompleted: isCompleted,
        hasError: hasError,
        count: count,
      );
    }).toList();
  }
}

class _MigrationStep {
  final String id;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool hasError;
  final int? count;

  const _MigrationStep({
    required this.id,
    required this.label,
    this.isActive = false,
    this.isCompleted = false,
    this.hasError = false,
    this.count,
  });
}

/// Widget compacto para mostrar status de migração inline
class MigrationStatusBadge extends ConsumerWidget {
  const MigrationStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(migrationControllerProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.status == MigrationStatus.notStarted) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String text;

    switch (state.status) {
      case MigrationStatus.inProgress:
        icon = Icons.sync;
        color = colors.primary;
        text = 'Migrando...';
        break;
      case MigrationStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Migrado';
        break;
      case MigrationStatus.failed:
        icon = Icons.error;
        color = colors.error;
        text = 'Falha';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isInProgress)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading overlay para operações de sync/migração
class SyncLoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;
  final VoidCallback? onCancel;

  const SyncLoadingOverlay({
    super.key,
    required this.message,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de progresso
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress != null)
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        color: colors.primary,
                        backgroundColor: colors.surfaceContainerHighest,
                      )
                    else
                      CircularProgressIndicator(
                        strokeWidth: 4,
                        color: colors.primary,
                      ),
                    if (progress != null)
                      Text(
                        '${(progress! * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mensagem
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Por favor, não feche o aplicativo',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),

              // Botão cancelar (opcional)
              if (onCancel != null) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onCancel,
                  child: Text(AppLocalizations.of(context)!.cancelar),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
