import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/settings/services/account_deletion_service.dart';
import 'package:odyssey/src/features/settings/services/data_export_service.dart';
import 'package:odyssey/src/features/auth/presentation/login_screen.dart';

/// Tela de exclusão de conta
/// Conforme LGPD Art. 18 - Direito ao Esquecimento
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _confirmDelete = false;
  bool _isGoogleAccount = false;
  bool _needsPassword = false;

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    final isGoogle = AccountDeletionService.isGoogleAccount();
    final needsReauth = await AccountDeletionService.needsReauth();
    
    setState(() {
      _isGoogleAccount = isGoogle;
      _needsPassword = needsReauth && !isGoogle;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Excluir Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ícone de aviso
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 80,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Atenção: Esta ação é irreversível',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Descrição
            Text(
              'Ao excluir sua conta, TODOS os seus dados serão '
              'permanentemente deletados:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // Lista de dados que serão deletados
            _buildDeletionList(colorScheme),
            const SizedBox(height: 24),

            // Aviso de backup
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recomendamos fazer um backup',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Exporte seus dados antes de continuar para não perder nenhuma informação.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botão de exportar dados
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Exportar Meus Dados Primeiro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Divisor
            Row(
              children: [
                Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Zona de perigo',
                    style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 24),

            // Campo de senha (se necessário)
            if (_needsPassword) ...[
              Text(
                'Para continuar, digite sua senha:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Checkbox de confirmação
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _confirmDelete 
                      ? Colors.red.withValues(alpha: 0.5)
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: CheckboxListTile(
                value: _confirmDelete,
                onChanged: _loading 
                    ? null 
                    : (value) => setState(() => _confirmDelete = value ?? false),
                title: const Text(
                  'Eu entendo que esta ação é permanente e todos os meus dados serão deletados.',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Botão de deletar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canDelete() ? _confirmDeletion : null,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(_loading ? 'Excluindo...' : 'Excluir Conta Permanentemente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Texto legal
            Text(
              'Conforme LGPD Art. 18 - Direito ao Esquecimento',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionList(ColorScheme colorScheme) {
    final items = [
      ('Registros de humor', Icons.mood),
      ('Diário pessoal', Icons.book),
      ('Tarefas e hábitos', Icons.check_circle),
      ('Notas e anotações', Icons.note),
      ('Biblioteca de livros', Icons.library_books),
      ('Dados de gamificação', Icons.stars),
      ('Backups na nuvem', Icons.cloud),
      ('Conta e configurações', Icons.settings),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.close, color: Colors.red, size: 18),
              const SizedBox(width: 12),
              Icon(item.$2, color: colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Text(
                item.$1,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  bool _canDelete() {
    if (_loading) return false;
    if (!_confirmDelete) return false;
    if (_needsPassword && _passwordController.text.isEmpty) return false;
    return true;
  }

  Future<void> _exportData() async {
    setState(() => _loading = true);

    try {
      final file = await DataExportService.exportAllUserData();
      
      if (mounted) {
        final share = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dados Exportados'),
            content: Text(
              'Seus dados foram salvos em:\n\n${file.path}\n\n'
              'Deseja compartilhar o arquivo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Compartilhar'),
              ),
            ],
          ),
        );

        if (share == true) {
          await DataExportService.shareExport(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmDeletion() async {
    // Confirmação final
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Confirmação Final'),
          ],
        ),
        content: const Text(
          'Tem ABSOLUTA certeza que deseja excluir sua conta?\n\n'
          'Esta ação NÃO pode ser desfeita. Todos os seus dados serão '
          'permanentemente deletados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final result = await AccountDeletionService.deleteAccountCompletely(
        password: _needsPassword ? _passwordController.text : null,
        isGoogleAccount: _isGoogleAccount,
      );

      if (!mounted) return;

      if (result.success || result.steps['hive'] == true) {
        // Navegar para tela de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: ${result.globalError ?? result.errors.values.first}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
