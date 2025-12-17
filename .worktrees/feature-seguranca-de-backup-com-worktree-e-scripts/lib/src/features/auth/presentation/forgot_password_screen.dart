import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Tela de recuperação de senha
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _emailSent
                  ? _buildSuccessView(colors)
                  : _buildFormView(colors, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ColorScheme colors, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(colors),
          const SizedBox(height: 40),

          // Campo de email
          _buildEmailField(colors),
          const SizedBox(height: 24),

          // Erro
          if (_errorMessage != null) _buildErrorMessage(colors),

          // Botão de enviar
          _buildSendButton(colors, isLoading),
          const SizedBox(height: 24),

          // Link para voltar ao login
          _buildBackToLoginLink(colors),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ColorScheme colors) {
    return Column(
      children: [
        const SizedBox(height: 60),
        
        // Ícone de sucesso
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF07E092).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 50,
            color: Color(0xFF07E092),
          ),
        ),
        const SizedBox(height: 32),

        // Título
        Text(
          'Email Enviado!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Descrição
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Enviamos um link de recuperação para:',
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        
        // Email
        Text(
          _emailController.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Instruções
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInstructionItem(
                colors,
                Icons.inbox_rounded,
                'Verifique sua caixa de entrada',
              ),
              const SizedBox(height: 12),
              _buildInstructionItem(
                colors,
                Icons.folder_rounded,
                'Confira também a pasta de spam',
              ),
              const SizedBox(height: 12),
              _buildInstructionItem(
                colors,
                Icons.link_rounded,
                'Clique no link para redefinir a senha',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Botão de reenviar
        TextButton.icon(
          onPressed: _handleResend,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context)!.naoRecebeuReenviar),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Botão de voltar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Voltar ao Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(ColorScheme colors, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Esqueceu a Senha?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Não se preocupe! Digite seu email e enviaremos um link para criar uma nova senha.',
          style: TextStyle(
            fontSize: 16,
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(ColorScheme colors) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'seu@email.com',
        prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira seu email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildErrorMessage(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: colors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(ColorScheme colors, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _handleSendReset,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          isLoading ? 'Enviando...' : 'Enviar Link',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink(ColorScheme colors) {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_rounded, size: 18, color: colors.primary),
        label: Text(
          'Voltar ao Login',
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    HapticFeedback.lightImpact();

    final authController = ref.read(authControllerProvider.notifier);
    final result = await authController.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Sucesso
      HapticFeedback.mediumImpact();
      setState(() => _emailSent = true);
    } else {
      // Erro
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = result.errorMessage ?? 'Erro ao enviar email');
    }
  }

  Future<void> _handleResend() async {
    HapticFeedback.lightImpact();
    
    final authController = ref.read(authControllerProvider.notifier);
    final result = await authController.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.emailReenviadoComSucesso),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Erro ao reenviar email'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
