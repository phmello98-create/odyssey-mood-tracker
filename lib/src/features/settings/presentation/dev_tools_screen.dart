import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/config/app_flavor.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/utils/services/haptic_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:odyssey/src/features/gamification/data/data_seeder.dart';

/// Tela de Ferramentas de Desenvolvedor
///
/// Visível apenas no flavor DEV. Contém:
/// - Informações do build
/// - Seed data actions
/// - Cache clearing
/// - Debug toggles
class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  bool _isClearing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEV',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Ferramentas de Dev'),
          ],
        ),
        backgroundColor: Colors.orange.withAlpha(30),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Build Info Card
          _buildSectionCard(
            context,
            title: '📱 Informações do Build',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Flavor', FlavorConfig.current.displayName),
              _buildInfoRow(
                'Package ID',
                'io.odyssey.moodtracker${FlavorConfig.current.packageSuffix}',
              ),
              _buildInfoRow(
                'Mode',
                FlavorConfig.isDev ? 'Development' : 'Production',
              ),
              _buildInfoRow(
                'Debug Banner',
                FlavorConfig.isDev ? 'Ativo' : 'Oculto',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Info Card
          _buildSectionCard(
            context,
            title: '👤 Usuário Atual',
            icon: Icons.person_outline,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final user = ref.watch(currentUserProvider);
                  if (user == null) {
                    return _buildInfoRow('Status', 'Não logado');
                  }
                  return Column(
                    children: [
                      _buildInfoRow('UID', user.uid),
                      _buildInfoRow('Email', user.email ?? 'N/A'),
                      _buildInfoRow('Nome', user.displayName),
                      _buildInfoRow(
                        'Verificado',
                        user.emailVerified ? 'Sim' : 'Não',
                      ),
                      _buildInfoRow('Guest', user.isGuest ? 'Sim' : 'Não'),
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actions Card
          _buildSectionCard(
            context,
            title: '⚡ Ações Rápidas',
            icon: Icons.flash_on,
            children: [
              _buildActionButton(
                context,
                icon: Icons.delete_sweep,
                label: 'Limpar Cache Hive',
                subtitle: 'Remove todos os dados locais',
                color: Colors.red,
                onTap: _clearHiveCache,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.data_array,
                label: 'Seed Data',
                subtitle: 'Carregar dados de exemplo',
                color: Colors.blue,
                onTap: _loadSeedData,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.copy_all,
                label: 'Copiar UID',
                subtitle: 'Copiar ID do usuário para clipboard',
                color: Colors.purple,
                onTap: _copyUserId,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.bug_report,
                label: 'Testar Crash',
                subtitle: 'Forçar um erro para teste',
                color: Colors.orange,
                onTap: _testCrash,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hive Boxes Card
          _buildSectionCard(
            context,
            title: '📦 Hive Boxes',
            icon: Icons.storage,
            children: [
              FutureBuilder<List<String>>(
                future: _getHiveBoxes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: snapshot.data!.map((boxName) {
                      return _buildInfoRow(
                        boxName,
                        Hive.isBoxOpen(boxName) ? '✅ Aberta' : '❌ Fechada',
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Message
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  if (_isClearing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Footer warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta tela só aparece no flavor DEV. Não estará disponível para usuários finais.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withAlpha(30)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          soundService.playButtonClick();
          hapticService.lightTap();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withAlpha(150)),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _getHiveBoxes() async {
    // Lista de boxes conhecidas do app
    return [
      'settings',
      'mood_records',
      'tasks',
      'habits',
      'diary_entries',
      'time_tracking_records',
      'gamification',
      'books_v3',
      'language_learning',
    ];
  }

  Future<void> _clearHiveCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Limpar Cache'),
        content: const Text(
          'Isso vai apagar TODOS os dados locais do app. '
          'Esta ação não pode ser desfeita!\n\n'
          'Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Apagar Tudo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isClearing = true;
      _statusMessage = 'Limpando cache...';
    });

    try {
      await Hive.deleteFromDisk();
      setState(() {
        _statusMessage = '✅ Cache limpo! Reinicie o app.';
        _isClearing = false;
      });
      soundService.playSuccess();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro: $e';
        _isClearing = false;
      });
    }
  }

  Future<void> _loadSeedData() async {
    setState(() {
      _statusMessage = '🌱 Semeando dados (force=true)...';
    });
    soundService.playButtonClick();

    try {
      await DataSeeder.seedAllData(force: true);

      setState(() {
        _statusMessage = '✅ Seed completo! Reinicie o app para ver tudo.';
      });
      soundService.playSuccess();
      hapticService.success();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro no seed: $e';
      });
      debugPrint('Seed Error: $e');
    }
  }

  Future<void> _copyUserId() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await Clipboard.setData(ClipboardData(text: user.uid));
      setState(() {
        _statusMessage = '📋 UID copiado: ${user.uid.substring(0, 8)}...';
      });
      soundService.playSuccess();
      hapticService.success();
    } else {
      setState(() {
        _statusMessage = '❌ Usuário não está logado';
      });
    }
  }

  void _testCrash() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Testar Crash'),
        content: const Text(
          'Isso vai forçar um erro no app para testar '
          'o sistema de crash reporting.\n\n'
          'O app pode fechar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              throw Exception('Dev Tools - Crash de teste forçado');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Forçar Crash'),
          ),
        ],
      ),
    );
  }
}
