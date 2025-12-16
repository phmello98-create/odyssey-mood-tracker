import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/language_learning_repository.dart';
import '../domain/language.dart';
import '../domain/study_session.dart';
import '../domain/vocabulary_item.dart';
import 'add_session_sheet.dart';
import 'vocabulary_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class LanguageDetailScreen extends ConsumerStatefulWidget {
  final String languageId;

  const LanguageDetailScreen({super.key, required this.languageId});

  @override
  ConsumerState<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends ConsumerState<LanguageDetailScreen> {
  late LanguageLearningRepository _repository;
  Language? _language;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(languageLearningRepositoryProvider);
    _loadLanguage();
  }

  void _loadLanguage() {
    setState(() {
      _language = _repository.getLanguage(widget.languageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_language == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: Text(AppLocalizations.of(context)!.idiomaNaoEncontrado)),
      );
    }

    final language = _language!;
    final color = Color(language.colorValue);
    final sessions = _repository.getSessionsForLanguage(language.id);
    final vocabulary = _repository.getVocabularyForLanguage(language.id);
    final activityStats = _repository.getMinutesPerActivityType(language.id);

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(colors, language, color),
          ),

          // Stats Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildStatsGrid(colors, language, vocabulary),
            ),
          ),

          // Activity breakdown
          if (activityStats.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildActivityBreakdown(colors, activityStats, color),
              ),
            ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildQuickActions(colors, language, vocabulary, color),
            ),
          ),

          // Sessions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.history, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO DE SESSÕES',
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

          // Sessions List
          if (sessions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 32, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma sessão ainda',
                          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= sessions.length) return null;
                  final session = sessions[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _buildSessionCard(colors, session, color),
                  );
                },
                childCount: sessions.length > 10 ? 10 : sessions.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSessionSheet(),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.estudar),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, Language language, Color color) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), colors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
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
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.onSurface),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditSheet(language);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(language);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 10), Text(AppLocalizations.of(context)!.editar)])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text('Excluir', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Language info
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    language.flag,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          language.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showLevelSelector(language),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  language.level,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit, size: 12, color: color),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LanguageLevels.getDescription(language.level),
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

  Widget _buildStatsGrid(ColorScheme colors, Language language, List<VocabularyItem> vocabulary) {
    final masteredCount = vocabulary.where((v) => v.status == VocabularyStatus.mastered).length;
    final needsReviewCount = vocabulary.where((v) => v.needsReview).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(colors, Icons.timer_outlined, language.formattedTotalTime, 'Tempo total', Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard(colors, Icons.local_fire_department, '${language.currentStreak}', 'Streak atual', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(colors, Icons.emoji_events, '${language.bestStreak}', 'Melhor streak', Colors.amber),
              const SizedBox(width: 12),
              _buildStatCard(colors, Icons.abc, '${vocabulary.length}', 'Palavras', Colors.purple),
            ],
          ),
          if (vocabulary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(colors, Icons.check_circle, '$masteredCount', 'Dominadas', const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildStatCard(colors, Icons.refresh, '$needsReviewCount', 'Para revisar', Colors.amber),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(ColorScheme colors, IconData icon, String value, String label, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBreakdown(ColorScheme colors, Map<String, int> activityStats, Color color) {
    final totalMinutes = activityStats.values.fold(0, (sum, v) => sum + v);
    if (totalMinutes == 0) return const SizedBox.shrink();

    final sortedActivities = activityStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'Distribuição por Atividade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedActivities.take(4).map((entry) {
            final percentage = (entry.value / totalMinutes * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        StudyActivityTypes.getIcon(entry.key),
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          StudyActivityTypes.getName(entry.key),
                          style: TextStyle(fontSize: 13, color: colors.onSurface),
                        ),
                      ),
                      Text(
                        '${entry.value}m',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colors, Language language, List<VocabularyItem> vocabulary, Color color) {
    final needsReview = vocabulary.where((v) => v.needsReview).length;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VocabularyScreen(
                    languageId: language.id,
                    languageName: language.name,
                    languageColor: color,
                  ),
                ),
              ).then((_) => _loadLanguage());
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.abc, size: 28, color: Colors.purple),
                  const SizedBox(height: 8),
                  Text(
                    'Vocabulário',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    '${vocabulary.length} palavras',
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: needsReview > 0
                ? () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VocabularyScreen(
                          languageId: language.id,
                          languageName: language.name,
                          languageColor: color,
                          showReviewMode: true,
                        ),
                      ),
                    ).then((_) => _loadLanguage());
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: needsReview > 0
                    ? Colors.amber.withValues(alpha: 0.1)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: needsReview > 0
                      ? Colors.amber.withValues(alpha: 0.2)
                      : colors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 28,
                    color: needsReview > 0 ? Colors.amber : colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: needsReview > 0 ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    needsReview > 0 ? '$needsReview pendentes' : 'Tudo em dia!',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
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

  Widget _buildSessionCard(ColorScheme colors, StudySession session, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              StudyActivityTypes.getIcon(session.activityType),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StudyActivityTypes.getName(session.activityType),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                if (session.resource != null)
                  Text(
                    session.resource!,
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.formattedDuration,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                _formatDate(session.startTime),
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          if (session.rating != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                Text(
                  '${session.rating}',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSessionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddSessionSheet(
        repository: _repository,
        preselectedLanguageId: widget.languageId,
      ),
    ).then((_) => _loadLanguage());
  }

  void _showLevelSelector(Language language) {
    final colors = Theme.of(context).colorScheme;
    final color = Color(language.colorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Atualizar Nível',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: LanguageLevels.levels.map((level) {
                final isSelected = language.level == level;
                return GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await _repository.updateLanguage(language.copyWith(level: level));
                    _loadLanguage();
                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.2) : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : colors.outline.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          level,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LanguageLevels.getDescription(level),
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(Language language) {
    // TODO: Implement edit sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.edicaoEmBreve)),
    );
  }

  void _showDeleteConfirmation(Language language) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text('Excluir ${language.name}?', style: TextStyle(color: colors.onSurface, fontSize: 18)),
          ],
        ),
        content: Text(
          'Isso irá excluir permanentemente o idioma, todas as sessões de estudo e palavras de vocabulário associadas.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _repository.deleteLanguage(language.id);
              if (mounted) {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Screen
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoje, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
