// lib/src/features/auth/presentation/screens/account_migration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/migration_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/localization/app_localizations_x.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';

/// Tela de migração de dados para a nuvem
class AccountMigrationScreen extends ConsumerStatefulWidget {
  /// Se deve mostrar opção de pular
  final bool canSkip;
  
  /// Callback quando migração for concluída ou pulada
  final VoidCallback? onComplete;

  const AccountMigrationScreen({
    super.key,
    this.canSkip = true,
    this.onComplete,
  });

  @override
  ConsumerState<AccountMigrationScreen> createState() => _AccountMigrationScreenState();
}

class _AccountMigrationScreenState extends ConsumerState<AccountMigrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final migrationState = ref.watch(migrationControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Skip button
                          if (widget.canSkip && !migrationState.isInProgress)
                            Align(
                              alignment: Alignment.topRight,
                              child: TextButton(
                                onPressed: () => _handleSkip(context),
                                child: Text(
                                  l10n.isEnglish ? 'Skip' : 'Pular',
                                  style: TextStyle(color: colorScheme.outline),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 48),

                          const Spacer(),

                          // Icon animado
                          _buildAnimatedIcon(migrationState, colorScheme),

                          const SizedBox(height: 32),

                          // Título
                          Text(
                            _getTitle(migrationState, l10n),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Descrição
                          Text(
                            _getDescription(migrationState, l10n),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Progress ou botões
                          if (migrationState.isInProgress)
                            _buildProgressSection(migrationState, colorScheme)
                          else if (migrationState.isCompleted)
                            _buildCompletedSection(migrationState, colorScheme, l10n)
                          else if (migrationState.isFailed)
                            _buildFailedSection(migrationState, colorScheme, l10n)
                          else
                            _buildStartSection(colorScheme, l10n),

                          const Spacer(),

                          const SizedBox(height: 24),

                          // Info de segurança
                          if (!migrationState.isInProgress)
                            _buildSecurityInfo(colorScheme, l10n),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleSkip(BuildContext context) {
    HapticFeedback.lightImpact();
    widget.onComplete?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OdysseyHome(),
      ),
    );
  }

  Widget _buildAnimatedIcon(MigrationState state, ColorScheme colorScheme) {
    IconData icon;
    Color color;
    
    if (state.isInProgress) {
      icon = Icons.cloud_sync;
      color = colorScheme.primary;
    } else if (state.isCompleted) {
      icon = Icons.cloud_done;
      color = Colors.green;
    } else if (state.isFailed) {
      icon = Icons.cloud_off;
      color = colorScheme.error;
    } else {
      icon = Icons.cloud_upload_outlined;
      color = colorScheme.primary;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: state.isInProgress
          ? Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 4,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )
          : Icon(icon, size: 60, color: color),
    );
  }

  String _getTitle(MigrationState state, AppLocalizations l10n) {
    if (state.isInProgress) {
      return l10n.isEnglish ? 'Migrating Data...' : 'Migrando Dados...';
    } else if (state.isCompleted) {
      return l10n.isEnglish ? 'Migration Complete!' : 'Migração Concluída!';
    } else if (state.isFailed) {
      return l10n.isEnglish ? 'Migration Failed' : 'Falha na Migração';
    }
    return l10n.isEnglish ? 'Migrate to Cloud' : 'Migrar para Nuvem';
  }

  String _getDescription(MigrationState state, AppLocalizations l10n) {
    if (state.isInProgress) {
      return state.currentStep ?? 
          (l10n.isEnglish ? 'Please wait...' : 'Por favor, aguarde...');
    } else if (state.isCompleted) {
      final result = state.lastResult;
      if (result != null) {
        return l10n.isEnglish
            ? '${result.totalItemsMigrated} items migrated successfully in ${result.duration.inSeconds}s'
            : '${result.totalItemsMigrated} itens migrados com sucesso em ${result.duration.inSeconds}s';
      }
      return l10n.isEnglish 
          ? 'Your data is now safely stored in the cloud'
          : 'Seus dados agora estão seguros na nuvem';
    } else if (state.isFailed) {
      return state.errorMessage ?? 
          (l10n.isEnglish 
              ? 'An error occurred during migration'
              : 'Ocorreu um erro durante a migração');
    }
    return l10n.isEnglish
        ? 'Your local data will be securely uploaded to the cloud. This ensures your data is safe and accessible from any device.'
        : 'Seus dados locais serão enviados com segurança para a nuvem. Isso garante que seus dados estejam seguros e acessíveis de qualquer dispositivo.';
  }

  Widget _buildProgressSection(MigrationState state, ColorScheme colorScheme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.progress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.currentStep ?? '',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSection(
    MigrationState state,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        // Detalhes da migração
        if (state.lastResult != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                ...state.lastResult!.steps.map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            step.success ? Icons.check_circle : Icons.error,
                            size: 20,
                            color: step.success ? Colors.green : colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getStepLabel(step.step, l10n),
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                          Text(
                            '${step.itemsCount}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onComplete?.call();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              } else {
                _navigateToHome(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.isEnglish ? 'Continue' : 'Continuar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedSection(
    MigrationState state,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        // Mostra etapas que falharam
        if (state.lastResult != null && state.lastResult!.failedSteps.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.isEnglish ? 'Failed steps:' : 'Etapas com falha:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.lastResult!.failedSteps.map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error, size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_getStepLabel(step.step, l10n)}: ${step.errorMessage ?? 'Unknown error'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(false);
                  } else {
                    _navigateToHome(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.isEnglish ? 'Cancel' : 'Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(migrationControllerProvider.notifier).migrateToCloud();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.isEnglish ? 'Retry' : 'Tentar Novamente'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      children: [
        // Benefícios
        _buildBenefitItem(
          Icons.security,
          l10n.isEnglish ? 'Secure backup' : 'Backup seguro',
          l10n.isEnglish 
              ? 'Your data is encrypted and stored safely'
              : 'Seus dados são criptografados e armazenados com segurança',
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildBenefitItem(
          Icons.devices,
          l10n.isEnglish ? 'Access anywhere' : 'Acesse de qualquer lugar',
          l10n.isEnglish 
              ? 'Sync your data across all your devices'
              : 'Sincronize seus dados em todos os seus dispositivos',
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildBenefitItem(
          Icons.restore,
          l10n.isEnglish ? 'Easy restore' : 'Restauração fácil',
          l10n.isEnglish 
              ? 'Recover your data if you change devices'
              : 'Recupere seus dados se trocar de dispositivo',
          colorScheme,
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(migrationControllerProvider.notifier).migrateToCloud();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.isEnglish ? 'Start Migration' : 'Iniciar Migração',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.isEnglish
                  ? 'Your data is encrypted and protected'
                  : 'Seus dados são criptografados e protegidos',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(String step, AppLocalizations l10n) {
    switch (step) {
      case 'moods':
        return l10n.isEnglish ? 'Moods' : 'Humores';
      case 'tasks':
        return l10n.isEnglish ? 'Tasks' : 'Tarefas';
      case 'habits':
        return l10n.isEnglish ? 'Habits' : 'Hábitos';
      case 'notes':
        return l10n.isEnglish ? 'Notes' : 'Notas';
      case 'quotes':
        return l10n.isEnglish ? 'Quotes' : 'Citações';
      default:
        return step;
    }
  }
}
