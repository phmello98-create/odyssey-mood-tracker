import '../domain/post.dart';
import '../domain/user_profile.dart';
import '../domain/topic.dart';

/// Repositório Mock para desenvolvimento e testes
/// Retorna dados fictícios realistas com karma, badges, imagens, tags e views
class MockCommunityData {
  static final List<Post> _mockPosts = [
    // 📌 PINNED POST
    Post(
      id: 'post_pinned_1',
      userId: 'user_admin',
      userName: 'Odyssey Team',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=odyssey',
      userLevel: 50,
      content:
          '📢 ANÚNCIO IMPORTANTE\n\nBem-vindos à Comunidade Odyssey! 🚀\n\nRegras básicas:\n• Respeite todos os membros\n• Compartilhe suas experiências\n• Ajude quem precisa\n• Sem spam ou autopromoção\n\nDúvidas? Pergunte! 💬',
      type: PostType.text,
      upvotes: 892,
      downvotes: 2,
      viewCount: 15234,
      commentCount: 156,
      authorKarma: 99999,
      authorFlair: 'Admin',
      authorBadge: 'official',
      tags: ['anúncio', 'regras', 'comunidade'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      categories: [CommunityTopic.general.name],
      metadata: {'isPinned': true},
    ),
    Post(
      id: 'post_1',
      userId: 'user_1',
      userName: 'Ana Silva',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=ana',
      userLevel: 12,
      content:
          'Bom dia, pessoal! 👋 Acabei de completar minha primeira semana usando o Odyssey e já sinto uma diferença enorme na minha produtividade. O timer Pomodoro tem me ajudado muito a manter o foco! #produtividade #foco #metas',
      type: PostType.text,
      upvotes: 127,
      downvotes: 3,
      viewCount: 892,
      commentCount: 23,
      authorKarma: 3247,
      authorFlair: 'Mentora',
      authorBadge: 'karma_1000',
      tags: ['produtividade', 'foco', 'metas'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      categories: [
        CommunityTopic.productivity.name,
        CommunityTopic.general.name,
      ],
    ),
    Post(
      id: 'post_2',
      userId: 'user_2',
      userName: 'Carlos Mendes',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=carlos',
      userLevel: 8,
      content:
          'Alguém mais aqui luta com ansiedade antes de tarefas importantes? Descobri que fazer 5 minutos de respiração consciente antes ajuda MUITO. Compartilho essa dica com vocês! 🧘‍♂️ #meditação #ansiedade #mindfulness',
      type: PostType.insight,
      upvotes: 234,
      downvotes: 5,
      viewCount: 1543,
      commentCount: 45,
      authorKarma: 1856,
      authorFlair: 'Guia',
      authorBadge: 'mindfulness_guru',
      tags: ['meditação', 'ansiedade', 'mindfulness'],
      imageUrls: [
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      categories: [CommunityTopic.mindfulness.name, CommunityTopic.tips.name],
    ),
    Post(
      id: 'post_3',
      userId: 'user_3',
      userName: 'Marina Costa',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=marina',
      userLevel: 15,
      content:
          '🏆 CONQUISTA DESBLOQUEADA! Acabei de atingir 100 horas de foco total! Quando comecei, mal conseguia 25 minutos sem me distrair. A jornada vale a pena, pessoal! #conquistas #foco #vitória',
      type: PostType.achievement,
      upvotes: 456,
      downvotes: 2,
      viewCount: 2876,
      commentCount: 67,
      authorKarma: 8934,
      authorFlair: 'Sábia',
      authorBadge: 'karma_1000',
      tags: ['conquistas', 'foco', 'vitória'],
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      categories: [
        CommunityTopic.achievements.name,
        CommunityTopic.motivation.name,
      ],
      metadata: {'hours': 100, 'achievement': 'focus_master'},
    ),
    Post(
      id: 'post_4',
      userId: 'user_4',
      userName: 'Pedro Oliveira',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=pedro',
      userLevel: 5,
      content:
          'Hoje está sendo um dia difícil... Não consegui manter minha streak de hábitos. Mas tudo bem, amanhã recomeço. Alguém tem palavras de encorajamento? 💙 #apoio #saúdemental',
      type: PostType.mood,
      upvotes: 189,
      downvotes: 0,
      viewCount: 756,
      commentCount: 89,
      authorKarma: 542,
      authorFlair: 'Guia',
      authorBadge: 'supporter',
      tags: ['apoio', 'saúdemental'],
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      categories: [CommunityTopic.support.name, CommunityTopic.wellness.name],
      metadata: {'mood': 'struggling'},
    ),
    Post(
      id: 'post_5',
      userId: 'user_5',
      userName: 'Julia Santos',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=julia',
      userLevel: 10,
      content:
          'Dica de ouro: Criei uma playlist específica para cada tipo de tarefa. Música instrumental para estudar, lo-fi para trabalho criativo, e energética para exercícios. Mudou meu jogo! 🎧 #dicas #produtividade #rotina',
      type: PostType.text,
      upvotes: 312,
      downvotes: 8,
      viewCount: 2103,
      commentCount: 34,
      authorKarma: 2156,
      authorFlair: 'Mentora',
      authorBadge: 'productivity_master',
      tags: ['dicas', 'produtividade', 'rotina'],
      imageUrls: [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      categories: [CommunityTopic.tips.name, CommunityTopic.productivity.name],
    ),
    Post(
      id: 'post_6',
      userId: 'user_6',
      userName: 'Rafael Lima',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=rafael',
      userLevel: 7,
      content:
          'Meditei por 20 minutos hoje sem me distrair nem uma vez! Pequenas vitórias importam. Há um mês, eu mal conseguia 2 minutos. Progresso é progresso! 🌟 #mindfulness #progresso',
      type: PostType.achievement,
      upvotes: 156,
      downvotes: 1,
      viewCount: 534,
      commentCount: 28,
      authorKarma: 789,
      authorFlair: 'Guia',
      authorBadge: 'streak_7',
      tags: ['mindfulness', 'progresso'],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      categories: [
        CommunityTopic.mindfulness.name,
        CommunityTopic.achievements.name,
      ],
    ),
    Post(
      id: 'post_7',
      userId: 'user_7',
      userName: 'Beatriz Alves',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=beatriz',
      userLevel: 13,
      content:
          'Lembrete importante: Não se compare com os outros. Cada um tem seu próprio ritmo e jornada. Você está exatamente onde precisa estar. Continue! 💚 #motivação #inspiração #apoio',
      type: PostType.insight,
      upvotes: 567,
      downvotes: 4,
      viewCount: 3421,
      commentCount: 78,
      authorKarma: 5643,
      authorFlair: 'Sábia',
      authorBadge: 'top_contributor',
      tags: ['motivação', 'inspiração', 'apoio'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      categories: [CommunityTopic.motivation.name, CommunityTopic.support.name],
    ),
    Post(
      id: 'post_8',
      userId: 'user_8',
      userName: 'Lucas Ferreira',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=lucas',
      userLevel: 9,
      content:
          'Alguém mais usa a técnica 2-2-2? 2 horas de foco profundo, 2 horas de tarefas leves, 2 horas de aprendizado. Tem funcionado muito bem para mim! #produtividade #dicas #foco',
      type: PostType.text,
      upvotes: 203,
      downvotes: 12,
      viewCount: 1234,
      commentCount: 56,
      authorKarma: 1432,
      authorFlair: 'Mentor',
      authorBadge: 'writer_10',
      tags: ['produtividade', 'dicas', 'foco'],
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      categories: [CommunityTopic.productivity.name, CommunityTopic.tips.name],
    ),
    // NEW POSTS
    Post(
      id: 'post_9',
      userId: 'user_9',
      userName: 'Fernanda Dias',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=fernanda',
      userLevel: 18,
      content:
          '📚 Terminei de ler "Atomic Habits" e PRECISO compartilhar: A chave é focar em sistemas, não em metas. O processo > resultado. Quem mais leu? O que acharam? #leitura #hábitos #crescimento',
      type: PostType.insight,
      upvotes: 423,
      downvotes: 3,
      viewCount: 2890,
      commentCount: 92,
      authorKarma: 7823,
      authorFlair: 'Sábia',
      authorBadge: 'book_lover',
      tags: ['leitura', 'hábitos', 'crescimento'],
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      categories: [CommunityTopic.tips.name, CommunityTopic.general.name],
    ),
    Post(
      id: 'post_10',
      userId: 'user_10',
      userName: 'Thiago Rocha',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=thiago',
      userLevel: 6,
      content:
          'Primeira semana acordando às 5h da manhã! ☀️ No início foi difícil, mas agora já estou curtindo o silêncio matinal. Alguém mais é do club das 5? #rotina #morningperson #desafio',
      type: PostType.text,
      upvotes: 89,
      downvotes: 15,
      viewCount: 567,
      commentCount: 34,
      authorKarma: 432,
      authorFlair: 'Aprendiz',
      tags: ['rotina', 'morningperson', 'desafio'],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      categories: [
        CommunityTopic.productivity.name,
        CommunityTopic.wellness.name,
      ],
    ),
    Post(
      id: 'post_11',
      userId: 'user_11',
      userName: 'Isabela Nunes',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=isabela',
      userLevel: 14,
      content:
          '🎯 30 dias completando TODOS os hábitos! Streak perfeita! O segredo? Comecei com apenas 3 micro-hábitos e fui adicionando gradualmente. Menos é mais no começo! #streak #hábitos #vitória',
      type: PostType.achievement,
      upvotes: 678,
      downvotes: 1,
      viewCount: 4532,
      commentCount: 123,
      authorKarma: 6234,
      authorFlair: 'Mestra',
      authorBadge: 'streak_30',
      tags: ['streak', 'hábitos', 'vitória'],
      imageUrls: [
        'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=400',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      categories: [
        CommunityTopic.achievements.name,
        CommunityTopic.motivation.name,
      ],
    ),
    Post(
      id: 'post_12',
      userId: 'user_12',
      userName: 'Gabriel Martins',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=gabriel',
      userLevel: 11,
      content:
          'Aqui vai uma confissão: Tenho procrastinado o dia todo. Às vezes acontece, né? Amanhã eu volto mais forte. Vocês também têm dias assim? #honestidade #procrastinação #humano',
      type: PostType.mood,
      upvotes: 234,
      downvotes: 0,
      viewCount: 987,
      commentCount: 156,
      authorKarma: 2341,
      authorFlair: 'Mentor',
      tags: ['honestidade', 'procrastinação', 'humano'],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      categories: [CommunityTopic.support.name, CommunityTopic.general.name],
    ),
    Post(
      id: 'post_13',
      userId: 'user_13',
      userName: 'Camila Souza',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=camila',
      userLevel: 16,
      content:
          '✨ DICA DE ORGANIZAÇÃO ✨\n\nUsem a "Regra dos 2 minutos": se uma tarefa leva menos de 2 minutos, faça AGORA. Isso elimina a maioria das pequenas pendências que nos drenam!\n\n#produtividade #gtd #organização',
      type: PostType.insight,
      upvotes: 512,
      downvotes: 7,
      viewCount: 3210,
      commentCount: 67,
      authorKarma: 7890,
      authorFlair: 'Sábia',
      authorBadge: 'tip_master',
      tags: ['produtividade', 'gtd', 'organização'],
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 10)),
      categories: [CommunityTopic.tips.name, CommunityTopic.productivity.name],
    ),
    Post(
      id: 'post_14',
      userId: 'user_14',
      userName: 'Diego Andrade',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=diego',
      userLevel: 4,
      content:
          'Sou novo aqui! 👋 Vim tentar melhorar meus hábitos de estudo. Alguém tem dicas para quem está começando? Aceito todas as sugestões! #novato #estudos #ajuda',
      type: PostType.text,
      upvotes: 56,
      downvotes: 0,
      viewCount: 234,
      commentCount: 45,
      authorKarma: 123,
      authorFlair: 'Iniciante',
      tags: ['novato', 'estudos', 'ajuda'],
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      categories: [CommunityTopic.general.name, CommunityTopic.support.name],
    ),
    Post(
      id: 'post_15',
      userId: 'user_15',
      userName: 'Larissa Pinto',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=larissa',
      userLevel: 20,
      content:
          '🧘‍♀️ 1000 minutos de meditação acumulados no app!\n\nO que mudou na minha vida:\n• Menos ansiedade\n• Melhor foco\n• Sono mais tranquilo\n• Mais paciência\n\nMeditação realmente transforma! #meditação #milestone #transformação',
      type: PostType.achievement,
      upvotes: 789,
      downvotes: 2,
      viewCount: 5678,
      commentCount: 134,
      authorKarma: 12345,
      authorFlair: 'Iluminada',
      authorBadge: 'meditation_master',
      tags: ['meditação', 'milestone', 'transformação'],
      imageUrls: [
        'https://images.unsplash.com/photo-1545389336-cf090694435e?w=400',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      categories: [
        CommunityTopic.achievements.name,
        CommunityTopic.mindfulness.name,
      ],
    ),
    Post(
      id: 'post_16',
      userId: 'user_16',
      userName: 'Renato Vieira',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=renato',
      userLevel: 8,
      content:
          'Pergunta séria: Vocês usam mais a técnica Pomodoro tradicional (25/5) ou adaptam para intervalos maiores? Eu prefiro 50/10, mas quero saber o que funciona pra vocês! 🍅⏱️',
      type: PostType.text,
      upvotes: 145,
      downvotes: 3,
      viewCount: 876,
      commentCount: 89,
      authorKarma: 987,
      authorFlair: 'Guia',
      tags: ['pomodoro', 'produtividade', 'enquete'],
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 7)),
      categories: [CommunityTopic.productivity.name, CommunityTopic.tips.name],
    ),
    Post(
      id: 'post_17',
      userId: 'user_17',
      userName: 'Vanessa Moreira',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=vanessa',
      userLevel: 12,
      content:
          'Precisando de apoio hoje 💔 Perdi um prazo importante no trabalho porque subestimei o tempo necessário. Como vocês lidam com a frustração de não atingir uma meta?',
      type: PostType.mood,
      upvotes: 167,
      downvotes: 0,
      viewCount: 654,
      commentCount: 112,
      authorKarma: 2876,
      authorFlair: 'Mentora',
      tags: ['apoio', 'frustração', 'crescimento'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      categories: [CommunityTopic.support.name, CommunityTopic.wellness.name],
    ),
    Post(
      id: 'post_18',
      userId: 'user_18',
      userName: 'André Costa',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=andre',
      userLevel: 19,
      content:
          '💪 Guia completo: Como construir uma rotina matinal imbatível!\n\n1. Durma cedo (antes das 23h)\n2. Acorde no primeiro alarme\n3. Nada de celular por 30min\n4. Hidrate-se imediatamente\n5. 10min de movimento\n6. Visualize o dia\n\nTestar por 21 dias! #rotina #morning #guia',
      type: PostType.insight,
      upvotes: 834,
      downvotes: 12,
      viewCount: 7654,
      commentCount: 145,
      authorKarma: 11234,
      authorFlair: 'Sábio',
      authorBadge: 'guide_creator',
      tags: ['rotina', 'morning', 'guia'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      categories: [CommunityTopic.tips.name, CommunityTopic.productivity.name],
    ),
    Post(
      id: 'post_19',
      userId: 'user_19',
      userName: 'Priscila Ramos',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=priscila',
      userLevel: 7,
      content:
          'Foto do meu setup de estudos! 📚💻 Minimalista e funcional. Mesa limpa = mente clara. O que vocês acham? Aceito sugestões! #setup #estudos #organização',
      type: PostType.image,
      upvotes: 278,
      downvotes: 5,
      viewCount: 1890,
      commentCount: 56,
      authorKarma: 876,
      authorFlair: 'Guia',
      tags: ['setup', 'estudos', 'organização'],
      imageUrls: [
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
        'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=400',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 14)),
      categories: [
        CommunityTopic.productivity.name,
        CommunityTopic.general.name,
      ],
    ),
    Post(
      id: 'post_20',
      userId: 'user_20',
      userName: 'Marcelo Dias',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=marcelo',
      userLevel: 22,
      content:
          '🔥 500 DIAS DE STREAK! 🔥\n\nNunca pensei que conseguiria! Começou como um experimento e virou um estilo de vida. O segredo? Ser consistente, não perfeito. Aparecer todo dia, mesmo quando não estou motivado.\n\n#streak #epic #milestone #nuncarenunciar',
      type: PostType.achievement,
      upvotes: 1234,
      downvotes: 3,
      viewCount: 12345,
      commentCount: 234,
      authorKarma: 25678,
      authorFlair: 'Lenda',
      authorBadge: 'streak_champion',
      tags: ['streak', 'epic', 'milestone', 'nuncarenunciar'],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
      categories: [
        CommunityTopic.achievements.name,
        CommunityTopic.motivation.name,
      ],
    ),
  ];

  static final List<PublicUserProfile> _mockUsers = [
    // ADMIN
    PublicUserProfile(
      userId: 'user_admin',
      displayName: 'Odyssey Team',
      photoUrl: 'https://i.pravatar.cc/150?u=odyssey',
      level: 50,
      totalXP: 999999,
      badges: ['official', 'admin', 'founder'],
      bio: 'Equipe oficial do Odyssey 🚀 | Estamos aqui para ajudar!',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    PublicUserProfile(
      userId: 'user_1',
      displayName: 'Ana Silva',
      photoUrl: 'https://i.pravatar.cc/150?u=ana',
      level: 12,
      totalXP: 3200,
      badges: ['early_bird', 'focus_master', 'karma_1000'],
      bio: 'Apaixonada por produtividade e mindfulness 🌸 | 3.2k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_2',
      displayName: 'Carlos Mendes',
      photoUrl: 'https://i.pravatar.cc/150?u=carlos',
      level: 8,
      totalXP: 1850,
      badges: ['meditation_guru', 'mindfulness_guru'],
      bio: 'Praticante de meditação e respiração consciente | 1.8k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PublicUserProfile(
      userId: 'user_3',
      displayName: 'Marina Costa',
      photoUrl: 'https://i.pravatar.cc/150?u=marina',
      level: 15,
      totalXP: 4500,
      badges: [
        'focus_master',
        'streak_keeper',
        'achievement_hunter',
        'karma_1000',
        'top_contributor',
      ],
      bio: 'Desenvolvedora | 100h+ de foco | 8.9k karma | Sempre aprendendo',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    PublicUserProfile(
      userId: 'user_7',
      displayName: 'Beatriz Alves',
      photoUrl: 'https://i.pravatar.cc/150?u=beatriz',
      level: 13,
      totalXP: 3800,
      badges: ['top_contributor', 'karma_1000', 'supporter'],
      bio: 'Ajudando pessoas a serem melhores ❤️ | 5.6k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PublicUserProfile(
      userId: 'user_9',
      displayName: 'Fernanda Dias',
      photoUrl: 'https://i.pravatar.cc/150?u=fernanda',
      level: 18,
      totalXP: 5600,
      badges: ['book_lover', 'wise_owl', 'karma_5000'],
      bio: 'Leitora ávida | Growth mindset | 7.8k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      lastActive: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    PublicUserProfile(
      userId: 'user_11',
      displayName: 'Isabela Nunes',
      photoUrl: 'https://i.pravatar.cc/150?u=isabela',
      level: 14,
      totalXP: 4200,
      badges: ['streak_30', 'consistency_queen', 'habit_master'],
      bio: '🎯 30+ dias de streak | Micro-hábitos | 6.2k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    PublicUserProfile(
      userId: 'user_15',
      displayName: 'Larissa Pinto',
      photoUrl: 'https://i.pravatar.cc/150?u=larissa',
      level: 20,
      totalXP: 7800,
      badges: ['meditation_master', 'zen_master', 'karma_10000'],
      bio: '🧘‍♀️ 1000+ min meditação | Paz interior | 12k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_18',
      displayName: 'André Costa',
      photoUrl: 'https://i.pravatar.cc/150?u=andre',
      level: 19,
      totalXP: 6900,
      badges: ['guide_creator', 'helpful_hero', 'karma_10000'],
      bio: '💪 Criador de guias | Morning routine | 11k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PublicUserProfile(
      userId: 'user_20',
      displayName: 'Marcelo Dias',
      photoUrl: 'https://i.pravatar.cc/150?u=marcelo',
      level: 22,
      totalXP: 12000,
      badges: ['streak_champion', 'legendary', 'karma_25000', 'og_member'],
      bio: '🔥 500+ dias de streak | Lenda viva | 25k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 550)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    PublicUserProfile(
      userId: 'user_14',
      displayName: 'Diego Andrade',
      photoUrl: 'https://i.pravatar.cc/150?u=diego',
      level: 4,
      totalXP: 450,
      badges: ['newcomer'],
      bio: 'Novo por aqui! Buscando melhorar meus estudos 📚',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    PublicUserProfile(
      userId: 'user_10',
      displayName: 'Thiago Rocha',
      photoUrl: 'https://i.pravatar.cc/150?u=thiago',
      level: 6,
      totalXP: 890,
      badges: ['early_bird', 'morning_warrior'],
      bio: '☀️ Club das 5h | Acordando cedo desde 2024',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PublicUserProfile(
      userId: 'user_12',
      displayName: 'Gabriel Martins',
      photoUrl: 'https://i.pravatar.cc/150?u=gabriel',
      level: 11,
      totalXP: 2800,
      badges: ['supporter', 'encourager'],
      bio: 'Humano tentando ser melhor | 2.3k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_17',
      displayName: 'Vanessa Moreira',
      photoUrl: 'https://i.pravatar.cc/150?u=vanessa',
      level: 12,
      totalXP: 3100,
      badges: ['mentor', 'karma_1000'],
      bio: 'Mentora | Compartilhando a jornada | 2.8k karma',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  /// Retorna lista de posts mock
  static List<Post> getPosts({int limit = 20}) {
    return _mockPosts.take(limit).toList();
  }

  /// Retorna um post específico
  static Post? getPost(String postId) {
    try {
      return _mockPosts.firstWhere((p) => p.id == postId);
    } catch (_) {
      return null;
    }
  }

  /// Retorna posts filtrados por tópico
  static List<Post> getPostsByTopic(CommunityTopic topic, {int limit = 20}) {
    return _mockPosts
        .where((p) => p.categories.contains(topic.name))
        .take(limit)
        .toList();
  }

  /// Retorna posts de um usuário
  static List<Post> getPostsByUser(String userId, {int limit = 20}) {
    return _mockPosts.where((p) => p.userId == userId).take(limit).toList();
  }

  /// Busca posts por query
  static List<Post> searchPosts(String query) {
    final lowerQuery = query.toLowerCase();
    return _mockPosts
        .where(
          (p) =>
              p.content.toLowerCase().contains(lowerQuery) ||
              p.userName.toLowerCase().contains(lowerQuery) ||
              p.tags.any((t) => t.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }

  /// Retorna perfil de usuário
  static PublicUserProfile? getUserProfile(String userId) {
    try {
      return _mockUsers.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Busca usuários
  static List<PublicUserProfile> searchUsers(String query) {
    final lowerQuery = query.toLowerCase();
    return _mockUsers
        .where((u) => u.displayName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Retorna posts em destaque (trending)
  static List<Post> getTrendingPosts({int limit = 5}) {
    final sorted = List<Post>.from(_mockPosts);
    sorted.sort((a, b) => b.engagement.compareTo(a.engagement));
    return sorted.take(limit).toList();
  }

  /// Retorna tags populares
  static List<String> getTrendingTags({int limit = 10}) {
    final tagCount = <String, int>{};
    for (final post in _mockPosts) {
      for (final tag in post.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
