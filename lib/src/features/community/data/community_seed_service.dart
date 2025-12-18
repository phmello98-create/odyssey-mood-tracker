import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/post_dto.dart';
import '../domain/topic.dart';
import '../domain/post.dart';
import 'community_repository.dart';

/// Serviço para popular o banco de dados com dados iniciais
class CommunitySeedService {
  final CommunityRepository _repository;
  final FirebaseAuth _auth;

  CommunitySeedService({
    required CommunityRepository repository,
    required FirebaseAuth auth,
  }) : _repository = repository, _auth = auth;

  Future<void> seedInitialPosts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final existingPosts = await _repository.getFeed(limit: 1);
    if (existingPosts.isNotEmpty) return; // Já tem dados

    final seedPosts = [
      CreatePostDto(
        content: 'Olá pessoal! Começando minha jornada no Odyssey hoje. Alguém tem dicas para quem está iniciando no rastreamento de humor?',
        type: PostType.text,
        categories: [CommunityTopic.general.name, CommunityTopic.support.name],
      ),
      CreatePostDto(
        content: 'Acabei de completar 50 horas de foco usando o Timer! Me sinto muito mais produtivo. 🚀',
        type: PostType.achievement,
        categories: [CommunityTopic.productivity.name, CommunityTopic.achievements.name],
        metadata: {'achievementType': 'timer_master', 'hours': 50},
      ),
      CreatePostDto(
        content: 'Dica do dia: Pratique 5 minutos de respiração consciente antes de começar uma tarefa difícil. Ajuda demais na ansiedade!',
        type: PostType.insight,
        categories: [CommunityTopic.mindfulness.name, CommunityTopic.tips.name],
      ),
      CreatePostDto(
        content: 'Hoje o dia está sendo desafiador emocionalmente, mas estou feliz por conseguir registrar tudo aqui. É um processo.',
        type: PostType.mood,
        categories: [CommunityTopic.wellness.name, CommunityTopic.support.name],
        metadata: {'mood': 'tired_but_stable'},
      ),
      CreatePostDto(
        content: 'Quais são as playlists favoritas de vocês para estudar? Eu gosto de Lofi Beats! 🎧',
        type: PostType.text,
        categories: [CommunityTopic.productivity.name, CommunityTopic.general.name],
      ),
      CreatePostDto(
        content: 'Completei minha primeira semana de hábitos saudáveis! Beber 2L de água por dia faz diferença.',
        type: PostType.achievement,
        categories: [CommunityTopic.wellness.name, CommunityTopic.achievements.name],
      ),
    ];

    for (final dto in seedPosts) {
      await _repository.createPost(dto);
      // Pequeno delay para os timestamps ficarem diferentes
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
