import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen_controller.dart';
import 'package:odyssey/src/utils/icon_map.dart';
import 'package:odyssey/src/utils/widgets/staggered_list_animation.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class MoodRecordsScreen extends ConsumerStatefulWidget {
  const MoodRecordsScreen({super.key});

  static void showAddMoodRecordForm(
      context, MapEntry<dynamic, MoodRecord>? recordToEdit) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddMoodRecordForm(recordToEdit: recordToEdit),
      ),
    );
  }

  @override
  ConsumerState<MoodRecordsScreen> createState() => _MoodRecordsScreenState();
}

class _MoodRecordsScreenState extends ConsumerState<MoodRecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  
  // Showcase keys
  final GlobalKey _showcaseMoodChart = GlobalKey();
  final GlobalKey _showcaseAddMood = GlobalKey();
  final GlobalKey _showcaseMoodList = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
  }
  
  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.moodLog);
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcaseMoodChart, _showcaseAddMood, _showcaseMoodList];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.moodLog,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.moodLog, keys);
  }

  void _startTour() {
    final keys = [_showcaseMoodChart, _showcaseAddMood, _showcaseMoodList];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.moodLog, keys);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(moodRecordScreenControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.surface,
      body: ValueListenableBuilder(
        valueListenable: controller.repository.box.listenable(),
        builder: (context, box, _) {
          final allRecords = box.values.toList().cast<MoodRecord>();
          
          final now = DateTime.now();
          final last7Days = List.generate(7, (i) {
            final d = now.subtract(Duration(days: 6 - i));
            return DateTime(d.year, d.month, d.day);
          });
          
          double averageMood = 0;
          if (allRecords.isNotEmpty) {
            averageMood = allRecords.map((e) => e.score).reduce((a, b) => a + b) / allRecords.length;
          }

          // Calcular estatísticas
          final todayRecords = allRecords.where((r) => _isSameDay(r.date, now)).length;
          final weekRecords = allRecords.where((r) => 
            r.date.isAfter(now.subtract(const Duration(days: 7)))
          ).length;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Header refinado
                  SliverToBoxAdapter(
                    child: _buildHeader(colors, allRecords.length, todayRecords),
                  ),

                  // Stats Cards
                  SliverToBoxAdapter(
                    child: _buildStatsRow(colors, averageMood, weekRecords, allRecords.length),
                  ),

                  // Gráfico refinado
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _buildChartSection(colors, allRecords, last7Days, averageMood),
                    ),
                  ),

                  // Mood Distribution
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildMoodDistribution(colors, allRecords),
                    ),
                  ),

                  // Date Selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildDateSelector(colors),
                    ),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 20, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.dailyRecords,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Records List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: _buildRecordsList(allRecords, colors),
                  ),
                ],
              ),
              
              // Botão de adicionar centralizado na parte inferior
              _buildBottomAddButton(colors),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, int totalRecords, int todayRecords) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withValues(alpha: 0.3),
            colors.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.moodDiary,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.emotionalJourney,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colors, double avgMood, int weekRecords, int totalRecords) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              colors: colors,
              icon: Icons.auto_graph_rounded,
              value: avgMood.toStringAsFixed(1),
              label: l10n.priorityMedium,
              color: _getMoodColor(avgMood),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              colors: colors,
              icon: Icons.calendar_today_rounded,
              value: '$weekRecords',
              label: l10n.thisWeekLabel,
              color: colors.tertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              colors: colors,
              icon: Icons.bar_chart_rounded,
              value: '$totalRecords',
              label: l10n.totalLabel,
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ColorScheme colors,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
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
              fontSize: 11,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(ColorScheme colors, List<MoodRecord> allRecords, List<DateTime> days, double avgMood) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.last7Days,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMoodColor(avgMood).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: _getMoodColor(avgMood),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.average(avgMood.toStringAsFixed(1)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getMoodColor(avgMood),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: _MoodChart(records: allRecords, days: days, colors: colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution(ColorScheme colors, List<MoodRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    final moodCounts = <int, int>{};
    for (final record in records) {
      moodCounts[record.score] = (moodCounts[record.score] ?? 0) + 1;
    }

    final moodLabels = {5: 'Ótimo', 4: 'Bem', 3: 'Ok', 2: 'Mal', 1: 'Péssimo'};
    final moodColors = {
      5: UltravioletColors.moodGreat,
      4: UltravioletColors.moodGood,
      3: UltravioletColors.moodOkay,
      2: UltravioletColors.moodBad,
      1: UltravioletColors.moodTerrible,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 20, color: colors.secondary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.moodDistribution,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(moodCounts.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)))
            .map((entry) {
              final percentage = (entry.value / records.length * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: moodColors[entry.key]!.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _getMoodEmoji(entry.key),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                moodLabels[entry.key] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: moodColors[entry.key],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: colors.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(moodColors[entry.key]),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ColorScheme colors) {
    final today = DateTime.now();
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: 7 - index));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, today);
          final hasMoodRecord = _hasMoodRecordForDate(date);
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected 
                    ? null 
                    : isToday 
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayAbbr(date.weekday),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.8)
                          : colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasMoodRecord
                          ? (isSelected ? Colors.white : UltravioletColors.moodGood)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsList(List<MoodRecord> allRecords, ColorScheme colors) {
    final filteredRecords = allRecords
        .where((record) => _isSameDay(record.date, _selectedDate))
        .toList();

    if (filteredRecords.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(colors),
      );
    }

    filteredRecords.sort((a, b) => b.date.compareTo(a.date));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final record = filteredRecords[index];
          return StaggeredListAnimation(
            index: index,
            child: _buildMoodCard(record, index, colors),
          );
        },
        childCount: filteredRecords.length,
      ),
    );
  }

  Widget _buildMoodCard(MoodRecord record, int index, ColorScheme colors) {
    final moodColor = Color(record.color);
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final controller = ref.read(moodRecordScreenControllerProvider.notifier);
            final entry = controller.repository.box.toMap().entries
                .firstWhere((e) => e.value == record);
            MoodRecordsScreen.showAddMoodRecordForm(context, entry);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: moodColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Time column
                Column(
                  children: [
                    Text(
                      timeFormat.format(record.date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [moodColor, moodColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: moodColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getMoodEmojiFromLabel(record.label),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: moodColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              record.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: moodColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                      if (record.note != null && record.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          record.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (record.activities.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: record.activities.take(3).map((activity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    OdysseyIcons.fromCodePoint(activity.iconCode),
                                    size: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.activityName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.sentiment_satisfied_alt_rounded,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noRecords,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tapToRecordMood,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAddButton(ColorScheme colors) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            MoodRecordsScreen.showAddMoodRecordForm(context, null);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.recordMood,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(double score) {
    if (score >= 4.5) return UltravioletColors.moodGreat;
    if (score >= 3.5) return UltravioletColors.moodGood;
    if (score >= 2.5) return UltravioletColors.moodOkay;
    if (score >= 1.5) return UltravioletColors.moodBad;
    return UltravioletColors.moodTerrible;
  }

  String _getMoodEmoji(int score) {
    final emojis = {5: '😊', 4: '🙂', 3: '😐', 2: '😔', 1: '😢'};
    return emojis[score] ?? '😐';
  }

  String _getMoodEmojiFromLabel(String label) {
    final moodEmojis = {
      'Great': '😊', 'Good': '🙂', 'Okay': '😐', 'Bad': '😔', 'Terrible': '😢',
      'Ótimo': '😊', 'Bem': '🙂', 'Ok': '😐', 'Triste': '😔', 'Mal': '😢',
    };
    return moodEmojis[label] ?? '😐';
  }

  String _getWeekdayAbbr(int weekday) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[weekday - 1];
  }

  bool _hasMoodRecordForDate(DateTime date) {
    final controller = ref.read(moodRecordScreenControllerProvider.notifier);
    final allRecords = controller.repository.box.values.toList().cast<MoodRecord>();
    return allRecords.any((record) => _isSameDay(record.date, date));
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }
}

class _MoodChart extends StatelessWidget {
  final List<MoodRecord> records;
  final List<DateTime> days;
  final ColorScheme colors;

  const _MoodChart({
    required this.records,
    required this.days,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight - 24;

        final dailyMoods = days.map((day) {
          final dayRecords = records.where((r) => 
            r.date.year == day.year && 
            r.date.month == day.month && 
            r.date.day == day.day
          ).toList();
          
          if (dayRecords.isEmpty) return null;
          
          final sum = dayRecords.map((r) => r.score).reduce((a, b) => a + b);
          return sum / dayRecords.length;
        }).toList();

        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size(width, height),
                painter: _ChartPainter(
                  dailyMoods: dailyMoods,
                  color: colors.primary,
                  gradientColors: [
                    colors.primary.withValues(alpha: 0.4),
                    colors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                return Text(
                  DateFormat('E', 'pt_BR').format(day)[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double?> dailyMoods;
  final Color color;
  final List<Color> gradientColors;

  _ChartPainter({
    required this.dailyMoods,
    required this.color,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();
    bool firstPoint = true;
    final segmentWidth = size.width / dailyMoods.length;

    for (int i = 0; i < dailyMoods.length; i++) {
      final mood = dailyMoods[i];
      if (mood == null) continue;

      final normalizedY = size.height - ((mood - 1) / 4 * size.height);
      final x = (i * segmentWidth) + (segmentWidth / 2);

      if (firstPoint) {
        path.moveTo(x, normalizedY);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, normalizedY);
        firstPoint = false;
      } else {
        final prevMood = _findPrevMood(i - 1);
        if (prevMood != null) {
          final prevX = ((i - 1) * segmentWidth) + (segmentWidth / 2);
          final prevY = size.height - ((prevMood - 1) / 4 * size.height);
          
          final controlPoint1X = prevX + (x - prevX) / 2;
          final controlPoint1Y = prevY;
          final controlPoint2X = prevX + (x - prevX) / 2;
          final controlPoint2Y = normalizedY;

          path.cubicTo(controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y, x, normalizedY);
          fillPath.cubicTo(controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y, x, normalizedY);
        } else {
          path.lineTo(x, normalizedY);
          fillPath.lineTo(x, normalizedY);
        }
      }
      
      // Dot com glow
      canvas.drawCircle(
        Offset(x, normalizedY),
        6,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(x, normalizedY), 5, Paint()..color = color);
      canvas.drawCircle(Offset(x, normalizedY), 2.5, Paint()..color = Colors.white);
    }
    
    if (!firstPoint) {
      final lastIndex = _findLastIndex();
      final lastX = (lastIndex * segmentWidth) + (segmentWidth / 2);
      fillPath.lineTo(lastX, size.height);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, Paint()..shader = gradient);
      canvas.drawPath(path, paint);
    }
  }

  double? _findPrevMood(int index) {
    for (int i = index; i >= 0; i--) {
      if (dailyMoods[i] != null) return dailyMoods[i];
    }
    return null;
  }
  
  int _findLastIndex() {
    for (int i = dailyMoods.length - 1; i >= 0; i--) {
      if (dailyMoods[i] != null) return i;
    }
    return 0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
