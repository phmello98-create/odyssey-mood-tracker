import '../domain/post.dart';
import '../domain/user_profile.dart';
import '../domain/topic.dart';

/// Repositório Mock para desenvolvimento e testes
/// Retorna dados fictícios realistas com karma, badges, imagens, tags e views
class MockCommunityData {
  static final List<Post> _mockPosts = [
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
  ];

  static final List<PublicUserProfile> _mockUsers = [
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
