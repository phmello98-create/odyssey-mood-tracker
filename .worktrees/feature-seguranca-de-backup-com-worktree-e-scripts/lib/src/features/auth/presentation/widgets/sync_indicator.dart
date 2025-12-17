import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/sync_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Status de sincronização para UI
/// 
/// Diferente do SyncStatus em auth_result.dart, este é específico para
/// estados de UI do indicador de sincronização.
enum UISyncStatus {
  /// Sincronização desativada (usuário guest ou preferência)
  disabled,
  /// Sem conexão com internet
  offline,
  /// Pronto para sincronizar
  idle,
  /// Tem operações pendentes
  pending,
  /// Sincronizando
  syncing,
  /// Sincronização concluída com sucesso
  success,
  /// Erro na sincronização
  error,
}

/// Provider para gerenciar o status de sincronização
final syncStatusProvider = Provider<UISyncStatus>((ref) {
  final user = ref.watch(currentUserProvider);
  
  // Se não tem usuário ou é guest, sync está desativado
  if (user == null || user.isGuest || !user.syncEnabled) {
    return UISyncStatus.disabled;
  }
  
  // Verificar status da fila offline
  final queueStatus = ref.watch(offlineSyncStatusProvider);
  
  return queueStatus.when(
    data: (status) {
      if (!status.isOnline) return UISyncStatus.offline;
      if (status.isSyncing) return UISyncStatus.syncing;
      if (status.hasPending) return UISyncStatus.pending;
      return UISyncStatus.idle;
    },
    loading: () => UISyncStatus.idle,
    error: (_, __) => UISyncStatus.error,
  );
});

/// Provider para última vez que sincronizou
final lastSyncProvider = StateProvider<DateTime?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.lastSyncAt;
});

/// Indicador visual de sincronização
/// 
/// Mostra o status atual da sincronização de dados com o servidor.
/// Pode ser usado na AppBar ou em qualquer lugar do app.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({
    super.key,
    this.size = 20,
    this.showLabel = false,
    this.compact = false,
  });

  /// Tamanho do ícone
  final double size;

  /// Se deve mostrar label de texto
  final bool showLabel;

  /// Modo compacto (apenas ícone)
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncProvider);
    final colors = Theme.of(context).colorScheme;

    // Não mostrar nada se sync está desativado
    if (syncStatus == UISyncStatus.disabled) {
      return const SizedBox.shrink();
    }

    final icon = _getIcon(syncStatus);
    final color = _getColor(syncStatus, colors);
    final label = _getLabel(syncStatus);

    if (compact) {
      return _buildCompact(icon, color, syncStatus);
    }

    return InkWell(
      onTap: () => _showSyncDetails(context, syncStatus, lastSync),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(icon, color, size, syncStatus),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(IconData icon, Color color, UISyncStatus status) {
    return _buildIcon(icon, color, size, status);
  }

  Widget _buildIcon(IconData icon, Color color, double size, UISyncStatus status) {
    if (status == UISyncStatus.syncing) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }

  IconData _getIcon(UISyncStatus status) {
    switch (status) {
      case UISyncStatus.disabled:
        return Icons.cloud_off_rounded;
      case UISyncStatus.offline:
        return Icons.wifi_off_rounded;
      case UISyncStatus.idle:
        return Icons.cloud_done_rounded;
      case UISyncStatus.pending:
        return Icons.cloud_upload_rounded;
      case UISyncStatus.syncing:
        return Icons.sync_rounded;
      case UISyncStatus.success:
        return Icons.cloud_done_rounded;
      case UISyncStatus.error:
        return Icons.cloud_off_rounded;
    }
  }

  Color _getColor(UISyncStatus status, ColorScheme colors) {
    switch (status) {
      case UISyncStatus.disabled:
        return colors.onSurfaceVariant.withValues(alpha: 0.5);
      case UISyncStatus.offline:
        return colors.onSurfaceVariant;
      case UISyncStatus.idle:
        return colors.primary;
      case UISyncStatus.pending:
        return Colors.orange;
      case UISyncStatus.syncing:
        return colors.primary;
      case UISyncStatus.success:
        return const Color(0xFF07E092); // Verde
      case UISyncStatus.error:
        return colors.error;
    }
  }

  String _getLabel(UISyncStatus status) {
    switch (status) {
      case UISyncStatus.disabled:
        return 'Desativado';
      case UISyncStatus.offline:
        return 'Sem internet';
      case UISyncStatus.idle:
        return 'Sincronizado';
      case UISyncStatus.pending:
        return 'Pendente';
      case UISyncStatus.syncing:
        return 'Sincronizando...';
      case UISyncStatus.success:
        return 'Atualizado';
      case UISyncStatus.error:
        return 'Erro';
    }
  }

  void _showSyncDetails(
    BuildContext context,
    UISyncStatus status,
    DateTime? lastSync,
  ) {
    final colors = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Ícone grande
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getColor(status, colors).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIcon(status),
                size: 32,
                color: _getColor(status, colors),
              ),
            ),
            const SizedBox(height: 16),
            
            // Status
            Text(
              _getStatusTitle(status),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              _getStatusDescription(status, lastSync),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Botões
            if (status == UISyncStatus.error || status == UISyncStatus.idle)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementar sincronização manual
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(AppLocalizations.of(context)!.sincronizarAgora),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getStatusTitle(UISyncStatus status) {
    switch (status) {
      case UISyncStatus.disabled:
        return 'Sincronização Desativada';
      case UISyncStatus.offline:
        return 'Sem Conexão';
      case UISyncStatus.idle:
        return 'Dados Sincronizados';
      case UISyncStatus.pending:
        return 'Sincronização Pendente';
      case UISyncStatus.syncing:
        return 'Sincronizando...';
      case UISyncStatus.success:
        return 'Sincronização Concluída';
      case UISyncStatus.error:
        return 'Erro na Sincronização';
    }
  }

  String _getStatusDescription(UISyncStatus status, DateTime? lastSync) {
    switch (status) {
      case UISyncStatus.disabled:
        return 'Faça login com uma conta para sincronizar seus dados entre dispositivos.';
      case UISyncStatus.offline:
        return 'Suas alterações serão sincronizadas automaticamente quando você voltar online.';
      case UISyncStatus.idle:
        return lastSync != null 
            ? 'Última sincronização: ${_formatDate(lastSync)}'
            : 'Seus dados estão salvos na nuvem.';
      case UISyncStatus.pending:
        return 'Há alterações aguardando sincronização. Elas serão enviadas automaticamente.';
      case UISyncStatus.syncing:
        return 'Aguarde enquanto seus dados são sincronizados...';
      case UISyncStatus.success:
        return 'Todos os seus dados foram sincronizados com sucesso!';
      case UISyncStatus.error:
        return 'Não foi possível sincronizar seus dados. Verifique sua conexão e tente novamente.';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'agora mesmo';
    } else if (diff.inMinutes < 60) {
      return 'há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'há ${diff.inHours}h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Badge para indicar tipo de conta
class AccountTypeBadge extends ConsumerWidget {
  const AccountTypeBadge({
    super.key,
    this.showIfFree = false,
  });

  /// Se deve mostrar badge mesmo para conta gratuita
  final bool showIfFree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colors = Theme.of(context).colorScheme;

    if (user == null) return const SizedBox.shrink();

    // Guest
    if (user.isGuest) {
      return _buildBadge(
        label: 'Visitante',
        color: colors.onSurfaceVariant,
        icon: Icons.person_outline_rounded,
      );
    }

    // PRO
    if (user.hasValidProAccess) {
      return _buildBadge(
        label: 'PRO',
        color: const Color(0xFFFFD700),
        icon: Icons.workspace_premium_rounded,
        isPro: true,
      );
    }

    // Free
    if (showIfFree) {
      return _buildBadge(
        label: 'Free',
        color: colors.primary,
        icon: Icons.person_rounded,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
    bool isPro = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPro ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPro 
            ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
