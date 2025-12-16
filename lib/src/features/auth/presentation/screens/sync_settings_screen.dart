// lib/src/features/auth/presentation/screens/sync_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/sync_providers.dart';
import '../../services/cloud_storage_service.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Tela de configurações de sincronização
/// 
/// Permite ao usuário:
/// - Escolher quais dados sincronizar
/// - Ver uso de storage na nuvem
/// - Forçar sincronização
/// - Limpar dados da nuvem
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  bool _isLoadingStorage = true;
  StorageUsageInfo? _storageInfo;
  bool _isSyncing = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final cloudStorage = ref.read(cloudStorageServiceProvider);
    if (cloudStorage == null) {
      setState(() => _isLoadingStorage = false);
      return;
    }

    try {
      final info = await cloudStorage.getStorageUsage();
      if (mounted) {
        setState(() {
          _storageInfo = info;
          _isLoadingStorage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStorage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final syncConfig = ref.watch(syncConfigProvider);
    final syncState = ref.watch(syncControllerProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final colors = Theme.of(context).colorScheme;

    if (user == null || user.isGuest) {
      return _buildGuestView(context, colors);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sincronizacao),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          _buildStatusCard(context, colors, syncState, pendingCount),
          
          const SizedBox(height: 24),

          // Storage Usage
          _buildStorageCard(context, colors),
          
          const SizedBox(height: 24),

          // Sync Categories
          _buildSyncCategoriesSection(context, colors, syncConfig),
          
          const SizedBox(height: 24),

          // Actions
          _buildActionsSection(context, colors),
          
          const SizedBox(height: 24),

          // Danger Zone
          _buildDangerZone(context, colors),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sincronizacao),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sincronização Desativada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Faça login com uma conta Google para sincronizar seus dados entre dispositivos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(AppLocalizations.of(context)!.voltar),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    ColorScheme colors,
    SyncState syncState,
    int pendingCount,
  ) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Conectado' : 'Offline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      syncState.lastSyncTime != null
                          ? 'Última sync: ${_formatDate(syncState.lastSyncTime!)}'
                          : 'Nenhuma sincronização ainda',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$pendingCount ${pendingCount == 1 ? 'alteração pendente' : 'alterações pendentes'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Uso do Storage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadStorageInfo,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingStorage)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_storageInfo != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storageInfo!.formattedSize,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        '${_storageInfo!.fileCount} arquivos',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              'Não foi possível carregar',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncCategoriesSection(
    BuildContext context,
    ColorScheme colors,
    SyncConfig config,
  ) {
    final configNotifier = ref.read(syncConfigProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Dados para Sincronizar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => configNotifier.enableAll(),
                child: Text(AppLocalizations.of(context)!.todos),
              ),
              TextButton(
                onPressed: () => configNotifier.disableAll(),
                child: Text(AppLocalizations.of(context)!.nenhum),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSyncToggle(
                icon: Icons.mood_rounded,
                title: 'Humores',
                subtitle: 'Registros de humor diários',
                value: config.moods,
                onChanged: (_) => configNotifier.toggleMoods(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.check_circle_rounded,
                title: 'Tarefas',
                subtitle: 'Lista de tarefas e to-dos',
                value: config.tasks,
                onChanged: (_) => configNotifier.toggleTasks(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.repeat_rounded,
                title: 'Hábitos',
                subtitle: 'Hábitos e streaks',
                value: config.habits,
                onChanged: (_) => configNotifier.toggleHabits(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.note_rounded,
                title: 'Notas',
                subtitle: 'Notas e anotações',
                value: config.notes,
                onChanged: (_) => configNotifier.toggleNotes(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.timer_rounded,
                title: 'Time Tracking',
                subtitle: 'Pomodoros e sessões de foco',
                value: config.timeTracking,
                onChanged: (_) => configNotifier.toggleTimeTracking(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.book_rounded,
                title: 'Biblioteca',
                subtitle: 'Livros e leituras',
                value: config.books,
                onChanged: (_) => configNotifier.toggleBooks(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.emoji_events_rounded,
                title: 'Gamificação',
                subtitle: 'XP, níveis e conquistas',
                value: config.gamification,
                onChanged: (_) => configNotifier.toggleGamification(),
                colors: colors,
              ),
              _buildDivider(colors),
              _buildSyncToggle(
                icon: Icons.format_quote_rounded,
                title: 'Citações',
                subtitle: 'Citações favoritas',
                value: config.quotes,
                onChanged: (_) => configNotifier.toggleQuotes(),
                colors: colors,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colors,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value 
              ? colors.primary.withValues(alpha: 0.1) 
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: value ? colors.primary : colors.onSurfaceVariant,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: colors.primary,
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Divider(
      height: 1,
      indent: 70,
      color: colors.outlineVariant.withValues(alpha: 0.3),
    );
  }

  Widget _buildActionsSection(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Ações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.cloud_upload_rounded,
                label: 'Enviar Tudo',
                isLoading: _isSyncing,
                onPressed: _syncAll,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.cloud_download_rounded,
                label: 'Baixar Tudo',
                isLoading: _isSyncing,
                onPressed: _downloadAll,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required ColorScheme colors,
  }) {
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                Icon(icon, color: colors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Zona de Perigo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.error.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: colors.error,
                size: 22,
              ),
            ),
            title: Text(
              'Limpar Dados da Nuvem',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              'Remove todos os seus dados do servidor',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: _isClearing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.error,
                    ),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
            onTap: _isClearing ? null : () => _showClearConfirmation(context, colors),
          ),
        ),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context, ColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.limparDadosDaNuvem),
        content: const Text(
          'Esta ação irá remover todos os seus dados sincronizados do servidor. '
          'Seus dados locais não serão afetados.\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancelar),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCloudData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            child: Text(AppLocalizations.of(context)!.limpar),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAll() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    try {
      await ref.read(syncControllerProvider.notifier).syncAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dadosEnviadosComSucesso),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _downloadAll() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSyncing = true);

    try {
      await ref.read(syncControllerProvider.notifier).downloadAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dadosBaixadosComSucesso),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _clearCloudData() async {
    HapticFeedback.heavyImpact();
    setState(() => _isClearing = true);

    try {
      final syncService = ref.read(syncServiceProvider);
      if (syncService != null) {
        await syncService.clearCloudData();
      }
      
      final cloudStorage = ref.read(cloudStorageServiceProvider);
      if (cloudStorage != null) {
        await cloudStorage.deleteAllUserFiles();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dadosDaNuvemRemovidos),
            backgroundColor: Colors.green,
          ),
        );
        _loadStorageInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year}';
  }
}
