import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/library/data/synced_book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(syncedBookRepositoryProvider);
    final allBooks = repo.getAllBooks();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors adapted to theme
    final accentGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    
    final totalBooks = allBooks.length;
    final readBooks = allBooks.where((b) => b.status == BookStatus.read).length;
    final readingBooks = allBooks.where((b) => b.status == BookStatus.inProgress).length;
    final toReadBooks = allBooks.where((b) => b.status == BookStatus.forLater).length;
    final abandonedBooks = allBooks.where((b) => b.status == BookStatus.unfinished).length;
    final totalPages = allBooks.fold(0, (sum, b) => (sum) + (b.status == BookStatus.read ? (b.pages ?? 0) : b.currentPage));
    final favouriteBooks = allBooks.where((b) => b.favourite).length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.onSurface),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.secondary.withValues(alpha: 0.08),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 16, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.estatisticasDeLeitura,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Acompanhe seu progresso',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary cards - 2x2 grid
                _buildSummaryGrid(context, totalBooks, readBooks, totalPages, favouriteBooks, colorScheme, accentGreen, isDark),
                const SizedBox(height: 32),
                
                // Status distribution
                _buildSectionHeader(context, 'Status da Biblioteca', Icons.pie_chart_rounded, colorScheme),
                const SizedBox(height: 20),
                _buildStatusCard(context, readBooks, readingBooks, toReadBooks, abandonedBooks, colorScheme, accentGreen, isDark),
                const SizedBox(height: 32),
                
                // Monthly chart
                _buildSectionHeader(context, 'Livros por Mês', Icons.bar_chart_rounded, colorScheme),
                const SizedBox(height: 16),
                _buildMonthlyChartCard(context, allBooks, colorScheme, isDark),
                const SizedBox(height: 32),
                
                // Genres
                _buildSectionHeader(context, 'Gêneros Favoritos', Icons.category_rounded, colorScheme),
                const SizedBox(height: 16),
                _buildGenreCard(context, allBooks, colorScheme, isDark),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, int total, int read, int pages, int favourites, ColorScheme colorScheme, Color accentGreen, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context, 'Total', '$total', Icons.library_books_rounded, 
                colorScheme.primary, colorScheme, isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context, 'Lidos', '$read', Icons.check_circle_rounded, 
                accentGreen, colorScheme, isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context, AppLocalizations.of(context)!.pages, '$pages', Icons.menu_book_rounded, 
                colorScheme.tertiary, colorScheme, isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context, 'Favoritos', '$favourites', Icons.favorite_rounded, 
                Colors.redAccent, colorScheme, isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.15 : 0.12),
            color.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.2)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, int read, int reading, int toRead, int abandoned, ColorScheme colorScheme, Color accentGreen, bool isDark) {
    final total = read + reading + toRead + abandoned;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (total == 0)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Adicione livros para ver estatísticas',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 45,
                  sections: [
                    if (read > 0)
                      PieChartSectionData(
                        color: accentGreen,
                        value: read.toDouble(),
                        title: '$read',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (reading > 0)
                      PieChartSectionData(
                        color: colorScheme.primary,
                        value: reading.toDouble(),
                        title: '$reading',
                        radius: 55,
                        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (toRead > 0)
                      PieChartSectionData(
                        color: colorScheme.tertiary,
                        value: toRead.toDouble(),
                        title: '$toRead',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (abandoned > 0)
                      PieChartSectionData(
                        color: colorScheme.error,
                        value: abandoned.toDouble(),
                        title: '$abandoned',
                        radius: 45,
                        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem(l10n.read, read, accentGreen, colorScheme),
                _buildLegendItem(l10n.reading, reading, colorScheme.primary, colorScheme),
                _buildLegendItem(l10n.toRead, toRead, colorScheme.tertiary, colorScheme),
                _buildLegendItem(l10n.abandoned, abandoned, colorScheme.error, colorScheme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChartCard(BuildContext context, List<Book> books, ColorScheme colorScheme, bool isDark) {
    final now = DateTime.now();
    final monthlyData = <int, int>{};
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = month.month + (month.year * 12);
      monthlyData[key] = 0;
    }
    
    for (var book in books) {
      if (book.status == BookStatus.read && book.latestFinishDate != null) {
        final finishDate = book.latestFinishDate!;
        final key = finishDate.month + (finishDate.year * 12);
        if (monthlyData.containsKey(key)) {
          monthlyData[key] = monthlyData[key]! + 1;
        }
      }
    }
    
    final sortedKeys = monthlyData.keys.toList()..sort();
    final maxValue = monthlyData.values.fold(0, (max, v) => v > max ? v : max);
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: maxValue == 0
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum livro terminado nos últimos 6 meses',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxValue + 1).toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => colorScheme.surfaceContainerHighest,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final key = sortedKeys[group.x];
                        final month = key % 12 == 0 ? 12 : key % 12;
                        return BarTooltipItem(
                          '${months[month - 1]}: ${rod.toY.toInt()} livros',
                          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            final key = sortedKeys[index];
                            final month = key % 12 == 0 ? 12 : key % 12;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[month - 1],
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble() && value >= 0) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: sortedKeys.asMap().entries.map((entry) {
                    final index = entry.key;
                    final key = entry.value;
                    final count = monthlyData[key] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [colorScheme.primary, colorScheme.secondary],
                          ),
                          width: 24,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (maxValue + 1).toDouble(),
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildGenreCard(BuildContext context, List<Book> books, ColorScheme colorScheme, bool isDark) {
    final genres = <String, int>{};
    for (var book in books) {
      if (book.genre != null && book.genre!.isNotEmpty) {
        genres[book.genre!] = (genres[book.genre!] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: genres.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.category_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Adicione gêneros aos seus livros',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : Column(
              children: (genres.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                  .take(5)
                  .map((entry) {
                final percentage = (entry.value / books.length);
                final colors = [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                  isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                  Colors.redAccent,
                ];
                final colorIndex = genres.keys.toList().indexOf(entry.key) % colors.length;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors[colorIndex].withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: TextStyle(
                                color: colors[colorIndex],
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(colors[colorIndex]),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
