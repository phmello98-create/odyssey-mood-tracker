import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/notes/presentation/notes_screen.dart';
import 'package:odyssey/src/features/library/presentation/library_screen.dart';
import 'package:odyssey/src/features/diary/presentation/pages/diary_home_page.dart';
import 'package:odyssey/src/features/analytics/presentation/analytics_screen.dart';
import 'package:odyssey/src/features/settings/presentation/settings_screen.dart';
import 'package:odyssey/src/features/suggestions/presentation/suggestions_screen.dart';
import 'package:odyssey/src/features/time_tracker/presentation/time_tracker_screen.dart';
import 'package:odyssey/src/features/language_learning/presentation/language_learning_screen.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';

/// Item de busca global
class GlobalSearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final VoidCallback onTap;

  const GlobalSearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.onTap,
  });
}

/// Widget de barra de busca global que pesquisa tudo no app
class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final bool _isExpanded = false;
  final List<GlobalSearchItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      _showSearchModal();
    }
  }

  List<GlobalSearchItem> _getAllSearchItems(BuildContext context) {
    return [
      // ===== FEATURES PRINCIPAIS =====
      GlobalSearchItem(
        title: 'Registrar Humor',
        subtitle: 'Adicionar novo registro de humor',
        icon: Icons.mood_rounded,
        color: const Color(0xFF10B981),
        category: 'Ações Rápidas',
        onTap: () {
          Navigator.pop(context);
          ref.read(navigationProvider.notifier).goToMood();
        },
      ),
      GlobalSearchItem(
        title: 'Iniciar Timer',
        subtitle: 'Pomodoro e foco',
        icon: Icons.timer_rounded,
        color: const Color(0xFF6366F1),
        category: 'Ações Rápidas',
        onTap: () {
          Navigator.pop(context);
          ref.read(navigationProvider.notifier).goToTimer();
        },
      ),
      GlobalSearchItem(
        title: 'Nova Tarefa',
        subtitle: 'Criar tarefa rápida',
        icon: Icons.add_task_rounded,
        color: const Color(0xFF06B6D4),
        category: 'Ações Rápidas',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TasksScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Nova Nota',
        subtitle: 'Criar nota rápida',
        icon: Icons.note_add_rounded,
        color: const Color(0xFFF59E0B),
        category: 'Ações Rápidas',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesScreen()),
          );
        },
      ),

      // ===== TELAS PRINCIPAIS =====
      GlobalSearchItem(
        title: 'Hábitos',
        subtitle: 'Gerenciar hábitos diários',
        icon: Icons.repeat_rounded,
        color: const Color(0xFF8B5CF6),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitsCalendarScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Tarefas',
        subtitle: 'Lista de tarefas e to-dos',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF06B6D4),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TasksScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Notas',
        subtitle: 'Bloco de notas e anotações',
        icon: Icons.sticky_note_2_rounded,
        color: const Color(0xFFF59E0B),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Diário',
        subtitle: 'Escrever no diário pessoal',
        icon: Icons.book_rounded,
        color: const Color(0xFFEC4899),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryHomePage()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Biblioteca',
        subtitle: 'Livros e leituras',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF14B8A6),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LibraryScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Estatísticas',
        subtitle: 'Análises e gráficos de humor',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF3B82F6),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Sugestões',
        subtitle: 'Hábitos e tarefas recomendadas',
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFF59E0B),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Pomodoro',
        subtitle: 'Timer de foco e produtividade',
        icon: Icons.timer_rounded,
        color: const Color(0xFFEF4444),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TimeTrackerScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Idiomas',
        subtitle: 'Aprendizado de idiomas',
        icon: Icons.translate_rounded,
        color: const Color(0xFF6366F1),
        category: 'Funcionalidades',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LanguageLearningScreen()),
          );
        },
      ),

      // ===== CONFIGURAÇÕES =====
      GlobalSearchItem(
        title: 'Configurações',
        subtitle: 'Ajustes do aplicativo',
        icon: Icons.settings_rounded,
        color: const Color(0xFF6B7280),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Tema',
        subtitle: 'Alterar tema claro/escuro',
        icon: Icons.palette_rounded,
        color: const Color(0xFF8B5CF6),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Notificações',
        subtitle: 'Configurar lembretes',
        icon: Icons.notifications_rounded,
        color: const Color(0xFFF59E0B),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Backup',
        subtitle: 'Salvar e restaurar dados',
        icon: Icons.cloud_upload_rounded,
        color: const Color(0xFF06B6D4),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Conta',
        subtitle: 'Gerenciar conta e login',
        icon: Icons.person_rounded,
        color: const Color(0xFF10B981),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          ref.read(navigationProvider.notifier).goToProfile();
        },
      ),
      GlobalSearchItem(
        title: 'Privacidade',
        subtitle: 'Configurações de privacidade',
        icon: Icons.lock_rounded,
        color: const Color(0xFFEF4444),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      GlobalSearchItem(
        title: 'Sons',
        subtitle: 'Configurar sons do app',
        icon: Icons.volume_up_rounded,
        color: const Color(0xFF3B82F6),
        category: 'Configurações',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];
  }

  void _showSearchModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlobalSearchModal(
        allItems: _getAllSearchItems(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _showSearchModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: colors.onSurfaceVariant.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buscar algo especial...',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_command_key_rounded,
                    size: 12,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'K',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
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
}

/// Modal de busca global com resultados categorizados
class _GlobalSearchModal extends StatefulWidget {
  final List<GlobalSearchItem> allItems;

  const _GlobalSearchModal({required this.allItems});

  @override
  State<_GlobalSearchModal> createState() => _GlobalSearchModalState();
}

class _GlobalSearchModalState extends State<_GlobalSearchModal> {
  final _searchController = TextEditingController();
  List<GlobalSearchItem> _filteredItems = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.allItems;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredItems = widget.allItems;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = widget.allItems.where((item) {
          return item.title.toLowerCase().contains(lowerQuery) ||
              item.subtitle.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Map<String, List<GlobalSearchItem>> _groupByCategory() {
    final grouped = <String, List<GlobalSearchItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final grouped = _groupByCategory();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Search Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar funcionalidades, configurações...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.primary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Results
            Expanded(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState(colors)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final category = grouped.keys.elementAt(index);
                        final items = grouped[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...items.map((item) => _buildSearchItem(item, colors)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchItem(GlobalSearchItem item, ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outline.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tente buscar por outra palavra',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
