import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/language_learning_repository.dart';
import '../domain/language.dart';
import '../domain/immersion_log.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class ImmersionScreen extends ConsumerStatefulWidget {
  final String? languageId;

  const ImmersionScreen({super.key, this.languageId});

  @override
  ConsumerState<ImmersionScreen> createState() => _ImmersionScreenState();
}

class _ImmersionScreenState extends ConsumerState<ImmersionScreen> {
  late LanguageLearningRepository _repository;
  bool _isInitialized = false;
  late Box<ImmersionLog> _immersionBox;
  String? _selectedLanguageId;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repository = ref.read(languageLearningRepositoryProvider);
    await _repository.init();
    
    // Register and open immersion box
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(ImmersionLogAdapter());
    }
    _immersionBox = await Hive.openBox<ImmersionLog>('immersion_logs');
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _selectedLanguageId = widget.languageId ?? 
            _repository.getAllLanguages().firstOrNull?.id;
      });
    }
  }

  List<ImmersionLog> get _logs {
    var logs = _immersionBox.values.toList();
    if (_selectedLanguageId != null) {
      logs = logs.where((l) => l.languageId == _selectedLanguageId).toList();
    }
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  int get _totalImmersionMinutes {
    return _logs.fold(0, (sum, l) => sum + l.durationMinutes);
  }

  Map<String, int> get _minutesByType {
    final map = <String, int>{};
    for (final log in _logs) {
      map[log.type] = (map[log.type] ?? 0) + log.durationMinutes;
    }
    return map;
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
    final totalHours = _totalImmersionMinutes ~/ 60;
    final totalMins = _totalImmersionMinutes % 60;

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

            // Language filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildLanguageFilter(colors, languages),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildStatsCard(colors, totalHours, totalMins),
              ),
            ),

            // Type breakdown
            if (_minutesByType.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildTypeBreakdown(colors),
                ),
              ),

            // Add immersion buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildQuickAddButtons(colors),
              ),
            ),

            // Logs section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.history, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'HISTÓRICO DE IMERSÃO',
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

            // Logs list
            if (_logs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.movie_outlined, size: 48, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma imersão registrada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registre filmes, séries, músicas e mais!',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _logs.length) return null;
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _buildLogCard(colors, log),
                    );
                  },
                  childCount: _logs.length > 20 ? 20 : _logs.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddImmersionSheet(),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.registrar),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withValues(alpha: 0.15), colors.surface],
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
                  'Imersão',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Filmes, séries, música e mais',
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

  Widget _buildLanguageFilter(ColorScheme colors, List<Language> languages) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: languages.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedLanguageId == null;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedLanguageId = null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.primary.withValues(alpha: 0.1),
                    ],
                  ) : null,
                  color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }

          final lang = languages[index - 1];
          final isSelected = _selectedLanguageId == lang.id;
          final color = Color(lang.colorValue);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedLanguageId = lang.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.1),
                  ],
                ) : null,
                color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : colors.outline.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        lang.flag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : colors.onSurface,
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

  Widget _buildStatsCard(ColorScheme colors, int hours, int mins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.15),
            Colors.pink.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.headphones, size: 28, color: Colors.purple),
              const SizedBox(width: 12),
              Text(
                '${hours}h ${mins}m',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'de imersão total',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(colors, '${_logs.length}', 'Registros', Icons.list_alt),
              _buildMiniStat(colors, '${_minutesByType.length}', 'Tipos', Icons.category),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ColorScheme colors, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.purple),
        const SizedBox(height: 4),
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
    );
  }

  Widget _buildTypeBreakdown(ColorScheme colors) {
    final sortedTypes = _minutesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Por tipo de conteúdo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedTypes.take(6).map((entry) {
              final typeColor = Color(ImmersionTypes.getColor(entry.key));
              final hours = entry.value ~/ 60;
              final mins = entry.value % 60;
              final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ImmersionTypes.getIcon(entry.key),
                      size: 16,
                      color: typeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ImmersionTypes.getName(entry.key)}: $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons(ColorScheme colors) {
    final quickTypes = ImmersionTypes.all.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADICIONAR RÁPIDO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: quickTypes.map((type) {
            final color = Color(type['color']);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: type == quickTypes.last ? 0 : 8),
                child: GestureDetector(
                  onTap: () => _showQuickAddSheet(type['id'], type['name']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          ImmersionTypes.getIcon(type['id']),
                          size: 24,
                          color: color,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['name'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLogCard(ColorScheme colors, ImmersionLog log) {
    final typeColor = Color(ImmersionTypes.getColor(log.type));
    final language = _repository.getLanguage(log.languageId);

    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await _immersionBox.delete(log.id);
        setState(() {});
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              typeColor.withValues(alpha: 0.08),
              typeColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: typeColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor.withValues(alpha: 0.2),
                    typeColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: typeColor.withValues(alpha: 0.2)),
              ),
              child: Icon(
                ImmersionTypes.getIcon(log.type),
                size: 22,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (language != null) ...[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(language.colorValue).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text(
                              language.flag,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(language.colorValue),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          log.title ?? ImmersionTypes.getName(log.type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        ImmersionTypes.getName(log.type),
                        style: TextStyle(fontSize: 12, color: typeColor),
                      ),
                      if (log.withSubtitles) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.subtitles, size: 12, color: colors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          'legendas',
                          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  log.formattedDuration,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
                Text(
                  _formatDate(log.date),
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            if (log.rating != null) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(
                    '${log.rating}',
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickAddSheet(String type, String typeName) {
    if (_selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selecioneUmIdiomaPrimeiro)),
      );
      return;
    }

    final colors = Theme.of(context).colorScheme;
    final typeColor = Color(ImmersionTypes.getColor(type));
    int selectedMinutes = ImmersionTypes.getDefaultDuration(type);
    final titleController = TextEditingController();
    bool withSubtitles = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header com ícone
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          ImmersionTypes.getIcon(type),
                          size: 24,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adicionar $typeName',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            _repository.getLanguage(_selectedLanguageId!)?.name ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Título (opcional)
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Nome (opcional)',
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.edit, size: 18, color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Duração
                  Text(
                    'DURAÇÃO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 25, 30, 45, 60, 90, 120].map((mins) {
                      final isSelected = selectedMinutes == mins;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedMinutes = mins),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? LinearGradient(
                              colors: [
                                typeColor.withValues(alpha: 0.25),
                                typeColor.withValues(alpha: 0.1),
                              ],
                            ) : null,
                            color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? typeColor : colors.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            mins >= 60 ? '${mins ~/ 60}h${mins % 60 > 0 ? " ${mins % 60}m" : ""}' : '${mins}m',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? typeColor : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Legendas (para vídeos)
                  if (type == ImmersionTypes.movie || 
                      type == ImmersionTypes.series || 
                      type == ImmersionTypes.anime ||
                      type == ImmersionTypes.youtube) ...[
                    GestureDetector(
                      onTap: () => setModalState(() => withSubtitles = !withSubtitles),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: withSubtitles 
                              ? colors.primary.withValues(alpha: 0.1) 
                              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: withSubtitles 
                                ? colors.primary.withValues(alpha: 0.3) 
                                : colors.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              withSubtitles ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 20,
                              color: withSubtitles ? colors.primary : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Com legendas',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Botão salvar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final id = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
                        final log = ImmersionLog(
                          id: id,
                          languageId: _selectedLanguageId!,
                          date: DateTime.now(),
                          durationMinutes: selectedMinutes,
                          type: type,
                          title: titleController.text.isEmpty ? null : titleController.text,
                          withSubtitles: withSubtitles,
                        );
                        await _immersionBox.put(id, log);
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${titleController.text.isEmpty ? typeName : titleController.text} registrado! +${selectedMinutes}m'),
                              backgroundColor: typeColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showAddImmersionSheet() {
    final colors = Theme.of(context).colorScheme;
    final languages = _repository.getAllLanguages();
    
    String? selectedLangId = _selectedLanguageId ?? languages.firstOrNull?.id;
    String selectedType = ImmersionTypes.movie;
    int duration = 60;
    final titleController = TextEditingController();
    bool withSubtitles = false;
    int? rating;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Registrar Imersão',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Language
                  if (languages.length > 1) ...[
                    Text('IDIOMA', style: _labelStyle(colors)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: languages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final lang = languages[index];
                          final isSelected = selectedLangId == lang.id;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedLangId = lang.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(lang.colorValue).withValues(alpha: 0.2)
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Color(lang.colorValue) : colors.outline.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(lang.name, style: TextStyle(color: colors.onSurface)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Type
                  Text('TIPO', style: _labelStyle(colors)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ImmersionTypes.all.map((type) {
                      final isSelected = selectedType == type['id'];
                      final typeColor = Color(type['color']);
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedType = type['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? typeColor.withValues(alpha: 0.2) : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? typeColor : colors.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ImmersionTypes.getIcon(type['id']), size: 16, color: isSelected ? typeColor : colors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(type['name'], style: TextStyle(fontSize: 12, color: isSelected ? typeColor : colors.onSurface)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Título (opcional)',
                      hintText: 'Ex: Breaking Bad S01E01',
                      labelStyle: TextStyle(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Duration
                  Text('DURAÇÃO', style: _labelStyle(colors)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90, 120].map((mins) {
                      final isSelected = duration == mins;
                      return GestureDetector(
                        onTap: () => setModalState(() => duration = mins),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.primary.withValues(alpha: 0.2) : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            mins >= 60 ? '${mins ~/ 60}h${mins % 60 > 0 ? " ${mins % 60}m" : ""}' : '${mins}m',
                            style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? colors.primary : colors.onSurface),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Subtitles toggle
                  Row(
                    children: [
                      Switch.adaptive(
                        value: withSubtitles,
                        onChanged: (v) => setModalState(() => withSubtitles = v),
                        activeColor: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Com legendas', style: TextStyle(color: colors.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rating
                  Text('AVALIAÇÃO (opcional)', style: _labelStyle(colors)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = rating != null && rating! >= starValue;
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = rating == starValue ? null : starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 32,
                            color: isSelected ? Colors.amber : colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedLangId == null ? null : () async {
                        final id = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
                        final log = ImmersionLog(
                          id: id,
                          languageId: selectedLangId!,
                          date: DateTime.now(),
                          durationMinutes: duration,
                          type: selectedType,
                          title: titleController.text.isEmpty ? null : titleController.text,
                          withSubtitles: withSubtitles,
                          rating: rating,
                        );
                        await _immersionBox.put(id, log);
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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

  TextStyle _labelStyle(ColorScheme colors) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: colors.onSurfaceVariant,
    letterSpacing: 1,
  );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoje';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${date.day}/${date.month}';
  }
}
