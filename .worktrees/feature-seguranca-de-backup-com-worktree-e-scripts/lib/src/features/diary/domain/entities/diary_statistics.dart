// lib/src/features/diary/domain/entities/diary_statistics.dart

/// Estatísticas do diário
class DiaryStatistics {
  final int totalEntries;
  final int totalWords;
  final int totalPhotos;
  final int currentStreak;
  final int bestStreak;
  final int entriesThisMonth;
  final int entriesThisWeek;
  final int entriesThisYear;
  final double averageWordsPerEntry;
  final Map<String, int> entriesByFeeling;
  final Map<String, int> entriesByTag;
  final Map<int, int> entriesByMonth; // 1-12 -> count
  final Map<int, int> entriesByDayOfWeek; // 1-7 -> count
  final DateTime? firstEntryDate;
  final DateTime? lastEntryDate;
  final List<String> topTags;
  final String? mostUsedFeeling;

  const DiaryStatistics({
    this.totalEntries = 0,
    this.totalWords = 0,
    this.totalPhotos = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.entriesThisMonth = 0,
    this.entriesThisWeek = 0,
    this.entriesThisYear = 0,
    this.averageWordsPerEntry = 0,
    this.entriesByFeeling = const {},
    this.entriesByTag = const {},
    this.entriesByMonth = const {},
    this.entriesByDayOfWeek = const {},
    this.firstEntryDate,
    this.lastEntryDate,
    this.topTags = const [],
    this.mostUsedFeeling,
  });

  /// Estatísticas vazias
  factory DiaryStatistics.empty() => const DiaryStatistics();

  /// Calcula estatísticas a partir de uma lista de entradas
  factory DiaryStatistics.fromEntries(List<dynamic> entries) {
    if (entries.isEmpty) return const DiaryStatistics();

    int totalWords = 0;
    int totalPhotos = 0;
    final Map<String, int> byFeeling = {};
    final Map<String, int> byTag = {};
    final Map<int, int> byMonth = {};
    final Map<int, int> byDayOfWeek = {};
    DateTime? firstDate;
    DateTime? lastDate;

    // Ordenar por data
    final sortedEntries = List.from(entries)
      ..sort((a, b) => (a.entryDate as DateTime).compareTo(b.entryDate as DateTime));

    for (final entry in sortedEntries) {
      // Contar palavras
      final searchableText = entry.searchableText as String?;
      if (searchableText != null && searchableText.isNotEmpty) {
        totalWords += searchableText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      }

      // Contar fotos
      final photoIds = entry.photoIds as List<String>? ?? [];
      totalPhotos += photoIds.length;

      // Contar por sentimento
      final feeling = entry.feeling as String?;
      if (feeling != null && feeling.isNotEmpty) {
        byFeeling[feeling] = (byFeeling[feeling] ?? 0) + 1;
      }

      // Contar por tag
      final tags = entry.tags as List<String>? ?? [];
      for (final tag in tags) {
        byTag[tag] = (byTag[tag] ?? 0) + 1;
      }

      // Contar por mês e dia da semana
      final date = entry.entryDate as DateTime;
      byMonth[date.month] = (byMonth[date.month] ?? 0) + 1;
      byDayOfWeek[date.weekday] = (byDayOfWeek[date.weekday] ?? 0) + 1;

      // Primeira e última data
      if (firstDate == null || date.isBefore(firstDate)) {
        firstDate = date;
      }
      if (lastDate == null || date.isAfter(lastDate)) {
        lastDate = date;
      }
    }

    // Calcular streak
    final streaks = _calculateStreaks(sortedEntries);

    // Calcular entradas deste período
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisYearStart = DateTime(now.year, 1, 1);

    int entriesThisWeek = 0;
    int entriesThisMonth = 0;
    int entriesThisYear = 0;

    for (final entry in sortedEntries) {
      final date = entry.entryDate as DateTime;
      if (date.isAfter(thisYearStart) || _isSameDay(date, thisYearStart)) {
        entriesThisYear++;
      }
      if (date.isAfter(thisMonthStart) || _isSameDay(date, thisMonthStart)) {
        entriesThisMonth++;
      }
      if (date.isAfter(thisWeekStart) || _isSameDay(date, thisWeekStart)) {
        entriesThisWeek++;
      }
    }

    // Top tags
    final sortedTags = byTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(5).map((e) => e.key).toList();

    // Sentimento mais usado
    String? mostUsedFeeling;
    if (byFeeling.isNotEmpty) {
      mostUsedFeeling = byFeeling.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return DiaryStatistics(
      totalEntries: entries.length,
      totalWords: totalWords,
      totalPhotos: totalPhotos,
      currentStreak: streaks['current'] ?? 0,
      bestStreak: streaks['best'] ?? 0,
      entriesThisMonth: entriesThisMonth,
      entriesThisWeek: entriesThisWeek,
      entriesThisYear: entriesThisYear,
      averageWordsPerEntry: entries.isEmpty ? 0 : totalWords / entries.length,
      entriesByFeeling: byFeeling,
      entriesByTag: byTag,
      entriesByMonth: byMonth,
      entriesByDayOfWeek: byDayOfWeek,
      firstEntryDate: firstDate,
      lastEntryDate: lastDate,
      topTags: topTags,
      mostUsedFeeling: mostUsedFeeling,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Map<String, int> _calculateStreaks(List<dynamic> sortedEntries) {
    if (sortedEntries.isEmpty) return {'current': 0, 'best': 0};

    // Agrupar entradas por dia
    final Set<String> daysWithEntries = {};
    for (final entry in sortedEntries) {
      final date = entry.entryDate as DateTime;
      daysWithEntries.add('${date.year}-${date.month}-${date.day}');
    }

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    // Calcular streak atual
    int currentStreak = 0;
    DateTime checkDate = now;

    // Se não tem entrada hoje, começar de ontem
    if (!daysWithEntries.contains(today)) {
      if (!daysWithEntries.contains(yesterdayKey)) {
        currentStreak = 0;
      } else {
        checkDate = yesterday;
      }
    }

    while (true) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (daysWithEntries.contains(key)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Calcular melhor streak
    int bestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    final sortedDays = daysWithEntries.toList()
      ..sort();

    for (final dayKey in sortedDays) {
      final parts = dayKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final diff = date.difference(lastDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else {
          if (tempStreak > bestStreak) bestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      lastDate = date;
    }

    if (tempStreak > bestStreak) bestStreak = tempStreak;

    return {'current': currentStreak, 'best': bestStreak};
  }

  @override
  String toString() => 'DiaryStatistics(entries: $totalEntries, words: $totalWords, streak: $currentStreak)';
}
