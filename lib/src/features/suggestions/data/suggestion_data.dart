import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';

/// Base de dados curada com sugestões inteligentes
final List<Suggestion> allSuggestions = [
  // ============================================
  // LIFESTYLE & BEM-ESTAR (Novas - Práticas)
  // ============================================
  const Suggestion(
    id: 'habit_digital_sunset',
    title: 'Pôr do Sol Digital',
    description:
        'Desligue todas as telas 1h antes de dormir para melhorar a melatonina',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'bedtime',
    colorValue: 0xFF6366F1,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '22:00',
  ),

  const Suggestion(
    id: 'habit_power_nap',
    title: 'Power Nap Estratégica',
    description: 'Cochilo de 20min pós-almoço para resetar o foco',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'battery_charging_full',
    colorValue: 0xFFF59E0B,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '13:30',
  ),

  const Suggestion(
    id: 'habit_cold_shower',
    title: 'Banho Gelado (Método Wim Hof)',
    description:
        '30 segundos de água fria no final do banho para energia e imunidade',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'ac_unit',
    colorValue: 0xFF06B6D4,
    minLevel: 2,
    difficulty: SuggestionDifficulty.hard,
    scheduledTime: '07:00',
  ),

  const Suggestion(
    id: 'task_declutter_digital',
    title: 'Faxina Digital',
    description: 'Remova 5 apps que você não usa ou fotos antigas inúteis',
    type: SuggestionType.task,
    category: SuggestionCategory.selfActualization,
    iconKey: 'delete_sweep',
    colorValue: 0xFF6366F1,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  const Suggestion(
    id: 'habit_sunlight_viewing',
    title: 'Visualizar Luz Solar',
    description:
        'Exponha-se à luz natural nos primeiros 30min ao acordar (Huberman)',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'wb_sunny',
    colorValue: 0xFFF59E0B,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '07:30',
  ),

  const Suggestion(
    id: 'task_kindness_act',
    title: 'Ato de Bondade Aleatório',
    description: 'Faça algo bom por um estranho ou amigo sem esperar nada',
    type: SuggestionType.task,
    category: SuggestionCategory.relations,
    iconKey: 'volunteer_activism',
    colorValue: 0xFFEF4444,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  const Suggestion(
    id: 'habit_focused_work_block',
    title: 'Bloco de Foco Profundo',
    description: '90min de trabalho sem interrupções (Deep Work)',
    type: SuggestionType.habit,
    category: SuggestionCategory.selfActualization,
    iconKey: 'timer',
    colorValue: 0xFF10B981,
    minLevel: 2,
    difficulty: SuggestionDifficulty.medium,
  ),

  const Suggestion(
    id: 'task_learn_new_recipe',
    title: 'Cozinhar Prato Novo',
    description: 'Tente uma receita saudável que nunca fez antes',
    type: SuggestionType.task,
    category: SuggestionCategory.creation,
    iconKey: 'restaurant_menu',
    colorValue: 0xFFF59E0B,
    minLevel: 1,
    difficulty: SuggestionDifficulty.medium,
  ),

  const Suggestion(
    id: 'habit_no_sugar_challenge',
    title: 'Dia Zero Açúcar',
    description: 'Evite doces e açúcares adicionados por 24h',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'no_food',
    colorValue: 0xFFEF4444,
    minLevel: 2,
    difficulty: SuggestionDifficulty.medium,
  ),

  const Suggestion(
    id: 'task_podcast_ep',
    title: 'Ouvir Podcast Novo',
    description:
        'Escute um episódio sobre um tema que você desconhece totalmente',
    type: SuggestionType.task,
    category: SuggestionCategory.selfActualization,
    iconKey: 'headphones',
    colorValue: 0xFF6366F1,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  // ============================================
  // CLÁSSICAS (Mantidas - Filosóficas)
  // ============================================
  const Suggestion(
    id: 'habit_dream_analysis',
    title: 'Análise dos Sonhos',
    description: 'Registre seus sonhos ao acordar para autoconhecimento',
    type: SuggestionType.habit,
    category: SuggestionCategory.selfKnowledge,
    iconKey: 'psychology',
    colorValue: 0xFF9B51E0,
    minLevel: 2,
    difficulty: SuggestionDifficulty.medium,
    scheduledTime: '07:00',
    relatedActivities: ['meditation', 'relax'],
  ),

  const Suggestion(
    id: 'habit_mindful_walk',
    title: 'Caminhada Mindful',
    description: 'Ande 15min prestando total atenção no ambiente e sensações',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'directions_walk',
    colorValue: 0xFF10B981,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '07:30',
    relatedActivities: ['walk', 'excercise'],
  ),

  const Suggestion(
    id: 'habit_free_writing',
    title: 'Escrita Livre',
    description: '10min escrevendo tudo que vier à mente, sem censura',
    type: SuggestionType.habit,
    category: SuggestionCategory.creation,
    iconKey: 'create',
    colorValue: 0xFFF59E0B,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '08:00',
  ),

  const Suggestion(
    id: 'habit_stoic_reflection',
    title: 'Reflexão Estoica',
    description: 'Distingua o que você controla do que não controla',
    type: SuggestionType.habit,
    category: SuggestionCategory.selfKnowledge,
    iconKey: 'account_balance',
    colorValue: 0xFF6B7280,
    minLevel: 2,
    difficulty: SuggestionDifficulty.medium,
  ),

  const Suggestion(
    id: 'habit_gratefulness_journal',
    title: 'Diário de Gratidão',
    description: 'Liste 3 coisas simples pelas quais você é grato hoje',
    type: SuggestionType.habit,
    category: SuggestionCategory.selfKnowledge,
    iconKey: 'favorite',
    colorValue: 0xFFEF4444,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
    scheduledTime: '21:00',
  ),

  const Suggestion(
    id: 'task_read_chapter',
    title: 'Ler 1 Capítulo',
    description: 'Leia um capítulo de um livro (ficção ou não-ficção)',
    type: SuggestionType.task,
    category: SuggestionCategory.selfActualization,
    iconKey: 'menu_book',
    colorValue: 0xFF6366F1,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  const Suggestion(
    id: 'habit_pomodoro_session',
    title: 'Sessão Pomodoro',
    description: 'Complete pelo menos um ciclo de foco de 25 minutos',
    type: SuggestionType.habit,
    category: SuggestionCategory.selfActualization,
    iconKey: 'timer',
    colorValue: 0xFFEF4444,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  const Suggestion(
    id: 'habit_hydration_goal',
    title: 'Meta de Hidratação',
    description: 'Beba 2L de água ao longo do dia',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'water_drop',
    colorValue: 0xFF06B6D4,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),

  const Suggestion(
    id: 'habit_digital_detox_hour',
    title: 'Hora Offline',
    description: 'Fique 1h sem celular ou computador',
    type: SuggestionType.habit,
    category: SuggestionCategory.presence,
    iconKey: 'phonelink_off',
    colorValue: 0xFF6B7280,
    minLevel: 3,
    difficulty: SuggestionDifficulty.hard,
  ),

  const Suggestion(
    id: 'task_organize_workspace',
    title: 'Organizar Espaço',
    description: 'Arrume sua mesa ou ambiente de trabalho',
    type: SuggestionType.task,
    category: SuggestionCategory.selfActualization,
    iconKey: 'cleaning_services',
    colorValue: 0xFF6366F1,
    minLevel: 1,
    difficulty: SuggestionDifficulty.easy,
  ),
];
