import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/subscription/subscription_provider.dart';

class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.2),
                        colors.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurface),
                            ),
                          ),
                          const Spacer(),
                          if (subscription.isProValid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium, color: Colors.black87, size: 16),
                                  const SizedBox(width: 4),
                                  Text(AppLocalizations.of(context)!.proAtivo, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Logo PRO
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium, size: 56, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ).createShader(bounds),
                        child: const Text(
                          'Odyssey PRO',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subscription.isProValid
                            ? 'Você já é PRO! Aproveite todos os benefícios.'
                            : 'Desbloqueie todo o potencial do app',
                        style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Benefícios
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BENEFÍCIOS PRO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...ProBenefits.benefits.map((benefit) => _buildBenefitCard(benefit, colors)),
                    ],
                  ),
                ),
              ),

              // Planos
              if (!subscription.isProValid)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESCOLHA SEU PLANO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPlanCard(
                          context: context,
                          ref: ref,
                          title: 'PRO Anual',
                          subtitle: 'Melhor custo-benefício',
                          price: subscriptionNotifier.yearlyPrice,
                          priceInfo: '/ano',
                          isPopular: true,
                          isLoading: subscription.isLoading,
                          onTap: () => _purchaseYearly(context, ref),
                          colors: colors,
                          badge: 'ECONOMIZE 33%',
                        ),
                        const SizedBox(height: 12),
                        _buildPlanCard(
                          context: context,
                          ref: ref,
                          title: 'PRO Mensal',
                          subtitle: 'Cancele quando quiser',
                          price: subscriptionNotifier.monthlyPrice,
                          priceInfo: '/mês',
                          isPopular: false,
                          isLoading: subscription.isLoading,
                          onTap: () => _purchaseMonthly(context, ref),
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ),

              // Erro
              if (subscription.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subscription.errorMessage!,
                              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: colors.onErrorContainer),
                            onPressed: () => ref.read(subscriptionProvider.notifier).clearError(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Restaurar compra
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: subscription.isLoading ? null : () => _restorePurchase(context, ref),
                    child: Text(
                      'Restaurar compra anterior',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          
          // Loading overlay
          if (subscription.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(ProBenefit benefit, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(benefit.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                Text(benefit.description, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF07E092), size: 22),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String price,
    required String priceInfo,
    required bool isPopular,
    required bool isLoading,
    required VoidCallback onTap,
    required ColorScheme colors,
    String? badge,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: [const Color(0xFFFFD700).withValues(alpha: 0.15), const Color(0xFFFFA500).withValues(alpha: 0.08)],
                  )
                : null,
            color: isPopular ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular ? const Color(0xFFFFD700) : colors.outline.withValues(alpha: 0.2),
              width: isPopular ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.onSurface)),
                            if (isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(AppLocalizations.of(context)!.popular, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black87)),
                              ),
                            ],
                            if (badge != null && !isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.green)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isPopular ? const Color(0xFFFFD700) : colors.primary)),
                      Text(priceInfo, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? const Color(0xFFFFD700) : colors.primary,
                    foregroundColor: isPopular ? Colors.black87 : colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Assinar ${title.split(' ').last}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseMonthly(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(subscriptionProvider.notifier).purchaseMonthly();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Assinatura ativada! Aproveite o PRO.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _purchaseYearly(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(subscriptionProvider.notifier).purchaseYearly();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Assinatura anual ativada! Você economizou 33%.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _restorePurchase(BuildContext context, WidgetRef ref) async {
    await ref.read(subscriptionProvider.notifier).restorePurchase();
    
    // O resultado virá via stream/state
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verificando compras anteriores...'),
        ),
      );
    }
  }
}
