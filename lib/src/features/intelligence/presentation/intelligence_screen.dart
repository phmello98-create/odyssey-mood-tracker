import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/insight.dart';
import '../services/intelligence_service.dart';
import 'widgets/insight_card.dart';

/// Tela principal de Descobertas/Insights
class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _expandedInsightId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = ref.watch(intelligenceServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Descobertas'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  // TODO: Trigger analysis refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analisando seus dados...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Atualizar análise',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => _showInfoDialog(context),
                tooltip: 'Sobre',
              ),
            ],
          ),

          // Stats Header
          SliverToBoxAdapter(
            child: _buildStatsHeader(context, service),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Padrões'),
                  Tab(text: 'Alertas'),
                  Tab(text: 'Previsões'),
                ],
              ),
              backgroundColor: colorScheme.surface,
            ),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsList(service.insights),
                _buildInsightsList(service.insights
                    .where((i) =>
                        i.type == InsightType.pattern ||
                        i.type == InsightType.correlation)
                    .toList()),
                _buildInsightsList(service.insights
                    .where((i) => i.type == InsightType.warning)
                    .toList()),
                _buildInsightsList(service.insights
                    .where((i) =>
                        i.type == InsightType.prediction ||
                        i.type == InsightType.celebration)
                    .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, IntelligenceService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Sistema de Inteligência',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                icon: Icons.insights_rounded,
                value: '${service.insights.length}',
                label: 'Insights',
                color: Colors.blue,
              ),
              _StatItem(
                icon: Icons.timeline_rounded,
                value: '${service.patterns.length}',
                label: 'Padrões',
                color: Colors.purple,
              ),
              _StatItem(
                icon: Icons.link_rounded,
                value: '${service.correlations.length}',
                label: 'Correlações',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.auto_awesome_rounded,
                value: '${service.predictions.length}',
                label: 'Previsões',
                color: Colors.teal,
              ),
            ],
          ),
          if (service.lastAnalysis != null) ...[
            const SizedBox(height: 12),
            Text(
              'Última análise: ${_formatLastAnalysis(service.lastAnalysis!)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsList(List<Insight> insights) {
    if (insights.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        final isExpanded = _expandedInsightId == insight.id;

        return InsightCard(
          insight: insight,
          expanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedInsightId = isExpanded ? null : insight.id;
            });
            ref.read(intelligenceServiceProvider).markInsightAsRead(insight.id);
          },
          onRate: (rating) {
            ref.read(intelligenceServiceProvider).rateInsight(insight.id, rating);
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum insight ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue registrando seu humor e atividades.\nO sistema aprenderá seus padrões automaticamente!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar Humor'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded),
            SizedBox(width: 8),
            Text('Sistema de Inteligência'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'O Odyssey aprende com seus dados para fornecer insights personalizados:\n',
              ),
              Text('📊 Padrões: Identifica tendências no seu humor e comportamento'),
              SizedBox(height: 8),
              Text('🔗 Correlações: Descobre o que afeta seu bem-estar'),
              SizedBox(height: 8),
              Text('🔮 Previsões: Antecipa riscos de streaks e mudanças de humor'),
              SizedBox(height: 8),
              Text('💡 Recomendações: Sugere ações baseadas no seu histórico'),
              SizedBox(height: 16),
              Text(
                '🔒 Privacidade: Todos os dados são processados localmente no seu dispositivo.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  String _formatLastAnalysis(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'há ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'há ${diff.inHours} horas';
    } else {
      return 'há ${diff.inDays} dias';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
