import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/language_learning_repository.dart';
import '../domain/language.dart';

class StudyStatsScreen extends ConsumerStatefulWidget {
  const StudyStatsScreen({super.key});

  @override
  ConsumerState<StudyStatsScreen> createState() => _StudyStatsScreenState();
}

class _StudyStatsScreenState extends ConsumerState<StudyStatsScreen> {
  late LanguageLearningRepository _repository;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = ref.read(languageLearningRepositoryProvider);
    await _repository.init();
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final languages = _repository.getAllLanguages();
    final weeklyMinutes = _repository.getWeeklyStudyMinutes();
    final totalMinutes = _repository.getTotalMinutesStudied();
    final totalVocab = _repository.getTotalVocabularyCount();
    final masteredVocab = _repository.getMasteredVocabularyCount();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(colors),
            ),

            // Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildSummaryCard(colors, totalMinutes, totalVocab, masteredVocab, languages.length),
              ),
            ),

            // Weekly Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildWeeklyChart(colors, weeklyMinutes),
              ),
            ),

            // Language Breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'TEMPO POR IDIOMA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Language time breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLanguageBreakdown(colors, languages, totalMinutes),
              ),
            ),

            // Achievements
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'CONQUISTAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAchievements(colors, languages, totalMinutes, totalVocab),
              ),
            ),

            // Study Insights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'INSIGHTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _buildInsights(colors, languages, weeklyMinutes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary.withValues(alpha: 0.15), colors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Seu progresso em detalhes',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colors, int totalMinutes, int totalVocab, int masteredVocab, int langCount) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Main stat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, size: 32, color: colors.primary),
              const SizedBox(width: 12),
              Text(
                '${hours}h ${mins}m',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total de estudo',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(colors, '$langCount', 'Idiomas', Icons.language, Colors.blue),
              _buildMiniStat(colors, '$totalVocab', 'Palavras', Icons.abc, Colors.purple),
              _buildMiniStat(colors, '$masteredVocab', 'Dominadas', Icons.check_circle, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ColorScheme colors, String value, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ColorScheme colors, Map<int, int> weeklyMinutes) {
    final maxMinutes = weeklyMinutes.values.isEmpty ? 1 : weeklyMinutes.values.reduce((a, b) => a > b ? a : b);
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Últimos 7 dias',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${weeklyMinutes.values.fold(0, (a, b) => a + b)} min total',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final minutes = weeklyMinutes[index] ?? 0;
                final height = maxMinutes > 0 ? (minutes / maxMinutes * 80).clamp(4.0, 80.0) : 4.0;
                final dayIndex = (now.weekday - 7 + index) % 7;
                final isToday = index == 6;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (minutes > 0)
                          Text(
                            '${minutes}m',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isToday ? colors.primary : colors.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [colors.primary, colors.primary.withValues(alpha: 0.6)]
                                  : [colors.primary.withValues(alpha: 0.4), colors.primary.withValues(alpha: 0.2)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[dayIndex],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isToday ? colors.primary : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBreakdown(ColorScheme colors, List<Language> languages, int totalMinutes) {
    if (languages.isEmpty || totalMinutes == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Nenhum dado ainda',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final sortedLanguages = List<Language>.from(languages)
      ..sort((a, b) => b.totalMinutesStudied.compareTo(a.totalMinutesStudied));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: sortedLanguages.map((lang) {
          final percentage = (lang.totalMinutesStudied / totalMinutes * 100).round();
          final color = Color(lang.colorValue);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      lang.flag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
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
                            lang.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            '${lang.formattedTotalTime} ($percentage%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: colors.outline.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievements(ColorScheme colors, List<Language> languages, int totalMinutes, int totalVocab) {
    final achievements = <Map<String, dynamic>>[];

    // Check achievements
    if (totalMinutes >= 60) {
      achievements.add({'icon': Icons.timer, 'title': 'Primeira Hora', 'desc': '1 hora de estudo', 'color': Colors.blue, 'unlocked': true});
    }
    if (totalMinutes >= 600) {
      achievements.add({'icon': Icons.local_fire_department, 'title': '10 Horas', 'desc': '10 horas de estudo', 'color': Colors.orange, 'unlocked': true});
    }
    if (totalMinutes >= 3000) {
      achievements.add({'icon': Icons.star, 'title': 'Dedicado', 'desc': '50 horas de estudo', 'color': Colors.amber, 'unlocked': true});
    }
    if (languages.length >= 2) {
      achievements.add({'icon': Icons.language, 'title': 'Poliglota', 'desc': 'Estudando 2+ idiomas', 'color': Colors.purple, 'unlocked': true});
    }
    if (totalVocab >= 50) {
      achievements.add({'icon': Icons.abc, 'title': 'Vocabulário Rico', 'desc': '50+ palavras', 'color': Colors.teal, 'unlocked': true});
    }
    if (languages.any((l) => l.currentStreak >= 7)) {
      achievements.add({'icon': Icons.whatshot, 'title': 'Semana Perfeita', 'desc': '7 dias seguidos', 'color': Colors.red, 'unlocked': true});
    }

    // Add locked achievements
    if (totalMinutes < 60) {
      achievements.add({'icon': Icons.timer, 'title': 'Primeira Hora', 'desc': 'Estude 1 hora', 'color': Colors.grey, 'unlocked': false});
    }
    if (languages.length < 2) {
      achievements.add({'icon': Icons.language, 'title': 'Poliglota', 'desc': 'Estude 2+ idiomas', 'color': Colors.grey, 'unlocked': false});
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: achievements.map((a) {
        final isUnlocked = a['unlocked'] as bool;
        return Container(
          width: (MediaQuery.of(context).size.width - 50) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnlocked
                ? (a['color'] as Color).withValues(alpha: 0.1)
                : colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked
                  ? (a['color'] as Color).withValues(alpha: 0.3)
                  : colors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                a['icon'] as IconData,
                size: 28,
                color: isUnlocked ? a['color'] as Color : colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? colors.onSurface : colors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      a['desc'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceVariant.withValues(alpha: isUnlocked ? 1 : 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                Icon(Icons.check_circle, size: 16, color: a['color'] as Color),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsights(ColorScheme colors, List<Language> languages, Map<int, int> weeklyMinutes) {
    final insights = <Map<String, dynamic>>[];

    // Calculate insights
    final todayMinutes = weeklyMinutes[6] ?? 0;
    final weekTotal = weeklyMinutes.values.fold(0, (a, b) => a + b);
    final avgDaily = weekTotal ~/ 7;

    if (todayMinutes > avgDaily && avgDaily > 0) {
      insights.add({
        'icon': Icons.trending_up,
        'text': 'Você está ${((todayMinutes / avgDaily - 1) * 100).round()}% acima da sua média diária hoje!',
        'color': const Color(0xFF10B981),
      });
    }

    if (languages.isNotEmpty) {
      final bestStreak = languages.map((l) => l.currentStreak).reduce((a, b) => a > b ? a : b);
      if (bestStreak > 0) {
        insights.add({
          'icon': Icons.local_fire_department,
          'text': 'Seu maior streak atual é de $bestStreak dias!',
          'color': Colors.orange,
        });
      }
    }

    if (weekTotal > 0) {
      final booksEquivalent = (weekTotal / 30).toStringAsFixed(1);
      insights.add({
        'icon': Icons.menu_book,
        'text': 'Essa semana você estudou o equivalente a ~$booksEquivalent capítulos de um livro!',
        'color': Colors.purple,
      });
    }

    if (todayMinutes == 0 && languages.isNotEmpty) {
      insights.add({
        'icon': Icons.lightbulb,
        'text': 'Ainda não estudou hoje. Que tal uma sessão rápida de 15 minutos?',
        'color': Colors.amber,
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.rocket_launch,
        'text': 'Comece a estudar para ver seus insights personalizados!',
        'color': colors.primary,
      });
    }

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (insight['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (insight['color'] as Color).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(insight['icon'] as IconData, size: 24, color: insight['color'] as Color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight['text'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
