import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/user_stats.dart';

// ============================================================
// WELLNESS SCORE - Design elegante com breakdown
// ============================================================

class WellnessScoreCard extends StatelessWidget {
  final int score;
  final String emoji;
  final String description;
  final Animation<double> animation;
  final int streakScore;
  final int moodScore;
  final int activityScore;
  final int engagementScore;

  const WellnessScoreCard({
    super.key,
    required this.score,
    required this.emoji,
    required this.description,
    required this.animation,
    this.streakScore = 0,
    this.moodScore = 0,
    this.activityScore = 0,
    this.engagementScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scoreColor = _getScoreColor(score);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(animation.value);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scoreColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Ring e Score
              Row(
                children: [
                  // Ring de progresso
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(100, 100),
                          painter: _WellnessRingPainter(
                            progress: (score / 100) * progress,
                            backgroundColor: colors.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                            foregroundColor: scoreColor,
                            strokeWidth: 10,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                            Text(
                              '${(score * progress).round()}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-estar',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini breakdown
                        _buildBreakdownBars(colors, progress),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownBars(ColorScheme colors, double animProgress) {
    return Column(
      children: [
        _miniBar(
          'Consistência',
          streakScore,
          const Color(0xFFFF6B6B),
          animProgress,
          colors,
        ),
        const SizedBox(height: 6),
        _miniBar(
          'Humor',
          moodScore,
          const Color(0xFFFFA94D),
          animProgress,
          colors,
        ),
        const SizedBox(height: 6),
        _miniBar(
          'Atividade',
          activityScore,
          const Color(0xFF51CF66),
          animProgress,
          colors,
        ),
        const SizedBox(height: 6),
        _miniBar(
          'Engajamento',
          engagementScore,
          const Color(0xFF339AF0),
          animProgress,
          colors,
        ),
      ],
    );
  }

  Widget _miniBar(
    String label,
    int value,
    Color color,
    double animProgress,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 100).clamp(0.0, 1.0) * animProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF51CF66);
    if (score >= 60) return const Color(0xFF339AF0);
    if (score >= 40) return const Color(0xFFFFA94D);
    if (score >= 20) return const Color(0xFFFF6B6B);
    return const Color(0xFFFA5252);
  }
}

class _WellnessRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  _WellnessRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress with gradient
    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [foregroundColor.withValues(alpha: 0.6), foregroundColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WellnessRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================
// PROFILE HEADER - Elegante com XP Bar estilo MMORPG
// ============================================================

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String? avatarPath;
  final String? bannerPath;
  final String title;
  final String titleEmoji;
  final String? bio;
  final String? currentMood;
  final int level;
  final int currentXP;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int currentMana;
  final int maxMana;
  final int daysSinceJoined;
  final int streak;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBannerTap;

  const ProfileHeader({
    super.key,
    required this.userName,
    this.avatarPath,
    this.bannerPath,
    required this.title,
    required this.titleEmoji,
    this.bio,
    this.currentMood,
    required this.level,
    this.currentXP = 0,
    this.xpForCurrentLevel = 0,
    this.xpForNextLevel = 100,
    this.currentMana = 100,
    this.maxMana = 100,
    required this.daysSinceJoined,
    required this.streak,
    required this.onEditProfile,
    required this.onSettings,
    this.onAvatarTap,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Calcular progresso do XP
    final xpInLevel = currentXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    final xpProgress = xpNeeded > 0
        ? (xpInLevel / xpNeeded).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        // === BANNER ===
        GestureDetector(
          onTap: onBannerTap ?? onEditProfile,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: bannerPath == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary.withValues(alpha: 0.3),
                        colors.secondary.withValues(alpha: 0.2),
                        colors.tertiary.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              image: bannerPath != null
                  ? DecorationImage(
                      image: FileImage(File(bannerPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colors.surface.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                // Edit hint
                if (bannerPath == null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Banner',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // === CONTENT ===
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // Actions row at top
              Transform.translate(
                offset: const Offset(0, -50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mood indicator
                    if (currentMood != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMood!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Agora',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    // Edit button only
                    _actionButton(Icons.edit_outlined, onEditProfile, colors),
                  ],
                ),
              ),

              // Avatar centrado com overlap no banner
              Transform.translate(
                offset: const Offset(0, -70),
                child: GestureDetector(
                  onTap: onAvatarTap != null
                      ? () {
                          HapticFeedback.selectionClick();
                          onAvatarTap!();
                        }
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarPath != null
                              ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [colors.primary, colors.tertiary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Level badge
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'Nv.$level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Name and XP/MP Bars
              Transform.translate(
                offset: const Offset(0, -60),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // XP and MP bars
                    SizedBox(
                      width: 180,
                      child: Column(
                        children: [
                          _buildBar(
                            'XP',
                            xpProgress,
                            const Color(0xFF22C55E),
                            const Color(0xFF4ADE80),
                          ),
                          const SizedBox(height: 4),
                          _buildBar(
                            'MP',
                            maxMana > 0
                                ? (currentMana / maxMana).clamp(0.0, 1.0)
                                : 1.0,
                            const Color(0xFF3B82F6),
                            const Color(0xFF60A5FA),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(titleEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    // Bio
                    if (bio != null && bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Stats chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statChip('📅', '$daysSinceJoined dias', colors),
                        const SizedBox(width: 10),
                        _statChip('🔥', '$streak streak', colors),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String label, double progress, Color color1, Color color2) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color1,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color1, color2]),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color1.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _statChip(String emoji, String text, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATS CAROUSEL - Cards horizontais
// ============================================================

class StatsCarousel extends StatelessWidget {
  final int moodRecords;
  final int tasksCompleted;
  final int pomodoroSessions;
  final int timeTrackedMinutes;
  final int habitsCompleted;
  final int notesCreated;

  const StatsCarousel({
    super.key,
    required this.moodRecords,
    required this.tasksCompleted,
    required this.pomodoroSessions,
    required this.timeTrackedMinutes,
    required this.habitsCompleted,
    required this.notesCreated,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final stats = [
      _StatData(
        '😊',
        moodRecords.toString(),
        'Check-ins',
        const Color(0xFFFFA94D),
      ),
      _StatData(
        '✅',
        tasksCompleted.toString(),
        'Tarefas',
        const Color(0xFF51CF66),
      ),
      _StatData(
        '🍅',
        pomodoroSessions.toString(),
        'Pomodoros',
        const Color(0xFFFF6B6B),
      ),
      _StatData(
        '⏱️',
        _formatTime(timeTrackedMinutes),
        'Foco',
        const Color(0xFF339AF0),
      ),
      _StatData(
        '🎯',
        habitsCompleted.toString(),
        'Hábitos',
        const Color(0xFFB197FC),
      ),
      _StatData(
        '📝',
        notesCreated.toString(),
        'Notas',
        const Color(0xFFFF922B),
      ),
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(stat, colors);
        },
      ),
    );
  }

  Widget _buildStatCard(_StatData stat, ColorScheme colors) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.color.withValues(alpha: 0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(stat.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            Text(
              stat.label,
              style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h';
  }
}

class _StatData {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  _StatData(this.emoji, this.value, this.label, this.color);
}

// ============================================================
// PERSONAL GOALS - Design elegante
// ============================================================

class PersonalGoalsCard extends StatelessWidget {
  final List<PersonalGoal> goals;
  final ColorScheme colors;
  final VoidCallback onAddGoal;
  final VoidCallback? onViewAll;
  final void Function(PersonalGoal goal)? onGoalTap;

  const PersonalGoalsCard({
    super.key,
    required this.goals,
    required this.colors,
    required this.onAddGoal,
    this.onViewAll,
    this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeGoals = goals.where((g) => !g.isCompleted).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metas',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              GestureDetector(
                onTap: onAddGoal,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add, size: 18, color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goals list
          if (activeGoals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma meta ativa',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeGoals.map(
              (goal) => PremiumGoalCard(
                goal: goal,
                onIncrement: () {
                  print(
                    'DEBUG: Goal card increment clicked (but handler empty in overview)',
                  );
                },
                onDelete: () {
                  print(
                    'DEBUG: Goal card delete clicked (but handler empty in overview)',
                  );
                },
                showActions: false,
                onTap: onGoalTap != null
                    ? () {
                        print(
                          'DEBUG: PremiumGoalCard tapped for goal: ${goal.title}',
                        );
                        onGoalTap!(goal);
                      }
                    : () {
                        print(
                          'DEBUG: PremiumGoalCard tapped but onGoalTap is null',
                        );
                      },
              ),
            ),

          if (activeGoals.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () {
                  print('DEBUG: Ver Todas as Metas button clicked');
                  if (onViewAll != null) {
                    print('DEBUG: onViewAll callback exists, calling it');
                    onViewAll!();
                  } else {
                    print('DEBUG: onViewAll callback is null!');
                  }
                },
                child: Text(
                  'Ver Todas as Metas',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumGoalCard extends StatelessWidget {
  final PersonalGoal goal;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool showActions;

  const PremiumGoalCard({
    super.key,
    required this.goal,
    required this.onIncrement,
    required this.onDelete,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final goalColor = _getGoalColor(goal.type);
    final percentage = (goal.progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark(context)
                ? Colors.white.withValues(alpha: 0.05)
                : colors.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon with glow
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _getGoalEmoji(goal.type),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Progress Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getGoalStatusText(goal),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                if (showActions && !goal.isCompleted)
                  Row(
                    children: [
                      _circleIconButton(
                        goal.trackingType == 'checklist'
                            ? Icons.check_rounded
                            : Icons.add,
                        goalColor,
                        () {
                          HapticFeedback.mediumImpact();
                          onIncrement();
                        },
                        colors,
                      ),
                      const SizedBox(width: 8),
                      _circleIconButton(
                        Icons.delete_outline,
                        colors.error,
                        onDelete,
                        colors,
                      ),
                    ],
                  )
                else if (goal.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF51CF66),
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar (Gradient)
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: goal.progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [goalColor, goalColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: goalColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: goalColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _getGoalStatusText(PersonalGoal goal) {
    if (goal.isCompleted) return 'Concluída';
    switch (goal.trackingType) {
      case 'checklist':
        return 'Pendente';
      case 'percentage':
        return '${goal.currentValue}% de ${goal.targetValue}%';
      case 'counter':
      default:
        return '${goal.currentValue} de ${goal.targetValue} concluídos';
    }
  }

  Color _getGoalColor(String type) {
    switch (type) {
      case 'mood':
        return const Color(0xFFFFA94D);
      case 'tasks':
        return const Color(0xFF51CF66);
      case 'focus':
        return const Color(0xFF339AF0);
      case 'habits':
        return const Color(0xFFB197FC);
      default:
        return const Color(0xFF868E96);
    }
  }

  String _getGoalEmoji(String type) {
    switch (type) {
      case 'mood':
        return '😊';
      case 'tasks':
        return '✅';
      case 'focus':
        return '⏱️';
      case 'habits':
        return '🎯';
      default:
        return '🌟';
    }
  }
}

class GoalsSummaryCard extends StatelessWidget {
  final int totalGoals;
  final int completedGoals;
  final double successRate;

  const GoalsSummaryCard({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Circular Progress
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
                    value: successRate,
                    strokeWidth: 10,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(successRate * 100).round()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Sucesso',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryStat(
                  'Metas Ativas',
                  '${totalGoals - completedGoals}',
                  colors.primary,
                  colors,
                ),
                const SizedBox(height: 12),
                _buildSummaryStat(
                  'Concluídas',
                  '$completedGoals',
                  const Color(0xFF51CF66),
                  colors,
                ),
                const SizedBox(height: 12),
                _buildSummaryStat(
                  'Tokens Ganhos',
                  '${completedGoals * 50}',
                  const Color(0xFFFFA94D),
                  colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    String label,
    String value,
    Color color,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                height: 1,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// LEVEL PROGRESS - Barra de progresso do nível
// ============================================================

class LevelProgressCard extends StatelessWidget {
  final int level;
  final int currentXP;
  final int xpForCurrentLevel;
  final int xpForNextLevel;

  const LevelProgressCard({
    super.key,
    required this.level,
    required this.currentXP,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final xpInLevel = currentXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    final progress = xpNeeded > 0
        ? (xpInLevel / xpNeeded).clamp(0.0, 1.0)
        : 1.0;
    final xpRemaining = xpForNextLevel - currentXP;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.1),
            colors.tertiary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nv.$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Próximo Nível',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nv.${level + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInLevel / $xpNeeded XP',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              Text(
                'Faltam $xpRemaining XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEMPORAL COMPARISON - Pills horizontais modernas
// ============================================================

class TemporalComparisonCard extends StatelessWidget {
  final double dailyChange;
  final double weeklyChange;
  final double monthlyChange;

  const TemporalComparisonCard({
    super.key,
    required this.dailyChange,
    required this.weeklyChange,
    required this.monthlyChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Sua Evolução',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
        // Pills horizontais
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPill('Ontem', dailyChange, colors),
              const SizedBox(width: 10),
              _buildPill('Esta Semana', weeklyChange, colors),
              const SizedBox(width: 10),
              _buildPill('Este Mês', monthlyChange, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String label, double change, ColorScheme colors) {
    final isPositive = change >= 0;
    final color = isPositive
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final icon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVITY TIMELINE - Scroll horizontal de atividades recentes
// ============================================================

class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Atividade Recente',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityCard(activity: activity, colors: colors);
            },
          ),
        ),
      ],
    );
  }
}

class ActivityItem {
  final String emoji;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Color color;
  final String type; // 'mood', 'task', 'pomodoro', 'habit', 'note'

  ActivityItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.color,
    required this.type,
  });
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final ColorScheme colors;

  const _ActivityCard({required this.activity, required this.colors});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(activity.timestamp);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: activity.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activity.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(activity.emoji, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          Text(
            activity.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            activity.subtitle,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// Manter compatibilidade com código antigo
typedef PremiumProfileHeader = ProfileHeader;
typedef DetailedStatsCard = StatsCarousel;
