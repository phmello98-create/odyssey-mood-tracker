import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/providers/locale_provider.dart';

/// Tela de cadastro com email e senha
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(colors),
                    const SizedBox(height: 40),

                    // Campos
                    _buildNameField(colors),
                    const SizedBox(height: 16),
                    _buildEmailField(colors),
                    const SizedBox(height: 16),
                    _buildPasswordField(colors),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(colors),
                    const SizedBox(height: 24),

                    // Termos
                    _buildTermsCheckbox(colors),
                    const SizedBox(height: 24),

                    // Erro
                    if (_errorMessage != null) _buildErrorMessage(colors),

                    // Botão de cadastro
                    _buildSignupButton(colors, isLoading),
                    const SizedBox(height: 24),

                    // Link para login
                    _buildLoginLink(colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
            Icons.person_add_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.createAccount,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.signupHeaderSubtitle,
          style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildNameField(ColorScheme colors) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.fullName,
        hintText: 'Seu nome',
        prefixIcon: Icon(Icons.person_outline_rounded, color: colors.primary),
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
          return 'Por favor, insira seu nome';
        }
        if (value.length < 2) {
          return 'Nome muito curto';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(ColorScheme colors) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.email,
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

  Widget _buildPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.password,
        hintText: 'Mínimo 6 caracteres',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: colors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colors.onSurfaceVariant,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
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
          return 'Por favor, insira uma senha';
        }
        if (value.length < 6) {
          return 'Senha deve ter pelo menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirmPassword,
        hintText: 'Repita a senha',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: colors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colors.onSurfaceVariant,
          ),
          onPressed: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
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
          return 'Por favor, confirme sua senha';
        }
        if (value != _passwordController.text) {
          return 'As senhas não coincidem';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          activeColor: colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)!.liEConcordoComOs,
                  ),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _showTermsOfUse,
                      child: Text(
                        AppLocalizations.of(context)!.termosDeUso,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' e '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Text(
                        AppLocalizations.of(context)!.politicaDePrivacidade,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsOfUse() {
    HapticFeedback.selectionClick();
    final isPortuguese =
        ref.read(localeStateProvider).currentLocale.languageCode == 'pt';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LegalDocumentSheet(
        title: isPortuguese ? 'Termos de Uso' : 'Terms of Use',
        content: isPortuguese ? _termsOfUsePt : _termsOfUseEn,
      ),
    );
  }

  void _showPrivacyPolicy() {
    HapticFeedback.selectionClick();
    final isPortuguese =
        ref.read(localeStateProvider).currentLocale.languageCode == 'pt';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LegalDocumentSheet(
        title: isPortuguese ? 'Política de Privacidade' : 'Privacy Policy',
        content: isPortuguese ? _privacyPolicyPt : _privacyPolicyEn,
      ),
    );
  }

  static const _termsOfUsePt = '''
TERMOS DE USO - ODYSSEY

Última atualização: Dezembro 2025

Bem-vindo ao Odyssey! Ao usar nosso aplicativo, você concorda com estes termos.

1. ACEITAÇÃO DOS TERMOS
Ao acessar e usar o Odyssey, você aceita e concorda em cumprir estes Termos de Uso.

2. DESCRIÇÃO DO SERVIÇO
O Odyssey é um aplicativo de produtividade pessoal e bem-estar que oferece:
• Rastreamento de humor e emoções
• Gerenciamento de hábitos e tarefas
• Timer Pomodoro para foco
• Diário pessoal
• Biblioteca de leitura
• Gamificação para motivação

3. CONTA DO USUÁRIO
• Você pode usar o app como visitante (dados locais) ou criar uma conta
• Você é responsável por manter a segurança de sua conta

4. USO ACEITÁVEL
Você concorda em usar o app apenas para fins pessoais e legais.

5. PROPRIEDADE INTELECTUAL
O Odyssey e todo seu conteúdo são protegidos por direitos autorais.

6. DADOS E BACKUP
• Seus dados são armazenados localmente no dispositivo
• Usuários com conta podem sincronizar na nuvem (Firebase)

7. ISENÇÃO DE GARANTIAS
O app é fornecido "como está", sem garantias.

8. LEI APLICÁVEL
Estes termos são regidos pelas leis do Brasil (LGPD aplicável).

Ao usar o Odyssey, você confirma que leu e concorda com estes Termos de Uso.
''';

  static const _termsOfUseEn = '''
TERMS OF USE - ODYSSEY

Last updated: December 2025

Welcome to Odyssey! By using our app, you agree to these terms.

1. ACCEPTANCE OF TERMS
By accessing and using Odyssey, you accept and agree to comply with these Terms of Use.

2. DESCRIPTION OF SERVICE
Odyssey is a personal productivity and wellness app that offers:
• Mood and emotion tracking
• Habit and task management
• Pomodoro timer for focus
• Personal diary
• Reading library
• Gamification for motivation

3. USER ACCOUNT
• You can use the app as a guest (local data) or create an account
• You are responsible for maintaining the security of your account

4. ACCEPTABLE USE
You agree to use the app only for personal and legal purposes.

5. INTELLECTUAL PROPERTY
Odyssey and all its content are protected by copyright.

6. DATA AND BACKUP
• Your data is stored locally on the device
• Users with an account can sync to the cloud (Firebase)

7. DISCLAIMER OF WARRANTIES
The app is provided "as is", without warranty.

8. APPLICABLE LAW
These terms are governed by the laws of Brazil (LGPD applicable).

By using Odyssey, you confirm that you have read and agree to these Terms of Use.
''';

  static const _privacyPolicyPt = '''
POLÍTICA DE PRIVACIDADE - ODYSSEY

Última atualização: Dezembro 2025

Sua privacidade é importante para nós.

1. DADOS COLETADOS
• Informações de perfil (nome, email)
• Dados de uso do app (humor, hábitos, tarefas)
• Dados de sincronização (se usar conta)

2. USO DOS DADOS
Seus dados são usados para:
• Fornecer funcionalidades do app
• Sincronização entre dispositivos
• Melhorar a experiência do usuário

3. ARMAZENAMENTO
• Dados locais: armazenados criptografados no dispositivo
• Dados na nuvem: Firebase (Google Cloud)

4. COMPARTILHAMENTO
Não vendemos nem compartilhamos seus dados pessoais com terceiros.

5. SEUS DIREITOS (LGPD)
Você tem direito a:
• Acessar seus dados
• Corrigir informações
• Excluir sua conta e dados
• Exportar seus dados

6. SEGURANÇA
Usamos criptografia e práticas de segurança para proteger seus dados.

7. CONTATO
suporte@odysseyapp.com.br

Esta política pode ser atualizada periodicamente.
''';

  static const _privacyPolicyEn = '''
PRIVACY POLICY - ODYSSEY

Last updated: December 2025

Your privacy is important to us.

1. DATA COLLECTED
• Profile information (name, email)
• App usage data (mood, habits, tasks)
• Sync data (if using account)

2. USE OF DATA
Your data is used to:
• Provide app functionality
• Sync between devices
• Improve user experience

3. STORAGE
• Local data: encrypted storage on device
• Cloud data: Firebase (Google Cloud)

4. SHARING
We do not sell or share your personal data with third parties.

5. YOUR RIGHTS (LGPD)
You have the right to:
• Access your data
• Correct information
• Delete your account and data
• Export your data

6. SECURITY
We use encryption and security practices to protect your data.

7. CONTACT
suporte@odysseyapp.com.br

This policy may be updated periodically.
''';

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

  Widget _buildSignupButton(ColorScheme colors, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading || !_acceptedTerms ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.createAccount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(ColorScheme colors) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            children: [
              TextSpan(text: AppLocalizations.of(context)!.jaTemUmaConta),
              TextSpan(
                text: AppLocalizations.of(context)!.entrar,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    HapticFeedback.lightImpact();

    final authController = ref.read(authControllerProvider.notifier);
    final result = await authController.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Sucesso - navegar para home ou verificação de email
      HapticFeedback.mediumImpact();

      // Mostrar diálogo de verificação de email se necessário
      final user = result.userOrNull;
      if (user != null && !user.emailVerified) {
        _showVerificationDialog();
      } else {
        Navigator.of(context).pop(true); // Retorna true indicando sucesso
      }
    } else {
      // Erro
      HapticFeedback.heavyImpact();
      setState(
        () => _errorMessage = result.errorMessage ?? 'Erro ao criar conta',
      );
    }
  }

  void _showVerificationDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: colors.primary),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.verifiqueSeuEmail),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviamos um link de verificação para:',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Clique no link do email para ativar sua conta.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .resendVerificationEmail();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.emailReenviado),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.reenviar),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.continuar),
          ),
        ],
      ),
    );
  }
}

/// Widget para exibir documentos legais (Termos/Privacidade)
class _LegalDocumentSheet extends StatelessWidget {
  final String title;
  final String content;

  const _LegalDocumentSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(color: Colors.white.withOpacity(0.1), height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.7,
                    ),
                  ),
                ),
              ),

              // Footer
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Entendi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
