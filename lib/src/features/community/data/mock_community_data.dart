import '../domain/post.dart';
import '../domain/comment.dart';
import '../domain/user_profile.dart';
import '../domain/topic.dart';
import '../domain/follow.dart';

/// Repositório Mock para desenvolvimento e testes
/// Retorna dados fictícios realistas com karma, badges, imagens, tags e views
class MockCommunityData {
  // ===========================================================================
  // USERS (26 Profiles)
  // ===========================================================================

  static final List<PublicUserProfile> _mockUsers = [
    // ===========================================================================
    // BOTS OFICIAIS (4 Bots com personalidade)
    // ===========================================================================
    PublicUserProfile(
      userId: 'bot_beatnix',
      displayName: 'Beatnix',
      photoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=beatnix&backgroundColor=6366f1',
      level: 99,
      totalXP: 999999,
      badges: ['bot_official', 'music_curator'],
      bio:
          '🎧 Curador musical do Odyssey | Viciado em café e frequências baixas | Bot Oficial',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    PublicUserProfile(
      userId: 'bot_erro404',
      displayName: 'Erro 404',
      photoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=erro404&backgroundColor=10b981',
      level: 99,
      totalXP: 999999,
      badges: ['bot_official', 'comedian'],
      bio:
          '🤖 Estagiário de Silício | Tentando entender humanos desde 2024 | Bugs existenciais inclusos',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    PublicUserProfile(
      userId: 'bot_wiki',
      displayName: 'Wiki',
      photoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=wiki&backgroundColor=8b5cf6',
      level: 99,
      totalXP: 999999,
      badges: ['bot_official', 'knowledge_seeker'],
      bio:
          '🧠 Banco de Dados Vivo | Curiosidades que fazem você parar e pensar | Fatos > Opiniões',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    PublicUserProfile(
      userId: 'bot_turbo',
      displayName: 'Turbo',
      photoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=turbo&backgroundColor=f59e0b',
      level: 99,
      totalXP: 999999,
      badges: ['bot_official', 'motivator', 'challenge_master'],
      bio:
          '⚡ Gerente de Caos | Desafios, XP e muita energia | Se você não tá suando, não tá tentando',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    // ===========================================================================
    // ADMIN
    // ===========================================================================
    PublicUserProfile(
      userId: 'user_admin',
      displayName: 'Odyssey Team',
      photoUrl: 'https://i.pravatar.cc/150?u=odyssey',
      level: 50,
      totalXP: 100000,
      badges: ['admin', 'founder'],
      bio: 'Equipe oficial do Odyssey 🚀 | Estamos aqui para ajudar!',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastActive: DateTime.now(),
    ),
    // USERS 1-25
    PublicUserProfile(
      userId: 'user_1',
      displayName: 'Maria Santos',
      photoUrl: 'https://i.pravatar.cc/150?u=maria',
      level: 15,
      totalXP: 4500,
      badges: ['creator', 'popular'],
      bio: 'Apaixonada por mindfulness e produtividade 🌸',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      lastActive: DateTime.now(),
    ),
    PublicUserProfile(
      userId: 'user_2',
      displayName: 'Lucas Ferreira',
      photoUrl: 'https://i.pravatar.cc/150?u=lucas',
      level: 8,
      totalXP: 1200,
      badges: ['early_bird'],
      bio: 'Buscando equilíbrio dia após dia.',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    PublicUserProfile(
      userId: 'user_3',
      displayName: 'Ana Silva',
      photoUrl: 'https://i.pravatar.cc/150?u=ana',
      level: 12,
      totalXP: 3200,
      badges: ['streak_master_30'],
      bio: 'Yoga | Meditação | Leitura 📚',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    PublicUserProfile(
      userId: 'user_4',
      displayName: 'Pedro Oliveira',
      photoUrl: 'https://i.pravatar.cc/150?u=pedro',
      level: 5,
      totalXP: 542,
      badges: ['supporter'],
      bio: 'Começando a jornada de autoconhecimento.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_5',
      displayName: 'Julia Santos',
      photoUrl: 'https://i.pravatar.cc/150?u=julia',
      level: 20,
      totalXP: 8900,
      badges: ['mentor', 'top_contributor'],
      bio: 'Psicóloga e entusiasta de tecnologia.',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PublicUserProfile(
      userId: 'user_6',
      displayName: 'Marcos Souza',
      photoUrl: 'https://i.pravatar.cc/150?u=marcos',
      level: 10,
      totalXP: 2100,
      badges: ['focus_master'],
      bio: 'Foco total! 🎯',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActive: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    PublicUserProfile(
      userId: 'user_7',
      displayName: 'Beatriz Costa',
      photoUrl: 'https://i.pravatar.cc/150?u=beatriz',
      level: 14,
      totalXP: 3800,
      badges: ['night_owl'],
      bio: 'Estudante de medicina | Sobrevivendo aos plantões',
      createdAt: DateTime.now().subtract(const Duration(days: 110)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    PublicUserProfile(
      userId: 'user_8',
      displayName: 'Fernanda Lima',
      photoUrl: 'https://i.pravatar.cc/150?u=fernanda',
      level: 7,
      totalXP: 980,
      badges: ['newcomer'],
      bio: 'Amante da natureza 🌿',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PublicUserProfile(
      userId: 'user_9',
      displayName: 'Ricardo Almeida',
      photoUrl: 'https://i.pravatar.cc/150?u=ricardo',
      level: 18,
      totalXP: 6700,
      badges: ['streak_master_100', 'motivator'],
      bio: '100 dias seguidos de meditação! 🧘‍♂️',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_10',
      displayName: 'Camila Rodrigues',
      photoUrl: 'https://i.pravatar.cc/150?u=camila',
      level: 16,
      totalXP: 5120,
      badges: ['productivity_guru'],
      bio: 'GTD & Bullet Journal lover 📝',
      createdAt: DateTime.now().subtract(const Duration(days: 130)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    PublicUserProfile(
      userId: 'user_11',
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
      userId: 'user_13',
      displayName: 'Mariana Costa',
      photoUrl: 'https://i.pravatar.cc/150?u=mariana',
      level: 9,
      totalXP: 1500,
      badges: ['bookworm'],
      bio: 'Lendo 1 livro por semana 📖',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      lastActive: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    PublicUserProfile(
      userId: 'user_14',
      displayName: 'Rafael Lima',
      photoUrl: 'https://i.pravatar.cc/150?u=rafael',
      level: 13,
      totalXP: 3500,
      badges: ['gym_rat'],
      bio: 'Crossfit e alimentação saudável 💪',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    PublicUserProfile(
      userId: 'user_15',
      displayName: 'Bruno Santos',
      photoUrl: 'https://i.pravatar.cc/150?u=bruno',
      level: 4,
      totalXP: 400,
      badges: ['newcomer'],
      bio: 'Novo por aqui!',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastActive: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    PublicUserProfile(
      userId: 'user_16',
      displayName: 'Patricia Silva',
      photoUrl: 'https://i.pravatar.cc/150?u=patricia',
      level: 19,
      totalXP: 7800,
      badges: ['meditator_expert'],
      bio: 'Instrutora de Mindfulness',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
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
    PublicUserProfile(
      userId: 'user_18',
      displayName: 'Rodrigo Ferreira',
      photoUrl: 'https://i.pravatar.cc/150?u=rodrigo',
      level: 7,
      totalXP: 950,
      badges: ['gamer'],
      bio: 'Conciliando jogos e estudos 🎮',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      lastActive: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    PublicUserProfile(
      userId: 'user_19',
      displayName: 'Aline Oliveira',
      photoUrl: 'https://i.pravatar.cc/150?u=aline',
      level: 10,
      totalXP: 2200,
      badges: ['artist'],
      bio: 'Arte como terapia 🎨',
      createdAt: DateTime.now().subtract(const Duration(days: 65)),
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PublicUserProfile(
      userId: 'user_20',
      displayName: 'Gustavo Souza',
      photoUrl: 'https://i.pravatar.cc/150?u=gustavo',
      level: 14,
      totalXP: 4100,
      badges: ['developer'],
      bio: 'Dev Flutter | Coding Life 💻',
      createdAt: DateTime.now().subtract(const Duration(days: 115)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    PublicUserProfile(
      userId: 'user_21',
      displayName: 'Leticia Almeida',
      photoUrl: 'https://i.pravatar.cc/150?u=leticia',
      level: 5,
      totalXP: 600,
      badges: ['student'],
      bio: 'Estudante de Psicologia',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      lastActive: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PublicUserProfile(
      userId: 'user_22',
      displayName: 'Felipe Rodrigues',
      photoUrl: 'https://i.pravatar.cc/150?u=felipe',
      level: 17,
      totalXP: 6200,
      badges: ['runner'],
      bio: 'Maratonista em construção 🏃‍♂️',
      createdAt: DateTime.now().subtract(const Duration(days: 140)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PublicUserProfile(
      userId: 'user_23',
      displayName: 'Juliana Rocha',
      photoUrl: 'https://i.pravatar.cc/150?u=juliana',
      level: 8,
      totalXP: 1300,
      badges: ['cat_lover'],
      bio: 'Mãe de 3 gatos 🐱',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PublicUserProfile(
      userId: 'user_24',
      displayName: 'Daniel Martins',
      photoUrl: 'https://i.pravatar.cc/150?u=daniel',
      level: 11,
      totalXP: 2900,
      badges: ['musician'],
      bio: 'Música cura a alma 🎵',
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
      lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PublicUserProfile(
      userId: 'user_25',
      displayName: 'Roberta Costa',
      photoUrl: 'https://i.pravatar.cc/150?u=roberta',
      level: 6,
      totalXP: 750,
      badges: ['traveler'],
      bio: 'Planejando a próxima viagem ✈️',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      lastActive: DateTime.now().subtract(const Duration(hours: 9)),
    ),
  ];

  // ===========================================================================
  // FOLLOW STATS
  // ===========================================================================

  static final Map<String, FollowStats> _mockFollowStats = {
    'user_admin': const FollowStats(
      userId: 'user_admin',
      followersCount: 15420,
      followingCount: 0,
    ),
    'user_1': const FollowStats(
      userId: 'user_1',
      followersCount: 1250,
      followingCount: 45,
    ),
    'user_2': const FollowStats(
      userId: 'user_2',
      followersCount: 89,
      followingCount: 120,
    ),
    'user_3': const FollowStats(
      userId: 'user_3',
      followersCount: 342,
      followingCount: 150,
    ),
    'user_4': const FollowStats(
      userId: 'user_4',
      followersCount: 23,
      followingCount: 67,
    ),
    'user_5': const FollowStats(
      userId: 'user_5',
      followersCount: 2450,
      followingCount: 300,
    ),
    'user_6': const FollowStats(
      userId: 'user_6',
      followersCount: 156,
      followingCount: 89,
    ),
    'user_7': const FollowStats(
      userId: 'user_7',
      followersCount: 567,
      followingCount: 230,
    ),
    'user_8': const FollowStats(
      userId: 'user_8',
      followersCount: 45,
      followingCount: 100,
    ),
    'user_9': const FollowStats(
      userId: 'user_9',
      followersCount: 1200,
      followingCount: 50,
    ),
    'user_10': const FollowStats(
      userId: 'user_10',
      followersCount: 890,
      followingCount: 400,
    ),
    'user_11': const FollowStats(
      userId: 'user_11',
      followersCount: 67,
      followingCount: 80,
    ),
    'user_12': const FollowStats(
      userId: 'user_12',
      followersCount: 340,
      followingCount: 210,
    ),
    'user_13': const FollowStats(
      userId: 'user_13',
      followersCount: 120,
      followingCount: 90,
    ),
    'user_14': const FollowStats(
      userId: 'user_14',
      followersCount: 450,
      followingCount: 300,
    ),
    'user_15': const FollowStats(
      userId: 'user_15',
      followersCount: 12,
      followingCount: 50,
    ),
    'user_16': const FollowStats(
      userId: 'user_16',
      followersCount: 1890,
      followingCount: 150,
    ),
    'user_17': const FollowStats(
      userId: 'user_17',
      followersCount: 560,
      followingCount: 400,
    ),
    'user_18': const FollowStats(
      userId: 'user_18',
      followersCount: 78,
      followingCount: 60,
    ),
    'user_19': const FollowStats(
      userId: 'user_19',
      followersCount: 230,
      followingCount: 180,
    ),
    'user_20': const FollowStats(
      userId: 'user_20',
      followersCount: 670,
      followingCount: 340,
    ),
    'user_21': const FollowStats(
      userId: 'user_21',
      followersCount: 45,
      followingCount: 90,
    ),
    'user_22': const FollowStats(
      userId: 'user_22',
      followersCount: 980,
      followingCount: 200,
    ),
    'user_23': const FollowStats(
      userId: 'user_23',
      followersCount: 156,
      followingCount: 300,
    ),
    'user_24': const FollowStats(
      userId: 'user_24',
      followersCount: 340,
      followingCount: 250,
    ),
    'user_25': const FollowStats(
      userId: 'user_25',
      followersCount: 67,
      followingCount: 120,
    ),
  };

  // ===========================================================================
  // METHODS
  // ===========================================================================

  static PublicUserProfile? getUserProfile(String userId) {
    try {
      return _mockUsers.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  static List<PublicUserProfile> searchUsers(String query) {
    final lowerQuery = query.toLowerCase();
    return _mockUsers
        .where((u) => u.displayName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  static FollowStats getFollowStats(String userId) {
    return _mockFollowStats[userId] ?? FollowStats(userId: userId);
  }

  static List<PublicUserProfile> getOdysseyTeam() {
    return _mockUsers.where((u) {
      return u.userId.startsWith('bot_') || u.userId == 'user_admin';
    }).toList();
  }

  // ===========================================================================
  // POSTS
  // ===========================================================================

  static final List<Post> _mockPosts = [
    // ===========================================================================
    // POSTS DOS BOTS (ambientação)
    // ===========================================================================
    // 🎧 BEATNIX - Música
    Post(
      id: 'post_bot_beatnix_1',
      userId: 'bot_beatnix',
      userName: 'Beatnix',
      userPhotoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=beatnix&backgroundColor=6366f1',
      userLevel: 99,
      authorFlair: '🎧 Robô Residente',
      content:
          '🎧 Aquele momento que você acha a faixa perfeita e o foco vem natural. A rádio Lofi tá com uma sequência incrível agora. Quem aí tá precisando de uma vibe assim?',
      type: PostType.text,
      upvotes: 45,
      downvotes: 0,
      commentCount: 8,
      viewCount: 320,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      tags: ['música', 'lofi', 'foco'],
      categories: [CommunityTopic.productivity.name],
    ),
    // 🤖 ERRO 404 - Humor
    Post(
      id: 'post_bot_erro404_1',
      userId: 'bot_erro404',
      userName: 'Erro 404',
      userPhotoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=erro404&backgroundColor=10b981',
      userLevel: 99,
      authorFlair: '🤖 Estagiário de Silício',
      content:
          'Tentei calcular quantas vezes você checou o celular hoje, mas meu processador travou em "undefined". Aparentemente, o número é maior que minha RAM consegue processar. 💀📱',
      type: PostType.text,
      upvotes: 89,
      downvotes: 2,
      commentCount: 15,
      viewCount: 580,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      tags: ['humor', 'tecnologia'],
      categories: [CommunityTopic.general.name],
    ),
    // 🧠 WIKI - Curiosidades
    Post(
      id: 'post_bot_wiki_1',
      userId: 'bot_wiki',
      userName: 'Wiki',
      userPhotoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=wiki&backgroundColor=8b5cf6',
      userLevel: 99,
      authorFlair: '🧠 Banco de Dados Vivo',
      content:
          '🧠 Você sabia que o cérebro consome a mesma energia que uma lâmpada de 20 watts? E que a maior parte dessa energia vai para... manter você distraído? Irônico, né? Use essa energia pra algo incrível hoje.',
      type: PostType.insight,
      upvotes: 156,
      downvotes: 1,
      commentCount: 23,
      viewCount: 890,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      tags: ['curiosidades', 'cérebro', 'produtividade'],
      categories: [CommunityTopic.mindfulness.name],
    ),
    // ⚡ TURBO - Gamificação
    Post(
      id: 'post_bot_turbo_1',
      userId: 'bot_turbo',
      userName: 'Turbo',
      userPhotoUrl:
          'https://api.dicebear.com/7.x/bottts/png?seed=turbo&backgroundColor=f59e0b',
      userLevel: 99,
      authorFlair: '⚡ Gerente de Caos',
      content:
          '⚡ DESAFIO DO DIA!\n\nQuem completar 3 tarefas antes do almoço ganha meu respeito eterno. E talvez XP virtual (que não vale nada, mas é legal).\n\nBora? 🚀💪',
      type: PostType.text,
      upvotes: 78,
      downvotes: 1,
      commentCount: 12,
      viewCount: 450,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      tags: ['desafio', 'produtividade', 'gamificação'],
      categories: [
        CommunityTopic.achievements.name,
        CommunityTopic.productivity.name,
      ],
    ),
    // ===========================================================================
    // 📌 PINNED POST
    // ===========================================================================
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
      commentCount: 2,
      viewCount: 15000,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      metadata: {'isPinned': true},
      tags: ['anuncio', 'regras', 'comunidade'],
      categories: [CommunityTopic.general.name],
    ),
    // MOOD POST (Ok)
    Post(
      id: 'post_mood_ok',
      userId: 'user_1',
      userName: 'Maria Santos',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=maria',
      userLevel: 15,
      content: 'Tudo tranquilo por aqui.',
      type: PostType.mood,
      upvotes: 12,
      downvotes: 0,
      commentCount: 1,
      viewCount: 150,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      metadata: {'moodLabel': 'Ok', 'moodEmoji': '😐'},
      categories: [CommunityTopic.general.name],
    ),
    // MOOD POST (Bem)
    Post(
      id: 'post_mood_bem',
      userId: 'user_2',
      userName: 'Lucas Ferreira',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=lucas',
      userLevel: 8,
      content: 'Dia produtivo!',
      type: PostType.mood,
      upvotes: 24,
      downvotes: 1,
      commentCount: 5,
      viewCount: 300,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      metadata: {'moodLabel': 'Bem', 'moodEmoji': '🙂'},
      categories: [CommunityTopic.productivity.name],
    ),
    // IMAGE POST
    Post(
      id: 'post_img_1',
      userId: 'user_5',
      userName: 'Julia Santos',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=julia',
      userLevel: 20,
      content: 'Cantinho de estudos organizado! 📚✨',
      type: PostType.image,
      imageUrls: [
        'https://images.unsplash.com/photo-1499750310159-5b5fafef6c9e',
      ],
      upvotes: 156,
      downvotes: 2,
      commentCount: 0,
      viewCount: 2400,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      tags: ['estudos', 'setup', 'produtividade'],
      categories: [CommunityTopic.productivity.name],
    ),
    // TEXT POST with High Engagement
    Post(
      id: 'post_text_1',
      userId: 'user_16',
      userName: 'Patricia Silva',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=patricia',
      userLevel: 19,
      content:
          'A meditação mudou minha vida nos últimos 6 meses. Quem aqui também pratica diariamente?',
      type: PostType.text,
      upvotes: 340,
      downvotes: 5,
      commentCount: 2,
      viewCount: 5600,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      tags: ['meditação', 'mindfulness'],
      categories: [CommunityTopic.mindfulness.name],
    ),
    // RANDOM POSTS
    Post(
      id: 'post_rand_1',
      userId: 'user_20',
      userName: 'Gustavo Souza',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=gustavo',
      userLevel: 14,
      content: 'Finalizei meu app! 🚀',
      type: PostType.image,
      imageUrls: ['https://images.unsplash.com/photo-1551650975-87deedd944c3'],
      upvotes: 560,
      downvotes: 10,
      commentCount: 1,
      viewCount: 8900,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      tags: ['dev', 'flutter', 'conquista'],
      categories: [CommunityTopic.achievements.name],
    ),
    Post(
      id: 'post_rand_2',
      userId: 'user_13',
      userName: 'Mariana Costa',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=mariana',
      userLevel: 9,
      content: 'Lendo "Hábitos Atômicos". Recomendo muito!',
      type: PostType.text,
      upvotes: 89,
      downvotes: 0,
      commentCount: 0,
      viewCount: 1200,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      tags: ['leitura', 'livros'],
      categories: [CommunityTopic.productivity.name],
    ),
    Post(
      id: 'post_rand_3',
      userId: 'user_22',
      userName: 'Felipe Rodrigues',
      userPhotoUrl: 'https://i.pravatar.cc/150?u=felipe',
      userLevel: 17,
      content: '10km hoje de manhã! 🏃‍♂️💨',
      type: PostType.mood,
      upvotes: 120,
      downvotes: 1,
      commentCount: 0,
      viewCount: 1500,
      metadata: {'moodLabel': 'Energético', 'moodEmoji': '⚡'},
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      categories: [CommunityTopic.general.name, CommunityTopic.motivation.name],
    ),
  ];

  static List<Post> getPosts({int limit = 20}) {
    return _mockPosts.take(limit).toList();
  }

  static Post? getPost(String postId) {
    try {
      return _mockPosts.firstWhere((p) => p.id == postId);
    } catch (_) {
      return null;
    }
  }

  static List<Post> getPostsByTopic(CommunityTopic topic, {int limit = 20}) {
    return _mockPosts
        .where((p) => p.categories.contains(topic.name))
        .take(limit)
        .toList();
  }

  static List<Post> searchPosts(String query) {
    final lower = query.toLowerCase();
    return _mockPosts
        .where(
          (p) =>
              p.content.toLowerCase().contains(lower) ||
              p.tags.any((t) => t.toLowerCase().contains(lower)) ||
              p.userName.toLowerCase().contains(lower),
        )
        .toList();
  }

  static List<Post> getTrendingPosts({int limit = 5}) {
    final sorted = List<Post>.from(_mockPosts);
    sorted.sort((a, b) => b.engagement.compareTo(a.engagement));
    return sorted.take(limit).toList();
  }

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

  // ===========================================================================
  // COMMENTS
  // ===========================================================================

  static final Map<String, List<Comment>> _mockComments = {
    'post_pinned_1': [
      Comment(
        id: 'c_p1_1',
        postId: 'post_pinned_1',
        userId: 'user_1',
        userName: 'Maria Santos',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=maria',
        content: 'Ótima iniciativa!',
        createdAt: DateTime.now().subtract(const Duration(days: 29)),
      ),
      Comment(
        id: 'c_p1_2',
        postId: 'post_pinned_1',
        userId: 'user_2',
        userName: 'Lucas Ferreira',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=lucas',
        content: 'Ansioso para interagir com a comunidade.',
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
      ),
    ],
    'post_mood_ok': [
      Comment(
        id: 'c_ok_1',
        postId: 'post_mood_ok',
        userId: 'user_3',
        userName: 'Ana Silva',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=ana',
        content: 'Isso aí, um dia de cada vez.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
    'post_text_1': [
      Comment(
        id: 'c_t1_1',
        postId: 'post_text_1',
        userId: 'user_20',
        userName: 'Gustavo Souza',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=gustavo',
        content: 'Pratico há 2 anos e recomendo!',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Comment(
        id: 'c_t1_2',
        postId: 'post_text_1',
        userId: 'user_5',
        userName: 'Julia Santos',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=julia',
        content: 'Qual app você usa?',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
    'post_rand_1': [
      Comment(
        id: 'c_r1_1',
        postId: 'post_rand_1',
        userId: 'user_12',
        userName: 'Gabriel Martins',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=gabriel',
        content: 'Parabéns mano! Ficou show.',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
    ],
  };

  static List<Comment> getComments(String postId) {
    return _mockComments[postId] ?? [];
  }

  static Comment addComment(
    String postId,
    String content,
    String userId,
    String userName,
  ) {
    final comment = Comment(
      id: 'local_comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: userId,
      userName: userName,
      content: content,
      createdAt: DateTime.now(),
    );

    if (_mockComments.containsKey(postId)) {
      _mockComments[postId]!.insert(0, comment);
    } else {
      _mockComments[postId] = [comment];
    }

    return comment;
  }
}
