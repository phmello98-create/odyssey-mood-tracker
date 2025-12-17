import 'dart:io';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:odyssey/src/utils/services/backup_service.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:intl/intl.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userPhotoUrl;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() {
      _isSignedIn = backupService.isSignedIn;
      _userEmail = backupService.userEmail;
      _userName = backupService.userName;
      _userPhotoUrl = backupService.userPhotoUrl;
    });

    if (_isSignedIn) {
      final lastBackup = await backupService.getLastDriveBackupTime();
      setState(() => _lastBackupTime = lastBackup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.backup,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Google Drive Section
                  _buildSectionTitle('☁️ Google Drive', colorScheme),
                  const SizedBox(height: 12),
                  _buildGoogleDriveCard(colorScheme),

                  const SizedBox(height: 32),

                  // Local Backup Section
                  _buildSectionTitle('📁 Backup Local', colorScheme),
                  const SizedBox(height: 12),
                  _buildLocalBackupCard(colorScheme),

                  const SizedBox(height: 32),

                  // Info Section
                  _buildInfoCard(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildGoogleDriveCard(ColorScheme colorScheme) {
    // Se não suporta Google Sign In (desktop), mostra mensagem
    if (!backupService.isGoogleAvailable) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Backup no Google Drive disponível apenas no Android e iOS.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Account Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isSignedIn
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    image: _userPhotoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_userPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _userPhotoUrl == null
                      ? Icon(
                          _isSignedIn ? Icons.person : Icons.cloud_outlined,
                          color: _isSignedIn
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignedIn ? (_userName ?? 'Conta Google') : 'Não conectado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_isSignedIn && _userEmail != null)
                        Text(
                          _userEmail!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (!_isSignedIn)
                        Text(
                          'Entre para fazer backup na nuvem',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Login/Logout Button
                TextButton(
                  onPressed: _isSignedIn ? _handleSignOut : _handleSignIn,
                  style: TextButton.styleFrom(
                    backgroundColor: _isSignedIn
                        ? Colors.red.withValues(alpha: 0.1)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isSignedIn ? 'Sair' : 'Entrar',
                    style: TextStyle(
                      color: _isSignedIn ? Colors.red : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isSignedIn) ...[
            Divider(color: colorScheme.outline.withValues(alpha: 0.1), height: 1),

            // Last Backup Info
            if (_lastBackupTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Último backup: ${_formatDate(_lastBackupTime!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            Divider(color: colorScheme.outline.withValues(alpha: 0.1), height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Fazer Backup',
                      color: colorScheme.primary,
                      onTap: _handleBackupToDrive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.cloud_download_outlined,
                      label: 'Restaurar',
                      color: Colors.green,
                      onTap: _handleRestoreFromDrive,
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

  Widget _buildLocalBackupCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.save_outlined,
            iconColor: Colors.blue,
            title: 'Exportar para JSON',
            subtitle: 'Salvar backup no dispositivo',
            onTap: _handleExportLocal,
            colorScheme: colorScheme,
          ),
          Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
          _buildActionTile(
            icon: Icons.folder_open_outlined,
            iconColor: Colors.orange,
            title: 'Importar de JSON',
            subtitle: 'Restaurar de arquivo local',
            onTap: _handleImportLocal,
            colorScheme: colorScheme,
          ),
          Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
          _buildActionTile(
            icon: Icons.share_outlined,
            iconColor: Colors.purple,
            title: 'Compartilhar Backup',
            subtitle: 'Enviar por email, WhatsApp, etc.',
            onTap: _handleShareBackup,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O backup salva: registros de humor, tarefas, hábitos, notas, livros, tempo de foco e configurações.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} horas';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // ==========================================
  // HANDLERS
  // ==========================================

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await backupService.signIn();
      if (success) {
        await _loadState();
        if (mounted) {
          FeedbackService.showSuccess(context, '✅ Conectado com sucesso!');
        }
      } else {
        if (mounted) {
          FeedbackService.showError(context, 'Não foi possível conectar');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.desconectar),
        content: Text(AppLocalizations.of(context)!.desejaSairDaContaGoogle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await backupService.signOut();
      setState(() {
        _isSignedIn = false;
        _userEmail = null;
        _userName = null;
        _userPhotoUrl = null;
        _lastBackupTime = null;
      });
    }
  }

  Future<void> _handleBackupToDrive() async {
    setState(() => _isLoading = true);
    try {
      final success = await backupService.backupToDrive();
      if (mounted) {
        if (success) {
          FeedbackService.showSuccess(context, '✅ Backup realizado com sucesso!');
          await _loadState();
        } else {
          FeedbackService.showError(context, 'Erro ao fazer backup');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreFromDrive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreBackup),
        content: const Text(
          'Isso irá substituir todos os dados atuais pelos dados do backup. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.restaurar, style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await backupService.restoreFromDrive();
        if (mounted) {
          if (success) {
            FeedbackService.showSuccess(context, '✅ Backup restaurado! Reinicie o app.');
          } else {
            FeedbackService.showError(context, 'Erro ao restaurar backup');
          }
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExportLocal() async {
    setState(() => _isLoading = true);
    try {
      final file = await backupService.exportToLocalFile();
      if (file != null && mounted) {
        FeedbackService.showSuccess(context, '✅ Backup salvo em:\n${file.path}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.importarBackup),
            content: const Text(
              'Isso irá substituir todos os dados atuais. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.importar),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() => _isLoading = true);
          final file = File(result.files.single.path!);
          final jsonString = await file.readAsString();
          final success = await backupService.importFromJson(jsonString);

          if (mounted) {
            if (success) {
              FeedbackService.showSuccess(context, '✅ Backup importado! Reinicie o app.');
            } else {
              FeedbackService.showError(context, 'Erro ao importar backup');
            }
          }
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleShareBackup() async {
    setState(() => _isLoading = true);
    try {
      final file = await backupService.exportToLocalFile();
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Odyssey Backup',
          text: 'Backup dos dados do Odyssey',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
