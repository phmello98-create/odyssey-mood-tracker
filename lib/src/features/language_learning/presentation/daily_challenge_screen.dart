import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../data/language_learning_repository.dart';
import '../domain/study_session.dart';
import 'add_session_sheet.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  late LanguageLearningRepository _repository;
  bool _isInitialized = false;
  List<DailyChallenge> _todayChallenges = [];

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = ref.read(languageLearningRepositoryProvider);
    await _repository.init();
    _generateDailyChallenges();
    if (mounted) setState(() => _isInitialized = true);
  }

  void _generateDailyChallenges() {
    final languages = _repository.getAllLanguages();
    final random = Random(DateTime.now().day + DateTime.now().month * 31);
    
    _todayChallenges = [];

    // Challenge 1: Study time goal
    final timeGoal = [15, 20, 25, 30, 45][random.nextInt(5)];
    final todayMinutes = _repository.getSessionsForDate(DateTime.now())
        .fold(0, (sum, s) => sum + s.durationMinutes);
    _todayChallenges.add(DailyChallenge(
      id: 'time_goal',
      icon: Icons.timer_outlined,
      title: 'Estudar $timeGoal minutos',
      description: 'Complete $timeGoal minutos de estudo hoje',
      progress: todayMinutes,
      goal: timeGoal,
      xpReward: timeGoal * 2,
      color: Colors.blue,
    ));

    // Challenge 2: Specific activity
    if (languages.isNotEmpty) {
      final activities = StudyActivityTypes.all;
      final randomActivity = activities[random.nextInt(activities.length)];
      final activitySessions = _repository.getSessionsForDate(DateTime.now())
          .where((s) => s.activityType == randomActivity['id'])
          .fold(0, (sum, s) => sum + s.durationMinutes);
      
      _todayChallenges.add(DailyChallenge(
        id: 'activity_${randomActivity['id']}',
        icon: StudyActivityTypes.getIcon(randomActivity['id']),
        title: '${randomActivity['name']} por 10 min',
        description: 'Pratique ${randomActivity['name'].toLowerCase()} por 10 minutos',
        progress: activitySessions,
        goal: 10,
        xpReward: 30,
        color: Colors.purple,
      ));
    }

    // Challenge 3: Vocabulary review
    final vocabToReview = _repository.getAllVocabulary().where((v) => v.needsReview).length;
    final reviewedToday = _repository.getAllVocabulary()
        .where((v) => v.lastReviewedAt != null && 
            v.lastReviewedAt!.day == DateTime.now().day)
        .length;
    
    if (vocabToReview > 0 || reviewedToday > 0) {
      final reviewGoal = min(5, max(1, vocabToReview));
      _todayChallenges.add(DailyChallenge(
        id: 'vocab_review',
        icon: Icons.refresh,
        title: 'Revisar $reviewGoal palavras',
        description: 'Complete a revisão de vocabulário',
        progress: reviewedToday,
        goal: reviewGoal,
        xpReward: reviewGoal * 10,
        color: Colors.amber,
      ));
    }

    // Challenge 4: Add new vocabulary
    final todayVocab = _repository.getAllVocabulary()
        .where((v) => v.createdAt.day == DateTime.now().day && 
            v.createdAt.month == DateTime.now().month)
        .length;
    _todayChallenges.add(DailyChallenge(
      id: 'new_vocab',
      icon: Icons.add_circle_outline,
      title: 'Aprender 3 palavras',
      description: 'Adicione 3 novas palavras ao vocabulário',
      progress: todayVocab,
      goal: 3,
      xpReward: 25,
      color: const Color(0xFF10B981),
    ));

    // Challenge 5: Streak maintenance
    if (languages.isNotEmpty) {
      final bestStreak = languages.map((l) => l.currentStreak).reduce((a, b) => a > b ? a : b);
      final studiedToday = _repository.hasStudiedToday();
      _todayChallenges.add(DailyChallenge(
        id: 'streak',
        icon: Icons.local_fire_department,
        title: 'Manter o streak',
        description: 'Não quebre sua sequência de ${bestStreak + (studiedToday ? 0 : 1)} dias',
        progress: studiedToday ? 1 : 0,
        goal: 1,
        xpReward: 20 + (bestStreak * 5),
        color: Colors.orange,
      ));
    }
  }

  int get _totalXpAvailable => _todayChallenges.fold(0, (sum, c) => sum + c.xpReward);
  int get _earnedXp => _todayChallenges.where((c) => c.isCompleted).fold(0, (sum, c) => sum + c.xpReward);
  int get _completedCount => _todayChallenges.where((c) => c.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

            // Progress summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildProgressSummary(colors),
              ),
            ),

            // Challenges list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'DESAFIOS DE HOJE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_completedCount/${_todayChallenges.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final challenge = _todayChallenges[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _buildChallengeCard(colors, challenge),
                  );
                },
                childCount: _todayChallenges.length,
              ),
            ),

            // Tips section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'DICA DO DIA',
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
                child: _buildDailyTip(colors),
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
          colors: [Colors.orange.withValues(alpha: 0.15), colors.surface],
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
                Row(
                  children: [
                    Text(
                      'Desafio Diário',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            '+$_totalXpAvailable XP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Complete desafios e ganhe XP!',
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

  Widget _buildProgressSummary(ColorScheme colors) {
    final progress = _todayChallenges.isEmpty 
        ? 0.0 
        : _completedCount / _todayChallenges.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.amber.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progresso do Dia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (progress >= 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'Completo!',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'XP Ganho',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 20, color: Colors.orange),
                      Text(
                        '$_earnedXp',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? const Color(0xFF10B981) : Colors.orange,
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ColorScheme colors, DailyChallenge challenge) {
    final progress = challenge.goal > 0 ? challenge.progress / challenge.goal : 0.0;
    final isCompleted = challenge.isCompleted;

    return GestureDetector(
      onTap: isCompleted ? null : () => _showQuickAction(challenge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : challenge.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : challenge.color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : challenge.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check : challenge.icon,
                size: 24,
                color: isCompleted ? const Color(0xFF10B981) : challenge.color,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: colors.outline.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              isCompleted ? const Color(0xFF10B981) : challenge.color,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${challenge.progress}/${challenge.goal}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 14,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.orange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '+${challenge.xpReward}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? const Color(0xFF10B981) : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTip(ColorScheme colors) {
    final tips = [
      {'icon': Icons.access_time, 'tip': 'Estudar pouco todo dia é mais eficaz do que maratonas ocasionais. Tente manter sessões de 15-30 minutos.'},
      {'icon': Icons.repeat, 'tip': 'A repetição espaçada ajuda a fixar vocabulário. Revise palavras regularmente!'},
      {'icon': Icons.headphones, 'tip': 'Misture diferentes atividades: leitura, escuta, fala e escrita para um aprendizado mais completo.'},
      {'icon': Icons.movie, 'tip': 'Assista séries e filmes no idioma que está aprendendo com legendas para imersão natural.'},
      {'icon': Icons.music_note, 'tip': 'Músicas são ótimas para aprender expressões e melhorar a pronúncia. Cante junto!'},
      {'icon': Icons.chat, 'tip': 'Pratique conversação sempre que possível. Falar em voz alta ajuda a fixar o aprendizado.'},
      {'icon': Icons.book, 'tip': 'Comece com livros infantis ou adaptados. Gradualmente aumente a dificuldade.'},
    ];

    final tip = tips[DateTime.now().day % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip['icon'] as IconData, size: 24, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip['tip'] as String,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAction(DailyChallenge challenge) {
    if (challenge.id.startsWith('time') || challenge.id.startsWith('activity')) {
      // Open add session sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => AddSessionSheet(repository: _repository),
      ).then((_) {
        _generateDailyChallenges();
        setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.completeEsteDesafioNaTelaCorrespondente),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class DailyChallenge {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final int progress;
  final int goal;
  final int xpReward;
  final Color color;

  DailyChallenge({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.progress,
    required this.goal,
    required this.xpReward,
    required this.color,
  });

  bool get isCompleted => progress >= goal;
}
