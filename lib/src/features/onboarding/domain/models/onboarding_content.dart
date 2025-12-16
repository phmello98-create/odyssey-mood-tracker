import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/onboarding_models.dart';

/// Páginas do onboarding inicial - SIMPLIFICADO para 3 páginas
/// Princípio: "Não explique tudo. Mostre apenas o próximo passo útil."
class OnboardingPages {
  static const List<OnboardingPage> all = [
    // Página 1: Boas-vindas curta e acolhedora
    OnboardingPage(
      id: 'welcome',
      titlePt: 'Olá! Bem-vindo ao Odyssey',
      titleEn: 'Hello! Welcome to Odyssey',
      subtitlePt: 'Seu companheiro de produtividade e bem-estar. Vamos começar?',
      subtitleEn: 'Your productivity and wellness companion. Shall we begin?',
      icon: Icons.rocket_launch_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      featureHighlights: ['Simples', 'Poderoso', 'Seu'],
    ),
    // Página 2: Foco no registro de humor (primeira ação)
    OnboardingPage(
      id: 'mood',
      titlePt: 'Como você está hoje?',
      titleEn: 'How are you feeling today?',
      subtitlePt: 'Comece registrando seu humor. É rápido - só um toque!',
      subtitleEn: 'Start by logging your mood. It\'s quick - just one tap!',
      icon: Icons.mood_rounded,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
      featureHighlights: ['1 toque', 'Diário', 'Insights'],
      // Esta página terá um CTA interativo para experimentar
      hasInteractiveDemo: true,
    ),
    // Página 3: Pronto! Menciona o botão de ajuda
    OnboardingPage(
      id: 'ready',
      titlePt: 'Tudo pronto!',
      titleEn: 'All set!',
      subtitlePt: 'Explore no seu ritmo. Precisa de ajuda? Procure o botão ? nas telas.',
      subtitleEn: 'Explore at your pace. Need help? Look for the ? button on screens.',
      icon: Icons.check_circle_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
      featureHighlights: ['Explore', 'Aprenda', 'Evolua'],
      // Mostra ícone do HelpFab para familiarizar usuário
      showHelpFabPreview: true,
    ),
  ];
}

/// Dicas de feature discovery organizadas
class FeatureTips {
  static const List<FeatureTip> all = [
    // --- MOOD ---
    FeatureTip(
      id: 'mood_quick_add',
      titlePt: 'Registro Rápido de Humor',
      titleEn: 'Quick Mood Entry',
      descriptionPt: 'Deslize para a direita em qualquer lugar da tela inicial para abrir rapidamente o registro de humor.',
      descriptionEn: 'Swipe right anywhere on the home screen to quickly open mood logging.',
      icon: Icons.swipe_right_rounded,
      type: TipType.gesture,
      category: FeatureCategory.mood,
      priority: 10,
    ),
    FeatureTip(
      id: 'mood_activities',
      titlePt: 'Atividades no Humor',
      titleEn: 'Activities in Mood',
      descriptionPt: 'Adicione atividades ao seu registro de humor para entender o que influencia como você se sente.',
      descriptionEn: 'Add activities to your mood log to understand what influences how you feel.',
      icon: Icons.local_activity_rounded,
      type: TipType.feature,
      category: FeatureCategory.mood,
      actionRoute: '/mood',
    ),
    FeatureTip(
      id: 'mood_analytics',
      titlePt: 'Padrões de Humor',
      titleEn: 'Mood Patterns',
      descriptionPt: 'Veja seus padrões de humor ao longo do tempo na seção de Analytics. Descubra seus dias mais produtivos!',
      descriptionEn: 'See your mood patterns over time in the Analytics section. Discover your most productive days!',
      icon: Icons.insights_rounded,
      type: TipType.productivity,
      category: FeatureCategory.analytics,
      actionRoute: '/analytics',
    ),

    // --- TIMER ---
    FeatureTip(
      id: 'timer_ambient_sounds',
      titlePt: 'Sons Ambiente',
      titleEn: 'Ambient Sounds',
      descriptionPt: 'Ative sons ambiente durante suas sessões de foco. Experimente chuva, floresta ou café para aumentar sua concentração.',
      descriptionEn: 'Enable ambient sounds during your focus sessions. Try rain, forest or café to boost your concentration.',
      icon: Icons.music_note_rounded,
      type: TipType.feature,
      category: FeatureCategory.timer,
      priority: 9,
    ),
    FeatureTip(
      id: 'timer_floating',
      titlePt: 'Timer Flutuante',
      titleEn: 'Floating Timer',
      descriptionPt: 'Quando você navega para outras telas com o timer ativo, um mini-timer flutuante aparece para você acompanhar seu tempo.',
      descriptionEn: 'When you navigate to other screens with the timer active, a floating mini-timer appears so you can track your time.',
      icon: Icons.picture_in_picture_rounded,
      type: TipType.hidden,
      category: FeatureCategory.timer,
    ),
    FeatureTip(
      id: 'timer_tomato',
      titlePt: 'Timer Tomate',
      titleEn: 'Tomato Timer',
      descriptionPt: 'Utilize o timer de tomate com visual de relógio de ponteiro para suas sessões de foco no estilo Pomodoro.',
      descriptionEn: 'Use the tomato timer with clock hand visual for your Pomodoro-style focus sessions.',
      icon: Icons.eco_rounded,
      type: TipType.hidden,
      category: FeatureCategory.timer,
      priority: 8,
    ),

    // --- TASKS ---
    FeatureTip(
      id: 'tasks_swipe',
      titlePt: 'Deslize para Completar',
      titleEn: 'Swipe to Complete',
      descriptionPt: 'Deslize uma tarefa para a direita para marcá-la como completa, ou para a esquerda para deletar.',
      descriptionEn: 'Swipe a task right to mark it complete, or left to delete.',
      icon: Icons.swipe_rounded,
      type: TipType.gesture,
      category: FeatureCategory.tasks,
      priority: 10,
    ),
    FeatureTip(
      id: 'tasks_tags',
      titlePt: 'Tags Coloridas',
      titleEn: 'Colored Tags',
      descriptionPt: 'Use tags para organizar suas tarefas por projeto, contexto ou prioridade. Cada tag pode ter sua própria cor!',
      descriptionEn: 'Use tags to organize your tasks by project, context or priority. Each tag can have its own color!',
      icon: Icons.label_rounded,
      type: TipType.feature,
      category: FeatureCategory.tasks,
    ),
    FeatureTip(
      id: 'tasks_voice',
      titlePt: 'Adicionar por Voz',
      titleEn: 'Add by Voice',
      descriptionPt: 'Toque e segure o botão de adicionar tarefa para ditar. O Odyssey transcreve automaticamente!',
      descriptionEn: 'Tap and hold the add task button to dictate. Odyssey transcribes automatically!',
      icon: Icons.mic_rounded,
      type: TipType.hidden,
      category: FeatureCategory.tasks,
      priority: 7,
    ),

    // --- NOTES ---
    FeatureTip(
      id: 'notes_markdown',
      titlePt: 'Markdown Support',
      titleEn: 'Markdown Support',
      descriptionPt: 'Use **negrito**, *itálico* e # títulos nas suas notas. O editor rico formata automaticamente!',
      descriptionEn: 'Use **bold**, *italic* and # headings in your notes. The rich editor formats automatically!',
      icon: Icons.text_format_rounded,
      type: TipType.shortcut,
      category: FeatureCategory.notes,
    ),
    FeatureTip(
      id: 'notes_templates',
      titlePt: 'Templates de Notas',
      titleEn: 'Note Templates',
      descriptionPt: 'Crie templates para tipos de notas que você usa com frequência, como diário, reuniões ou ideias.',
      descriptionEn: 'Create templates for note types you use frequently, like journal, meetings or ideas.',
      icon: Icons.dashboard_customize_rounded,
      type: TipType.productivity,
      category: FeatureCategory.notes,
    ),

    // --- LIBRARY ---
    FeatureTip(
      id: 'library_scan',
      titlePt: 'Busca Inteligente',
      titleEn: 'Smart Search',
      descriptionPt: 'Digite o nome de um livro e o Odyssey busca automaticamente na Open Library com capa e informações completas.',
      descriptionEn: 'Type a book name and Odyssey automatically searches Open Library with cover and complete info.',
      icon: Icons.search_rounded,
      type: TipType.feature,
      category: FeatureCategory.library,
    ),
    FeatureTip(
      id: 'library_progress',
      titlePt: 'Progresso de Leitura',
      titleEn: 'Reading Progress',
      descriptionPt: 'Atualize sua página atual em cada livro. O Odyssey calcula automaticamente seu progresso e ritmo de leitura.',
      descriptionEn: 'Update your current page in each book. Odyssey automatically calculates your progress and reading pace.',
      icon: Icons.auto_stories_rounded,
      type: TipType.feature,
      category: FeatureCategory.library,
    ),

    // --- SETTINGS ---
    FeatureTip(
      id: 'settings_backup',
      titlePt: 'Backup no Google Drive',
      titleEn: 'Google Drive Backup',
      descriptionPt: 'Configure backup automático para nunca perder seus dados. Conecte sua conta Google em Configurações.',
      descriptionEn: 'Set up automatic backup to never lose your data. Connect your Google account in Settings.',
      icon: Icons.backup_rounded,
      type: TipType.feature,
      category: FeatureCategory.settings,
      actionRoute: '/settings',
      priority: 10,
    ),
    FeatureTip(
      id: 'settings_themes',
      titlePt: 'Temas Personalizados',
      titleEn: 'Custom Themes',
      descriptionPt: 'Escolha entre vários temas de cores ou deixe o app seguir as cores do seu sistema (Material You).',
      descriptionEn: 'Choose from multiple color themes or let the app follow your system colors (Material You).',
      icon: Icons.palette_rounded,
      type: TipType.feature,
      category: FeatureCategory.settings,
    ),
    FeatureTip(
      id: 'settings_notifications',
      titlePt: 'Notificações Inteligentes',
      titleEn: 'Smart Notifications',
      descriptionPt: 'Configure lembretes personalizados para cada hábito e receba sugestões baseadas nos seus padrões.',
      descriptionEn: 'Set up personalized reminders for each habit and receive suggestions based on your patterns.',
      icon: Icons.notifications_active_rounded,
      type: TipType.productivity,
      category: FeatureCategory.settings,
    ),

    // --- GAMIFICATION ---
    FeatureTip(
      id: 'gamification_streaks',
      titlePt: 'Mantenha sua Streak',
      titleEn: 'Keep Your Streak',
      descriptionPt: 'Registre seu humor todos os dias para manter sua streak ativa e ganhar XP bônus!',
      descriptionEn: 'Log your mood every day to keep your streak active and earn bonus XP!',
      icon: Icons.local_fire_department_rounded,
      type: TipType.productivity,
      category: FeatureCategory.gamification,
      priority: 9,
    ),
    FeatureTip(
      id: 'gamification_achievements',
      titlePt: 'Conquistas Secretas',
      titleEn: 'Secret Achievements',
      descriptionPt: 'Existem conquistas secretas para descobrir! Explore todas as features do app para desbloqueá-las.',
      descriptionEn: 'There are secret achievements to discover! Explore all app features to unlock them.',
      icon: Icons.emoji_events_rounded,
      type: TipType.hidden,
      category: FeatureCategory.gamification,
    ),

    // --- GENERAL ---
    FeatureTip(
      id: 'general_sounds',
      titlePt: 'Sons de Interface',
      titleEn: 'Interface Sounds',
      descriptionPt: 'O Odyssey tem sons sutis de feedback. Você pode ajustar ou desativar em Configurações > Sons.',
      descriptionEn: 'Odyssey has subtle feedback sounds. You can adjust or disable them in Settings > Sounds.',
      icon: Icons.volume_up_rounded,
      type: TipType.tip,
      category: FeatureCategory.general,
    ),
    FeatureTip(
      id: 'general_keyboard',
      titlePt: 'Atalhos de Teclado',
      titleEn: 'Keyboard Shortcuts',
      descriptionPt: 'Em tablets e desktop, use atalhos de teclado: Ctrl+N para nova nota, Ctrl+T para nova tarefa.',
      descriptionEn: 'On tablets and desktop, use keyboard shortcuts: Ctrl+N for new note, Ctrl+T for new task.',
      icon: Icons.keyboard_rounded,
      type: TipType.shortcut,
      category: FeatureCategory.general,
    ),
  ];

  /// Retorna dicas filtradas por categoria
  static List<FeatureTip> byCategory(FeatureCategory category) {
    return all.where((tip) => tip.category == category).toList();
  }

  /// Retorna dicas filtradas por tipo
  static List<FeatureTip> byType(TipType type) {
    return all.where((tip) => tip.type == type).toList();
  }

  /// Retorna dicas não vistas
  static List<FeatureTip> unviewed(Set<String> viewedIds) {
    return all.where((tip) => !viewedIds.contains(tip.id)).toList();
  }

  /// Retorna uma dica aleatória não vista
  static FeatureTip? getRandomUnviewed(Set<String> viewedIds) {
    final unviewedTips = unviewed(viewedIds);
    if (unviewedTips.isEmpty) return null;
    
    // Prioriza por priority
    unviewedTips.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Retorna uma das 3 com maior prioridade aleatoriamente
    final topTips = unviewedTips.take(3).toList();
    topTips.shuffle();
    return topTips.first;
  }
}

/// Tours guiados por seção
class FeatureTours {
  static List<FeatureTour> all = [
    const FeatureTour(
      id: 'home_tour',
      sectionNamePt: 'Tela Inicial',
      sectionNameEn: 'Home Screen',
      category: FeatureCategory.general,
      estimatedSeconds: 45,
      steps: [
        CoachMark(
          id: 'home_mood_section',
          titlePt: 'Registro Rápido',
          titleEn: 'Quick Entry',
          descriptionPt: 'Toque em um emoji para registrar como está se sentindo agora.',
          descriptionEn: 'Tap an emoji to record how you\'re feeling now.',
          order: 1,
          nextMarkId: 'home_stats',
          category: FeatureCategory.mood,
        ),
        CoachMark(
          id: 'home_stats',
          titlePt: 'Suas Estatísticas',
          titleEn: 'Your Statistics',
          descriptionPt: 'Veja seu nível, XP e streak atuais. Cada ação te aproxima do próximo nível!',
          descriptionEn: 'See your current level, XP and streak. Every action brings you closer to the next level!',
          order: 2,
          nextMarkId: 'home_habits',
          category: FeatureCategory.gamification,
        ),
        CoachMark(
          id: 'home_habits',
          titlePt: 'Hábitos do Dia',
          titleEn: 'Today\'s Habits',
          descriptionPt: 'Seus hábitos para hoje aparecem aqui. Toque para marcar como feito!',
          descriptionEn: 'Your habits for today appear here. Tap to mark as done!',
          order: 3,
          category: FeatureCategory.habits,
        ),
      ],
    ),
    const FeatureTour(
      id: 'timer_tour',
      sectionNamePt: 'Timer Pomodoro',
      sectionNameEn: 'Pomodoro Timer',
      category: FeatureCategory.timer,
      estimatedSeconds: 60,
      steps: [
        CoachMark(
          id: 'timer_main',
          titlePt: 'Seu Timer',
          titleEn: 'Your Timer',
          descriptionPt: 'Configure o tempo e toque para iniciar. Use 25 minutos de foco + 5 de pausa.',
          descriptionEn: 'Set the time and tap to start. Use 25 minutes of focus + 5 break.',
          order: 1,
          nextMarkId: 'timer_sounds',
          category: FeatureCategory.timer,
        ),
        CoachMark(
          id: 'timer_sounds',
          titlePt: 'Sons Ambiente',
          titleEn: 'Ambient Sounds',
          descriptionPt: 'Ative sons relaxantes como chuva ou café para ajudar na concentração.',
          descriptionEn: 'Enable relaxing sounds like rain or café to help with concentration.',
          order: 2,
          nextMarkId: 'timer_sessions',
          category: FeatureCategory.timer,
        ),
        CoachMark(
          id: 'timer_sessions',
          titlePt: 'Histórico',
          titleEn: 'History',
          descriptionPt: 'Veja quantas sessões você completou e quanto tempo focou.',
          descriptionEn: 'See how many sessions you completed and how much time you focused.',
          order: 3,
          category: FeatureCategory.timer,
        ),
      ],
    ),
    // Tour de Notas
    const FeatureTour(
      id: 'notes_tour',
      sectionNamePt: 'Suas Notas',
      sectionNameEn: 'Your Notes',
      category: FeatureCategory.notes,
      estimatedSeconds: 50,
      steps: [
        CoachMark(
          id: 'notes_list',
          titlePt: 'Lista de Notas',
          titleEn: 'Notes List',
          descriptionPt: 'Todas as suas notas aparecem aqui. Toque em uma para editar ou criar uma nova.',
          descriptionEn: 'All your notes appear here. Tap one to edit or create a new one.',
          order: 1,
          nextMarkId: 'notes_add',
          category: FeatureCategory.notes,
        ),
        CoachMark(
          id: 'notes_add',
          titlePt: 'Nova Nota',
          titleEn: 'New Note',
          descriptionPt: 'Toque aqui para criar uma nota rapidamente. Use o editor rico para formatar seu texto.',
          descriptionEn: 'Tap here to quickly create a note. Use the rich editor to format your text.',
          order: 2,
          nextMarkId: 'notes_search',
          category: FeatureCategory.notes,
        ),
        CoachMark(
          id: 'notes_search',
          titlePt: 'Busca Inteligente',
          titleEn: 'Smart Search',
          descriptionPt: 'Encontre qualquer nota digitando palavras-chave. A busca é rápida e precisa!',
          descriptionEn: 'Find any note by typing keywords. The search is fast and accurate!',
          order: 3,
          category: FeatureCategory.notes,
        ),
      ],
    ),
    // Tour de Biblioteca
    const FeatureTour(
      id: 'library_tour',
      sectionNamePt: 'Biblioteca de Livros',
      sectionNameEn: 'Book Library',
      category: FeatureCategory.library,
      estimatedSeconds: 55,
      steps: [
        CoachMark(
          id: 'library_shelves',
          titlePt: 'Suas Estantes',
          titleEn: 'Your Shelves',
          descriptionPt: 'Organize seus livros em 3 estantes: para ler, lendo e concluídos.',
          descriptionEn: 'Organize your books in 3 shelves: to read, reading and completed.',
          order: 1,
          nextMarkId: 'library_add',
          category: FeatureCategory.library,
        ),
        CoachMark(
          id: 'library_add',
          titlePt: 'Adicionar Livro',
          titleEn: 'Add Book',
          descriptionPt: 'Busque por título ou autor. O Odyssey encontra capas e informações automaticamente!',
          descriptionEn: 'Search by title or author. Odyssey finds covers and info automatically!',
          order: 2,
          nextMarkId: 'library_progress',
          category: FeatureCategory.library,
        ),
        CoachMark(
          id: 'library_progress',
          titlePt: 'Progresso de Leitura',
          titleEn: 'Reading Progress',
          descriptionPt: 'Atualize sua página atual e veja seu ritmo de leitura e previsão de conclusão.',
          descriptionEn: 'Update your current page and see your reading pace and completion forecast.',
          order: 3,
          category: FeatureCategory.library,
        ),
      ],
    ),
    // Tour de Tarefas
    const FeatureTour(
      id: 'tasks_tour',
      sectionNamePt: 'Gerenciador de Tarefas',
      sectionNameEn: 'Task Manager',
      category: FeatureCategory.tasks,
      estimatedSeconds: 60,
      steps: [
        CoachMark(
          id: 'tasks_list',
          titlePt: 'Lista de Tarefas',
          titleEn: 'Task List',
          descriptionPt: 'Suas tarefas organizadas por prioridade. Deslize para completar ou deletar.',
          descriptionEn: 'Your tasks organized by priority. Swipe to complete or delete.',
          order: 1,
          nextMarkId: 'tasks_add',
          category: FeatureCategory.tasks,
        ),
        CoachMark(
          id: 'tasks_add',
          titlePt: 'Nova Tarefa',
          titleEn: 'New Task',
          descriptionPt: 'Adicione tarefas com título, data, prioridade e tags coloridas.',
          descriptionEn: 'Add tasks with title, date, priority and colored tags.',
          order: 2,
          nextMarkId: 'tasks_filter',
          category: FeatureCategory.tasks,
        ),
        CoachMark(
          id: 'tasks_filter',
          titlePt: 'Filtros e Tags',
          titleEn: 'Filters and Tags',
          descriptionPt: 'Filtre por tags, prioridade ou data. Crie sua própria organização!',
          descriptionEn: 'Filter by tags, priority or date. Create your own organization!',
          order: 3,
          category: FeatureCategory.tasks,
        ),
      ],
    ),
    // Tour de Hábitos
    const FeatureTour(
      id: 'habits_tour',
      sectionNamePt: 'Rastreador de Hábitos',
      sectionNameEn: 'Habit Tracker',
      category: FeatureCategory.habits,
      estimatedSeconds: 55,
      steps: [
        CoachMark(
          id: 'habits_streak',
          titlePt: 'Sua Streak',
          titleEn: 'Your Streak',
          descriptionPt: 'Veja quantos dias seguidos você mantém seus hábitos. Consistência é a chave!',
          descriptionEn: 'See how many consecutive days you maintain your habits. Consistency is key!',
          order: 1,
          nextMarkId: 'habits_calendar',
          category: FeatureCategory.habits,
        ),
        CoachMark(
          id: 'habits_calendar',
          titlePt: 'Calendário de Hábitos',
          titleEn: 'Habits Calendar',
          descriptionPt: 'Visualize seu progresso no calendário. Cada dia marcado mostra seus hábitos completados.',
          descriptionEn: 'Visualize your progress on the calendar. Each marked day shows your completed habits.',
          order: 2,
          category: FeatureCategory.habits,
        ),
      ],
    ),
  ];

  /// Retorna tour por ID
  static FeatureTour? byId(String id) {
    return all.firstWhereOrNull((tour) => tour.id == id);
  }

  /// Retorna tour por categoria
  static FeatureTour? byCategory(FeatureCategory category) {
    return all.firstWhereOrNull((tour) => tour.category == category);
  }
}
