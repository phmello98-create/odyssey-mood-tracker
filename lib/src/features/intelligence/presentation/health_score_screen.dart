import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_score_provider.dart';
import '../domain/engines/health_score_engine.dart';
import 'widgets/health_score_widget.dart';

/// Tela dedicada do Health Score com detalhes de cada dimensão
class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthScoreAsync = ref.watch(healthScoreProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: healthScoreAsync.when(
                data: (report) => report != null
                    ? _buildHeaderContent(context, report)
                    : _buildEmptyHeader(context),
                loading: () => _buildLoadingHeader(context),
                error: (_, __) => _buildEmptyHeader(context),
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: colorScheme.onSurface),
                ),
                onPressed: () => _showInfoBottomSheet(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Conteúdo
          healthScoreAsync.when(
            data: (report) => report != null
                ? _buildContent(context, report)
                : _buildEmptyContent(context),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildEmptyContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context, HealthReport report) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getLevelColor(report.level).withValues(alpha: 0.15),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Gauge
            HealthScoreGauge(
              score: report.overallScore,
              level: report.level,
              size: 160,
            ),
            const SizedBox(height: 16),
            // Nível e tendência
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLevelColor(report.level).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getLevelColor(report.level).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getLevelIcon(report.level),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.levelText,
                        style: TextStyle(
                          color: _getLevelColor(report.level),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        report.trendIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTrendText(report.trend),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HealthReport report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Pontos fortes e fracos
          if (report.topStrengths.isNotEmpty || report.topWeaknesses.isNotEmpty) ...[
            Row(
              children: [
                if (report.topStrengths.isNotEmpty)
                  Expanded(
                    child: _buildHighlightCard(
                      context,
                      icon: '💪',
                      title: 'Pontos Fortes',
                      items: report.topStrengths,
                      color: Colors.green,
                    ),
                  ),
                if (report.topStrengths.isNotEmpty && report.topWeaknesses.isNotEmpty)
                  const SizedBox(width: 12),
                if (report.topWeaknesses.isNotEmpty)
                  Expanded(
                    child: _buildHighlightCard(
                      context,
                      icon: '🎯',
                      title: 'Áreas de Foco',
                      items: report.topWeaknesses,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Título das dimensões
          Text(
            'Dimensões',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Cards de dimensão
          ...report.dimensions.map((dim) => DimensionCard(dimension: dim)),

          // Ações prioritárias
          if (report.priorityActions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Ações Recomendadas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...report.priorityActions.asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context, {
    required String icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Health Score',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 60),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Calculando...'),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Dados Insuficientes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Continue registrando seu humor, hábitos e tarefas para ver seu Health Score personalizado.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add),
                label: const Text('Começar a Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Como funciona o Health Score?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              icon: '😊',
              title: 'Humor (35%)',
              description: 'Baseado na média, estabilidade e tendência do seu humor.',
            ),
            _buildInfoItem(
              context,
              icon: '✅',
              title: 'Hábitos (25%)',
              description: 'Taxa de conclusão dos hábitos e streaks ativos.',
            ),
            _buildInfoItem(
              context,
              icon: '📋',
              title: 'Produtividade (20%)',
              description: 'Tarefas completadas e volume diário.',
            ),
            _buildInfoItem(
              context,
              icon: '📊',
              title: 'Consistência (20%)',
              description: 'Regularidade de uso do app e registros.',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Colors.green;
      case HealthLevel.good:
        return Colors.lightGreen;
      case HealthLevel.moderate:
        return Colors.amber;
      case HealthLevel.needsAttention:
        return Colors.orange;
      case HealthLevel.critical:
        return Colors.red;
    }
  }

  String _getLevelIcon(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return '🌟';
      case HealthLevel.good:
        return '✅';
      case HealthLevel.moderate:
        return '⚠️';
      case HealthLevel.needsAttention:
        return '🔶';
      case HealthLevel.critical:
        return '🚨';
    }
  }

  String _getTrendText(HealthTrend trend) {
    switch (trend) {
      case HealthTrend.improving:
        return 'Melhorando';
      case HealthTrend.stable:
        return 'Estável';
      case HealthTrend.declining:
        return 'Em queda';
      case HealthTrend.insufficientData:
        return 'Sem dados';
    }
  }
}
