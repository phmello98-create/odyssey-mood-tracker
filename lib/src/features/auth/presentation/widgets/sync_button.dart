// lib/src/features/auth/presentation/widgets/sync_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Botão de sincronização que mostra o estado atual e permite iniciar sync
class SyncButton extends ConsumerWidget {
  /// Estilo do botão
  final SyncButtonStyle style;
  
  /// Callback após sync completo
  final VoidCallback? onSyncComplete;
  
  /// Se deve mostrar texto
  final bool showLabel;

  const SyncButton({
    super.key,
    this.style = SyncButtonStyle.iconButton,
    this.onSyncComplete,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final isAvailable = ref.watch(isSyncAvailableProvider);
    final theme = Theme.of(context);

    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    switch (style) {
      case SyncButtonStyle.iconButton:
        return _buildIconButton(context, ref, syncState, theme);
      case SyncButtonStyle.elevated:
        return _buildElevatedButton(context, ref, syncState, theme);
      case SyncButtonStyle.outlined:
        return _buildOutlinedButton(context, ref, syncState, theme);
      case SyncButtonStyle.text:
        return _buildTextButton(context, ref, syncState, theme);
      case SyncButtonStyle.listTile:
        return _buildListTile(context, ref, syncState, theme);
    }
  }

  Widget _buildIconButton(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ThemeData theme,
  ) {
    return IconButton(
      onPressed: syncState.isSyncing ? null : () => _onSync(ref),
      icon: syncState.isSyncing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.sync,
              color: syncState.errorMessage != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
      tooltip: _getTooltip(syncState),
    );
  }

  Widget _buildElevatedButton(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ThemeData theme,
  ) {
    return ElevatedButton.icon(
      onPressed: syncState.isSyncing ? null : () => _onSync(ref),
      icon: syncState.isSyncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.sync),
      label: Text(showLabel ? _getButtonLabel(syncState) : ''),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ThemeData theme,
  ) {
    return OutlinedButton.icon(
      onPressed: syncState.isSyncing ? null : () => _onSync(ref),
      icon: syncState.isSyncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : const Icon(Icons.sync),
      label: Text(showLabel ? _getButtonLabel(syncState) : ''),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ThemeData theme,
  ) {
    return TextButton.icon(
      onPressed: syncState.isSyncing ? null : () => _onSync(ref),
      icon: syncState.isSyncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : const Icon(Icons.sync),
      label: Text(showLabel ? _getButtonLabel(syncState) : ''),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    ThemeData theme,
  ) {
    return ListTile(
      leading: syncState.isSyncing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.sync,
              color: syncState.errorMessage != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
      title: Text(_getButtonLabel(syncState)),
      subtitle: syncState.lastSyncTime != null
          ? Text(_formatLastSync(syncState.lastSyncTime!))
          : syncState.errorMessage != null
              ? Text(
                  syncState.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                )
              : Text(AppLocalizations.of(context)!.nuncaSincronizado),
      trailing: syncState.isSyncing
          ? null
          : const Icon(Icons.chevron_right),
      onTap: syncState.isSyncing ? null : () => _onSync(ref),
    );
  }

  void _onSync(WidgetRef ref) async {
    await ref.read(syncControllerProvider.notifier).syncAll();
    onSyncComplete?.call();
  }

  String _getButtonLabel(SyncState state) {
    if (state.isSyncing) {
      return state.currentOperation ?? 'Sincronizando...';
    }
    return 'Sincronizar';
  }

  String _getTooltip(SyncState state) {
    if (state.isSyncing) {
      return state.currentOperation ?? 'Sincronizando...';
    }
    if (state.errorMessage != null) {
      return 'Erro: ${state.errorMessage}';
    }
    if (state.lastSyncTime != null) {
      return 'Última sync: ${_formatLastSync(state.lastSyncTime!)}';
    }
    return 'Sincronizar dados';
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours}h';
    } else {
      return 'Há ${diff.inDays} dias';
    }
  }
}

/// Estilos disponíveis para o SyncButton
enum SyncButtonStyle {
  iconButton,
  elevated,
  outlined,
  text,
  listTile,
}

/// Card de sincronização com informações detalhadas
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final isAvailable = ref.watch(isSyncAvailableProvider);
    final theme = Theme.of(context);

    if (!isAvailable) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: theme.colorScheme.outline),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sincronização indisponível',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Faça login para sincronizar seus dados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  syncState.isSyncing
                      ? Icons.sync
                      : syncState.allSuccessful
                          ? Icons.cloud_done
                          : Icons.cloud_sync,
                  color: syncState.errorMessage != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncState.isSyncing
                            ? syncState.currentOperation ?? 'Sincronizando...'
                            : 'Sincronização',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (syncState.lastSyncTime != null)
                        Text(
                          'Última sync: ${_formatLastSync(syncState.lastSyncTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!syncState.isSyncing)
                  IconButton(
                    onPressed: () {
                      ref.read(syncControllerProvider.notifier).syncAll();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            if (syncState.isSyncing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
            if (syncState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncState.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(syncControllerProvider.notifier).clearError();
                      },
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (syncState.lastResults != null && !syncState.isSyncing) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Último resultado:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ...syncState.lastResults!.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          e.value.success
                              ? Icons.check_circle
                              : Icons.error,
                          size: 16,
                          color: e.value.success
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_categoryLabel(e.key)}: ${e.value.itemsSynced} itens',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours} horas';
    } else {
      return 'Há ${diff.inDays} dias';
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'moods':
        return 'Humores';
      case 'tasks':
        return 'Tarefas';
      case 'habits':
        return 'Hábitos';
      case 'notes':
        return 'Notas';
      case 'quotes':
        return 'Citações';
      default:
        return category;
    }
  }
}
