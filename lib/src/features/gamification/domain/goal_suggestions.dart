/// Sugestões de metas inspiradoras para o usuário
///
/// Seguindo @ui-specialist: Metas com banners motivacionais
/// Seguindo @code-quality: Dados separados da lógica de apresentação

import 'package:odyssey/src/features/gamification/domain/user_stats.dart';

/// Categorias de metas
enum GoalCategory {
  financial,
  travel,
  education,
  health,
  career,
  personal;

  String get displayName {
    switch (this) {
      case GoalCategory.financial:
        return 'Financeiro';
      case GoalCategory.travel:
        return 'Viagens';
      case GoalCategory.education:
        return 'Educação';
      case GoalCategory.health:
        return 'Saúde';
      case GoalCategory.career:
        return 'Carreira';
      case GoalCategory.personal:
        return 'Pessoal';
    }
  }

  String get emoji {
    switch (this) {
      case GoalCategory.financial:
        return '💰';
      case GoalCategory.travel:
        return '✈️';
      case GoalCategory.education:
        return '📚';
      case GoalCategory.health:
        return '💪';
      case GoalCategory.career:
        return '💼';
      case GoalCategory.personal:
        return '⭐';
    }
  }
}

/// Template de meta sugerida
class GoalSuggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final String trackingType;
  final int targetValue;
  final String? bannerUrl;
  final String emoji;
  final List<String> tips;

  const GoalSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.trackingType,
    required this.targetValue,
    this.bannerUrl,
    required this.emoji,
    this.tips = const [],
  });

  /// Converte para PersonalGoal
  PersonalGoal toPersonalGoal() {
    return PersonalGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      targetValue: targetValue,
      type: 'custom',
      trackingType: trackingType,
      createdAt: DateTime.now(),
      bannerUrl: bannerUrl,
      category: category,
    );
  }
}

/// Lista de sugestões de metas inspiradoras
const List<GoalSuggestion> goalSuggestions = [
  // 💰 FINANCEIRO
  GoalSuggestion(
    id: 'buy_car',
    title: 'Comprar um Carro',
    description:
        'Juntar dinheiro para realizar o sonho do carro próprio. Liberdade para ir onde quiser!',
    category: 'financial',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800',
    emoji: '🚗',
    tips: [
      'Defina um valor alvo realista',
      'Pesquise modelos e preços',
      'Considere financiamento ou consórcio',
      'Separe uma % do salário todo mês',
    ],
  ),
  GoalSuggestion(
    id: 'buy_house',
    title: 'Comprar a Casa Própria',
    description: 'O maior investimento da vida. Um lar para chamar de seu!',
    category: 'financial',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
    emoji: '🏠',
    tips: [
      'Pesquise regiões e valores',
      'Simule financiamentos',
      'Junte para a entrada',
      'Considere FGTS',
    ],
  ),
  GoalSuggestion(
    id: 'emergency_fund',
    title: 'Reserva de Emergência',
    description:
        '6 meses de despesas guardados para imprevistos. Segurança financeira!',
    category: 'financial',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
    emoji: '🛡️',
    tips: [
      'Calcule suas despesas mensais',
      'Multiplique por 6',
      'Deixe em investimento de fácil resgate',
    ],
  ),

  // ✈️ VIAGENS
  GoalSuggestion(
    id: 'travel_abroad',
    title: 'Viajar para Outro País',
    description:
        'Explorar uma nova cultura, conhecer pessoas e criar memórias incríveis!',
    category: 'travel',
    trackingType: 'checklist',
    targetValue: 1,
    bannerUrl:
        'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
    emoji: '🌍',
    tips: [
      'Escolha o destino dos sonhos',
      'Pesquise passagens com antecedência',
      'Verifique necessidade de visto',
      'Faça um roteiro flexível',
    ],
  ),
  GoalSuggestion(
    id: 'visit_7_countries',
    title: 'Conhecer 7 Países',
    description:
        'Expandir horizontes visitando diferentes culturas ao redor do mundo.',
    category: 'travel',
    trackingType: 'counter',
    targetValue: 7,
    bannerUrl:
        'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800',
    emoji: '🗺️',
    tips: [
      'Faça uma lista de destinos prioritários',
      'Aproveite feriados prolongados',
      'Considere países vizinhos',
    ],
  ),
  GoalSuggestion(
    id: 'backpacking',
    title: 'Mochilão pela América do Sul',
    description:
        'Aventura épica explorando o continente de forma econômica e autêntica!',
    category: 'travel',
    trackingType: 'checklist',
    targetValue: 1,
    bannerUrl:
        'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800',
    emoji: '🎒',
    tips: [
      'Planeje rota e duração',
      'Pesquise hostels e transporte',
      'Prepare documentação',
    ],
  ),

  // 📚 EDUCAÇÃO
  GoalSuggestion(
    id: 'fluent_english',
    title: 'Fluente em Inglês',
    description:
        'Dominar o idioma mais falado no mundo. Portas abertas para oportunidades globais!',
    category: 'education',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1543109740-4bdb38fda756?w=800',
    emoji: '🇬🇧',
    tips: [
      'Estude diariamente (mesmo 15 min)',
      'Assista séries em inglês',
      'Pratique conversação',
      'Use apps como Duolingo',
    ],
  ),
  GoalSuggestion(
    id: 'learn_spanish',
    title: 'Aprender Espanhol',
    description:
        'A segunda língua mais falada nas Américas. Conecte-se com milhões de pessoas!',
    category: 'education',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1489945052260-4f21c52268b9?w=800',
    emoji: '🇪🇸',
    tips: [
      'Aproveite a similaridade com português',
      'Ouça músicas latinas',
      'Pratique com nativos online',
    ],
  ),
  GoalSuggestion(
    id: 'read_24_books',
    title: 'Ler 24 Livros no Ano',
    description: 'Dois livros por mês. Expandir conhecimento e imaginação!',
    category: 'education',
    trackingType: 'counter',
    targetValue: 24,
    bannerUrl:
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
    emoji: '📖',
    tips: [
      'Reserve 30 min diários para leitura',
      'Varie entre ficção e não-ficção',
      'Use Kindle ou audiobooks',
    ],
  ),
  GoalSuggestion(
    id: 'graduation',
    title: 'Concluir Graduação',
    description: 'Diploma na mão! O primeiro passo para uma carreira sólida.',
    category: 'education',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800',
    emoji: '🎓',
    tips: [
      'Organize cronograma de estudos',
      'Participe de grupos de estudo',
      'Não deixe matérias acumularem',
    ],
  ),

  // 💪 SAÚDE
  GoalSuggestion(
    id: 'run_marathon',
    title: 'Correr uma Maratona',
    description:
        '42km de superação pessoal. Provar que você pode ir além dos limites!',
    category: 'health',
    trackingType: 'checklist',
    targetValue: 1,
    bannerUrl:
        'https://images.unsplash.com/photo-1513593771513-7b58b6c4af38?w=800',
    emoji: '🏃',
    tips: [
      'Comece com distâncias menores',
      'Siga um plano de treino',
      'Cuide da alimentação',
      'Descanse adequadamente',
    ],
  ),
  GoalSuggestion(
    id: 'gym_365',
    title: '365 Dias de Academia',
    description: 'Um ano completo de treinos. Transformação física e mental!',
    category: 'health',
    trackingType: 'counter',
    targetValue: 365,
    bannerUrl:
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
    emoji: '🏋️',
    tips: [
      'Encontre um horário fixo',
      'Varie os treinos',
      'Descanse nos fins de semana se precisar',
    ],
  ),
  GoalSuggestion(
    id: 'meditation_100',
    title: '100 Dias de Meditação',
    description: 'Mente calma e focada. Paz interior e clareza mental!',
    category: 'health',
    trackingType: 'counter',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
    emoji: '🧘',
    tips: [
      'Comece com 5 minutos',
      'Use apps como Headspace',
      'Medite no mesmo horário',
    ],
  ),

  // 💼 CARREIRA
  GoalSuggestion(
    id: 'promotion',
    title: 'Conseguir Promoção',
    description: 'Subir de cargo e salário. Reconhecimento pelo seu trabalho!',
    category: 'career',
    trackingType: 'checklist',
    targetValue: 1,
    bannerUrl:
        'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
    emoji: '📈',
    tips: [
      'Defina objetivos claros',
      'Converse com seu gestor',
      'Desenvolva novas habilidades',
      'Documente suas conquistas',
    ],
  ),
  GoalSuggestion(
    id: 'start_business',
    title: 'Abrir Próprio Negócio',
    description: 'Empreender e ser seu próprio chefe. Liberdade e autonomia!',
    category: 'career',
    trackingType: 'checklist',
    targetValue: 1,
    bannerUrl:
        'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=800',
    emoji: '🚀',
    tips: [
      'Valide sua ideia',
      'Faça um plano de negócios',
      'Tenha reserva financeira',
      'Comece pequeno e teste',
    ],
  ),
  GoalSuggestion(
    id: 'freelance_income',
    title: 'Renda Extra Freelance',
    description:
        'Usar suas habilidades para ganhar dinheiro extra nas horas livres.',
    category: 'career',
    trackingType: 'counter',
    targetValue: 12,
    bannerUrl:
        'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=800',
    emoji: '💻',
    tips: [
      'Defina seu nicho',
      'Crie portfólio online',
      'Use plataformas como Upwork',
    ],
  ),

  // ⭐ PESSOAL
  GoalSuggestion(
    id: 'journal_365',
    title: 'Diário por 1 Ano',
    description:
        'Registrar pensamentos e reflexões diariamente. Autoconhecimento profundo!',
    category: 'personal',
    trackingType: 'counter',
    targetValue: 365,
    bannerUrl:
        'https://images.unsplash.com/photo-1471107340929-a87cd0f5b5f3?w=800',
    emoji: '📝',
    tips: [
      'Escreva antes de dormir',
      'Não se preocupe com gramática',
      'Seja honesto consigo mesmo',
    ],
  ),
  GoalSuggestion(
    id: 'learn_instrument',
    title: 'Aprender um Instrumento',
    description:
        'Tocar música é terapia para a alma. Violão, piano, ukulele...',
    category: 'personal',
    trackingType: 'percentage',
    targetValue: 100,
    bannerUrl:
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
    emoji: '🎸',
    tips: [
      'Escolha um instrumento acessível',
      'Pratique 15-30 min por dia',
      'Aprenda músicas que você gosta',
    ],
  ),
  GoalSuggestion(
    id: 'cooking_mastery',
    title: 'Dominar a Cozinha',
    description: 'Aprender 50 receitas diferentes. Chef em casa!',
    category: 'personal',
    trackingType: 'counter',
    targetValue: 50,
    bannerUrl:
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
    emoji: '👨‍🍳',
    tips: [
      'Comece com receitas simples',
      'Experimente novas culturas',
      'Documente suas criações',
    ],
  ),
  GoalSuggestion(
    id: 'digital_detox',
    title: '30 Dias Sem Redes Sociais',
    description: 'Desconectar para reconectar consigo mesmo. Paz mental!',
    category: 'personal',
    trackingType: 'counter',
    targetValue: 30,
    bannerUrl:
        'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
    emoji: '📵',
    tips: [
      'Delete os apps do celular',
      'Substitua por hobbies offline',
      'Avise amigos próximos',
    ],
  ),
];

/// Agrupa sugestões por categoria
Map<String, List<GoalSuggestion>> get suggestionsByCategory {
  final map = <String, List<GoalSuggestion>>{};
  for (final suggestion in goalSuggestions) {
    map.putIfAbsent(suggestion.category, () => []).add(suggestion);
  }
  return map;
}

/// Retorna sugestões aleatórias
List<GoalSuggestion> getRandomSuggestions(int count) {
  final shuffled = List<GoalSuggestion>.from(goalSuggestions)..shuffle();
  return shuffled.take(count).toList();
}
