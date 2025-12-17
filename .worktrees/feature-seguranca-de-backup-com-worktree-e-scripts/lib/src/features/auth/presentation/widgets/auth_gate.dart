import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../login_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Widget que controla o fluxo de autenticação
/// 
/// Se o usuário não estiver autenticado, mostra a tela de login.
/// Se estiver autenticado, mostra o conteúdo principal do app.
class AuthGate extends ConsumerWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.loadingWidget,
    this.loginBuilder,
  });

  /// Widget a ser mostrado quando o usuário estiver autenticado
  final Widget child;

  /// Widget customizado para o estado de loading (opcional)
  final Widget? loadingWidget;

  /// Builder customizado para a tela de login (opcional)
  final Widget Function(BuildContext context)? loginBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Não autenticado - mostrar login
          return loginBuilder?.call(context) ?? const LoginScreen();
        }
        // Autenticado - mostrar conteúdo principal
        return child;
      },
      loading: () {
        return loadingWidget ?? _buildLoadingWidget(context);
      },
      error: (error, stack) {
        // Em caso de erro, mostrar tela de login com opção de retry
        return _buildErrorWidget(context, error, ref);
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou ícone do app
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando...',
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colors.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Erro ao verificar autenticação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Tentar novamente invalida o provider para refazer a verificação
                  ref.invalidate(authStateChangesProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.tentarNovamente),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Ir direto para o login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Ir para login',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget simplificado que só verifica se está autenticado
/// 
/// Útil para proteger rotas específicas sem mostrar loading screen completa.
class AuthCheck extends ConsumerWidget {
  const AuthCheck({
    super.key,
    required this.child,
    this.onUnauthenticated,
  });

  /// Widget a ser mostrado quando autenticado
  final Widget child;

  /// Callback quando não autenticado (se null, navega para login)
  final VoidCallback? onUnauthenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      // Schedule navigation para depois do build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (onUnauthenticated != null) {
          onUnauthenticated!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      });
      
      // Mostrar tela vazia enquanto navega
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return child;
  }
}
