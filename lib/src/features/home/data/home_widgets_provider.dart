import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de widgets disponíveis para a Home
/// Expandido para incluir todos os widgets úteis e reorganizáveis
enum HomeWidgetType {
  quickNotes, // Notas rápidas
  quickPomodoro, // Timer rápido
  dailyGoals, // Sua semana
  activityGrid, // Grid de atividade estilo GitHub
  streak, // Widget de streak/sequência
  todayTasks, // Tarefas de hoje
  dailyQuote, // Citação do dia
  weeklyChart, // Gráfico semanal
  currentReading, // Leitura atual
  habits, // Widget de hábitos compacto
  quickMood, // Humor rápido
  weekCalendar, // Calendário semanal
  monthlyOverview, // Visão mensal
  waterTracker, // Rastreador de água
}

/// Configuração de um widget
class HomeWidgetConfig {
  final HomeWidgetType type;
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final int order;

  const HomeWidgetConfig({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isEnabled = true,
    this.order = 0,
  });

  HomeWidgetConfig copyWith({bool? isEnabled, int? order}) {
    return HomeWidgetConfig(
      type: type,
      id: id,
      name: name,
      description: description,
      icon: icon,
      color: color,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }
}

/// Configurações padrão dos widgets (expandido)
class DefaultHomeWidgets {
  static List<HomeWidgetConfig> getDefaults() {
    return [
      const HomeWidgetConfig(
        type: HomeWidgetType.quickNotes,
        id: 'quick_notes',
        name: 'Notas Rápidas',
        description: 'Ver e criar notas rapidamente',
        icon: Icons.sticky_note_2_rounded,
        color: Color(0xFFFFA726),
        isEnabled: true,
        order: 0,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.quickPomodoro,
        id: 'quick_pomodoro',
        name: 'Pomodoro Rápido',
        description: 'Inicie um timer de foco',
        icon: Icons.timer_rounded,
        color: Color(0xFFEF5350),
        isEnabled: true,
        order: 1,
      ),
      // Movido para cima: Tarefas de Hoje
      const HomeWidgetConfig(
        type: HomeWidgetType.todayTasks,
        id: 'today_tasks',
        name: 'Tarefas de Hoje',
        description: 'Suas tarefas para hoje',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF2196F3),
        isEnabled: true,
        order: 2,
      ),
      // Movido para cima: Hábitos
      const HomeWidgetConfig(
        type: HomeWidgetType.habits,
        id: 'habits_compact',
        name: 'Hábitos',
        description: 'Seus hábitos do dia',
        icon: Icons.repeat_rounded,
        color: Color(0xFF66BB6A),
        isEnabled: true,
        order: 3,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.dailyGoals,
        id: 'daily_goals',
        name: 'Sua Semana',
        description: 'Visualize sua atividade da semana',
        icon: Icons.insights_rounded,
        color: Color(0xFF4CAF50),
        isEnabled: true,
        order: 4,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.activityGrid,
        id: 'activity_grid',
        name: 'Contribuições',
        description: 'Grid de atividade estilo GitHub',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF9C27B0),
        isEnabled: false,
        order: 5,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.streak,
        id: 'streak',
        name: 'Sequência',
        description: 'Veja sua sequência de dias ativos',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF5722),
        isEnabled: false,
        order: 6,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.dailyQuote,
        id: 'daily_quote',
        name: 'Citação do Dia',
        description: 'Inspiração diária',
        icon: Icons.format_quote_rounded,
        color: Color(0xFF9575CD),
        isEnabled: false,
        order: 7,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.weeklyChart,
        id: 'weekly_chart',
        name: 'Gráfico Semanal',
        description: 'Visualize seu progresso semanal',
        icon: Icons.bar_chart_rounded,
        color: Color(0xFF26A69A),
        isEnabled: false,
        order: 8,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.currentReading,
        id: 'current_reading',
        name: 'Leitura Atual',
        description: 'Seu livro atual',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFF8D6E63),
        isEnabled: false,
        order: 9,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.quickMood,
        id: 'quick_mood',
        name: 'Humor Rápido',
        description: 'Registre seu humor rapidamente',
        icon: Icons.mood_rounded,
        color: Color(0xFFFFCA28),
        isEnabled: false,
        order: 10,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.weekCalendar,
        id: 'week_calendar',
        name: 'Calendário Semanal',
        description: 'Visualize sua semana',
        icon: Icons.calendar_view_week_rounded,
        color: Color(0xFF42A5F5),
        isEnabled: false,
        order: 11,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.monthlyOverview,
        id: 'monthly_overview',
        name: 'Visão Mensal',
        description: 'Resumo do seu mês',
        icon: Icons.calendar_month_rounded,
        color: Color(0xFF7E57C2),
        isEnabled: false,
        order: 12,
      ),
      const HomeWidgetConfig(
        type: HomeWidgetType.waterTracker,
        id: 'water_tracker',
        name: 'Hidratação',
        description: 'Acompanhe seu consumo de água',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF42A5F5),
        isEnabled: true,
        order: 13,
      ),
    ];
  }
}

/// Estado dos widgets da home
class HomeWidgetsState {
  final List<HomeWidgetConfig> widgets;

  const HomeWidgetsState({required this.widgets});

  List<HomeWidgetConfig> get enabledWidgets {
    final enabled = widgets.where((w) => w.isEnabled).toList();
    enabled.sort((a, b) => a.order.compareTo(b.order));
    return enabled;
  }

  HomeWidgetsState copyWith({List<HomeWidgetConfig>? widgets}) {
    return HomeWidgetsState(widgets: widgets ?? this.widgets);
  }
}

/// Notifier para gerenciar widgets da home
class HomeWidgetsNotifier extends StateNotifier<HomeWidgetsState> {
  HomeWidgetsNotifier()
    : super(HomeWidgetsState(widgets: DefaultHomeWidgets.getDefaults())) {
    _loadWidgets();
  }

  static const _widgetsKey = 'home_widgets_config';

  Future<void> _loadWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfig = prefs.getStringList(_widgetsKey);

    if (savedConfig != null && savedConfig.isNotEmpty) {
      final defaults = DefaultHomeWidgets.getDefaults();
      final loadedWidgets = <HomeWidgetConfig>[];

      for (int i = 0; i < defaults.length; i++) {
        final defaultWidget = defaults[i];
        // Formato: "id:enabled:order"
        final savedData = savedConfig.firstWhere(
          (s) => s.startsWith('${defaultWidget.id}:'),
          orElse: () => '${defaultWidget.id}:${defaultWidget.isEnabled}:$i',
        );

        final parts = savedData.split(':');
        final isEnabled = parts.length > 1
            ? parts[1] == 'true'
            : defaultWidget.isEnabled;
        final order = parts.length > 2 ? int.tryParse(parts[2]) ?? i : i;

        loadedWidgets.add(
          defaultWidget.copyWith(isEnabled: isEnabled, order: order),
        );
      }

      state = HomeWidgetsState(widgets: loadedWidgets);
    }
  }

  Future<void> _saveWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    final configStrings = state.widgets
        .map((w) => '${w.id}:${w.isEnabled}:${w.order}')
        .toList();
    await prefs.setStringList(_widgetsKey, configStrings);
  }

  /// Ativar/desativar widget
  Future<void> toggleWidget(String widgetId) async {
    final updatedWidgets = state.widgets.map((w) {
      if (w.id == widgetId) {
        return w.copyWith(isEnabled: !w.isEnabled);
      }
      return w;
    }).toList();

    state = state.copyWith(widgets: updatedWidgets);
    await _saveWidgets();
  }

  /// Reordenar widgets
  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    final enabledWidgets = state.enabledWidgets;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final widget = enabledWidgets.removeAt(oldIndex);
    enabledWidgets.insert(newIndex, widget);

    // Atualizar orders
    final updatedWidgets = state.widgets.map((w) {
      final newOrder = enabledWidgets.indexWhere((e) => e.id == w.id);
      if (newOrder >= 0) {
        return w.copyWith(order: newOrder);
      }
      return w;
    }).toList();

    state = state.copyWith(widgets: updatedWidgets);
    await _saveWidgets();
  }

  /// Resetar para padrão
  Future<void> resetToDefaults() async {
    state = HomeWidgetsState(widgets: DefaultHomeWidgets.getDefaults());
    await _saveWidgets();
  }
}

/// Providers
final homeWidgetsProvider =
    StateNotifierProvider<HomeWidgetsNotifier, HomeWidgetsState>((ref) {
      return HomeWidgetsNotifier();
    });

final enabledHomeWidgetsProvider = Provider<List<HomeWidgetConfig>>((ref) {
  return ref.watch(homeWidgetsProvider).enabledWidgets;
});
