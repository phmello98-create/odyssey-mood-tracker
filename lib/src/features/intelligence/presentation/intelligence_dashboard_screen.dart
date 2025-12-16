import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../domain/engines/health_score_engine.dart';
import '../domain/engines/pattern_engine.dart';
import '../domain/models/user_pattern.dart';
import '../providers/health_score_provider.dart';
import '../../mood_records/data/mood_log/mood_record_repository.dart';

/// Dashboard de Analytics Interativo
class IntelligenceDashboardScreen extends ConsumerStatefulWidget {
  const IntelligenceDashboardScreen({super.key});

  @override
  ConsumerState<IntelligenceDashboardScreen> createState() => _IntelligenceDashboardScreenState();
}

class _IntelligenceDashboardScreenState extends ConsumerState<IntelligenceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1; // 0 = 7d, 1 = 30d, 2 = 90d

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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Analytics',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            actions: [
              // Period selector
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodButton('7d', 0),
                    _buildPeriodButton('30d', 1),
                    _buildPeriodButton('90d', 2),
                  ],
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Visão Geral'),
                Tab(text: 'Humor'),
                Tab(text: 'Padrões'),
                Tab(text: 'Correlações'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMoodTab(),
            _buildPatternsTab(),
            _buildCorrelationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index) {
    final isSelected = _selectedPeriod == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPeriod = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ============ VISÃO GERAL ============
  Widget _buildOverviewTab() {
    final healthScoreAsync = ref.watch(healthScoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          healthScoreAsync.when(
            data: (report) => report != null
                ? _buildHealthScoreCard(report)
                : _buildEmptyCard('Dados insuficientes'),
            loading: () => _buildLoadingCard(),
            error: (_, __) => _buildEmptyCard('Erro ao carregar'),
          ),

          const SizedBox(height: 24),

          // Quick Stats Grid
          _buildQuickStatsGrid(),

          const SizedBox(height: 24),

          // Mood Trend Chart
          _buildSectionTitle('Tendência de Humor'),
          const SizedBox(height: 12),
          _buildMoodTrendChart(),

          const SizedBox(height: 24),

          // Activity Impact
          _buildSectionTitle('Impacto das Atividades'),
          const SizedBox(height: 12),
          _buildActivityImpactChart(),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthReport report) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLevelColor(report.level).withValues(alpha: 0.15),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getLevelColor(report.level).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Gauge
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: report.overallScore / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(_getLevelColor(report.level)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.overallScore.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(report.level),
                      ),
                    ),
                    Text(
                      'Health',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.levelText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(report.level),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(report.trendIcon, style: const TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                // Mini dimension bars
                ...report.dimensions.take(3).map((dim) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          dim.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: dim.score / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(_getLevelColor(dim.level)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dim.score.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyCard('Sem dados no período');
        }

        final avgMood = filtered.map((r) => r.score).reduce((a, b) => a + b) / filtered.length;
        final totalRecords = filtered.length;
        final uniqueDays = filtered.map((r) => '${r.date.year}-${r.date.month}-${r.date.day}').toSet().length;
        
        // Melhor dia da semana
        final byWeekday = <int, List<int>>{};
        for (final r in filtered) {
          byWeekday.putIfAbsent(r.date.weekday, () => []).add(r.score);
        }
        final avgByWeekday = byWeekday.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
        final bestDay = avgByWeekday.entries.reduce((a, b) => a.value > b.value ? a : b);
        final weekdayNames = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        return Row(
          children: [
            Expanded(child: _buildStatCard('😊', 'Humor Médio', avgMood.toStringAsFixed(1), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('📝', 'Registros', '$totalRecords', Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('📅', 'Dias Ativos', '$uniqueDays', Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('⭐', 'Melhor Dia', weekdayNames[bestDay.key], Colors.purple)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
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
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendChart() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();
        
        if (filtered.length < 3) {
          return _buildEmptyCard('Dados insuficientes para gráfico');
        }

        filtered.sort((a, b) => a.date.compareTo(b.date));

        // Agrupa por dia
        final dailyAvg = <DateTime, double>{};
        for (final r in filtered) {
          final day = DateTime(r.date.year, r.date.month, r.date.day);
          dailyAvg.update(day, (v) => (v + r.score) / 2, ifAbsent: () => r.score.toDouble());
        }

        final sortedDays = dailyAvg.keys.toList()..sort();
        final spots = <FlSpot>[];
        
        for (int i = 0; i < sortedDays.length; i++) {
          spots.add(FlSpot(i.toDouble(), dailyAvg[sortedDays[i]]!));
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value < 1 || value > 5) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 1,
              maxY: 5,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: spots.length < 15,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityImpactChart() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyCard('Sem dados');
        }

        // Calcula impacto por atividade
        final activityScores = <String, List<int>>{};
        final noActivityScores = <int>[];

        for (final r in filtered) {
          if (r.activities.isEmpty) {
            noActivityScores.add(r.score);
          } else {
            for (final act in r.activities) {
              activityScores.putIfAbsent(act.activityName, () => []).add(r.score);
            }
          }
        }

        final baselineAvg = noActivityScores.isEmpty 
            ? 3.0 
            : noActivityScores.reduce((a, b) => a + b) / noActivityScores.length;

        final impacts = <MapEntry<String, double>>[];
        for (final entry in activityScores.entries) {
          if (entry.value.length >= 2) {
            final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
            final impact = avg - baselineAvg;
            impacts.add(MapEntry(entry.key, impact));
          }
        }

        impacts.sort((a, b) => b.value.compareTo(a.value));
        final topImpacts = impacts.take(6).toList();

        if (topImpacts.isEmpty) {
          return _buildEmptyCard('Poucos dados de atividades');
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.5,
              minY: -1.5,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: value == 0 
                      ? Colors.grey.withValues(alpha: 0.5) 
                      : Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: value == 0 ? 2 : 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= topImpacts.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          topImpacts[idx].key.substring(0, math.min(6, topImpacts[idx].key.length)),
                          style: const TextStyle(fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: topImpacts.asMap().entries.map((entry) {
                final impact = entry.value.value;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: impact.clamp(-1.5, 1.5),
                      color: impact >= 0 ? Colors.green : Colors.red,
                      width: 20,
                      borderRadius: BorderRadius.vertical(
                        top: impact >= 0 ? const Radius.circular(4) : Radius.zero,
                        bottom: impact < 0 ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ============ TAB HUMOR ============
  Widget _buildMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Distribuição de Humor'),
          const SizedBox(height: 12),
          _buildMoodDistributionChart(),

          const SizedBox(height: 24),

          _buildSectionTitle('Humor por Dia da Semana'),
          const SizedBox(height: 12),
          _buildWeekdayMoodChart(),

          const SizedBox(height: 24),

          _buildSectionTitle('Humor por Hora do Dia'),
          const SizedBox(height: 12),
          _buildHourlyMoodChart(),

          const SizedBox(height: 24),

          _buildSectionTitle('Volatilidade'),
          const SizedBox(height: 12),
          _buildVolatilityCard(),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionChart() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyCard('Sem dados');
        }

        // Conta por score
        final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final r in filtered) {
          counts[r.score] = (counts[r.score] ?? 0) + 1;
        }

        final colors = [Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
        final labels = ['Péssimo', 'Ruim', 'Ok', 'Bom', 'Ótimo'];

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(5, (i) {
                final score = i + 1;
                final count = counts[score] ?? 0;
                final percentage = filtered.isNotEmpty ? count / filtered.length * 100 : 0;
                
                return PieChartSectionData(
                  color: colors[i],
                  value: count.toDouble(),
                  title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekdayMoodChart() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyCard('Sem dados');
        }

        final byWeekday = <int, List<int>>{};
        for (final r in filtered) {
          byWeekday.putIfAbsent(r.date.weekday, () => []).add(r.score);
        }

        final avgByWeekday = <int, double>{};
        for (int i = 1; i <= 7; i++) {
          final scores = byWeekday[i] ?? [];
          avgByWeekday[i] = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
        }

        final weekdayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        return Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 5,
              minY: 0,
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= 7) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(weekdayNames[idx], style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final avg = avgByWeekday[i + 1] ?? 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: avg,
                      color: _getMoodColor(avg),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourlyMoodChart() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyCard('Sem dados');
        }

        // Agrupa por período do dia
        final periods = {
          'Manhã\n6-12h': <int>[],
          'Tarde\n12-18h': <int>[],
          'Noite\n18-24h': <int>[],
          'Madrugada\n0-6h': <int>[],
        };

        for (final r in filtered) {
          final hour = r.date.hour;
          if (hour >= 6 && hour < 12) {
            periods['Manhã\n6-12h']!.add(r.score);
          } else if (hour >= 12 && hour < 18) {
            periods['Tarde\n12-18h']!.add(r.score);
          } else if (hour >= 18) {
            periods['Noite\n18-24h']!.add(r.score);
          } else {
            periods['Madrugada\n0-6h']!.add(r.score);
          }
        }

        final periodAvgs = periods.map((k, v) => MapEntry(
          k, 
          v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length,
        ));

        return Row(
          children: periodAvgs.entries.map((entry) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.value).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getMoodColor(entry.value).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getMoodColor(entry.value),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVolatilityCard() {
    return Consumer(
      builder: (context, ref, _) {
        final moodRepo = ref.watch(moodRecordRepositoryProvider);
        final records = moodRepo.fetchMoodRecords().values.toList();
        
        final days = _getPeriodDays();
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = records.where((r) => r.date.isAfter(cutoff)).toList();

        if (filtered.length < 7) {
          return _buildEmptyCard('Dados insuficientes');
        }

        final scores = filtered.map((r) => r.score.toDouble()).toList();
        final mean = scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
        final stdDev = math.sqrt(variance);
        final cv = stdDev / mean;

        String status;
        Color color;
        String description;

        if (cv > 0.25) {
          status = 'Alta';
          color = Colors.orange;
          description = 'Seu humor varia bastante. Tente identificar os gatilhos.';
        } else if (cv < 0.1) {
          status = 'Baixa';
          color = Colors.green;
          description = 'Seu humor é muito estável. Ótimo sinal!';
        } else {
          status = 'Normal';
          color = Colors.blue;
          description = 'Variações normais de humor.';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  status == 'Alta' ? '📊' : (status == 'Baixa' ? '😌' : '⚖️'),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volatilidade $status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CV: ${(cv * 100).toStringAsFixed(1)}% | σ: ${stdDev.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ TAB PADRÕES ============
  Widget _buildPatternsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatternsList(),
        ],
      ),
    );
  }

  // ============ TAB CORRELAÇÕES ============
  Widget _buildCorrelationsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CorrelationsList(),
        ],
      ),
    );
  }

  // ============ HELPERS ============

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  int _getPeriodDays() {
    switch (_selectedPeriod) {
      case 0: return 7;
      case 1: return 30;
      case 2: return 90;
      default: return 30;
    }
  }

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent: return Colors.green;
      case HealthLevel.good: return Colors.lightGreen;
      case HealthLevel.moderate: return Colors.amber;
      case HealthLevel.needsAttention: return Colors.orange;
      case HealthLevel.critical: return Colors.red;
    }
  }

  Color _getMoodColor(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.lightGreen;
    if (score >= 2.5) return Colors.amber;
    if (score >= 1.5) return Colors.orange;
    return Colors.red;
  }
}

// ============ WIDGETS SEPARADOS ============

class _PatternsList extends ConsumerWidget {
  const _PatternsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final records = moodRepo.fetchMoodRecords().values.toList();

    if (records.length < 14) {
      return _buildEmptyState(context, 'Precisa de mais dados para detectar padrões');
    }

    final moodData = records.map((r) => MoodDataPoint(
      date: r.date,
      score: r.score.toDouble(),
      activities: r.activities.map((a) => a.activityName).toList(),
    )).toList();

    final engine = PatternEngine();
    final patterns = engine.detectTemporalPatterns(
      moodData: moodData,
      activityData: [],
    );

    if (patterns.isEmpty) {
      return _buildEmptyState(context, 'Nenhum padrão significativo detectado');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Padrões Detectados',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...patterns.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_getPatternIcon(p.type), style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Força: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        ...List.generate(5, (i) => Icon(
                          i < (p.strength * 5).round() ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.temporal: return '📅';
      case PatternType.behavioral: return '🎯';
      case PatternType.cyclical: return '🔄';
      case PatternType.correlation: return '🔗';
    }
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrelationsList extends ConsumerWidget {
  const _CorrelationsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final records = moodRepo.fetchMoodRecords().values.toList();

    if (records.length < 14) {
      return _buildEmptyState(context, 'Precisa de mais dados para calcular correlações');
    }

    // Calcula correlações simplificadas
    final correlations = _calculateSimpleCorrelations(records);

    if (correlations.isEmpty) {
      return _buildEmptyState(context, 'Nenhuma correlação significativa encontrada');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correlações Encontradas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...correlations.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (c['positive'] as bool ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (c['positive'] as bool ? Colors.green : Colors.red).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                c['positive'] as bool ? '↑' : '↓',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c['positive'] as bool ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['description'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'r = ${(c['coefficient'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  List<Map<String, dynamic>> _calculateSimpleCorrelations(List records) {
    final correlations = <Map<String, dynamic>>[];

    // Agrupa por atividade
    final activityScores = <String, List<int>>{};
    final noActivityScores = <int>[];

    for (final r in records) {
      if (r.activities.isEmpty) {
        noActivityScores.add(r.score);
      } else {
        for (final act in r.activities) {
          activityScores.putIfAbsent(act.name, () => []).add(r.score);
        }
      }
    }

    if (noActivityScores.isEmpty) return [];

    final baselineAvg = noActivityScores.reduce((a, b) => a + b) / noActivityScores.length;

    for (final entry in activityScores.entries) {
      if (entry.value.length >= 5) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final diff = avg - baselineAvg;

        if (diff.abs() > 0.3) {
          correlations.add({
            'activity': entry.key,
            'description': diff > 0
                ? '${entry.key} melhora seu humor'
                : '${entry.key} pode piorar seu humor',
            'coefficient': diff,
            'positive': diff > 0,
          });
        }
      }
    }

    correlations.sort((a, b) => (b['coefficient'] as double).abs().compareTo((a['coefficient'] as double).abs()));
    return correlations.take(6).toList();
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🔗', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
