import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_repository.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_analytics_repository.dart';
import 'package:odyssey/src/features/suggestions/presentation/widgets/suggestion_card.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/gamification/data/synced_gamification_repository.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Suggestion> _suggestions = [];
  List<String> _addedIds = [];
  List<String> _markedIds = [];
  bool _isLoading = true;
  SuggestionType? _typeFilter;
  SuggestionDifficulty? _difficultyFilter;
  String _searchQuery = '';

  final List<({SuggestionCategory category, String label, IconData icon})> _categories = [
    (
      category: SuggestionCategory.selfKnowledge,
      label: 'Autoconhecimento',
      icon: Icons.psychology,
    ),
    (
      category: SuggestionCategory.presence,
      label: 'Presença & Corpo',
      icon: Icons.self_improvement,
    ),
    (
      category: SuggestionCategory.relations,
      label: 'Relações',
      icon: Icons.people,
    ),
    (
      category: SuggestionCategory.creation,
      label: 'Criação',
      icon: Icons.palette,
    ),
    (
      category: SuggestionCategory.reflection,
      label: 'Reflexão',
      icon: Icons.lightbulb_outline,
    ),
    (
      category: SuggestionCategory.selfActualization,
      label: 'Autorrealização',
      icon: Icons.trending_up,
    ),
    (
      category: SuggestionCategory.consciousness,
      label: 'Consciência',
      icon: Icons.visibility,
    ),
    (
      category: SuggestionCategory.emptiness,
      label: 'Vacuidade',
      icon: Icons.blur_on,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final suggestionRepo = ref.read(suggestionRepositoryProvider);
      final analyticsRepo = ref.read(suggestionAnalyticsRepositoryProvider);
      
      await analyticsRepo.init();
      
      final allSuggestions = await suggestionRepo.getRecommendedSuggestions();
      final addedIds = await analyticsRepo.getAddedSuggestionIds();
      final markedIds = await analyticsRepo.getFavoriteSuggestionIds();
      
      setState(() {
        _suggestions = allSuggestions;
        _addedIds = addedIds;
        _markedIds = markedIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Suggestion> _getFilteredSuggestions(SuggestionCategory category) {
    var filtered = _suggestions.where((s) => s.category == category).toList();
    
    // Filtro de tipo
    if (_typeFilter != null) {
      filtered = filtered.where((s) => s.type == _typeFilter).toList();
    }
    
    // Filtro de dificuldade
    if (_difficultyFilter != null) {
      filtered = filtered.where((s) => s.difficulty == _difficultyFilter).toList();
    }
    
    // Busca por texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(query) ||
               s.description.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _addSuggestion(Suggestion suggestion) async {
    try {
      if (suggestion.type == SuggestionType.habit) {
        await _addHabit(suggestion);
      } else {
        await _addTask(suggestion);
      }
      
      // Marcar como adicionada
      final analyticsRepo = ref.read(suggestionAnalyticsRepositoryProvider);
      await analyticsRepo.markAsAdded(suggestion.id);
      
      // Dar XP e verificar badges
      final gamificationRepo = ref.read(syncedGamificationRepositoryProvider);
      await gamificationRepo.addXP(10);
      
      // Verificar badges de sugestões
      final totalAccepted = await analyticsRepo.getTotalAddedCount();
      final newBadges = await gamificationRepo.checkSuggestionBadges(totalAccepted);
      
      // Recarregar dados
      await _loadData();
      
      // Mostrar feedback
      if (mounted) {
        String message = suggestion.type == SuggestionType.habit
            ? '✓ Hábito "${suggestion.title}" adicionado! +10 XP'
            : '✓ Tarefa "${suggestion.title}" adicionada! +10 XP';
        
        // Se desbloqueou badge, adicionar à mensagem
        if (newBadges.isNotEmpty) {
          message += '\n🎉 Badge desbloqueado: ${newBadges.first.name}!';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: Duration(seconds: newBadges.isNotEmpty ? 4 : 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding suggestion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addHabit(Suggestion suggestion) async {
    final habitRepo = ref.read(habitRepositoryProvider);
    await habitRepo.init();
    
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: suggestion.title,
      iconCode: suggestion.icon.codePoint,
      colorValue: suggestion.colorValue,
      scheduledTime: suggestion.scheduledTime,
      daysOfWeek: suggestion.suggestedDays ?? [],
      createdAt: DateTime.now(),
      completedDates: [],
      currentStreak: 0,
      bestStreak: 0,
      order: habitRepo.getAllHabits().length,
    );
    
    await habitRepo.addHabit(habit);
  }

  Future<void> _addTask(Suggestion suggestion) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.init();
    
    final taskData = TaskData(
      key: DateTime.now().millisecondsSinceEpoch.toString(),
      title: suggestion.title,
      notes: suggestion.description,
      completed: false,
      priority: suggestion.difficulty == SuggestionDifficulty.easy
          ? 'low'
          : suggestion.difficulty == SuggestionDifficulty.medium
              ? 'medium'
              : 'high',
      category: 'personal',
      createdAt: DateTime.now(),
    );
    
    await taskRepo.addTask(taskData);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _typeFilter = null;
                        _difficultyFilter = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.limpar),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Filtro de tipo
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.todos),
                    selected: _typeFilter == null,
                    onSelected: (selected) {
                      setState(() => _typeFilter = null);
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.habitos),
                    selected: _typeFilter == SuggestionType.habit,
                    onSelected: (selected) {
                      setState(() => _typeFilter = SuggestionType.habit);
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.tarefas),
                    selected: _typeFilter == SuggestionType.task,
                    onSelected: (selected) {
                      setState(() => _typeFilter = SuggestionType.task);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Filtro de dificuldade
              const Text('Dificuldade', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.todas),
                    selected: _difficultyFilter == null,
                    onSelected: (selected) {
                      setState(() => _difficultyFilter = null);
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.facil),
                    selected: _difficultyFilter == SuggestionDifficulty.easy,
                    onSelected: (selected) {
                      setState(() => _difficultyFilter = SuggestionDifficulty.easy);
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.medio),
                    selected: _difficultyFilter == SuggestionDifficulty.medium,
                    onSelected: (selected) {
                      setState(() => _difficultyFilter = SuggestionDifficulty.medium);
                      setModalState(() {});
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.dificil),
                    selected: _difficultyFilter == SuggestionDifficulty.hard,
                    onSelected: (selected) {
                      setState(() => _difficultyFilter = SuggestionDifficulty.hard);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.aplicar),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.explorarSugestoes),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_typeFilter != null || _difficultyFilter != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilters,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((cat) => Tab(
            child: Row(
              children: [
                Icon(cat.icon, size: 18),
                const SizedBox(width: 8),
                Text(cat.label),
              ],
            ),
          )).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de busca
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar sugestões...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF9FAFB),
                    ),
                  ),
                ),
                
                // Lista de sugestões por categoria
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((cat) {
                      final suggestions = _getFilteredSuggestions(cat.category);
                      
                      if (suggestions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma sugestão encontrada',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_typeFilter != null || _difficultyFilter != null || _searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _typeFilter = null;
                                        _difficultyFilter = null;
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Text(AppLocalizations.of(context)!.limparFiltros),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          final isAdded = _addedIds.contains(suggestion.id);
                          final isMarked = _markedIds.contains(suggestion.id);
                          
                          return SuggestionCard(
                            key: ValueKey(suggestion.id),
                            suggestion: suggestion,
                            isAdded: isAdded,
                            isMarked: isMarked,
                            onAdd: () => _addSuggestion(suggestion),
                            onFavoriteToggle: _loadData,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
